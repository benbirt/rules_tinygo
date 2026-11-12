load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":go_sdk.bzl", "exec_go_sdk")

bzl_library(
    name = "toolchains_repo",
    srcs = ["toolchains_repo.bzl"],
    visibility = ["//tinygo:__subpackages__"],
)

bzl_library(
    name = "versions",
    srcs = ["versions.bzl"],
    visibility = ["//tinygo:__subpackages__"],
)

bzl_library(
    name = "resolved_toolchain",
    srcs = ["resolved_toolchain.bzl"],
    visibility = ["//tinygo:__subpackages__"],
)

bzl_library(
    name = "rules",
    srcs = ["rules.bzl"],
    visibility = ["//tinygo:__subpackages__"],
    deps = [
        ":go_sdk",
        "@bazel_skylib//lib:paths",
        "@rules_go//go:def",
    ],
)

bzl_library(
    name = "go_sdk",
    srcs = ["go_sdk.bzl"],
    visibility = ["//tinygo:__subpackages__"],
    deps = ["@rules_go//go:def"],
)

# The Go SDK for the execution platform, as resolved by rules_go.
exec_go_sdk(
    name = "exec_go_sdk",
    visibility = ["//visibility:public"],
)
