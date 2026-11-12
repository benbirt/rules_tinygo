package langversion_test

import (
	"os/exec"
	"strings"
	"testing"
)

// TestLanguageVersion runs the TinyGo-built host binary. "3 4 3" means the
// loop variable was per-iteration (Go 1.22) and both range forms worked.
func TestLanguageVersion(t *testing.T) {
	out, err := exec.Command("./langversion").CombinedOutput()
	if err != nil {
		t.Fatalf("running langversion: %v\n%s", err, out)
	}
	if got, want := strings.TrimSpace(string(out)), "3 4 3"; got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
