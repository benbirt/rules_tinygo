"""Unit tests for starlark helpers
See https://bazel.build/rules/testing#testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//tinygo/private:go_sdk.bzl", "GO_MINOR_VERSIONS", "check_go_version")
load("//tinygo/private:versions.bzl", "TOOL_VERSIONS")

def _smoke_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "0.31.2", TOOL_VERSIONS.keys()[0])
    return unittest.end(env)

def _go_version_test_impl(ctx):
    env = unittest.begin(ctx)

    # Every TinyGo release on offer has a Go version range.
    asserts.equals(env, sorted(TOOL_VERSIONS.keys()), sorted(GO_MINOR_VERSIONS.keys()))

    asserts.equals(env, None, check_go_version("0.42.0", "1.25.0"))
    asserts.equals(env, None, check_go_version("0.42.0", "1.27.1"))
    asserts.equals(env, None, check_go_version("0.42.0", "1.27rc1"))
    asserts.equals(
        env,
        "TinyGo 0.42.0 requires Go 1.25 through 1.27, but the Go SDK is 1.24.3",
        check_go_version("0.42.0", "1.24.3"),
    )
    asserts.equals(
        env,
        "TinyGo 0.41.1 requires Go 1.19 through 1.26, but the Go SDK is 1.27.0",
        check_go_version("0.41.1", "1.27.0"),
    )

    # Releases and SDK versions this table does not know are left to TinyGo.
    asserts.equals(env, None, check_go_version("9.9.9", "1.2.0"))
    asserts.equals(env, None, check_go_version("", "1.2.0"))
    asserts.equals(env, None, check_go_version("0.42.0", "devel"))
    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
_t0_test = unittest.make(_smoke_test_impl)
_t1_test = unittest.make(_go_version_test_impl)

def versions_test_suite(name):
    unittest.suite(name, _t0_test, _t1_test)
