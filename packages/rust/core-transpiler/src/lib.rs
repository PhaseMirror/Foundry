//! Rust port of `core/scripts/nl_to_pirtm.py` — the PIRTM Ring 0.5 ISA
//! transpiler that maps natural-language stability requirements onto the
//! `pirtm.step` MLIR dialect plus a dual-hash witness.
//!
//! The Python used a `Poseidon` mock (SHA-256 with a `"poseidon:"` prefix);
//! this port reproduces it. When no modulus is stated, the Python derives one
//! deterministically from the input via `blake3`; this port always uses the
//! `blake3` crate (the Python's sha256 fallback branch only ran when blake3 was
//! not installed, which never holds here).
//!
//! The emitted MLIR is byte-for-byte identical to the Python f-string output,
//! including its trailing spaces.

#![forbid(unsafe_code)]
#![warn(missing_docs)]

use pyjson::to_python_style;
use regex::Regex;
use serde_json::json;
use sha2::{Digest, Sha256};

/// Canonical certified prime set used for deterministic modulus mapping.
pub const CERTIFIED_PRIMES: [u64; 25] = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
];

/// Primality test.
pub fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    let mut divisor = 2u64;
    while divisor.saturating_mul(divisor) <= n {
        if n.is_multiple_of(divisor) {
            return false;
        }
        divisor += if divisor == 2 { 1 } else { 2 };
    }
    true
}

/// Modulus type: `"tensor"` for prime moduli, `"ctensor"` otherwise.
pub fn get_modulus_type(modulus: u64) -> &'static str {
    if is_prime(modulus) {
        "tensor"
    } else {
        "ctensor"
    }
}

/// Mock Poseidon hash: `sha256("poseidon:" + data)`.
pub fn poseidon_hash(data: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(b"poseidon:");
    hasher.update(data.as_bytes());
    hex::encode(hasher.finalize())
}

/// Plain SHA-256 hex digest.
pub fn sha256_hash(data: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data.as_bytes());
    hex::encode(hasher.finalize())
}

/// The dual-hash witness emitted for a transpiled payload.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DualHashWitness {
    /// `sha256(witness_data)`.
    pub sha256: String,
    /// `sha256("poseidon:" + witness_data)`.
    pub poseidon: String,
}

/// PIRTM transpiler state.
#[derive(Debug, Clone)]
pub struct PirtmTranspiler {
    /// Stability margin ε.
    pub epsilon: f64,
    /// Contraction coefficient q.
    pub q_target: f64,
    /// Nonlinear gain ‖T‖.
    pub op_norm_t: f64,
    /// Prime index modulus.
    pub modulus: u64,
    /// Identity secret for commitment hashing.
    pub identity_secret: String,
}

impl Default for PirtmTranspiler {
    fn default() -> Self {
        Self::new()
    }
}

impl PirtmTranspiler {
    /// Build a transpiler with the Python defaults.
    pub fn new() -> Self {
        Self {
            epsilon: 0.05,
            q_target: 0.95,
            op_norm_t: 1.0,
            modulus: 7,
            identity_secret: "default_secret".to_string(),
        }
    }

    /// Parse a natural-language requirement, mirroring `parse_nl`.
    pub fn parse_nl(&mut self, text: &str) {
        const MAPPINGS: [(&str, &[&str]); 4] = [
            (
                "epsilon",
                &[
                    r"stability margin of ([\d\.]+)",
                    r"epsilon of ([\d\.]+)",
                    r"ε = ([\d\.]+)",
                    r"([\d\.]+)% margin",
                    r"margin of ([\d\.]+)%",
                ],
            ),
            (
                "q_target",
                &[
                    r"spectral radius of ([\d\.]+)",
                    r"contraction coefficient of ([\d\.]+)",
                    r"q = ([\d\.]+)",
                    r"spectral radius < ([\d\.]+)",
                ],
            ),
            (
                "op_norm_t",
                &[
                    r"nonlinear gain of ([\d\.]+)",
                    r"operator norm of ([\d\.]+)",
                    r"‖T‖ = ([\d\.]+)",
                ],
            ),
            (
                "mod",
                &[r"modulus ([\d]+)", r"prime index ([\d]+)", r"p = ([\d]+)"],
            ),
        ];

        for (attr, patterns) in MAPPINGS {
            for pattern in patterns {
                let regex = Regex::new(&format!("(?i){pattern}")).expect("valid regex");
                let Some(captures) = regex.captures(text) else {
                    continue;
                };
                let raw = &captures[1];
                let full_match = captures.get(0).expect("whole match");
                let after_is_percent =
                    full_match.end() < text.len() && text.as_bytes()[full_match.end()] == b'%';

                if attr == "mod" {
                    self.modulus = raw.parse::<u64>().unwrap_or(self.modulus);
                } else {
                    let mut value: f64 = raw.parse().unwrap_or(0.0);
                    if pattern.contains('%') || after_is_percent {
                        value /= 100.0;
                    }
                    match attr {
                        "epsilon" => self.epsilon = value,
                        "q_target" => self.q_target = value,
                        "op_norm_t" => self.op_norm_t = value,
                        _ => unreachable!("covered attributes"),
                    }
                }
                break;
            }
        }

        let lowered = text.to_lowercase();
        if !lowered.contains("modulus")
            && !lowered.contains("prime index")
            && !lowered.contains("p =")
        {
            let hash = blake3::hash(text.as_bytes());
            let bytes = hash.as_bytes();
            let idx = u32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]) as usize
                % CERTIFIED_PRIMES.len();
            self.modulus = CERTIFIED_PRIMES[idx];
        }
    }

    /// Emit the PIRTM MLIR dialect output, byte-identical to the Python.
    pub fn emit_mlir(&self, name: &str) -> String {
        let mod_type = get_modulus_type(self.modulus);
        let identity_commitment = poseidon_hash(&self.identity_secret);
        format!(
            concat!(
                r#"// PIRTM-SPEC-1.0 MLIR Dialect Output"#,
                "\n",
                r#"module @{name} {{"#,
                "\n",
                r#"  pirtm.module {{ "#,
                "\n",
                r#"    prime_index = {modulus} : i64, "#,
                "\n",
                r#"    epsilon = {epsilon:.4} : f64, "#,
                "\n",
                r#"    op_norm_T = {op_norm_t:.4} : f64, "#,
                "\n",
                r#"    identity_commitment = "{identity_commitment}" "#,
                "\n",
                r#"  }} {{"#,
                "\n",
                r#"    %X = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={modulus}>"#,
                "\n",
                r#"    %Xi = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={modulus}>"#,
                "\n",
                r#"    %Lambda = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={modulus}>"#,
                "\n",
                r#"    %G = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={modulus}>"#,
                "\n",
                r#"    "#,
                "\n",
                r#"    %0 = "pirtm.step"(%X, %Xi, %Lambda, %G) {{ "#,
                "\n",
                r#"      mod = {modulus} : i64, "#,
                "\n",
                r#"      epsilon = {epsilon:.4} : f64,"#,
                "\n",
                r#"      q_target = {q_target:.4} : f64"#,
                "\n",
                r#"    }} : (!pirtm.{mod_type}<mod={modulus}>, !pirtm.{mod_type}<mod={modulus}>, !pirtm.{mod_type}<mod={modulus}>, !pirtm.{mod_type}<mod={modulus}>) -> !pirtm.{mod_type}<mod={modulus}>"#,
                "\n",
                r#"  }}}}"#,
                "\n",
                r#"}}}}"#,
            ),
            name = name,
            modulus = self.modulus,
            epsilon = self.epsilon,
            op_norm_t = self.op_norm_t,
            identity_commitment = identity_commitment,
            mod_type = mod_type,
            q_target = self.q_target,
        )
    }

    /// Emit the canonical dual-hash witness payload.
    pub fn emit_witness(&self) -> DualHashWitness {
        let payload = to_python_style(&json!({
            "mod": self.modulus,
            "epsilon": self.epsilon,
            "q_target": self.q_target,
            "op_norm_t": self.op_norm_t,
            "scheme": "dual",
        }));
        DualHashWitness {
            sha256: sha256_hash(&payload),
            poseidon: poseidon_hash(&payload),
        }
    }
}

/// Attributes extracted from emitted MLIR (mirrors `extract_attributes`).
#[derive(Debug, Clone, PartialEq)]
pub struct ExtractedAttributes {
    /// `epsilon` attribute value.
    pub epsilon: Option<f64>,
    /// `q_target` attribute value.
    pub q_target: Option<f64>,
    /// first `mod` `: i64` value (the module prime index).
    pub modulus: Option<u64>,
    /// `op_norm_T` attribute value.
    pub op_norm_t: Option<f64>,
}

/// Extract numeric attributes from emitted MLIR text.
pub fn extract_attributes(output: &str) -> ExtractedAttributes {
    fn capture(regex: &Regex, output: &str) -> Option<f64> {
        regex
            .captures(output)
            .and_then(|c| c.get(1))
            .and_then(|m| m.as_str().parse::<f64>().ok())
    }
    let epsilon = Regex::new(r"epsilon = ([\d\.]+) : f64").expect("valid regex");
    let q_target = Regex::new(r"q_target = ([\d\.]+) : f64").expect("valid regex");
    let modulus = Regex::new(r"mod = ([\d]+) : i64").expect("valid regex");
    let op_norm_t = Regex::new(r"op_norm_T = ([\d\.]+) : f64").expect("valid regex");

    ExtractedAttributes {
        epsilon: capture(&epsilon, output),
        q_target: capture(&q_target, output),
        modulus: modulus
            .captures(output)
            .and_then(|c| c.get(1))
            .and_then(|m| m.as_str().parse::<u64>().ok()),
        op_norm_t: capture(&op_norm_t, output),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn certified_primes_are_prime() {
        assert!(CERTIFIED_PRIMES.into_iter().all(is_prime));
    }

    #[test]
    fn modulus_type_tensor_vs_ctensor() {
        assert_eq!(get_modulus_type(7), "tensor");
        assert_eq!(get_modulus_type(8), "ctensor");
        assert_eq!(get_modulus_type(1), "ctensor");
    }

    #[test]
    fn hash_mocks_match_python() {
        assert_eq!(
            sha256_hash("hello"),
            "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        );
        assert!(poseidon_hash("hello").is_ascii() && poseidon_hash("hello").len() == 64);
        assert_ne!(poseidon_hash("hello"), sha256_hash("hello"));
    }

    #[test]
    fn emits_default_mlir_structure() {
        let transpiler = PirtmTranspiler::new();
        let mlir = transpiler.emit_mlir("generated_module");

        assert!(mlir.contains("module @generated_module"));
        assert!(mlir.contains("prime_index = 7 : i64"));
        assert!(mlir.contains("epsilon = 0.0500 : f64"));
        assert!(mlir.contains("op_norm_T = 1.0000 : f64"));
        assert!(mlir.contains("!pirtm.tensor<mod=7>"));
        assert!(mlir.contains("q_target = 0.9500 : f64"));
        assert!(mlir.contains("identity_commitment = \""));
        assert_eq!(mlir.matches("pirtm.undef").count(), 4);
        assert_eq!(mlir.matches("pirtm.step").count(), 1);
        // Ends like the python triple-quoted string (no trailing newline).
        assert!(mlir.ends_with("}}"));
    }

    #[test]
    fn witness_payload_is_python_style_sorted() {
        let transpiler = PirtmTranspiler::new();
        let witness = transpiler.emit_witness();
        let payload =
            r#"{"epsilon": 0.05, "mod": 7, "op_norm_t": 1.0, "q_target": 0.95, "scheme": "dual"}"#;
        assert_eq!(witness.sha256, sha256_hash(payload));
        assert_eq!(witness.poseidon, poseidon_hash(payload));
    }

    #[test]
    fn parse_nl_recovers_defaults_on_empty_input() {
        let mut transpiler = PirtmTranspiler::new();
        transpiler.parse_nl("");
        assert_eq!(transpiler.epsilon, 0.05);
        assert_eq!(transpiler.q_target, 0.95);
        assert_eq!(transpiler.op_norm_t, 1.0);
    }

    #[test]
    fn parse_nl_extracts_stated_attributes() {
        let mut transpiler = PirtmTranspiler::new();
        transpiler.parse_nl("Ensure ε = 0.07 for p = 13");
        assert!((transpiler.epsilon - 0.07).abs() < 1e-12);
        assert_eq!(transpiler.modulus, 13);
    }

    #[test]
    fn parse_nl_percent_margin_halves_both_forms() {
        let mut a = PirtmTranspiler::new();
        a.parse_nl("guarantee convergence with a 10% margin");
        assert!((a.epsilon - 0.10).abs() < 1e-12);

        let mut b = PirtmTranspiler::new();
        b.parse_nl("spectral radius < 0.92 and 5% stability margin");
        assert!((b.q_target - 0.92).abs() < 1e-12);
        assert!((b.epsilon - 0.05).abs() < 1e-12);
    }

    #[test]
    fn deterministic_prime_mapping_when_modulus_unspecified() {
        let mut transpiler = PirtmTranspiler::new();
        transpiler.parse_nl("operator norm of 0.4 with contraction coefficient of 0.88");
        assert!((transpiler.op_norm_t - 0.4).abs() < 1e-12);
        assert!((transpiler.q_target - 0.88).abs() < 1e-12);
        // Modulus is derived deterministically from the input text.
        let mut repeat = PirtmTranspiler::new();
        repeat.parse_nl("operator norm of 0.4 with contraction coefficient of 0.88");
        assert_eq!(transpiler.modulus, repeat.modulus);
        assert!(CERTIFIED_PRIMES.contains(&transpiler.modulus));
    }

    #[test]
    fn modulus_keywords_suppress_derivation() {
        let mut a = PirtmTranspiler::new();
        a.parse_nl("nonlinear gain of 0.6 and 15% margin for prime index 19");
        assert_eq!(a.modulus, 19);
        assert!((a.op_norm_t - 0.6).abs() < 1e-12);
        assert!((a.epsilon - 0.15).abs() < 1e-12);

        let mut b = PirtmTranspiler::new();
        b.parse_nl("use modulus 2");
        assert_eq!(b.modulus, 2);
    }

    #[test]
    fn extract_attributes_matches_emitted_mlir() {
        let mut transpiler = PirtmTranspiler::new();
        transpiler.parse_nl("nonlinear gain of 0.4 with contraction coefficient of 0.88");
        let mlir = transpiler.emit_mlir("generated_module");
        let attrs = extract_attributes(&mlir);
        assert_eq!(
            attrs,
            ExtractedAttributes {
                epsilon: Some(transpiler.epsilon),
                q_target: Some(0.88),
                modulus: Some(transpiler.modulus),
                op_norm_t: Some(0.4),
            }
        );
    }
}
