//! ADR-0029 FPES build script — escape-proof enforcement (decision driver 5).
//!
//! Gates binary production on proof completeness:
//!   Phase 1: Validate YAML contract exists
//!   Phase 2: Verify no sorry/admit/axiom in FPES Lean sources
//!   Phase 3: Enable CONTRACT_FPES env for debug_assert! injection
//!
//! If any check fails, `cargo build` refuses to produce a binary.

use std::fs;
use std::path::Path;
use std::process::Command;

fn main() {
    println!("cargo:rerun-if-changed=contracts/fpes.yaml");
    println!("cargo:rerun-if-changed=Multiplicity/FPES/");
    println!("cargo:rerun-if-changed=scripts/fpes-gate.sh");

    // Phase 1: YAML contract must exist
    let contract_path = Path::new("contracts/fpes.yaml");
    if !contract_path.exists() {
        panic!(
            "ADR-0029 GATE FAILED: contracts/fpes.yaml not found. \
             The FPES proof obligations YAML contract is required for build."
        );
    }

    let contract_content = fs::read_to_string(contract_path)
        .expect("ADR-0029 GATE FAILED: cannot read contracts/fpes.yaml");
    if contract_content.trim().is_empty() {
        panic!(
            "ADR-0029 GATE FAILED: contracts/fpes.yaml is empty. \
             Proof obligations must be specified."
        );
    }

    // Phase 2: No sorry/admit/axiom in FPES Lean sources (word-boundary match)
    let fpes_dir = Path::new("Multiplicity/FPES");
    if fpes_dir.exists() {
        // Patterns: whole-word match only (not "admitted", "admits", etc.)
        let forbidden_patterns: Vec<(&str, regex::Regex)> = vec![
            ("sorry", regex::Regex::new(r"\bsorry\b").unwrap()),
            ("admit", regex::Regex::new(r"\badmit\b").unwrap()),
            ("axiom", regex::Regex::new(r"\baxiom\b").unwrap()),
        ];
        for entry in fs::read_dir(fpes_dir).expect("cannot read Multiplicity/FPES/") {
            let entry = entry.expect("dir entry");
            let path = entry.path();
            if path.extension().map_or(false, |ext| ext == "lean") {
                let content = fs::read_to_string(&path)
                    .unwrap_or_else(|e| panic!("cannot read {}: {}", path.display(), e));
                for (i, line) in content.lines().enumerate() {
                    let trimmed = line.trim();
                    // Skip single-line comments
                    if trimmed.starts_with("--") {
                        continue;
                    }
                    // Strip inline comments before checking
                    let code = if let Some(pos) = trimmed.find("--") {
                        &trimmed[..pos]
                    } else {
                        trimmed
                    };
                    // Skip block comment markers
                    let code = code.replace("/-!", "").replace("/-", "").replace("-/", "");
                    let code = code.trim();
                    if code.is_empty() {
                        continue;
                    }
                    for (name, re) in &forbidden_patterns {
                        if re.is_match(code) {
                            panic!(
                                "ADR-0029 GATE FAILED: '{}' found at {}:{}: {}. \
                                 Every Lean theorem must be machine-checked (decision driver 1).",
                                name,
                                path.display(),
                                i + 1,
                                trimmed
                            );
                        }
                    }
                }
            }
        }
    }

    // Phase 3: Enable CONTRACT_FPES for runtime debug_assert! injection
    println!("cargo:rustc-env=CONTRACT_FPES=1");

    eprintln!("ADR-0029 FPES build gate: all checks passed");
}
