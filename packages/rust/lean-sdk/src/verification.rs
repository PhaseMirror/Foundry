use sha2::{Digest, Sha256};

/// Lean-derived maximal allowable effective Lipschitz constant for the 108-cycle.
/// Source: `Core.lean` `aceBound` for dimension 108 = 6000/10000 = 0.6.
pub const ACE_BOUND_THRESHOLD: f64 = 0.6;

/// Theorem identifier used in the proof attestation digest.
const THEOREM_TAG: &[u8] = b"validator_sound_hecke_deligne_v1";

// ---------------------------------------------------------------------------
// 1. Domain types
// ---------------------------------------------------------------------------

/// A single prime power block in an IR word.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrimeBlock {
    /// Prime p.
    pub prime: u32,
    /// Maximal exponent r_max; coefficients span a_{p^0} .. a_{p^{r_max}}.
    pub r_max: u32,
    /// Coefficients a_{p^r} for r in 0..=r_max.
    pub coeffs: Vec<i64>,
}

/// A full IR word: an ordered collection of prime blocks.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IRWord {
    pub blocks: Vec<PrimeBlock>,
}

impl IRWord {
    /// Deterministic binary serialization with magic prefix.
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut out = Vec::new();
        out.extend_from_slice(b"RAMN");
        out.extend_from_slice(&(self.blocks.len() as u32).to_le_bytes());
        for b in &self.blocks {
            out.extend_from_slice(&b.prime.to_le_bytes());
            out.extend_from_slice(&b.r_max.to_le_bytes());
            out.extend_from_slice(&(b.coeffs.len() as u32).to_le_bytes());
            for c in &b.coeffs {
                out.extend_from_slice(&c.to_le_bytes());
            }
        }
        out
    }
}

/// Result of the verification step.
#[derive(Debug, Clone)]
pub struct VerificationResult {
    pub is_valid: bool,
    /// Dimension D = prod_p p^{r_max}.
    pub dimension: u64,
    /// Effective Lipschitz constant λ_eff (computed).
    pub lambda_eff: f64,
    pub hecke_ok: bool,
    pub deligne_ok: bool,
    /// SHA-256 of (serialized_word || THEOREM_TAG).
    pub digest: Vec<u8>,
}

// ---------------------------------------------------------------------------
// 2. Deserialization
// ---------------------------------------------------------------------------

/// Inverse of `IRWord::to_bytes`. Returns None on any malformed input.
pub fn deserialize_word(buf: &[u8]) -> Option<IRWord> {
    if buf.len() < 8 {
        return None;
    }
    if &buf[..4] != b"RAMN" {
        return None;
    }
    let n_blocks = u32::from_le_bytes([buf[4], buf[5], buf[6], buf[7]]) as usize;
    let mut pos = 8usize;
    let mut blocks = Vec::with_capacity(n_blocks);
    for _ in 0..n_blocks {
        if pos + 12 > buf.len() {
            return None;
        }
        let prime = u32::from_le_bytes([buf[pos], buf[pos + 1], buf[pos + 2], buf[pos + 3]]);
        let r_max = u32::from_le_bytes([buf[pos + 4], buf[pos + 5], buf[pos + 6], buf[pos + 7]]);
        let n_coeff =
            u32::from_le_bytes([buf[pos + 8], buf[pos + 9], buf[pos + 10], buf[pos + 11]]) as usize;
        pos += 12;
        if pos + n_coeff * 8 > buf.len() {
            return None;
        }
        let mut coeffs = Vec::with_capacity(n_coeff);
        for _ in 0..n_coeff {
            let c = i64::from_le_bytes([
                buf[pos],
                buf[pos + 1],
                buf[pos + 2],
                buf[pos + 3],
                buf[pos + 4],
                buf[pos + 5],
                buf[pos + 6],
                buf[pos + 7],
            ]);
            coeffs.push(c);
            pos += 8;
        }
        if coeffs.len() != (r_max as usize + 1) {
            return None;
        }
        blocks.push(PrimeBlock {
            prime,
            r_max,
            coeffs,
        });
    }
    if pos != buf.len() {
        return None;
    }
    Some(IRWord { blocks })
}

// ---------------------------------------------------------------------------
// 3. Mathematical checks
// ---------------------------------------------------------------------------

/// Hecke recurrence check:
///   a_{p^{r+2}} = a_p * a_{p^{r+1}} - p^11 * a_{p^r}
/// for all 0 <= r <= r_max - 2.
fn check_hecke_recurrence(block: &PrimeBlock) -> bool {
    if block.coeffs.len() != (block.r_max as usize + 1) {
        return false;
    }
    if block.r_max < 2 {
        return true;
    }
    let p11 = block.prime.pow(11) as i128;
    let a1 = block.coeffs[1] as i128;
    for r in 0..=(block.r_max as usize).saturating_sub(2) {
        let expected = a1 * (block.coeffs[r + 1] as i128) - p11 * (block.coeffs[r] as i128);
        if (block.coeffs[r + 2] as i128) != expected {
            return false;
        }
    }
    true
}

/// Deligne bound (weight 12, squared form): a_p^2 <= 4 * p^11.
/// `a_p` is the coefficient at p^1 (index 1), not the unit a_{p^0}=1.
fn check_deligne_bound(block: &PrimeBlock) -> bool {
    if block.coeffs.len() < 2 {
        return false;
    }
    let a_p = block.coeffs[1] as i128;
    let bound = 4i128 * (block.prime.pow(11) as i128);
    a_p.pow(2) <= bound
}

/// Dimension D = prod_p (p^{r_max}).
fn compute_dimension(word: &IRWord) -> u64 {
    word.blocks
        .iter()
        .map(|b| (b.prime as u64).pow(b.r_max))
        .product()
}

/// Effective Lipschitz constant from the operator-norm ansatz:
///   lambda_eff = (kappa / sqrt(D)) * sum_p p^{(1/2 - sigma)}
fn compute_lambda_eff(word: &IRWord) -> f64 {
    let kappa = 2.0f64;
    let sigma = 0.25f64;
    let d = compute_dimension(word) as f64;
    if d <= 0.0 {
        return f64::INFINITY;
    }
    let sum: f64 = word
        .blocks
        .iter()
        .map(|b| (b.prime as f64).powf(0.5 - sigma))
        .sum();
    kappa * sum / d.sqrt()
}

/// Compute proof digest: SHA-256(serialized_bytes || THEOREM_TAG).
pub fn compute_proof_digest(serialized: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(serialized);
    hasher.update(THEOREM_TAG);
    hasher.finalize().into()
}

// ---------------------------------------------------------------------------
// 4. Core verification
// ---------------------------------------------------------------------------

/// Verify a serialized IR word.
///
/// Steps:
///   1. deserialize
///   2. Hecke consistency per block
///   3. Deligne bound per block
///   4. compute dimension D and lambda_eff
///   5. accept iff all checks pass AND lambda_eff <= ACE_BOUND_THRESHOLD
///   6. digest = SHA-256(word_bytes || THEOREM_TAG)
pub fn verify_certificate(cert: &[u8]) -> VerificationResult {
    let digest = compute_proof_digest(cert);

    let word = match deserialize_word(cert) {
        Some(w) => w,
        None => {
            return VerificationResult {
                is_valid: false,
                dimension: 0,
                lambda_eff: f64::INFINITY,
                hecke_ok: false,
                deligne_ok: false,
                digest: digest.to_vec(),
            };
        }
    };

    let hecke_ok = word.blocks.iter().all(|b| check_hecke_recurrence(b));
    let deligne_ok = word.blocks.iter().all(|b| check_deligne_bound(b));
    let dimension = compute_dimension(&word);
    let lambda_eff = compute_lambda_eff(&word);
    let is_valid = hecke_ok && deligne_ok && lambda_eff <= ACE_BOUND_THRESHOLD;

    VerificationResult {
        is_valid,
        dimension,
        lambda_eff,
        hecke_ok,
        deligne_ok,
        digest: digest.to_vec(),
    }
}

/// Convenience wrapper returning (is_valid, Some(digest)).
pub fn verify_certificate_with_digest(cert: &[u8]) -> (bool, Option<Vec<u8>>) {
    let v = verify_certificate(cert);
    (v.is_valid, Some(v.digest))
}

// ---------------------------------------------------------------------------
// 5. Canonical 108-cycle word
// ---------------------------------------------------------------------------

/// Construct the canonical 108-cycle word:
///   cycle108 = [MocOp.subdivision 3 3, MocOp.subdivision 2 2]
/// i.e. block p=3 (r_max=3) and block p=2 (r_max=2), with coefficients given
/// by Ramanujan tau and the Hecke recurrence. D = 3^3 * 2^2 = 108.
pub fn generate_canonical_word() -> IRWord {
    let block2 = PrimeBlock {
        prime: 2,
        r_max: 2,
        coeffs: vec![1, -24, -1472],
    };

    let block3 = PrimeBlock {
        prime: 3,
        r_max: 3,
        coeffs: vec![1, 252, -113643, -73279080],
    };

    IRWord {
        blocks: vec![block3, block2],
    }
}

/// Generate the canonical certificate bytes and write to a file.
/// Returns the computed proof digest and lambda_eff for informational display.
pub fn generate_certificate_file(path: &str) -> std::io::Result<([u8; 32], f64)> {
    let word = generate_canonical_word();
    let bytes = word.to_bytes();
    let result = verify_certificate(&bytes);
    if !result.is_valid {
        return Err(std::io::Error::new(
            std::io::ErrorKind::Other,
            format!("generated word rejected by verifier: {:?}", result),
        ));
    }
    std::fs::write(path, &bytes)?;
    Ok((
        result.digest[..32].try_into().unwrap_or([0; 32]),
        result.lambda_eff,
    ))
}

// ---------------------------------------------------------------------------
// 6. Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn canonical_word_is_valid() {
        let word = generate_canonical_word();
        let bytes = word.to_bytes();
        let result = verify_certificate(&bytes);

        assert!(result.is_valid, "canonical word must verify: {:?}", result);
        assert!(result.hecke_ok, "Hecke recurrence must hold");
        assert!(result.deligne_ok, "Deligne bound must hold");
        assert_eq!(result.dimension, 108, "dimension must be 108");
        assert!(
            result.lambda_eff > 0.0 && result.lambda_eff <= ACE_BOUND_THRESHOLD,
            "lambda_eff {} must be in (0, {}]",
            result.lambda_eff,
            ACE_BOUND_THRESHOLD
        );
    }

    #[test]
    fn digest_is_reproducible() {
        let bytes = generate_canonical_word().to_bytes();
        let a = verify_certificate(&bytes);
        let b = verify_certificate(&bytes);
        assert_eq!(a.digest, b.digest, "digest must be deterministic");
        assert_eq!(
            a.lambda_eff, b.lambda_eff,
            "lambda_eff must be deterministic"
        );
    }

    #[test]
    fn corruption_is_rejected() {
        let bytes = generate_canonical_word().to_bytes();
        let good = verify_certificate(&bytes);
        assert!(good.is_valid);

        let mut corrupted = bytes.clone();
        let flip_idx = corrupted.len() / 2;
        corrupted[flip_idx] ^= 0x01;

        let bad = verify_certificate(&corrupted);
        assert_ne!(
            good.digest, bad.digest,
            "a byte flip must change the proof digest"
        );
        assert!(!bad.is_valid, "a corrupted word must be rejected");
    }

    #[test]
    fn hecke_violation_is_rejected() {
        let mut bad = generate_canonical_word();
        bad.blocks[0].coeffs[2] += 1;
        let bytes = bad.to_bytes();
        let v = verify_certificate(&bytes);
        assert!(!v.is_valid, "Hecke violation must be rejected");
        assert!(!v.hecke_ok);
    }

    #[test]
    fn deligne_violation_is_rejected() {
        let mut bad = generate_canonical_word();
        bad.blocks[0].coeffs[1] = 10000;
        let bytes = bad.to_bytes();
        let v = verify_certificate(&bytes);
        assert!(!v.is_valid, "Deligne violation must be rejected");
        assert!(!v.deligne_ok);
    }

    #[test]
    fn malformed_input_rejected() {
        let result = verify_certificate(b"not a certificate");
        assert!(!result.is_valid);
    }

    #[test]
    fn digest_changes_when_bytes_change() {
        let bytes = generate_canonical_word().to_bytes();
        let d1 = compute_proof_digest(&bytes);
        let mut bytes2 = bytes.clone();
        bytes2.push(0);
        let d2 = compute_proof_digest(&bytes2);
        assert_ne!(d1, d2, "digest must be sensitive to input changes");
    }

    #[test]
    fn generate_certificate_file_creates_valid_fixture() {
        let path = std::env::temp_dir().join("test_lean_sdk_cert.bin");
        let (digest, lambda) = generate_certificate_file(path.to_str().unwrap())
            .expect("certificate generation must succeed");
        let bytes = std::fs::read(&path).expect("fixture file must exist");
        let result = verify_certificate(&bytes);
        assert!(result.is_valid);
        assert_eq!(result.digest[..32], digest);
        assert!((result.lambda_eff - lambda).abs() < 1e-10);
    }
}
