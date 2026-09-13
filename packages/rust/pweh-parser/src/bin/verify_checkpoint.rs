//! CLI entry point mirroring `pweh_adapter.py`'s `main()`.
//!
//! Usage: `verify-checkpoint <checkpoint.json>`
//!
//! Reads a PWEH checkpoint receipt, verifies it, prints the DecisionAssure
//! verification output as pretty JSON, and exits `0` on PASS / `1` on FAIL.

use pweh_parser::{DecisionAssureAdapter, PwehReceipt};
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: verify-checkpoint <checkpoint.json>");
        return ExitCode::FAILURE;
    }

    let path = &args[1];
    let text = match std::fs::read_to_string(path) {
        Ok(text) => text,
        Err(err) => {
            eprintln!("error: could not read {path}: {err}");
            return ExitCode::FAILURE;
        }
    };

    let receipt = match serde_json::from_str::<PwehReceipt>(&text) {
        Ok(receipt) => receipt,
        Err(err) => {
            eprintln!("error: could not parse {path} as a PwehReceipt: {err}");
            return ExitCode::FAILURE;
        }
    };

    let result = DecisionAssureAdapter.verify_checkpoint(&receipt);
    let pretty = serde_json::to_string_pretty(&result).expect("verify output serializes");
    println!("{pretty}");

    if result.is_pass() {
        ExitCode::SUCCESS
    } else {
        ExitCode::FAILURE
    }
}
