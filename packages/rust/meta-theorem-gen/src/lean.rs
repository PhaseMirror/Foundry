//! Port of `gen_real_basis.py` — renders `RealBasis.lean` from
//! `basis_factors.json`.
//!
//! The output is byte-identical to the Python generator (see
//! `tests/fidelity.rs`): a Lean file defining `primes`, `basisNumbers`,
//! `basisValuations`, `N_states`, and `valuationOf` in
//! `namespace SemanticArithmetic.RealBasis`.

use crate::model::BasisData;

/// `fmt_nat_list` — `"[2, 3, 5, 7]"`, the Python `"[" + ", ".join(str(x)) + "]"`.
pub fn format_nat_list(values: &[u64]) -> String {
    let body = values
        .iter()
        .map(|v| v.to_string())
        .collect::<Vec<_>>()
        .join(", ");
    format!("[{body}]")
}

/// `fmt_val_list` — nested list of exponent vectors, one line in Python.
pub fn format_valuation_list(valuations: &[Vec<u64>]) -> String {
    let body = valuations
        .iter()
        .map(|v| format_nat_list(v))
        .collect::<Vec<_>>()
        .join(", ");
    format!("[{body}]")
}

/// Render the full `RealBasis.lean` source.
pub fn render_real_basis(data: &BasisData) -> String {
    let numbers: Vec<u64> = data.basis.iter().map(|e| e.n).collect();
    let valuations: Vec<Vec<u64>> = data.basis.iter().map(|e| e.exponents.clone()).collect();
    let header = format!(
        "Real (non-mock) basis data: primes = {:?}, {} states.",
        data.primes,
        numbers.len()
    );

    let mut lines: Vec<String> = Vec::new();
    lines.push("/-".to_string());
    lines.push("RealBasis.lean".to_string());
    lines.push("Generated from basis_factors.json by gen_real_basis.py.".to_string());
    lines.push(header);
    lines.push("Do not edit by hand; re-run gen_real_basis.py instead.".to_string());
    lines.push("-/".to_string());
    lines.push(String::new());
    lines.push("import SemanticArithmetic.Core".to_string());
    lines.push(String::new());
    lines.push("namespace SemanticArithmetic.RealBasis".to_string());
    lines.push(String::new());
    lines.push(format!(
        "def primes : List Nat := {}",
        format_nat_list(&data.primes)
    ));
    lines.push(String::new());
    lines.push(format!(
        "/-- The {} basis integers n, in basis order. -/",
        numbers.len()
    ));
    lines.push(format!(
        "def basisNumbers : List Nat := {}",
        format_nat_list(&numbers)
    ));
    lines.push(String::new());
    lines.push("/-- Valuations (exponent vectors) aligned with `basisNumbers`. -/".to_string());
    lines.push(format!(
        "def basisValuations : List (List Nat) := {}",
        format_valuation_list(&valuations)
    ));
    lines.push(String::new());
    lines.push("/-- Number of basis states. -/".to_string());
    lines.push(format!("def N_states : Nat := {}", numbers.len()));
    lines.push(String::new());
    lines.push("/-- Look up the valuation vector of a basis integer (defaults to zeros). -/".to_string());
    lines.push("def valuationOf (n : Nat) : List Nat :=".to_string());
    lines.push(
        "  (List.zip basisNumbers basisValuations).lookup n |>.getD (List.replicate primes.length 0)"
            .to_string(),
    );
    lines.push(String::new());
    lines.push("end SemanticArithmetic.RealBasis".to_string());
    lines.push(String::new());
    lines.join("\n")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nat_list_format_matches_python() {
        assert_eq!(format_nat_list(&[2, 3, 5, 7]), "[2, 3, 5, 7]");
        assert_eq!(format_valuation_list(&[vec![0, 0], vec![1, 0]]), "[[0, 0], [1, 0]]");
    }
}