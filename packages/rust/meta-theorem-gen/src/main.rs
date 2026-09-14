//! CLI for the meta-theorem basis tooling.
//!
//! ```text
//! meta-theorem-gen export  [--primes 2,3,5,7] [--max-exp 3] [--output basis_factors.json]
//! meta-theorem-gen gen-lean [--input basis_factors.json] [--output RealBasis.lean]
//! meta-theorem-gen gen-rust [--input basis_factors.json] [--output generated_vals_array.rs]
//! ```
//!
//! Defaults mirror the Python scripts.

use meta_theorem_gen::basis::{compute_valuations, generate_basis};
use meta_theorem_gen::lean::render_real_basis;
use meta_theorem_gen::model::BasisData;
use meta_theorem_gen::python_json::render_basis_data;
use meta_theorem_gen::rust_array::render_generated_vals;
use std::collections::HashMap;
use std::process::ExitCode;

const DEFAULT_PRIMES: &[u64] = &[2, 3, 5, 7];
const DEFAULT_MAX_EXP: u64 = 3;

fn parse_opts(args: &[String]) -> HashMap<String, String> {
    let mut opts = HashMap::new();
    let mut i = 0;
    while i + 1 < args.len() {
        if args[i].starts_with("--") {
            opts.insert(args[i][2..].to_string(), args[i + 1].clone());
            i += 2;
        } else {
            i += 1;
        }
    }
    opts
}

fn parse_primes(s: &str) -> Vec<u64> {
    s.split(',')
        .filter(|p| !p.trim().is_empty())
        .filter_map(|p| p.trim().parse().ok())
        .collect()
}

fn load_data(input: &str) -> Result<BasisData, String> {
    let bytes = std::fs::read(input).map_err(|e| format!("cannot read {input}: {e}"))?;
    serde_json::from_slice(&bytes).map_err(|e| format!("cannot parse {input}: {e}"))
}

fn cmd_export(args: &[String]) -> Result<String, String> {
    let opts = parse_opts(args);
    let primes = match opts.get("primes") {
        Some(raw) => parse_primes(raw),
        None => DEFAULT_PRIMES.to_vec(),
    };
    if primes.is_empty() {
        return Err("primes must be a non-empty comma-separated list of integers >= 2".to_string());
    }
    let max_exp = opts
        .get("max-exp")
        .map(|s| s.parse())
        .transpose()
        .map_err(|_| "max-exp must be an integer".to_string())?
        .unwrap_or(DEFAULT_MAX_EXP);
    let output = opts.get("output").cloned().unwrap_or_else(|| "basis_factors.json".to_string());

    let numbers = generate_basis(&primes, max_exp);
    let valuations = compute_valuations(&numbers, &primes);
    let data = BasisData::new(primes, max_exp, &numbers, &valuations);
    let json = render_basis_data(&data);
    std::fs::write(&output, &json)
        .map_err(|e| format!("cannot write {output}: {e}"))?;
    Ok(format!("Exported {} numbers to {output}", numbers.len()))
}

fn cmd_gen_lean(args: &[String]) -> Result<String, String> {
    let opts = parse_opts(args);
    let input = opts.get("input").cloned().unwrap_or_else(|| "basis_factors.json".to_string());
    let output = opts.get("output").cloned().unwrap_or_else(|| "RealBasis.lean".to_string());
    let data = load_data(&input)?;
    let lean = render_real_basis(&data);
    std::fs::write(&output, &lean).map_err(|e| format!("cannot write {output}: {e}"))?;
    Ok(format!("Wrote {output} ({} states)", data.basis.len()))
}

fn cmd_gen_rust(args: &[String]) -> Result<String, String> {
    let opts = parse_opts(args);
    let input = opts.get("input").cloned().unwrap_or_else(|| "basis_factors.json".to_string());
    let output = opts.get("output").cloned().unwrap_or_else(|| "generated_vals_array.rs".to_string());
    let data = load_data(&input)?;
    let rs = render_generated_vals(&data);
    std::fs::write(&output, &rs).map_err(|e| format!("cannot write {output}: {e}"))?;
    Ok(format!("Wrote {output} ({} states)", data.basis.len()))
}

fn usage() -> ! {
    eprintln!(
        "usage:\n  meta-theorem-gen export [--primes 2,3,5,7] [--max-exp 3] [--output basis_factors.json]\n  meta-theorem-gen gen-lean [--input basis_factors.json] [--output RealBasis.lean]\n  meta-theorem-gen gen-rust [--input basis_factors.json] [--output generated_vals_array.rs]"
    );
    std::process::exit(2);
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    let Some(cmd) = args.get(1).map(String::as_str) else {
        usage();
    };
    let result = match cmd {
        "export" => cmd_export(&args[2..]),
        "gen-lean" => cmd_gen_lean(&args[2..]),
        "gen-rust" => cmd_gen_rust(&args[2..]),
        "help" | "--help" | "-h" => {
            usage();
        }
        other => {
            eprintln!("unknown command: {other}");
            usage();
        }
    };
    match result {
        Ok(message) => {
            println!("{message}");
            ExitCode::SUCCESS
        }
        Err(message) => {
            eprintln!("{message}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn option_parser_handles_flags() {
        let args = vec![
            "--primes".to_string(),
            "2,3".to_string(),
            "--output".to_string(),
            "out.json".to_string(),
        ];
        let opts = parse_opts(&args);
        assert_eq!(opts.get("primes").unwrap(), "2,3");
        assert_eq!(opts.get("output").unwrap(), "out.json");
    }

    #[test]
    fn exports_default_basis_to_temp_file() {
        let dir = std::env::temp_dir();
        let out = dir.join("mtgen-test-export.json");
        let msg = cmd_export(&["--output".to_string(), out.to_string_lossy().into_owned()]).unwrap();
        assert!(msg.contains("Exported 256 numbers"));
        let bytes = std::fs::read(&out).unwrap();
        assert!(!bytes.is_empty());
        std::fs::remove_file(&out).unwrap();
    }
}