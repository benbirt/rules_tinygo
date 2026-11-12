"""
The rules for TinyGo.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_go//go:def.bzl", "GoInfo", "GoPath", "GoSDK")
load(":go_sdk.bzl", "check_go_version")

def _tinygo_binary(ctx):
    srcs = ctx.files.srcs
    embed = ctx.attr.embed
    importpath = ctx.attr.importpath
    gopath = ctx.attr.gopath

    if embed:
        if importpath:
            fail("tinygo_binary: set embed or importpath, not both")
        if not gopath:
            fail("tinygo_binary: internal error: gopath is required when embed is set")
        importpath = embed[0][GoInfo].importpath
        if not importpath:
            fail("tinygo_binary: embed target must have an importpath")
    elif not importpath and not srcs:
        fail("tinygo_binary: embed, importpath, or srcs is required")

    if importpath and not embed and not ctx.file.mod:
        fail("tinygo_binary: mod is required when importpath is set")
    if srcs and importpath and not ctx.attr.package_dir and not embed:
        fail("tinygo_binary: package_dir is required when both importpath and srcs are set")

    binaryen = ctx.toolchains["@rules_tinygo//binaryen:toolchain_type"]
    toolchain = ctx.toolchains["@rules_tinygo//tinygo:toolchain_type"]

    # TinyGo runs the go command as a build tool, so the SDK comes from the exec
    # configuration unless the target names one.
    sdk = (ctx.attr.go_sdk or ctx.attr._go_sdk)[GoSDK]
    error = check_go_version(getattr(toolchain, "version", ""), sdk.version)
    if error:
        fail("tinygo_binary: {}. Register a supported Go SDK with rules_go, or pick another TinyGo version.".format(error))

    args = [
        toolchain.tinygo,
        "build",
        "-x",
        "-o",
        ctx.outputs.out.path,
    ]

    if not ctx.attr.debug:
        args.append("-no-debug")

    if ctx.attr.target:
        args += ["-target", ctx.attr.target]

    if ctx.attr.scheduler:
        args += ["-scheduler", ctx.attr.scheduler]

    if ctx.attr.buildmode:
        args += ["-buildmode", ctx.attr.buildmode]

    mod_inputs = []
    extra_inputs = []
    env = {
        "BUILDER_GOROOT": sdk.root_file.dirname,
        "BUILDER_GOBIN_PATH": sdk.go.dirname,
        "BUILDER_SCRATCH": ctx.outputs.out.path + ".scratch",
        "BUILDER_TINYGOROOT": paths.dirname(paths.dirname(toolchain.tinygo)),
        "WASMOPT": binaryen.wasm_opt.path,
    }
    execution_requirements = {}

    if embed:
        # GOPATH mode: every package, including third-party dependencies, comes
        # from the go_path tree that Bazel built, so no go.mod and no network.
        env["BUILDER_GOPATH_DIR"] = gopath[GoPath].gopath_file.path
        extra_inputs = gopath[DefaultInfo].files.to_list()
        args.append(importpath)
    elif importpath:
        # Module mode: the go command downloads the module's dependencies, so
        # this is the one mode that needs the network.
        mod_inputs = [ctx.file.mod]
        env["BUILDER_GOMOD"] = ctx.file.mod.path
        if ctx.file.sum:
            mod_inputs.append(ctx.file.sum)
            env["BUILDER_GOSUM"] = ctx.file.sum.path
        args.append(importpath)
        execution_requirements["requires-network"] = "1"
        if srcs:
            env["BUILDER_COPY_SPECS"] = ",".join([
                ctx.attr.package_dir + "/" + paths.basename(src.path) + "|" + src.path
                for src in srcs
            ])
    else:
        args += [src.path for src in srcs]

    ctx.actions.run(
        executable = ctx.executable._builder,
        inputs = depset(
            direct = (
                toolchain.tool_files +
                srcs +
                mod_inputs +
                toolchain.srcs +
                toolchain.libs +
                toolchain.targets +
                [sdk.go, binaryen.wasm_opt] +
                extra_inputs
            ),
            transitive = [
                sdk.srcs,
                sdk.tools,
            ],
        ),
        arguments = args,
        outputs = [ctx.outputs.out],
        env = env,
        execution_requirements = execution_requirements,
        mnemonic = "TinyGoBuild",
        progress_message = "TinyGo building %{output}",
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

tinygo_binary = rule(
    implementation = _tinygo_binary,
    doc = "Compiles a Go binary using TinyGo.",
    attrs = {
        "embed": attr.label_list(
            providers = [GoInfo],
            doc = "go_library targets to embed, like go_binary. Built offline from a go_path tree of the Bazel dependency graph.",
        ),
        "gopath": attr.label(
            providers = [GoPath],
            doc = "Internal go_path output populated by the tinygo_binary macro.",
        ),
        "srcs": attr.label_list(
            allow_files = [".go"],
            doc = "Source files to compile. With importpath, main-package sources copied into package_dir.",
        ),
        "importpath": attr.string(
            doc = "Import path of the main package to build in module mode. Requires mod. " +
                  "The go command downloads the module's dependencies, so the action needs network access; " +
                  "prefer embed, which builds offline from Bazel's dependency graph.",
        ),
        "package_dir": attr.string(
            doc = "Module-relative directory for srcs when building importpath with local sources.",
        ),
        "mod": attr.label(
            allow_single_file = [".mod"],
            doc = "go.mod file for module-mode builds.",
        ),
        "sum": attr.label(
            allow_single_file = [".sum"],
            doc = "go.sum file for module-mode builds.",
        ),
        "scheduler": attr.string(
            doc = "Optional TinyGo scheduler, e.g. \"none\".",
        ),
        "buildmode": attr.string(
            doc = "Optional TinyGo build mode, e.g. \"wasi-legacy\" for Zellij plugins.",
        ),
        "target": attr.string(
            doc = "Target architecture.",
        ),
        "debug": attr.bool(
            default = False,
            doc = "Keep debug information. TinyGo records absolute paths in it, and Bazel runs each " +
                  "action in a differently named sandbox, so a binary with debug information is not " +
                  "reproducible. Off by default.",
        ),
        "out": attr.output(
            doc = "Output binary.",
        ),
        "go_sdk": attr.label(
            doc = "Go SDK to use. Defaults to the SDK that rules_go resolves for the execution platform.",
            providers = [GoSDK],
        ),
        "_go_sdk": attr.label(
            default = Label("//tinygo/private:exec_go_sdk"),
            providers = [GoSDK],
            cfg = "exec",
        ),
        "_builder": attr.label(
            default = Label("@rules_tinygo//tinygo/builder:builder"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = [
        "@rules_tinygo//tinygo:toolchain_type",
        "@rules_tinygo//binaryen:toolchain_type",
    ],
)
