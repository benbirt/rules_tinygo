// Command builder runs TinyGo for a Bazel action.
//
// Bazel hands it execroot-relative paths. TinyGo and the go command it shells
// out to want absolute ones, and keep caches under HOME, so this wrapper
// resolves the paths and gives the build a private scratch directory.
package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

// absEnv returns the absolute form of the path in the named variable.
func absEnv(name string) (string, error) {
	v := os.Getenv(name)
	if v == "" {
		return "", fmt.Errorf("%s is not set", name)
	}
	return filepath.Abs(v)
}

func run() error {
	if len(os.Args) < 2 {
		return fmt.Errorf("usage: builder <tinygo> <args...>")
	}
	tinygo, err := filepath.Abs(os.Args[1])
	if err != nil {
		return err
	}
	args := append([]string(nil), os.Args[2:]...)
	for i := 0; i+1 < len(args); i++ {
		// The build may run in another directory (module mode), so the output
		// path must not depend on the working directory.
		if args[i] == "-o" {
			if args[i+1], err = filepath.Abs(args[i+1]); err != nil {
				return err
			}
		}
	}

	gobin, err := absEnv("BUILDER_GOBIN_PATH")
	if err != nil {
		return err
	}
	goroot, err := absEnv("BUILDER_GOROOT")
	if err != nil {
		return err
	}
	tinyGoRoot, err := absEnv("BUILDER_TINYGOROOT")
	if err != nil {
		return err
	}
	wasmOpt, err := absEnv("WASMOPT")
	if err != nil {
		return err
	}

	// TinyGo and the go command keep caches under HOME, and TinyGo records
	// paths below it in debug info. The scratch directory sits next to the
	// output: private to this action, and the same path on every run.
	scratch, err := absEnv("BUILDER_SCRATCH")
	if err != nil {
		return err
	}
	if err := os.RemoveAll(scratch); err != nil {
		return err
	}
	defer os.RemoveAll(scratch)
	home := filepath.Join(scratch, "home")
	if err := os.MkdirAll(home, 0o755); err != nil {
		return err
	}

	cmd := exec.Command(tinygo, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	cmd.Env = append(os.Environ(),
		"PATH="+gobin,
		"GOROOT="+goroot,
		"TINYGOROOT="+tinyGoRoot,
		"WASMOPT="+wasmOpt,
		"HOME="+home,
		// Never let the go command fetch a different Go toolchain.
		"GOTOOLCHAIN=local",
	)

	if gopathDir := os.Getenv("BUILDER_GOPATH_DIR"); gopathDir != "" {
		// GOPATH mode: all packages come from the go_path tree built by Bazel.
		gopathDir, err = filepath.Abs(gopathDir)
		if err != nil {
			return err
		}
		cmd.Env = append(cmd.Env,
			"GOPATH="+gopathDir,
			"GO111MODULE=off",
			"GOPROXY=off",
		)
	} else if gomod := os.Getenv("BUILDER_GOMOD"); gomod != "" {
		// Module mode: assemble the module in the scratch directory rather than
		// in the source tree, and let the go command download its dependencies.
		moduleDir := filepath.Join(scratch, "module")
		if err := copyFile(gomod, filepath.Join(moduleDir, "go.mod")); err != nil {
			return err
		}
		if gosum := os.Getenv("BUILDER_GOSUM"); gosum != "" {
			if err := copyFile(gosum, filepath.Join(moduleDir, "go.sum")); err != nil {
				return err
			}
		}
		if err := copyPackageSources(moduleDir); err != nil {
			return err
		}
		cmd.Dir = moduleDir
	}

	return cmd.Run()
}

func copyPackageSources(moduleDir string) error {
	specs := os.Getenv("BUILDER_COPY_SPECS")
	if specs == "" {
		return nil
	}
	for _, spec := range strings.Split(specs, ",") {
		parts := strings.SplitN(spec, "|", 2)
		if len(parts) != 2 {
			return fmt.Errorf("invalid BUILDER_COPY_SPECS entry %q", spec)
		}
		if err := copyFile(parts[1], filepath.Join(moduleDir, parts[0])); err != nil {
			return err
		}
	}
	return nil
}

func copyFile(src, dest string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(dest), 0o755); err != nil {
		return err
	}
	return os.WriteFile(dest, data, 0o644)
}
