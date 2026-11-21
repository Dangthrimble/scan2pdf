// buildpackage creates a portable release archive from tested executables.
package main

import (
	"archive/zip"
	"bytes"
	"crypto/sha256"
	"debug/buildinfo"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime/debug"
	"sort"
	"strings"
	"time"
)

type releaseConfig struct {
	Product  string   `json:"product"`
	Module   string   `json:"module"`
	Commands []string `json:"commands"`
	Include  []string `json:"include"`
}

type entry struct {
	name string
	data []byte
	mode fs.FileMode
}

type binaryList []string

func (b *binaryList) String() string { return strings.Join(*b, ",") }

func (b *binaryList) Set(value string) error {
	*b = append(*b, value)
	return nil
}

var versionPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._+-]*$`)

func main() {
	var binaries binaryList
	flag.Var(&binaries, "binary", "tested executable to include (repeat for each command)")
	version := flag.String("version", "", "version embedded in the executables")
	configPath := flag.String("config", "release.json", "release configuration file")
	out := flag.String("out", "dist/packages", "directory for the ZIP and checksum")
	flag.Parse()
	if err := packageRelease(binaries, *version, *configPath, *out); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func packageRelease(binaries []string, version, configPath, out string) error {
	if len(binaries) == 0 {
		return errors.New("supply at least one -binary")
	}
	if !versionPattern.MatchString(version) {
		return errors.New("version must contain only letters, digits, dots, underscores, pluses or hyphens")
	}
	cfg, err := loadConfig(configPath)
	if err != nil {
		return err
	}

	var platform, goos, goarch, goVersion, commit, modified string
	var dependencies []*debug.Module
	for _, binary := range binaries {
		info, err := buildinfo.ReadFile(binary)
		if err != nil {
			return fmt.Errorf("%s: %w", binary, err)
		}
		settings := settingsMap(info.Settings)
		binaryOS, binaryArch := settings["GOOS"], settings["GOARCH"]
		binaryPlatform := platformFor(binaryOS + "/" + binaryArch)
		if binaryPlatform == "" {
			return fmt.Errorf("%s: unsupported platform %s/%s", binary, binaryOS, binaryArch)
		}
		if settings["CGO_ENABLED"] != "0" {
			return fmt.Errorf("%s: release executables must be built with CGO_ENABLED=0", binary)
		}
		command := strings.TrimSuffix(filepath.Base(binary), ".exe")
		if !containsString(cfg.Commands, command) {
			return fmt.Errorf("%s: command %q is not listed in %s", binary, command, configPath)
		}
		if info.Path != cfg.Module+"/cmd/"+command {
			return fmt.Errorf("%s: build path is %q, expected %q", binary, info.Path, cfg.Module+"/cmd/"+command)
		}
		if platform == "" {
			platform, goos, goarch = binaryPlatform, binaryOS, binaryArch
			goVersion, commit, modified = info.GoVersion, settings["vcs.revision"], settings["vcs.modified"]
			dependencies = info.Deps
		} else if binaryPlatform != platform {
			return fmt.Errorf("%s: platform %s differs from %s", binary, binaryPlatform, platform)
		}

		absolute, err := filepath.Abs(binary)
		if err != nil {
			return err
		}
		output, err := exec.Command(absolute, "--version").CombinedOutput()
		if err != nil || !strings.Contains(string(output), version) {
			return fmt.Errorf("%s: --version does not report %q: %q (%v)", binary, version, output, err)
		}
	}
	if commit == "" {
		commit = "unknown"
	}
	if modified == "" {
		modified = "unknown"
	}

	files := make([]entry, 0, 32)
	add := func(name, path string, mode fs.FileMode) error {
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		files = append(files, entry{name, data, mode})
		return nil
	}
	for _, binary := range binaries {
		if err := add(filepath.Base(binary), binary, 0755); err != nil {
			return err
		}
	}
	for _, name := range []string{"README.md", "INSTALL.md", "LICENSE", "BACKLOG.md", "DEVELOPMENT_HISTORY.md"} {
		if err := add(name, name, 0644); err != nil {
			return err
		}
	}
	docs, err := collectDocs("docs")
	if err != nil {
		return err
	}
	files = append(files, docs...)
	for _, name := range cfg.Include {
		clean := filepath.ToSlash(filepath.Clean(name))
		if err := add(clean, name, 0644); err != nil {
			return err
		}
	}

	buildKind := "Development build"
	if strings.HasPrefix(version, "v") && !strings.HasPrefix(version, "dev-") {
		buildKind = "Release build"
	}
	versionText := fmt.Sprintf(
		"%s %s\nPlatform: %s (%s/%s)\nCommit: %s\nSource modified: %s\nGo: %s\n%s; updates are manual.\n",
		cfg.Product, version, platform, goos, goarch, commit, modified, goVersion, buildKind,
	)
	files = append(files, entry{"VERSION.txt", []byte(versionText), 0644})
	licenses, err := dependencyLicenses(dependencies, cfg.Product)
	if err != nil {
		return err
	}
	files = append(files, licenses...)

	if err := os.MkdirAll(out, 0755); err != nil {
		return err
	}
	stem := fmt.Sprintf("%s-%s-%s", cfg.Product, version, platform)
	archivePath := filepath.Join(out, stem+".zip")
	if err := writeArchive(archivePath, stem, files); err != nil {
		return err
	}
	data, err := os.ReadFile(archivePath)
	if err != nil {
		return err
	}
	checksum := fmt.Sprintf("%x  %s\n", sha256.Sum256(data), filepath.Base(archivePath))
	if err := os.WriteFile(archivePath+".sha256", []byte(checksum), 0644); err != nil {
		return err
	}
	fmt.Println(archivePath)
	return nil
}

func loadConfig(path string) (releaseConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return releaseConfig{}, err
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	var cfg releaseConfig
	if err := decoder.Decode(&cfg); err != nil {
		return releaseConfig{}, fmt.Errorf("%s: %w", path, err)
	}
	if !versionPattern.MatchString(cfg.Product) {
		return releaseConfig{}, fmt.Errorf("%s: invalid product %q", path, cfg.Product)
	}
	if strings.TrimSpace(cfg.Module) == "" {
		return releaseConfig{}, fmt.Errorf("%s: module is required", path)
	}
	if len(cfg.Commands) == 0 {
		return releaseConfig{}, fmt.Errorf("%s: at least one command is required", path)
	}
	seen := map[string]bool{}
	for _, command := range cfg.Commands {
		if command == "" || command == "." || command == ".." || strings.ContainsAny(command, `/\`) {
			return releaseConfig{}, fmt.Errorf("%s: invalid command %q", path, command)
		}
		if seen[command] {
			return releaseConfig{}, fmt.Errorf("%s: duplicate command %q", path, command)
		}
		seen[command] = true
	}
	for _, include := range cfg.Include {
		clean := filepath.Clean(include)
		if filepath.IsAbs(clean) || clean == "." || clean == ".." || strings.HasPrefix(clean, ".."+string(os.PathSeparator)) {
			return releaseConfig{}, fmt.Errorf("%s: include %q must stay inside the repository", path, include)
		}
	}
	return cfg, nil
}

func settingsMap(settings []debug.BuildSetting) map[string]string {
	out := make(map[string]string, len(settings))
	for _, setting := range settings {
		out[setting.Key] = setting.Value
	}
	return out
}

func platformFor(target string) string {
	return map[string]string{
		"darwin/amd64":  "macos-intel",
		"darwin/arm64":  "macos-apple-silicon",
		"windows/amd64": "windows-x64",
		"windows/arm64": "windows-arm64",
		"linux/amd64":   "linux-x64",
		"linux/arm64":   "linux-arm64",
	}[target]
}

func containsString(values []string, want string) bool {
	for _, value := range values {
		if value == want {
			return true
		}
	}
	return false
}

func collectDocs(root string) ([]entry, error) {
	var files []entry
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !d.Type().IsRegular() {
			return nil
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		files = append(files, entry{filepath.ToSlash(path), data, 0644})
		return nil
	})
	return files, err
}

func dependencyLicenses(deps []*debug.Module, product string) ([]entry, error) {
	var files []entry
	var index strings.Builder
	index.WriteString("Third-party software included in this build\n\n")
	index.WriteString(product + " is licensed under the MIT licence; see LICENSE.\n")
	index.WriteString("The dependencies listed below retain their own licences and notices.\n\n")

	goRootOutput, err := exec.Command("go", "env", "GOROOT").Output()
	if err != nil {
		return nil, err
	}
	data, err := goLicense(strings.TrimSpace(string(goRootOutput)))
	if err != nil {
		return nil, err
	}
	files = append(files, entry{"THIRD_PARTY_LICENSES/Go/LICENSE", data, 0644})
	index.WriteString("Go standard library/runtime: THIRD_PARTY_LICENSES/Go/LICENSE\n")

	for _, dep := range deps {
		if dep == nil || dep.Path == "" {
			continue
		}
		if dep.Replace != nil {
			return nil, fmt.Errorf("cannot package an unreviewed module replacement: %s", dep.Path)
		}
		output, err := exec.Command("go", "list", "-m", "-json", dep.Path).Output()
		if err != nil {
			return nil, fmt.Errorf("locate dependency %s: %w", dep.Path, err)
		}
		var module struct{ Dir, Version string }
		if err := json.Unmarshal(output, &module); err != nil {
			return nil, err
		}
		if module.Dir == "" || module.Version != dep.Version {
			return nil, fmt.Errorf("dependency cache does not match binary: %s", dep.Path)
		}
		found := false
		err = filepath.WalkDir(module.Dir, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if !d.Type().IsRegular() {
				return nil
			}
			upper := strings.ToUpper(d.Name())
			if !(upper == "PATENTS" || strings.HasPrefix(upper, "LICENSE") || strings.HasPrefix(upper, "NOTICE") || strings.HasPrefix(upper, "COPYING")) {
				return nil
			}
			data, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			rel, err := filepath.Rel(module.Dir, path)
			if err != nil {
				return err
			}
			name := "THIRD_PARTY_LICENSES/" + dep.Path + "@" + dep.Version + "/" + filepath.ToSlash(rel)
			files = append(files, entry{name, data, 0644})
			found = true
			return nil
		})
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, fmt.Errorf("no licence found for %s", dep.Path)
		}
		fmt.Fprintf(&index, "%s %s: THIRD_PARTY_LICENSES/%s@%s/\n", dep.Path, dep.Version, dep.Path, dep.Version)
	}
	files = append(files, entry{"THIRD_PARTY_NOTICES.txt", []byte(index.String()), 0644})
	return files, nil
}

func goLicense(goRoot string) ([]byte, error) {
	candidates := []string{filepath.Join(goRoot, "LICENSE")}
	// Package-managed Go installations sometimes place the licence in a
	// versioned documentation directory instead of the GOROOT root.
	for _, pattern := range []string{
		filepath.Join(goRoot, "..", "share", "doc", "go*", "LICENSE"),
		filepath.Join(goRoot, "..", "..", "share", "doc", "go*", "LICENSE"),
	} {
		if matches, err := filepath.Glob(pattern); err == nil {
			candidates = append(candidates, matches...)
		}
	}
	for _, path := range candidates {
		data, err := os.ReadFile(path)
		if err == nil {
			return data, nil
		}
	}
	return nil, fmt.Errorf("go licence not found under %s", goRoot)
}

func writeArchive(path, stem string, files []entry) (err error) {
	seen := map[string]bool{}
	for _, file := range files {
		if seen[file.name] {
			return fmt.Errorf("duplicate package member %s", file.name)
		}
		seen[file.name] = true
	}
	sort.Slice(files, func(i, j int) bool { return files[i].name < files[j].name })

	var manifest strings.Builder
	for _, file := range files {
		fmt.Fprintf(&manifest, "%x  %s\n", sha256.Sum256(file.data), file.name)
	}
	files = append(files, entry{"SHA256SUMS.txt", []byte(manifest.String()), 0644})

	output, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer func() {
		output.Close()
		if err != nil {
			os.Remove(path)
		}
	}()
	archive := zip.NewWriter(output)
	for _, file := range files {
		header := &zip.FileHeader{Name: stem + "/" + file.name, Method: zip.Deflate}
		header.SetMode(file.mode)
		header.Modified = time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
		writer, err := archive.CreateHeader(header)
		if err != nil {
			return err
		}
		if _, err := writer.Write(file.data); err != nil {
			return err
		}
	}
	if err := archive.Close(); err != nil {
		return err
	}
	if err := output.Close(); err != nil {
		return err
	}

	reader, err := zip.OpenReader(path)
	if err != nil {
		return err
	}
	defer reader.Close()
	if len(reader.File) != len(files) {
		return errors.New("package verification failed: wrong file count")
	}
	for i, file := range reader.File {
		content, err := file.Open()
		if err != nil {
			return err
		}
		data, err := io.ReadAll(content)
		content.Close()
		want := files[i]
		if err != nil || file.Name != stem+"/"+want.name || file.Mode().Perm() != want.mode || !bytes.Equal(data, want.data) {
			return fmt.Errorf("package verification failed: %s", file.Name)
		}
	}
	return nil
}
