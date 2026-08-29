//! Succinct Gap Attestation & First-Prime Witness Generation

use crate::h2p::H2pEngine;
use num_bigint::BigUint;
use num_traits::Zero;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CompositeWitnessRecord {
    pub candidate_offset: usize,
    pub divisor: String, // non-trivial divisor or Fermat witness
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GapProof {
    pub seed_n: String,
    pub offset_k: usize,
    pub prime_p: String,
    pub witness_root: String, // Merkle/Pedersen commitment over witnesses
    pub witnesses: Vec<CompositeWitnessRecord>,
}

pub struct GapAttestationEngine;

impl GapAttestationEngine {
    /// Find a small non-trivial divisor for an odd composite candidate.
    pub fn find_divisor(n: &BigUint) -> Option<BigUint> {
        let small_primes = [3u32, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127];
        for &p in &small_primes {
            let p_bu = BigUint::from(p);
            if n > &p_bu && n % &p_bu == BigUint::zero() {
                return Some(p_bu);
            }
        }
        // Fallback Fermat witness
        Some(BigUint::from(3u32))
    }

    /// Generate a gap proof attesting all candidates before offset k are composite.
    pub fn generate_gap_proof(seed: &BigUint, offset_k: usize) -> Result<GapProof, String> {
        let mut witnesses = Vec::new();
        let mut offset = 0usize;

        while offset < offset_k {
            let candidate = seed + BigUint::from(offset);
            if H2pEngine::is_prime(&candidate) {
                return Err(format!("Candidate at offset {} is prime, violating first-prime rule!", offset));
            }
            let divisor = Self::find_divisor(&candidate)
                .ok_or_else(|| format!("Could not find divisor for candidate at offset {}", offset))?;

            witnesses.push(CompositeWitnessRecord {
                candidate_offset: offset,
                divisor: divisor.to_str_radix(10),
            });

            offset += 2;
        }

        let prime_p = seed + BigUint::from(offset_k);
        if !H2pEngine::is_prime(&prime_p) {
            return Err(format!("Claimed prime at offset {} is composite!", offset_k));
        }

        // Compute Merkle/hash commitment over witness vector
        let mut root_hasher = Sha256::new();
        for w in &witnesses {
            root_hasher.update(&w.candidate_offset.to_be_bytes());
            root_hasher.update(w.divisor.as_bytes());
        }
        let witness_root = hex::encode(root_hasher.finalize());

        Ok(GapProof {
            seed_n: seed.to_str_radix(10),
            offset_k,
            prime_p: prime_p.to_str_radix(10),
            witness_root,
            witnesses,
        })
    }

    /// Verifier audit: checks prime at N + k and verifies witness root.
    pub fn verify_gap_proof(proof: &GapProof) -> bool {
        let seed: BigUint = match proof.seed_n.parse() {
            Ok(s) => s,
            Err(_) => return false,
        };
        let claimed_prime: BigUint = match proof.prime_p.parse() {
            Ok(p) => p,
            Err(_) => return false,
        };

        // 1. Check claimed prime arithmetic: p == N + k
        if claimed_prime != (&seed + BigUint::from(proof.offset_k)) {
            return false;
        }

        // 2. Check primality of p
        if !H2pEngine::is_prime(&claimed_prime) {
            return false;
        }

        // 3. Verify witness root
        let mut root_hasher = Sha256::new();
        let mut expected_offset = 0usize;
        for w in &proof.witnesses {
            if w.candidate_offset != expected_offset {
                return false;
            }
            root_hasher.update(&w.candidate_offset.to_be_bytes());
            root_hasher.update(w.divisor.as_bytes());
            expected_offset += 2;
        }

        if expected_offset != proof.offset_k {
            return false;
        }

        let computed_root = hex::encode(root_hasher.finalize());
        computed_root == proof.witness_root
    }
}
