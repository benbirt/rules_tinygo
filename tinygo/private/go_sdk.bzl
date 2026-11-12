"""Go SDK selection for TinyGo actions."""

load("@rules_go//go:def.bzl", "GoSDK")

# Go 1.x minor versions each TinyGo release accepts, from minorMin and minorMax
# in TinyGo's builder/config.go.
GO_MINOR_VERSIONS = {
    "0.31.2": (18, 22),
    "0.35.0": (19, 23),
    "0.39.0": (19, 25),
    "0.41.1": (19, 26),
    "0.42.0": (25, 27),
}

def _exec_go_sdk_impl(ctx):
    return [ctx.toolchains["@rules_go//go:toolchain"].sdk]

exec_go_sdk = rule(
    implementation = _exec_go_sdk_impl,
    doc = """Forwards the Go SDK that rules_go resolves for the current configuration.

tinygo_binary depends on this in the exec configuration. TinyGo runs the go
command as a build tool, so the SDK has to match the machine the action runs
on, whatever the target platform is. Going through toolchain resolution also
means the SDK is the one the root module registered with rules_go.
""",
    toolchains = ["@rules_go//go:toolchain"],
    provides = [GoSDK],
)

def _minor(version):
    """Returns the minor number of a Go version such as "1.27.1" or "1.27rc1", or None."""
    parts = version.split(".")
    if len(parts) < 2 or parts[0] != "1":
        return None
    digits = ""
    for c in parts[1].elems():
        if not c.isdigit():
            break
        digits += c
    return int(digits) if digits else None

def check_go_version(tinygo_version, go_version):
    """Returns an error message if TinyGo does not support the Go SDK, else None.

    Args:
      tinygo_version: TinyGo release, e.g. "0.42.0". Unknown releases are not checked.
      go_version: Go SDK version, e.g. "1.27.1".

    Returns:
      An error message, or None if the pair is supported or unknown.
    """
    supported = GO_MINOR_VERSIONS.get(tinygo_version)
    minor = _minor(go_version)
    if not supported or minor == None:
        return None
    if minor < supported[0] or minor > supported[1]:
        return "TinyGo {} requires Go 1.{} through 1.{}, but the Go SDK is {}".format(
            tinygo_version,
            supported[0],
            supported[1],
            go_version,
        )
    return None
