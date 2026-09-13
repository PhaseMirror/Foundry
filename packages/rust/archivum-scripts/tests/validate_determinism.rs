//! Integration coverage for `validate-determinism.py` parity, driven by the
//! `determinism-dummy` runner (see its doc comment).

use archivum_scripts::{run_validation, DeterminismError};
use std::env;
use std::path::PathBuf;
use std::process::Command;

fn dummy_runner(output: &PathBuf) -> Command {
    let mut cmd = Command::new(env!("CARGO_BIN_EXE_determinism-dummy"));
    cmd.arg("--output").arg(output);
    cmd
}

#[test]
fn driver_passes_on_identical_runs_and_caches_baseline() {
    let dir = tempfile::tempdir().expect("tempdir");
    let output = dir.path().join("validation.json");

    // Fresh counter file (previous runs in the same tempdir may have dated).
    std::fs::remove_file(dir.path().join(".dummy_counter")).ok();

    run_validation(dummy_runner(&output), 3, &output, dir.path()).expect("deterministic runs pass");
    let baseline = std::fs::read_to_string(&output).expect("output exists");
    assert_eq!(
        baseline,
        "{\"status\": \"DETERMINISTIC\", \"hash\": \"abc123\"}"
    );
}

#[test]
fn driver_fails_on_first_divergence() {
    let dir = tempfile::tempdir().expect("tempdir");
    let output = dir.path().join("validation.json");
    std::fs::remove_file(dir.path().join(".dummy_counter")).ok();

    // Flip from the 2nd invocation onward: runs 1 and 2 will differ.
    let mut cmd = dummy_runner(&output);
    cmd.arg("--flip").arg("1");
    let err = run_validation(cmd, 3, &output, dir.path());

    assert!(matches!(
        err,
        Err(DeterminismError::OutputMismatch { run: 2 })
    ));
}
