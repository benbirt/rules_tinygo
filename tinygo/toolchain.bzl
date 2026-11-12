"""This module implements the language-specific toolchain rule."""

def _tinygo_toolchain_impl(ctx):
    tinygo = None
    for f in ctx.files.tools:
        if f.path.endswith("bin/tinygo"):
            tinygo = f
            break
    if not tinygo:
        fail("tinygo not found in tools")

    return [platform_common.ToolchainInfo(
        tool_files = [tinygo],
        tinygo = tinygo.path,
        version = ctx.attr.version,
        srcs = ctx.files.srcs,
        targets = ctx.files.targets,
        libs = ctx.files.libs,
    )]

tinygo_toolchain = rule(
    implementation = _tinygo_toolchain_impl,
    attrs = {
        "tools": attr.label_list(mandatory = True),
        "srcs": attr.label_list(mandatory = True),
        "targets": attr.label_list(mandatory = True),
        "libs": attr.label_list(mandatory = True),
        "version": attr.string(
            doc = "TinyGo release, e.g. \"0.42.0\". Used to check that the Go SDK is one this release supports.",
        ),
    },
    doc = """Defines a tinygo compiler/runtime toolchain.

For usage see https://docs.bazel.build/versions/main/toolchains.html#defining-toolchains.
""",
)
