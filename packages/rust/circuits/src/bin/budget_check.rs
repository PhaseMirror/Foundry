//! Port of `Foundry/circuits/tests/test_constraint_budget.py` — the
//! snarkjs-driven ZK constraint budget gate (BUDGET_CAP = 5,087).
//!
//! This binary is the snarkjs `r1cs info` driver: it invokes
//! `npx snarkjs r1cs info <ace.r1cs>`, parses the constraint count, and then
//! either confirms the circuit is within budget or ships it as an external
//! certificate. Mirrors the Python `unittest` behavior: a missing R1CS
//! artifact or a missing constraint count is a hard failure.
//!
//! Set `CIRCUITS_SKIP_SNARKJS=1` to exit cleanly when the snarkjs toolchain
//! is unavailable (e.g. offline builds), mirroring a skipped test.

use circuits::{decide_budget, parse_constraint_count, BUDGET_CAP};
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let r1cs_path = manifest_dir.join("../../../circuits/build/ace.r1cs");
    let certificate_dir = manifest_dir.join("../../../circuits/build/certificates");

    if std::env::var("CIRCUITS_SKIP_SNARKJS").is_ok() {
        println!("SKIPPED: snarkjs toolchain unavailable (CIRCUITS_SKIP_SNARKJS).");
        return;
    }

    if !r1cs_path.exists() {
        eprintln!(
            "FAIL: R1CS artifact missing: {}. Run the circuit build step first.",
            r1cs_path.display()
        );
        std::process::exit(1);
    }

    let result = Command::new("npx")
        .args(["snarkjs", "r1cs", "info", r1cs_path.to_str().expect("path")])
        .output()
        .expect("spawn npx snarkjs");
    if !result.status.success() {
        eprintln!(
            "FAIL: snarkjs exited {:?}:\n{}",
            result.status.code(),
            String::from_utf8_lossy(&result.stderr)
        );
        std::process::exit(1);
    }
    let stdout = String::from_utf8_lossy(&result.stdout);

    let some_actual = parse_constraint_count(&stdout);
    let Some(actual) = some_actual else {
        eprintln!("FAIL: snarkjs output did not contain a constraint count.");
        std::process::exit(1);
    };

    match decide_budget(actual, &certificate_dir) {
        circuits::BudgetDecision::WithinBudget { actual } => {
            println!("OK: {actual} constraints <= {BUDGET_CAP} (within budget).");
        }
        circuits::BudgetDecision::ShippedAsCertificate {
            actual,
            manifest_path,
        } => {
            println!(
                "WARNING: circuit is over budget ({actual} > {BUDGET_CAP}). Shipped as external certificate: {manifest_path}"
            );
        }
    }
}
