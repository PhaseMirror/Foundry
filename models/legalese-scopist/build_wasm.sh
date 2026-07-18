#!/usr/bin/env bash
set -e
# Build the WASM bindings using wasm-bindgen
# Assumes wasm-bindgen CLI is installed.
wasm-bindgen --target web --out-dir ./pkg target/wasm32-unknown-unknown/release/sedona_spine.wasm
