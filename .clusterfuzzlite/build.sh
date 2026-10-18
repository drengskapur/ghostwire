#!/bin/bash -eu

cd "${SRC}/ghostwire/fuzz"
compile_native_go_fuzzer github.com/drengskapur/ghostwire/fuzz FuzzRender fuzz_render

# The fuzzer execs helm and reads the chart from beside the fuzzer binary
# when it is not running inside the source tree.
cp "$(command -v helm)" "${OUT}/helm"
mkdir -p "${OUT}/chart"
cp -a "${SRC}/ghostwire/chart/." "${OUT}/chart/"
