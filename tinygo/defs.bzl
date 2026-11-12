"Public API re-exports"

load("@rules_go//go:def.bzl", "go_path")
load("//tinygo/private:rules.bzl", _tinygo_binary = "tinygo_binary")

def tinygo_binary(name, embed = None, mod = None, sum = None, **kwargs):
    """Builds a TinyGo binary.

    Set `embed` to `go_library` targets, like `go_binary`. A hidden `go_path`
    target materializes them and their transitive dependencies, and TinyGo builds
    from that tree in GOPATH mode: no go.mod and no network access.

    For a program that imports only the standard library, `srcs` alone is enough.

    Building by `importpath` against a go.mod (module mode) is deprecated: the go
    command downloads the dependencies during the build instead of using the ones
    Bazel resolved. To migrate, declare the main package as a `go_library` and
    pass it in `embed`; `importpath`, `mod`, `sum` and `package_dir` can then go.

    Args:
      name: Target name.
      embed: go_library targets to embed, like go_binary.
      mod: Deprecated: use embed. go.mod label for importpath builds; ignored when embed is set.
      sum: Deprecated: use embed. go.sum label for importpath builds; ignored when embed is set.
      **kwargs: Remaining attributes passed to the underlying tinygo_binary rule.
    """
    if embed:
        if mod or sum:
            # buildifier: disable=print
            print("{}: mod and sum are deprecated and ignored when embed is set; remove them.".format(
                native.package_relative_label(name),
            ))
        gopath_name = name + "_gopath"
        go_path(
            name = gopath_name,
            deps = embed,
            mode = "copy",
            visibility = ["//visibility:private"],
        )
        _tinygo_binary(
            name = name,
            embed = embed,
            gopath = ":" + gopath_name,
            **kwargs
        )
    else:
        _tinygo_binary(
            name = name,
            mod = mod,
            sum = sum,
            **kwargs
        )
