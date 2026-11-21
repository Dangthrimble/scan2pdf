package main

import (
	"archive/zip"
	"bytes"
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestArchivePreservesExecutableAndExtras(t *testing.T) {
	path := filepath.Join(t.TempDir(), "package.zip")
	binary := []byte("test executable bytes")
	extra := []byte("# test readme\n")
	if err := writeArchive(path, "scan2pdf-dev-test", []entry{
		{"scan2pdf", binary, 0755},
		{"README.md", extra, 0644},
	}); err != nil {
		t.Fatal(err)
	}
	archive, err := zip.OpenReader(path)
	if err != nil {
		t.Fatal(err)
	}
	defer archive.Close()
	contents := map[string][]byte{}
	for _, file := range archive.File {
		reader, err := file.Open()
		if err != nil {
			t.Fatal(err)
		}
		data, err := io.ReadAll(reader)
		reader.Close()
		if err != nil {
			t.Fatal(err)
		}
		name := strings.TrimPrefix(file.Name, "scan2pdf-dev-test/")
		contents[name] = data
		if name == "scan2pdf" && file.Mode().Perm() != 0755 {
			t.Fatal("executable permissions lost")
		}
	}
	if !bytes.Equal(contents["scan2pdf"], binary) || !bytes.Equal(contents["README.md"], extra) {
		t.Fatal("packaged bytes differ")
	}
	manifest := string(contents["SHA256SUMS.txt"])
	for name, data := range map[string][]byte{"scan2pdf": binary, "README.md": extra} {
		if !strings.Contains(manifest, fmt.Sprintf("%x  %s\n", sha256.Sum256(data), name)) {
			t.Fatalf("missing or incorrect checksum for %s", name)
		}
	}
	before, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := writeArchive(path, "replacement", nil); err == nil {
		t.Fatal("existing package was overwritten")
	}
	after, _ := os.ReadFile(path)
	if !bytes.Equal(before, after) {
		t.Fatal("existing package changed after refusal")
	}
}

func TestPlatformFor(t *testing.T) {
	for target, want := range map[string]string{
		"darwin/amd64":  "macos-intel",
		"darwin/arm64":  "macos-apple-silicon",
		"windows/amd64": "windows-x64",
		"windows/arm64": "windows-arm64",
		"linux/amd64":   "linux-x64",
		"linux/arm64":   "linux-arm64",
	} {
		if got := platformFor(target); got != want {
			t.Errorf("platformFor(%q) = %q, want %q", target, got, want)
		}
	}
	if got := platformFor("plan9/amd64"); got != "" {
		t.Errorf("platformFor(plan9/amd64) = %q, want empty", got)
	}
}

func TestLoadConfigRejectsUnsafePaths(t *testing.T) {
	dir := t.TempDir()
	valid := filepath.Join(dir, "valid.json")
	if err := os.WriteFile(valid, []byte(`{
		"product": "example",
		"module": "example.com/example",
		"commands": ["example"],
		"include": ["README.md"]
	}`), 0644); err != nil {
		t.Fatal(err)
	}
	if _, err := loadConfig(valid); err != nil {
		t.Fatal(err)
	}

	invalid := filepath.Join(dir, "invalid.json")
	if err := os.WriteFile(invalid, []byte(`{
		"product": "example",
		"module": "example.com/example",
		"commands": ["example"],
		"include": ["../outside.json"]
	}`), 0644); err != nil {
		t.Fatal(err)
	}
	if _, err := loadConfig(invalid); err == nil {
		t.Fatal("expected unsafe include path to be rejected")
	}
}
