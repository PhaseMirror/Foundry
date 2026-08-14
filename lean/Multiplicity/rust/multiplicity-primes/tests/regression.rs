//! Deterministic regression vectors for `multiplicity-primes`, loaded from
//! the JSON vectors under `kani/regression/`.

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
fn regression_is_prime() {
    let v = load("is_prime.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let n = c["n"].as_u64().unwrap();
        let expected = c["expected"].as_bool().unwrap();
        assert_eq!(multiplicity_primes::is_prime(n), expected, "is_prime({n})");
    }
}

#[test]
fn regression_valuation() {
    let v = load("valuation.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let p = c["p"].as_u64().unwrap();
        let n = c["n"].as_u64().unwrap();
        let expected = c["expected"].as_u64().unwrap();
        assert_eq!(multiplicity_primes::valuation(p, n), expected, "valuation({p}, {n})");
    }
}

#[test]
fn regression_prime_factors() {
    let v = load("prime_factors.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let n = c["n"].as_u64().unwrap();
        let expected: Vec<u64> = c["expected"]
            .as_array()
            .unwrap()
            .iter()
            .map(|x| x.as_u64().unwrap())
            .collect();
        assert_eq!(multiplicity_primes::prime_factors(n), expected, "prime_factors({n})");
    }
}
