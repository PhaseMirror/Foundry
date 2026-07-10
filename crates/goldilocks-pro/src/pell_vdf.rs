use num_bigint::BigUint;
use num_traits::{Zero, One};
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use num_prime::RandPrime;
use thiserror::Error;
use tracing::{instrument, info, error};
use zeroize::Zeroize;

#[derive(Error, Debug)]
pub enum VDFError {
    #[error("Invalid VDF proof")]
    InvalidProof,
    #[error("VDF timeout")]
    Timeout,
    #[error("Evaluation error: {0}")]
    EvalError(String),
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct QuadElement {
    pub x: BigUint,
    pub y: BigUint,
}

fn mul_quad(a: &QuadElement, b: &QuadElement, d: &BigUint, n: &BigUint) -> QuadElement {
    let ac = (&a.x * &b.x) % n;
    let bd = (&a.y * &b.y) % n;
    let ad = (&a.x * &b.y) % n;
    let bc = (&a.y * &b.x) % n;

    let x = (ac + (bd * d) % n) % n;
    let y = (ad + bc) % n;

    QuadElement { x, y }
}

fn fundamental_unit(n: &BigUint) -> QuadElement {
    let x = BigUint::from(3u64) % n;
    let y = BigUint::from(2u64) % n;
    QuadElement { x, y }
}

fn seed_to_quad(seed: &[u8], party_id: u64, d: &BigUint, n: &BigUint) -> QuadElement {
    let mut hasher = Sha256::new();
    hasher.update(seed);
    hasher.update(party_id.to_le_bytes());
    let mut hash = hasher.finalize();
    let k = BigUint::from_bytes_be(&hash);
    hash.zeroize();

    exp_quad(&fundamental_unit(n), &k, d, n)
}

fn exp_quad(base: &QuadElement, exp: &BigUint, d: &BigUint, n: &BigUint) -> QuadElement {
    let mut result = QuadElement { x: BigUint::from(1u64), y: BigUint::zero() };
    let mut base_cloned = base.clone();
    let mut exp_cloned = exp.clone();
    
    while exp_cloned > BigUint::zero() {
        if &exp_cloned & BigUint::from(1u64) == BigUint::from(1u64) {
            result = mul_quad(&result, &base_cloned, d, n);
        }
        base_cloned = mul_quad(&base_cloned, &base_cloned, d, n);
        exp_cloned >>= 1;
    }
    result
}

pub fn prove_vdf(g: &QuadElement, t: u64, d: &BigUint, n: &BigUint) -> QuadElement {
    let mut state = g.clone();
    for _ in 0..t {
        state = mul_quad(&state, &state, d, n);
    }
    state
}

fn generate_proof(g: &QuadElement, t: u64, d: &BigUint, n: &BigUint) -> (BigUint, QuadElement, QuadElement) {
    let mut rng = rand::thread_rng();
    let l = RandPrime::<BigUint>::gen_prime(&mut rng, 128, None);

    let two = BigUint::from(2u64);
    let mut state = g.clone();
    let mut q = BigUint::zero();
    let mut r = BigUint::one(); // 2^0 mod l

    for _ in 0..t {
        // Pell squaring
        state = mul_quad(&state, &state, d, n);

        // Update q, r for 2^i -> 2^{i+1}
        r = &r * &two;
        if r >= l {
            q = &q + (&r / &l);
            r = &r % &l;
        }
    }
    
    let pi = exp_quad(g, &q, d, n);
    (l, pi, state)
}

fn verify_proof(g: &QuadElement, output: &QuadElement, l: &BigUint, pi: &QuadElement, t: u64, d: &BigUint, n: &BigUint) -> bool {
    let two = BigUint::from(2u64);
    
    // Verifier computes r = 2^T mod l efficiently
    let r = two.modpow(&BigUint::from(t), l);

    let pi_l = exp_quad(pi, l, d, n);
    let g_r = exp_quad(g, &r, d, n);
    let lhs = mul_quad(&pi_l, &g_r, d, n);

    lhs == *output
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PellVDFProof {
    pub output: QuadElement,
    pub challenge_prime: BigUint,
    pub pi: QuadElement,
}

pub struct PellVDF {
    d: BigUint,
    pub n: BigUint,
    pub t: u64,
}

impl PellVDF {
    pub fn new(n: BigUint, t: u64) -> Self {
        let d = BigUint::from(2u64);
        PellVDF { d, n, t }
    }

    #[instrument(skip(self, seed), err)]
    pub fn evaluate(&self, seed: &[u8], party_id: u64) -> Result<PellVDFProof, VDFError> {
        info!("Starting VDF evaluation for party_id: {}", party_id);
        let g = seed_to_quad(seed, party_id, &self.d, &self.n);
        let (l, pi, output) = generate_proof(&g, self.t, &self.d, &self.n);
        info!("Completed VDF evaluation for party_id: {}", party_id);
        Ok(PellVDFProof { output, challenge_prime: l, pi })
    }

    #[instrument(skip(self, seed), err)]
    pub fn verify(&self, seed: &[u8], party_id: u64, proof: &PellVDFProof) -> Result<(), VDFError> {
        info!("Verifying VDF proof for party_id: {}", party_id);
        let g = seed_to_quad(seed, party_id, &self.d, &self.n);
        if verify_proof(&g, &proof.output, &proof.challenge_prime, &proof.pi, self.t, &self.d, &self.n) {
            info!("VDF proof verified successfully for party_id: {}", party_id);
            Ok(())
        } else {
            error!("VDF proof verification failed for party_id: {}", party_id);
            Err(VDFError::InvalidProof)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_modulus() -> BigUint {
        let n_str = "c7970ceedcc3b0754490201a7aa613cd73911081c790f5f1a8726f463550bb5b\
        7ff0dad8b8f79b0b5e2e9e2c3b9d9e5a4d3b9a6d7f0b1c3d5e6f7a8b9c0d1e2f\
        3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5\
        c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e\
        8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0\
        b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d\
        3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5\
        a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c\
        8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0\
        f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b\
        3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5\
        e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a\
        8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0\
        d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f\
        3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5\
        c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e\
        8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0\
        b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d\
        3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5\
        a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c\
        8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9";
        BigUint::parse_bytes(n_str.as_bytes(), 16).unwrap()
    }

    #[test]
    fn test_pell_vdf_honest() {
        let n = test_modulus();
        let vdf = PellVDF::new(n, 100);
        let seed = b"test_seed";
        let proof = vdf.evaluate(seed, 0).unwrap();
        assert!(vdf.verify(seed, 0, &proof).is_ok());
    }

    #[test]
    fn test_pell_vdf_cheater_caught() {
        let n = test_modulus();
        let vdf = PellVDF::new(n, 100);
        let seed = b"test_seed";
        let mut proof = vdf.evaluate(seed, 0).unwrap();
        proof.output.x += 1u64; // tamper
        assert!(vdf.verify(seed, 0, &proof).is_err());
    }
}
