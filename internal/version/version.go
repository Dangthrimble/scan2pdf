package version

import "runtime/debug"

// Version is the release tag. Release builds set it with -ldflags -X.
// A plain build leaves it as dev.
var Version = "dev"

// String returns the release tag when one was linked in, otherwise the
// module version from go install. A local build reports dev.
func String() string {
	if Version != "" && Version != "dev" {
		return Version
	}
	if info, ok := debug.ReadBuildInfo(); ok && !localVCS(info) {
		v := info.Main.Version
		if v != "" && v != "(devel)" {
			return v
		}
	}
	return "dev"
}

// localVCS reports a binary built from a checkout. Those builds carry VCS
// metadata. go install from a module does not, and Main.Version is the tag.
func localVCS(info *debug.BuildInfo) bool {
	for _, s := range info.Settings {
		if s.Key == "vcs" && s.Value != "" {
			return true
		}
	}
	return false
}
