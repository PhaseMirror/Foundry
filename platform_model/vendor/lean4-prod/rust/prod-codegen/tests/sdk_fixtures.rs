//! Executable fixtures for every generated SDK language.
//!
//! C, Rust, and Python call a real generated native library. TypeScript and
//! Kotlin execute their generated adapter logic against deterministic fake
//! native interfaces. The packaged WebAssembly SDK has its own Node e2e test
//! in `fixtures/wasm_sdk_test.mjs`, run by `just wasm-sdk-fixture`.

use prod_codegen::{generate_module, generate_sdks, SdkBindings};
use prod_ir::parser::parse_module;
use prod_ir::Module;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Output};
use std::time::{SystemTime, UNIX_EPOCH};

struct FixtureDir {
    path: PathBuf,
}

impl FixtureDir {
    fn new(language: &str) -> Self {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock is before Unix epoch")
            .as_nanos();
        let path = env::temp_dir().join(format!("lean4-prod-{language}-sdk-fixture-{nonce}"));
        fs::create_dir(&path).expect("create SDK fixture directory");
        Self { path }
    }

    fn file(&self, name: &str) -> PathBuf {
        self.path.join(name)
    }
}

impl Drop for FixtureDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.path);
    }
}

fn fixture_module() -> Module {
    let (_, module) =
        parse_module(include_str!("fixtures/sdk_scalar.ir")).expect("parse SDK fixture IR");
    module
}

fn fixture_sdk(module: &Module) -> SdkBindings {
    generate_sdks(module, "fixture").expect("generate SDK fixture")
}

fn tool_available(program: &str) -> bool {
    Command::new(program).arg("--version").output().is_ok()
}

fn require_tools(language: &str, programs: &[&str]) -> bool {
    let missing = programs
        .iter()
        .copied()
        .filter(|program| !tool_available(program))
        .collect::<Vec<_>>();
    if missing.is_empty() {
        true
    } else {
        eprintln!(
            "skipping {language} SDK runtime fixture; missing declared tool(s): {}",
            missing.join(", ")
        );
        false
    }
}

fn run_command(command: &mut Command, label: &str) -> Output {
    let output = command
        .output()
        .unwrap_or_else(|error| panic!("run {label}: {error}"));
    assert!(
        output.status.success(),
        "{label} failed\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    output
}

fn compute_error_source() -> &'static str {
    r#"
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComputeError {
    AddOverflow,
    MulOverflow,
    ShiftOverflow,
    PowOverflow,
    ShiftExponentTooLarge,
    PowExponentTooLarge,
    OutputTooSmall,
}
"#
}

fn native_library_name() -> &'static str {
    if cfg!(target_os = "macos") {
        "libfixture.dylib"
    } else {
        "libfixture.so"
    }
}

fn build_native_library(fixture: &FixtureDir, module: &Module, sdk: &SdkBindings) -> PathBuf {
    let generated = generate_module(module).expect("generate fixture implementation");
    let source = fixture.file("native.rs");
    let library = fixture.file(native_library_name());
    fs::write(
        &source,
        format!(
            "#![allow(non_snake_case, unused_parens)]\n{}\n{}\n{}",
            compute_error_source(),
            generated,
            sdk.c_wrapper
        ),
    )
    .expect("write generated native fixture");
    run_command(
        Command::new("rustc")
            .arg("--edition=2021")
            .arg("--crate-type=cdylib")
            .arg("--crate-name=fixture")
            .arg("-o")
            .arg(&library)
            .arg(&source),
        "generated native library compile",
    );
    library
}

fn add_dynamic_library_path(command: &mut Command, directory: &Path) {
    let variable = if cfg!(target_os = "macos") {
        "DYLD_LIBRARY_PATH"
    } else {
        "LD_LIBRARY_PATH"
    };
    let mut paths = vec![directory.to_path_buf()];
    if let Some(existing) = env::var_os(variable) {
        paths.extend(env::split_paths(&existing));
    }
    command.env(
        variable,
        env::join_paths(paths).expect("join dynamic library search path"),
    );
}

#[test]
fn generated_c_sdk_executes_native_library() {
    if cfg!(target_os = "windows") || !require_tools("C", &["rustc", "cc"]) {
        return;
    }
    let fixture = FixtureDir::new("c");
    let module = fixture_module();
    let sdk = fixture_sdk(&module);
    build_native_library(&fixture, &module, &sdk);

    let header = fixture.file("fixture.h");
    let source = fixture.file("fixture.c");
    let binary = fixture.file("c_sdk_test");
    fs::write(&header, &sdk.c_header).expect("write C header");
    fs::write(
        &source,
        r#"
#include <stdint.h>
#include "fixture.h"

int main(void) {
    prod_fixture_add_result_t sum = prod_fixture_add(2, 3);
    prod_fixture_add_result_t overflow = prod_fixture_add(UINT64_MAX, 1);
    prod_fixture_riskyflag_result_t risky = prod_fixture_riskyflag(UINT64_MAX);
    return sum.status != PROD_STATUS_OK || sum.value != 5 ||
           overflow.status != PROD_STATUS_ADD_OVERFLOW ||
           risky.status != PROD_STATUS_ADD_OVERFLOW ||
           prod_fixture_less(2, 3) != 1 ||
           prod_fixture_less(3, 2) != 0 ||
           prod_fixture_echo(1) != 1 || prod_fixture_echo(0) != 0;
}
"#,
    )
    .expect("write C SDK behavior test");
    run_command(
        Command::new("cc")
            .arg("-std=c11")
            .arg("-Wall")
            .arg("-Werror")
            .arg("-I")
            .arg(&fixture.path)
            .arg(&source)
            .arg("-L")
            .arg(&fixture.path)
            .arg("-lfixture")
            .arg("-o")
            .arg(&binary),
        "C SDK compile",
    );
    let mut command = Command::new(&binary);
    add_dynamic_library_path(&mut command, &fixture.path);
    run_command(&mut command, "C SDK runtime");
}

#[test]
fn generated_rust_sdk_executes_native_library() {
    if cfg!(target_os = "windows") || !require_tools("Rust", &["rustc"]) {
        return;
    }
    let fixture = FixtureDir::new("rust");
    let module = fixture_module();
    let sdk = fixture_sdk(&module);
    build_native_library(&fixture, &module, &sdk);

    let sdk_source = fixture.file("sdk.rs");
    let caller = fixture.file("main.rs");
    let binary = fixture.file("rust_sdk_test");
    fs::write(&sdk_source, &sdk.rust).expect("write Rust SDK");
    fs::write(
        &caller,
        r#"
mod sdk;

fn main() {
    assert_eq!(sdk::prod_fixture_add(2, 3), Ok(5));
    assert_eq!(sdk::prod_fixture_add(u64::MAX, 1), Err(1));
    assert!(sdk::prod_fixture_less(2, 3));
    assert!(!sdk::prod_fixture_less(3, 2));
    assert!(sdk::prod_fixture_echo(true));
    assert!(!sdk::prod_fixture_echo(false));
    assert_eq!(sdk::prod_fixture_riskyflag(u64::MAX), Err(1));
}
"#,
    )
    .expect("write Rust SDK behavior test");
    run_command(
        Command::new("rustc")
            .arg("--edition=2021")
            .arg(&caller)
            .arg("-L")
            .arg(format!("native={}", fixture.path.display()))
            .arg("-o")
            .arg(&binary),
        "Rust SDK compile",
    );
    let mut command = Command::new(&binary);
    add_dynamic_library_path(&mut command, &fixture.path);
    run_command(&mut command, "Rust SDK runtime");
}

#[test]
fn generated_python_sdk_executes_native_library() {
    if cfg!(target_os = "windows") || !require_tools("Python", &["rustc", "python3"]) {
        return;
    }
    let fixture = FixtureDir::new("python");
    let module = fixture_module();
    let sdk = fixture_sdk(&module);
    let library = build_native_library(&fixture, &module, &sdk);

    let sdk_source = fixture.file("fixture.py");
    let test_source = fixture.file("test_fixture.py");
    fs::write(&sdk_source, &sdk.python).expect("write Python SDK");
    fs::write(
        &test_source,
        r#"
import sys
import fixture

lib = fixture.load_library(sys.argv[1])
assert fixture.prod_fixture_add(lib, 2, 3) == 5
assert fixture.prod_fixture_less(lib, 2, 3) is True
assert fixture.prod_fixture_less(lib, 3, 2) is False
assert fixture.prod_fixture_echo(lib, True) is True
assert fixture.prod_fixture_echo(lib, False) is False

try:
    fixture.prod_fixture_add(lib, 2**64 - 1, 1)
    raise AssertionError("overflow was not reported")
except RuntimeError as error:
    assert "status 1" in str(error)

try:
    fixture.prod_fixture_riskyflag(lib, 2**64 - 1)
    raise AssertionError("nested overflow was not reported")
except RuntimeError as error:
    assert "status 1" in str(error)
"#,
    )
    .expect("write Python SDK behavior test");
    run_command(
        Command::new("python3").arg(&test_source).arg(&library),
        "Python SDK runtime",
    );
}

#[test]
fn generated_typescript_sdk_executes_adapter_contract() {
    if !require_tools("TypeScript", &["tsc", "node"]) {
        return;
    }
    let fixture = FixtureDir::new("typescript");
    let sdk = fixture_sdk(&fixture_module());
    let sdk_source = fixture.file("index.ts");
    let test_source = fixture.file("test.ts");
    let output = fixture.file("dist");
    fs::write(&sdk_source, &sdk.typescript).expect("write TypeScript SDK");
    fs::write(
        &test_source,
        r#"
import { bind, NativeLibrary } from "./index";

let echoArgument = -1;
const native: NativeLibrary = {
  prod_fixture_add: (a, b) => ({ status: 0, value: BigInt(a) + BigInt(b) }),
  prod_fixture_less: (a, b) => BigInt(a) < BigInt(b) ? 1 : 0,
  prod_fixture_echo: (value) => { echoArgument = Number(value); return value; },
  prod_fixture_riskyflag: (x) => BigInt(x) === 99n
    ? { status: 1, value: 0 }
    : { status: 0, value: BigInt(x) + 1n < 2n ? 1 : 0 },
};

const api = bind(native);
const assertEchoArgument = (expected: number) => {
  if (echoArgument !== expected) throw new Error("bool argument conversion");
};
if (api.prod_fixture_add(2n, 3n) !== 5n) throw new Error("add result");
if (!api.prod_fixture_less(2n, 3n)) throw new Error("less true result");
if (api.prod_fixture_less(3n, 2n)) throw new Error("less false result");
if (!api.prod_fixture_echo(true)) throw new Error("bool true result");
assertEchoArgument(1);
if (api.prod_fixture_echo(false)) throw new Error("bool false result");
assertEchoArgument(0);

let failed = false;
try { api.prod_fixture_riskyflag(99n); } catch (error) {
  failed = String(error).includes("status 1");
}
if (!failed) throw new Error("fallible result was not reported");
"#,
    )
    .expect("write TypeScript SDK behavior test");
    run_command(
        Command::new("tsc")
            .arg("--strict")
            .arg("--target")
            .arg("ES2020")
            .arg("--module")
            .arg("commonjs")
            .arg("--outDir")
            .arg(&output)
            .arg(&sdk_source)
            .arg(&test_source),
        "TypeScript SDK compile",
    );
    run_command(
        Command::new("node").arg(output.join("test.js")),
        "TypeScript SDK runtime",
    );
}

#[test]
fn generated_kotlin_sdk_executes_adapter_contract() {
    if !require_tools("Kotlin", &["kotlinc", "java"]) {
        return;
    }
    let fixture = FixtureDir::new("kotlin");
    let sdk = fixture_sdk(&fixture_module());
    let sdk_source = fixture.file("Lean4Prod.kt");
    let jna_stub = fixture.file("JnaStubs.kt");
    let test_source = fixture.file("FixtureTest.kt");
    let jar = fixture.file("fixture.jar");
    fs::write(&sdk_source, &sdk.kotlin).expect("write Kotlin SDK");
    fs::write(
        &jna_stub,
        r#"
package com.sun.jna

interface Library

open class Structure {
    interface ByValue
    open fun getFieldOrder(): List<String> = emptyList()
}

object Native {
    fun <T> load(path: String, type: Class<T>): T = error("fixture stub: $path $type")
}
"#,
    )
    .expect("write Kotlin JNA stubs");
    fs::write(
        &test_source,
        r#"
private class FakeNative : Lean4ProdNative {
    override fun prod_fixture_add(a: Long, b: Long): ProdFixtureAddResult =
        ProdFixtureAddResult().also { result ->
            if (a == Long.MAX_VALUE) result.status = 1 else result.value = a + b
        }

    override fun prod_fixture_less(a: Long, b: Long): Byte = if (a < b) 1 else 0
    override fun prod_fixture_echo(value: Byte): Byte = value

    override fun prod_fixture_riskyflag(x: Long): ProdFixtureRiskyflagResult =
        ProdFixtureRiskyflagResult().also { result ->
            if (x == 99L) result.status = 1 else result.value = if (x + 1 < 2) 1 else 0
        }
}

fun main() {
    val native = FakeNative()
    check(native.safe_prod_fixture_add(2, 3).getOrThrow() == 5L)
    check(native.safe_prod_fixture_add(Long.MAX_VALUE, 1).isFailure)
    check(native.safe_prod_fixture_less(2, 3))
    check(!native.safe_prod_fixture_less(3, 2))
    check(native.safe_prod_fixture_echo(true))
    check(!native.safe_prod_fixture_echo(false))
    check(native.safe_prod_fixture_riskyflag(99).isFailure)
}
"#,
    )
    .expect("write Kotlin SDK behavior test");
    run_command(
        Command::new("kotlinc")
            // Kotlin 1.3 requires this compatibility flag for the public
            // Result-returning adapter API; newer compilers accept it too.
            .arg("-Xallow-result-return-type")
            .arg(&jna_stub)
            .arg(&sdk_source)
            .arg(&test_source)
            .arg("-include-runtime")
            .arg("-d")
            .arg(&jar),
        "Kotlin SDK compile",
    );
    run_command(
        Command::new("java").arg("-jar").arg(&jar),
        "Kotlin SDK runtime",
    );
}

#[test]
fn every_generated_sdk_has_fixture_coverage() {
    let sdk = fixture_sdk(&fixture_module());
    assert!(sdk.c_header.contains("prod_fixture_add"));
    assert!(sdk.rust.contains("pub fn prod_fixture_add"));
    assert!(sdk.python.contains("def prod_fixture_add"));
    assert!(sdk.typescript.contains("export function bind"));
    assert!(sdk
        .kotlin
        .contains("fun Lean4ProdNative.safe_prod_fixture_add"));
    assert!(sdk.wasm.contains("#[wasm_bindgen"));
}
