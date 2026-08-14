//! Deterministic regression vectors for `multiplicity-core`, loaded from the
//! JSON vectors under `kani/regression/`.  These are the executable regression
//! half of the three-form contract (Lean spec + Rust impl + regression/Kani).

use serde_json::Value;
use std::path::PathBuf;

fn regression_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("..")
        .join("kani")
        .join("regression")
}

fn load(name: &str) -> Value {
    let path = regression_dir().join(name);
    let text = std::fs::read_to_string(&path)
        .unwrap_or_else(|e| panic!("cannot read regression vector {path:?}: {e}"));
    serde_json::from_str(&text).expect("regression vector is valid JSON")
}

#[test]
fn regression_factorial() {
    let v = load("factorial.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let input = c["input"].as_u64().unwrap();
        let expected = c["expected"].as_u64().unwrap();
        assert_eq!(
            multiplicity_core::factorial(input),
            expected,
            "factorial({input})"
        );
    }
}

#[test]
fn regression_divides() {
    let v = load("divides.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let a = c["a"].as_u64().unwrap();
        let b = c["b"].as_u64().unwrap();
        let expected = c["expected"].as_bool().unwrap();
        assert_eq!(
            multiplicity_core::divides(a, b),
            expected,
            "divides({a}, {b})"
        );
    }
}

#[test]
fn regression_int_div_mod() {
    let v = load("int_div_mod.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let a = c["a"].as_i64().unwrap();
        let b = c["b"].as_i64().unwrap();
        let q = c["q"].as_i64().unwrap();
        let r = c["r"].as_i64().unwrap();
        assert_eq!(multiplicity_core::int_div_mod(a, b), (q, r), "int_div_mod({a}, {b})");
    }
}
