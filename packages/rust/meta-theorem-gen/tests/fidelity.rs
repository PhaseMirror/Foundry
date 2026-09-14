//! Byte-level fidelity tests against goldens produced by the original Python
//! scripts (`crates/materia_commons/meta-theorem/`).
//!
//! * `golden: basis_factors.json` — the committed `json.dump(indent=2)` output,
//! * `golden_real_basis.lean` — output of `gen_real_basis.py`,
//! * `golden_generated_vals.rs` — output of `generate_rust_vals.py`.

use meta_theorem_gen::basis::{compute_valuations, generate_basis};
use meta_theorem_gen::lean::render_real_basis;
use meta_theorem_gen::model::BasisData;
use meta_theorem_gen::python_json::render_basis_data;
use meta_theorem_gen::rust_array::render_generated_vals;

const BASIS_FACTORS_JSON: &str = include_str!("fixtures/basis_factors.json");
const GOLDEN_REAL_BASIS_LEAN: &str = include_str!("fixtures/golden_real_basis.lean");
const GOLDEN_GENERATED_VALS_RS: &str = include_str!("fixtures/golden_generated_vals.rs");

fn committed_basis() -> BasisData {
    serde_json::from_str(BASIS_FACTORS_JSON).expect("fixture JSON parses")
}

#[test]
fn export_renders_byte_identical_json() {
    let primes = vec![2, 3, 5, 7];
    let numbers = generate_basis(&primes, 3);
    let valuations = compute_valuations(&numbers, &primes);
    let data = BasisData::new(primes, 3, &numbers, &valuations);
    assert_eq!(render_basis_data(&data), BASIS_FACTORS_JSON);
}

#[test]
fn generation_reproduces_committed_data() {
    let committed = committed_basis();
    let primes = committed.primes.clone();
    let numbers = generate_basis(&primes, committed.max_exp);
    assert_eq!(numbers.len(), committed.basis.len());
    for (generated, expected) in numbers.iter().zip(committed.basis.iter()) {
        assert_eq!(*generated, expected.n);
    }
}

#[test]
fn gen_real_basis_is_byte_identical_to_python() {
    let data = committed_basis();
    assert_eq!(render_real_basis(&data), GOLDEN_REAL_BASIS_LEAN);
}

#[test]
fn generate_rust_vals_is_byte_identical_to_python() {
    let data = committed_basis();
    assert_eq!(render_generated_vals(&data), GOLDEN_GENERATED_VALS_RS);
}

#[test]
fn valuation_lengths_match_prime_count() {
    let data = committed_basis();
    for entry in &data.basis {
        assert_eq!(entry.exponents.len(), data.primes.len());
    }
}