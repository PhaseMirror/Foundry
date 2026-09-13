//! Test-only "runner" that writes a deterministic `validation.json` file.
//!
//! Mirrors the interface expected by `validate-determinism`: the caller
//! passes `--output <path>` and this binary writes a fixed JSON payload
//! that never varies across runs. Used as the runner subprocess in
//! integration tests so we can exercise the determinism driver without
//! the full archivum stack.
//!
//! When the environment variable `DETERMINISM_DUMMY_FLIP_RUNS` is set to
//! a positive integer N, every run after the first N writes a *different*
//! payload (as though the archivum stack had become non-deterministic),
//! which allows integration-testing the mismatch detection path.

use std::io::Write;
use std::path::PathBuf;

fn payload(flip_at: Option<usize>, invocation_counter: &mut usize) -> String {
    *invocation_counter += 1;
    match flip_at {
        Some(flip) if *invocation_counter > flip => {
            format!("{{\"status\": \"UNSTABLE\", \"invocation\": {}}}", invocation_counter)
        }
        _ => "{{\"status\": \"DETERMINISTIC\", \"hash\": \"abc123\"}}".into(),
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let mut output = None;
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--output" => {
                i += 1;
                output = Some(PathBuf::from(&args[i]));
            }
            _ => {}
        }
        i += 1;
    }
    let output = output.expect("--output <path> is required");

    let flip_at: Option<usize> = std::env::var("DETERMINISM_DUMMY_FLIP_RUNS")
        .ok()
        .and_then(|v| v.parse().ok());

    // Maintain a per-process invocation counter via a file next to the
    // output, allowing successive subprocesses (same working directory)
    // to know their global call index.
    let counter_path = output.parent().unwrap().join(".dummy_counter");
    let mut counter: usize = std::fs::read_to_string(&counter_path)
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(0);
    let data = payload(flip_at, &mut counter);
    std::fs::write(&counter_path, counter.to_string()).expect("write counter");

    std::fs::File::create(&output)
        .expect("create output")
        .write_all(data.as_bytes())
        .expect("write output");
}