//! BN254 Pedersen Commitment and Try-and-Increment Hash-to-Curve

use crate::bn254::{Bn254, G1Point};
use num_bigint::BigUint;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// Stored opening record matching artifacts/pm4_opening.json.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PedersenOpeningRecord {
    pub preimage: String,
    pub preimage_sha256: String,
    pub v_scalar: String,
    pub r_scalar: String,
    pub h_new_x: String,
    pub h_new_y: String,
    pub commitment_x: String,
    pub commitment_y: String,
}

pub struct PedersenEngine;

impl PedersenEngine {
    /// Try-and-increment hash-to-curve for generator H_new with domain tag "pedersen-H-v1".
    pub fn compute_h_new() -> G1Point {
        let p = Bn254::p();
        let domain_tag = b"pedersen-H-v1";
        let mut counter = 0u32;

        loop {
            let mut hasher = Sha256::new();
            hasher.update(domain_tag);
            hasher.update(&counter.to_be_bytes());
            let hash_bytes = hasher.finalize();

            let x = BigUint::from_bytes_be(&hash_bytes) % &p;
            let rhs = ((&x * &x % &p * &x) % &p + 3u32) % &p;

            // Check if rhs is quadratic residue in F_p: rhs^((p-1)/2) == 1 mod p
            let exp = (&p - BigUint::from(1u32)) / 2u32;
            if rhs.modpow(&exp, &p) == BigUint::from(1u32) {
                // Compute y = rhs^((p+1)/4) mod p (since p = 3 mod 4 for BN254)
                let sqrt_exp = (&p + BigUint::from(1u32)) / 4u32;
                let y = rhs.modpow(&sqrt_exp, &p);

                // Pick smaller y
                let alt_y = &p - &y;
                let final_y = if y < alt_y { y } else { alt_y };

                let pt = G1Point::Affine { x, y: final_y };
                if Bn254::is_in_subgroup(&pt) {
                    return pt;
                }
            }

            counter += 1;
        }
    }

    /// Compute commitment C = r * G + v * H_new.
    pub fn commit(v: &BigUint, r: &BigUint, h_point: &G1Point) -> G1Point {
        let g = Bn254::generator_g();
        let rg = Bn254::scalar_mul(&g, r);
        let vh = Bn254::scalar_mul(h_point, v);
        Bn254::add(&rg, &vh)
    }

    /// Derives scalar v = OS2IP(SHA256(preimage)) mod q.
    pub fn derive_v_scalar(preimage: &str) -> (BigUint, String) {
        let mut hasher = Sha256::new();
        hasher.update(preimage.as_bytes());
        let hash_bytes = hasher.finalize();
        let hash_hex = hex::encode(hash_bytes);

        let q = Bn254::q();
        let v = BigUint::from_bytes_be(&hash_bytes) % &q;
        (v, hash_hex)
    }

    /// Verifies opening (v, r) against commitment C.
    pub fn verify_opening(c: &G1Point, v: &BigUint, r: &BigUint, h_point: &G1Point) -> bool {
        let recomputed_c = Self::commit(v, r, h_point);
        c == &recomputed_c && Bn254::is_on_curve(c) && Bn254::is_in_subgroup(c)
    }
}
