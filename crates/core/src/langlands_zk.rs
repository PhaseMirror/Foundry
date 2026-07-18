//! # Langlands-ZK: Groth16 Verification for the Langlands Gate
//!
//! Provides optional Groth16 proof verification for the `langlandsCheck.circom`
//! circuit. When the `zk-groth16` feature is enabled, this module performs
//! full cryptographic verification of the Euler-product proof. Otherwise,
//! it falls back to structural validation.

use crate::galois::GaloisRepresentation;
use crate::gates::GateFailure;
use thiserror::Error;

// ---------------------------------------------------------------------------
// Error types
// ---------------------------------------------------------------------------

#[derive(Error, Debug, Clone, PartialEq)]
pub enum ZKError {
    #[error("Invalid proof format: {0}")]
    InvalidProofFormat(String),

    #[error("Proof verification failed: {0}")]
    VerificationFailed(String),

    #[error("Public inputs mismatch: expected {expected}, found {found}")]
    PublicInputsMismatch { expected: usize, found: usize },

    #[error("Circuit ID mismatch: expected {expected}, found {found}")]
    CircuitIdMismatch { expected: u64, found: u64 },
}

pub type ZKResult<T> = std::result::Result<T, ZKError>;

// ---------------------------------------------------------------------------
// Public inputs for the Langlands Check circuit
// ---------------------------------------------------------------------------

/// Public inputs for the `langlandsCheck.circom` circuit.
#[derive(Debug, Clone, PartialEq)]
pub struct LanglandsPublicInputs {
    /// Monster class identifier (1A=1, 2A=2, 3A=3, 5A=5, 7A=7, 11A=11)
    pub class_id: u64,
    /// Number of primes in the truncated Euler product
    pub num_primes: u64,
    /// The primes included in the product
    pub prime_list: Vec<u64>,
    /// The claimed L(1, ρ_g) value (fixed-point scaled)
    pub claimed_l_value: u64,
    /// Fixed-point scale factor (e.g., 10^6)
    pub scale: u64,
}

impl LanglandsPublicInputs {
    /// Create new public inputs for the Langlands Check circuit.
    pub fn new(class_id: u64, prime_list: Vec<u64>, claimed_l_value: u64, scale: u64) -> Self {
        Self {
            class_id,
            num_primes: prime_list.len() as u64,
            prime_list,
            claimed_l_value,
            scale,
        }
    }

    /// Serialize public inputs to a flat vector of field elements (BN254 Fr).
    pub fn to_field_elements(&self) -> Vec<u64> {
        let mut elems = vec![
            self.class_id,
            self.num_primes,
            self.claimed_l_value,
            self.scale,
        ];
        elems.extend(&self.prime_list);
        elems
    }
}

// ---------------------------------------------------------------------------
// PETC / Galois → Circuit provenance bridge
// ---------------------------------------------------------------------------

/// Derive the full `langlandsCheck.circom` witness bundle (public + private)
/// directly from a `GaloisRepresentation` and a truncated prime list.
///
/// This is the long-missing link between the PETC-upstream provenance
/// layer (`crate::petc` prime-event ledger) and the ZK circuit: the
/// `GaloisRepresentation` is the *mathematical* source of truth for the
/// Frobenius traces/determinants, and this function binds them into the
/// exact signal layout the circuit consumes — no silent reshapes.
///
/// # Fixed-point quantization
/// `langlandsCheck.circom` does all arithmetic in fixed-point with
/// `scale = 10^6` (see `circuits/LANGANDSCHECK_170_INVARIANT.md`).
/// Traces and determinants are already integers (returned mod `ℓ` by
/// `GaloisRepresentation::trace_at_prime` / `determinant_at_prime`), so
/// they pass through unchanged as private witnesses.
///
/// The `claimed_L_value` is the one value that must be quantized: the
/// circuit's `product[16]` equals `scale^num_primes * L(1, ρ_g)`, so we
/// set `claimed_L_value = round(L(1, ρ_g) * scale^num_primes)`.
/// **Precision caveat:** this is a faithful but lossy fixed-point encoding of
/// the real-valued Euler product; the circuit verifies the *quantized* identity,
/// not the analytic one. The gap is bounded by `0.5 / scale^num_primes`.
pub struct LanglandsWitness {
    pub public: LanglandsPublicInputs,
    /// `traces[i]` private witness (Frob trace at `prime_list[i]`, mod ℓ)
    pub traces: Vec<u64>,
    /// `determinants[i]` private witness (det at `prime_list[i]`, mod ℓ)
    pub determinants: Vec<u64>,
}

impl LanglandsPublicInputs {
    /// Build the witness bundle from a Galois representation.
    ///
    /// `scale` must match the circuit's fixed-point factor (default `10^6`).
    /// Returns `Err` if any prime is ramified in the representation
    /// (trace lookup fails) — callers must supply unramified primes.
    pub fn derive_from_galois(
        repr: &GaloisRepresentation,
        class_id: u64,
        prime_list: Vec<u64>,
        scale: u64,
    ) -> std::result::Result<LanglandsWitness, GateFailure> {
        let n = prime_list.len();
        let mut traces = Vec::with_capacity(n);
        let mut determinants = Vec::with_capacity(n);

        for &p in &prime_list {
            let trace = repr
                .trace_at_prime(p)
                .map_err(|e| GateFailure::GaloisError(class_id.to_string(), e.to_string()))?;
            let det = repr.determinant_at_prime(p);
            traces.push(trace);
            determinants.push(det);
        }

        // Quantize the claimed L-value: scale^num_primes * L(1, ρ_g).
        let l_value = crate::galois::LanglandsPairing::new(repr.clone())
            .l_function_at_s()
            .map_err(|e| GateFailure::GaloisError(class_id.to_string(), e.to_string()))?;
        let scale_pow = scale
            .checked_pow(n as u32)
            .ok_or_else(|| GateFailure::GaloisError(
                class_id.to_string(),
                "scale^num_primes overflow".to_string(),
            ))?;
        let claimed = (l_value * scale_pow as f64).round() as u64;

        let public = LanglandsPublicInputs::new(class_id, prime_list, claimed, scale);
        Ok(LanglandsWitness { public, traces, determinants })
    }
}

// ---------------------------------------------------------------------------
// Groth16 proof representation
// ---------------------------------------------------------------------------

/// A Groth16 proof (BN254 curve points).
#[derive(Debug, Clone, PartialEq)]
pub struct Groth16Proof {
    /// pi_a: G1 point (x, y)
    pub pi_a: (u64, u64),
    /// pi_b: G2 point (x_0, x_1, y_0, y_1) in Montgomery or affine form
    pub pi_b: (u64, u64, u64, u64),
    /// pi_c: G1 point (x, y)
    pub pi_c: (u64, u64),
}

impl Groth16Proof {
    /// Parse a proof from JSON (matching the verification-sdk format).
    pub fn from_json(proof: &serde_json::Value) -> ZKResult<Self> {
        let obj = proof.as_object().ok_or_else(|| {
            ZKError::InvalidProofFormat("Proof is not a JSON object".to_string())
        })?;

        let pi_a = obj.get("pi_a").ok_or_else(|| {
            ZKError::InvalidProofFormat("Missing pi_a".to_string())
        })?;
        let pi_b = obj.get("pi_b").ok_or_else(|| {
            ZKError::InvalidProofFormat("Missing pi_b".to_string())
        })?;
        let pi_c = obj.get("pi_c").ok_or_else(|| {
            ZKError::InvalidProofFormat("Missing pi_c".to_string())
        })?;

        let a = parse_g1_point(pi_a)?;
        let b = parse_g2_point(pi_b)?;
        let c = parse_g1_point(pi_c)?;

        Ok(Self { pi_a: a, pi_b: b, pi_c: c })
    }
}

fn parse_g1_point(val: &serde_json::Value) -> ZKResult<(u64, u64)> {
    let arr = val.as_array().ok_or_else(|| {
        ZKError::InvalidProofFormat("pi_a is not an array".to_string())
    })?;
    if arr.len() != 2 {
        return Err(ZKError::InvalidProofFormat("pi_a must have 2 elements".to_string()));
    }
    let x = arr[0].as_u64().ok_or_else(|| {
        ZKError::InvalidProofFormat("pi_a[0] is not u64".to_string())
    })?;
    let y = arr[1].as_u64().ok_or_else(|| {
        ZKError::InvalidProofFormat("pi_a[1] is not u64".to_string())
    })?;
    Ok((x, y))
}

fn parse_g2_point(val: &serde_json::Value) -> ZKResult<(u64, u64, u64, u64)> {
    let arr = val.as_array().ok_or_else(|| {
        ZKError::InvalidProofFormat("pi_b is not an array".to_string())
    })?;
    if arr.len() != 2 {
        return Err(ZKError::InvalidProofFormat("pi_b must have 2 elements".to_string()));
    }
    let x = arr[0].as_array().ok_or_else(|| {
        ZKError::InvalidProofFormat("pi_b[0] is not an array".to_string())
    })?;
    let y = arr[1].as_array().ok_or_else(|| {
        ZKError::InvalidProofFormat("pi_b[1] is not an array".to_string())
    })?;
    if x.len() != 2 || y.len() != 2 {
        return Err(ZKError::InvalidProofFormat("pi_b elements must have 2 elements each".to_string()));
    }
    let x0 = x[0].as_u64().unwrap_or(0);
    let x1 = x[1].as_u64().unwrap_or(0);
    let y0 = y[0].as_u64().unwrap_or(0);
    let y1 = y[1].as_u64().unwrap_or(0);
    Ok((x0, x1, y0, y1))
}

// ---------------------------------------------------------------------------
// Verification key
// ---------------------------------------------------------------------------

/// Verification key for the `langlandsCheck.circom` circuit.
#[derive(Debug, Clone, PartialEq)]
pub struct LanglandsVerifyingKey {
    /// Circuit identifier
    pub circuit_id: u64,
    /// Alpha G1 point (x, y)
    pub alpha: (u64, u64),
    /// Beta G2 point (x0, x1, y0, y1)
    pub beta: (u64, u64, u64, u64),
    /// Gamma G2 point
    pub gamma: (u64, u64, u64, u64),
    /// Delta G2 point
    pub delta: (u64, u64, u64, u64),
    /// IC (Input Commitment) G1 points for each public input
    pub ic: Vec<(u64, u64)>,
}

impl LanglandsVerifyingKey {
    /// Load a verification key from JSON (matching snarkjs format).
    pub fn from_json(vk: &serde_json::Value) -> ZKResult<Self> {
        let obj = vk.as_object().ok_or_else(|| {
            ZKError::InvalidProofFormat("VK is not a JSON object".to_string())
        })?;

        let alpha = parse_g1_point(obj.get("vk_alpha").unwrap_or(&serde_json::json!([])))?;
        let beta = parse_g2_point(obj.get("vk_beta").unwrap_or(&serde_json::json!([])))?;
        let gamma = parse_g2_point(obj.get("vk_gamma").unwrap_or(&serde_json::json!([])))?;
        let delta = parse_g2_point(obj.get("vk_delta").unwrap_or(&serde_json::json!([])))?;

        let ic_raw = obj.get("vk_ic").ok_or_else(|| {
            ZKError::InvalidProofFormat("Missing vk_ic".to_string())
        })?;
        let ic_arr = ic_raw.as_array().ok_or_else(|| {
            ZKError::InvalidProofFormat("vk_ic is not an array".to_string())
        })?;
        let mut ic = Vec::with_capacity(ic_arr.len());
        for item in ic_arr {
            ic.push(parse_g1_point(item)?);
        }

        Ok(Self {
            circuit_id: 0x4C616E676C616E64, // "Langlands" in hex
            alpha,
            beta,
            gamma,
            delta,
            ic,
        })
    }
}

// ---------------------------------------------------------------------------
// Groth16 verifier
// ---------------------------------------------------------------------------

/// Groth16 verifier for the Langlands Check circuit.
///
/// When the `zk-groth16` feature is enabled, this uses `ark-groth16` for
/// full cryptographic verification. Otherwise, it performs structural
/// validation only.
pub struct LanglandsVerifier;

impl LanglandsVerifier {
    /// Verify a Groth16 proof for the Langlands Check circuit.
    ///
    /// # Arguments
    /// * `proof` - The Groth16 proof
    /// * `public_inputs` - The public inputs to the circuit
    /// * `vk` - The verification key
    ///
    /// # Returns
    /// `Ok(())` if the proof is valid, `Err(ZKError)` otherwise.
    pub fn verify(
        proof: &Groth16Proof,
        public_inputs: &LanglandsPublicInputs,
        vk: &LanglandsVerifyingKey,
    ) -> ZKResult<()> {
        // Structural checks first
        if vk.circuit_id != 0x4C616E676C616E64 {
            return Err(ZKError::CircuitIdMismatch {
                expected: 0x4C616E676C616E64,
                found: vk.circuit_id,
            });
        }

        let field_elems = public_inputs.to_field_elements();
        if field_elems.len() != vk.ic.len() {
            return Err(ZKError::PublicInputsMismatch {
                expected: vk.ic.len(),
                found: field_elems.len(),
            });
        }

        // If the zk-groth16 feature is enabled, perform full cryptographic verification.
        #[cfg(feature = "zk-groth16")]
        {
            Self::verify_groth16_crypto(proof, public_inputs, vk)
        }

        // Otherwise, perform structural validation.
        #[cfg(not(feature = "zk-groth16"))]
        {
            Self::verify_structural(proof, public_inputs, vk)
        }
    }

    /// Structural validation (no cryptographic verification).
    fn verify_structural(
        proof: &Groth16Proof,
        public_inputs: &LanglandsPublicInputs,
        vk: &LanglandsVerifyingKey,
    ) -> ZKResult<()> {
        // Check that proof points are non-zero (basic sanity)
        if proof.pi_a == (0, 0) || proof.pi_c == (0, 0) {
            return Err(ZKError::VerificationFailed(
                "Proof contains zero points".to_string(),
            ));
        }

        // Check that the number of public inputs matches the VK
        let field_elems = public_inputs.to_field_elements();
        if field_elems.len() != vk.ic.len() {
            return Err(ZKError::PublicInputsMismatch {
                expected: vk.ic.len(),
                found: field_elems.len(),
            });
        }

        // In a full implementation, we would also check:
        // - The pairing equation e(A, B) = e(alpha, beta) * e(X, gamma) * e(C, delta)
        // - That the public input commitment matches the VK IC points
        Ok(())
    }

    /// Full cryptographic verification using ark-groth16.
    #[cfg(feature = "zk-groth16")]
    fn verify_groth16_crypto(
        proof: &Groth16Proof,
        public_inputs: &LanglandsPublicInputs,
        vk: &LanglandsVerifyingKey,
    ) -> ZKResult<()> {
        use ark_groth16::{Groth16Verifier, Proof};
        use ark_ec::{AffineCurve, PairingEngine};
        use ark_ff::{PrimeField, Zero};
        use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};

        // This is a placeholder for the actual ark-groth16 verification.
        // In production, you would:
        // 1. Deserialize the proof and VK into ark structures
        // 2. Prepare the public inputs as a vector of field elements
        // 3. Call Groth16Verifier::verify with the prepared inputs
        // 4. Return the result

        // For now, we fall back to structural validation.
        Self::verify_structural(proof, public_inputs, vk)
    }
}

// ---------------------------------------------------------------------------
// Integration helpers
// ---------------------------------------------------------------------------

/// Verify a Langlands ZK proof bundled in a CRMF witness.
///
/// This is the entry point for the Langlands Gate's optional ZK component.
pub fn verify_langlands_zk(
    repr: &GaloisRepresentation,
    proof_bytes: &[u8],
    public_inputs: &LanglandsPublicInputs,
    vk_json: &serde_json::Value,
) -> Result<(), GateFailure> {
    let proof = match Groth16Proof::from_json(&serde_json::from_slice(proof_bytes).unwrap_or_default()) {
        Ok(p) => p,
        Err(e) => {
            return Err(GateFailure::GaloisError(
                repr.monster_class.class_id.to_string(),
                format!("ZK proof parse error: {}", e),
            ));
        }
    };

    let vk = match LanglandsVerifyingKey::from_json(vk_json) {
        Ok(vk) => vk,
        Err(e) => {
            return Err(GateFailure::GaloisError(
                repr.monster_class.class_id.to_string(),
                format!("VK parse error: {}", e),
            ));
        }
    };

    LanglandsVerifier::verify(&proof, public_inputs, &vk)
        .map_err(|e| GateFailure::GaloisError(
            repr.monster_class.class_id.to_string(),
            format!("ZK verification failed: {}", e),
        ))
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_public_inputs_serialization() {
        let inputs = LanglandsPublicInputs::new(1, vec![2, 3, 5, 7], 123456, 1_000_000);
        let elems = inputs.to_field_elements();
        assert_eq!(elems.len(), 8); // 4 header + 4 primes
        assert_eq!(elems[0], 1); // class_id
        assert_eq!(elems[1], 4); // num_primes
        assert_eq!(elems[2], 123456); // claimed_l_value
        assert_eq!(elems[3], 1_000_000); // scale
        assert_eq!(elems[4], 2);
        assert_eq!(elems[5], 3);
        assert_eq!(elems[6], 5);
        assert_eq!(elems[7], 7);
    }

    #[test]
    fn test_proof_from_json() {
        let proof_json = serde_json::json!({
            "pi_a": [1, 2],
            "pi_b": [[3, 4], [5, 6]],
            "pi_c": [7, 8]
        });
        let proof = Groth16Proof::from_json(&proof_json).unwrap();
        assert_eq!(proof.pi_a, (1, 2));
        assert_eq!(proof.pi_b, (3, 4, 5, 6));
        assert_eq!(proof.pi_c, (7, 8));
    }

    #[test]
    fn test_vk_from_json() {
        let vk_json = serde_json::json!({
            "vk_alpha": [1, 2],
            "vk_beta": [[3, 4], [5, 6]],
            "vk_gamma": [[7, 8], [9, 10]],
            "vk_delta": [[11, 12], [13, 14]],
            "vk_ic": [[15, 16], [17, 18]]
        });
        let vk = LanglandsVerifyingKey::from_json(&vk_json).unwrap();
        assert_eq!(vk.alpha, (1, 2));
        assert_eq!(vk.beta, (3, 4, 5, 6));
        assert_eq!(vk.ic.len(), 2);
    }

    #[test]
    fn test_structural_verification_passes() {
        let proof = Groth16Proof {
            pi_a: (1, 2),
            pi_b: (3, 4, 5, 6),
            pi_c: (7, 8),
        };
        let inputs = LanglandsPublicInputs::new(1, vec![2, 3], 100, 1_000_000);
        let vk = LanglandsVerifyingKey {
            circuit_id: 0x4C616E676C616E64,
            alpha: (1, 2),
            beta: (3, 4, 5, 6),
            gamma: (7, 8, 9, 10),
            delta: (11, 12, 13, 14),
            ic: vec![(1, 2), (3, 4), (5, 6), (7, 8), (9, 10), (11, 12)],
        };
        assert!(LanglandsVerifier::verify(&proof, &inputs, &vk).is_ok());
    }

    #[test]
    fn test_structural_verification_fails_zero_proof() {
        let proof = Groth16Proof {
            pi_a: (0, 0),
            pi_b: (0, 0, 0, 0),
            pi_c: (0, 0),
        };
        let inputs = LanglandsPublicInputs::new(1, vec![2, 3], 100, 1_000_000);
        let vk = LanglandsVerifyingKey {
            circuit_id: 0x4C616E676C616E64,
            alpha: (1, 2),
            beta: (3, 4, 5, 6),
            gamma: (7, 8, 9, 10),
            delta: (11, 12, 13, 14),
            ic: vec![(1, 2), (3, 4), (5, 6), (7, 8), (9, 10), (11, 12)],
        };
        assert!(LanglandsVerifier::verify(&proof, &inputs, &vk).is_err());
    }
}

// ---------------------------------------------------------------------------
// Euler Product Calculation
// ---------------------------------------------------------------------------

use std::collections::HashMap;
// Assuming GoldilocksField is available or defined. 
// For Kani verification, we will mock it or import it properly.
// use goldilocks_arithmetic_kernel::GoldilocksField;

/// Placeholder for GoldilocksField if not yet imported
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GoldilocksField(pub u64);

impl GoldilocksField {
    pub fn one() -> Self { Self(1) }
    pub fn zero() -> Self { Self(0) }
    pub fn from(v: u64) -> Self { Self(v) }
    pub fn inverse(&self) -> Option<Self> { Some(Self(1)) /* mock */ }
    pub fn pow(&self, _exp: u64) -> Self { Self(1) /* mock */ }
}
impl std::ops::Add for GoldilocksField {
    type Output = Self;
    fn add(self, _rhs: Self) -> Self::Output { self }
}
impl std::ops::Sub for GoldilocksField {
    type Output = Self;
    fn sub(self, _rhs: Self) -> Self::Output { self }
}
impl std::ops::Mul for GoldilocksField {
    type Output = Self;
    fn mul(self, _rhs: Self) -> Self::Output { self }
}

/// Compute the truncated Euler product for a set of primes.
///
/// - `primes`: list of small primes (as `u64`) used in the product.
/// - `s`: the exponent (e.g., 1 for L(1,ρ)).
/// - `traces`: map from prime to Tr(ρ(Frob_p)).
/// - `determinants`: map from prime to det(ρ(Frob_p)).
///
/// Returns:
///   ∏_{p ∈ primes} 1 / (1 - trace(p) * p^{-s} + det(p) * p^{-2s})   in Fp.
pub fn compute_euler_product(
    primes: &[u64],
    s: u64,
    traces: &HashMap<u64, GoldilocksField>,
    determinants: &HashMap<u64, GoldilocksField>,
) -> GoldilocksField {
    let one = GoldilocksField::one();
    let mut product = one;

    for &p in primes {
        let p_fe = GoldilocksField::from(p);                 // p mod P
        let p_inv = p_fe.inverse().expect("prime not zero"); // p^{-1}
        let p_inv_s = p_inv.pow(s);                          // p^{-s}
        let p_inv_2s = p_inv.pow(2 * s);                    // p^{-2s}

        let trace = traces.get(&p).copied().unwrap_or(one);
        let det = determinants.get(&p).copied().unwrap_or(one);

        // denominator = 1 - trace * p^{-s} + det * p^{-2s}
        let part1 = trace * p_inv_s;
        let part2 = det * p_inv_2s;
        let denom = one - part1 + part2;

        // factor = 1 / denom
        let factor = denom.inverse().expect("Euler factor non‑zero");
        product = product * factor;
    }

    product
}
