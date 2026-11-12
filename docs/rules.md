<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="tinygo_binary"></a>

## tinygo_binary

<pre>
load("@rules_tinygo//tinygo:defs.bzl", "tinygo_binary")

tinygo_binary(<a href="#tinygo_binary-name">name</a>, <a href="#tinygo_binary-embed">embed</a>, <a href="#tinygo_binary-mod">mod</a>, <a href="#tinygo_binary-sum">sum</a>, <a href="#tinygo_binary-kwargs">**kwargs</a>)
</pre>

Builds a TinyGo binary.

Set `embed` to `go_library` targets, like `go_binary`. A hidden `go_path`
target materializes them and their transitive dependencies, and TinyGo builds
from that tree in GOPATH mode: no go.mod and no network access.

For a program that imports only the standard library, `srcs` alone is enough.

Building by `importpath` against a go.mod (module mode) is deprecated: the go
command downloads the dependencies during the build instead of using the ones
Bazel resolved. To migrate, declare the main package as a `go_library` and
pass it in `embed`; `importpath`, `mod`, `sum` and `package_dir` can then go.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tinygo_binary-name"></a>name |  Target name.   |  none |
| <a id="tinygo_binary-embed"></a>embed |  go_library targets to embed, like go_binary.   |  `None` |
| <a id="tinygo_binary-mod"></a>mod |  Deprecated: use embed. go.mod label for importpath builds; ignored when embed is set.   |  `None` |
| <a id="tinygo_binary-sum"></a>sum |  Deprecated: use embed. go.sum label for importpath builds; ignored when embed is set.   |  `None` |
| <a id="tinygo_binary-kwargs"></a>kwargs |  Remaining attributes passed to the underlying tinygo_binary rule.   |  none |


