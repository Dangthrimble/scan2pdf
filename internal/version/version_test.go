package version

import "testing"

func TestStringDevBuild(t *testing.T) {
	if got := String(); got != "dev" {
		t.Fatalf("String() = %q, want dev", got)
	}
}

func TestStringUsesLinkedVersion(t *testing.T) {
	prev := Version
	t.Cleanup(func() { Version = prev })
	Version = "v1.2.3"
	if got := String(); got != "v1.2.3" {
		t.Fatalf("String() = %q, want v1.2.3", got)
	}
}
