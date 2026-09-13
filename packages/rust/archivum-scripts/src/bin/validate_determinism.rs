//! Port of `packages/rust/archivum/scripts/validate-determinism.py`.
//!
//! Runs the archivum runner command `runs` times (Python defaulted to 1000;
//! the port defaults to 50) and asserts the produced `validation.json` is
//! byte-identical on every execution. Kills on the first mismatch.
//!
//! Usage: `validate-determinism [runs]`

use archivum_scripts::{DEFAULT_RUNNER_OUTPUT, run_validation};
use std::path::PathBuf;

fn main() {
    let runs: usize = std::env::args()
        .nth(1)
        .and_then(|r| r.parse().ok())
        .unwrap_or(50);

    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let workdir = &manifest_dir;
    let runner_cmd = {
        let mut cmd = std::process::Command::new("cargo");
        cmd.args([
            "run",
            "-q",
            "-p",
            "archivum-cli",
            "--",
            "--vectors",
            DEFAULT_VECTOR_OUTPUT_DIR,
            "--output",
            DEFAULT_RUNNER_OUTPUT,
        ]);
        cmd
    };
    let output_path = workdir.join("..").join(DEFAULT_RUNNER_OUTPUT);

    println!("Validating determinism across {runs} runs...");
    match run_validation(runner_cmd, runs, &output_path, workdir) {
        Ok(()) => {
            println!("SUCCESS: 100% determinism achieved across {runs} executions.");
        }
        Err(err) => {
            eprintln!("VALIDATION FAILED: {err}");
            std::process::exit(1);
        }
    }
}