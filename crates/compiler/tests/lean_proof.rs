// Integration tests for Lean proof verification in the PIRTM compiler

use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;
use tempfile::tempdir;

/// Helper to create a minimal PIRTM source file in a temporary directory.
fn write_test_source(dir: &Path) -> std::path::PathBuf {
    let source_path = dir.join("test.pirtm");
    fs::write(&source_path, "Ap(2) + 3").expect("failed to write source");
    source_path
}

/// Runs the compiler CLI with the given arguments and returns the exit status.
fn run_compiler(args: &[&str]) -> std::process::ExitStatus {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap_or_default();
    Command::new("cargo")
        .arg("run")
        .arg("--")
        .args(args)
        .current_dir(&manifest_dir)
        .status()
        .expect("failed to execute cargo")
}

#[test]
fn test_lean_proof_fallback_when_lean_missing() {
    // Test that proof verification gracefully falls back when Lean is not installed
    let tmp = tempdir().expect("failed to create temp dir");
    let source_path = write_test_source(tmp.path());
    let out_path = tmp.path().join("out.mlir");

    // Create a temporary Lean file that we control
    let lean_file = tmp.path().join("test.lean");
    fs::write(&lean_file, "def main : IO Unit := do IO.println \"OK\"").unwrap();

    // Run the compiler with the Lean proof flag
    let status = run_compiler(&[
        "compile",
        source_path.to_str().unwrap(),
        "--lean-proof",
        "--output",
        out_path.to_str().unwrap(),
    ]);
    // With fallback, compilation should succeed even without Lean installed
    assert!(
        status.success(),
        "Compilation with fallback proof should succeed"
    );
}

#[test]
#[ignore]
fn test_lean_proof_success() {
    // Skipped by default - requires actual Lean installation and proof file
    let tmp = tempdir().expect("failed to create temp dir");
    let source_path = write_test_source(tmp.path());
    let out_path = tmp.path().join("out.mlir");

    let status = run_compiler(&[
        "compile",
        source_path.to_str().unwrap(),
        "--lean-proof",
        "--output",
        out_path.to_str().unwrap(),
    ]);
    assert!(
        status.success(),
        "Compilation with Lean proof should succeed"
    );
    assert!(out_path.exists(), "MLIR output file not found");
}
