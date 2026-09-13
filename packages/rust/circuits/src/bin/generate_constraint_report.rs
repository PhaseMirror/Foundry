//! Port of `Foundry/circuits/tests/generate_constraint_report.py`.
//!
//! Reads `Foundry/circuits/ace.circom`, writes the pretty-printed
//! `constraint_report.json` into the build dir, and prints the report.

use circuits::generate_report;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let circom_path = manifest_dir.join("../../../circuits/ace.circom");
    let report_path = manifest_dir.join("../../../circuits/build/ace_js/constraint_report.json");

    let content = std::fs::read_to_string(&circom_path).unwrap_or_else(|e| {
        eprintln!("ERROR: reading {}: {e}", circom_path.display());
        std::process::exit(1);
    });
    let file_name = circom_path
        .file_name()
        .expect("file name")
        .to_string_lossy()
        .into_owned();

    match generate_report(&content, &file_name, &report_path) {
        Ok(report) => {
            println!("Generated constraint report: {}", report_path.display());
            println!(
                "{}",
                serde_json::to_string_pretty(&report).expect("print report")
            );
        }
        Err(err) => {
            eprintln!("ERROR: {err}");
            std::process::exit(1);
        }
    }
}
