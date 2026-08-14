//! Deterministic regression vectors for `multiplicity-algebra`, loaded from
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

fn cs(value: &Value) -> Vec<i64> {
    value
        .as_array()
        .unwrap()
        .iter()
        .map(|x| x.as_i64().unwrap())
        .collect()
}

#[test]
fn regression_gcd_lcm() {
    let v = load("gcd_lcm.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let a = c["a"].as_u64().unwrap();
        let b = c["b"].as_u64().unwrap();
        let g = c["gcd"].as_u64().unwrap();
        let l = c["lcm"].as_u64().unwrap();
        assert_eq!(multiplicity_algebra::gcd_lcm(a, b), (g, l), "gcd_lcm({a}, {b})");
    }
}

#[test]
fn regression_poly_eval() {
    let v = load("poly_eval.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let coefficients = cs(&c["cs"]);
        let x = c["x"].as_i64().unwrap();
        let expected = c["expected"].as_i64().unwrap();
        assert_eq!(
            multiplicity_algebra::poly_eval(&coefficients, x),
            expected,
            "poly_eval({coefficients:?}, {x})"
        );
    }
}

#[test]
fn regression_synthetic_division() {
    let v = load("synthetic_division.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let coefficients = cs(&c["cs"]);
        let r = c["r"].as_i64().unwrap();
        let q = cs(&c["quotient"]);
        let rem = c["remainder"].as_i64().unwrap();
        assert_eq!(
            multiplicity_algebra::synthetic_division(&coefficients, r),
            (q, rem),
            "synthetic_division({coefficients:?}, {r})"
        );
    }
}

#[test]
fn regression_root_multiplicity() {
    let v = load("root_multiplicity.json");
    let cases = v["vectors"].as_array().expect("vectors array");
    for c in cases {
        let coefficients = cs(&c["cs"]);
        let r = c["r"].as_i64().unwrap();
        let expected = c["expected"].as_u64().unwrap() as usize;
        assert_eq!(
            multiplicity_algebra::root_multiplicity(&coefficients, r),
            expected,
            "root_multiplicity({coefficients:?}, {r})"
        );
    }
}
