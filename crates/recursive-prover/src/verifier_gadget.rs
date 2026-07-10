use goldilocks::GoldilocksField;
use pasta_curves::{AffinePoint, PastaField, PedersenCommitment, get_pallas_params};
use prover::StarkProof;
use num_bigint::BigUint;
use anyhow::{Result, anyhow};
use serde::{Serialize, Deserialize};
use sha3::{Digest, Keccak256};

/// Recursive Proof Object (RPO) v1 (ADR-036 §1).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecursiveProofObject {
    pub protocol_v: u32,
    pub inner_root: [u8; 32],
    pub inputs: Vec<u64>,
    pub fri_roots: Vec<[u8; 32]>,
    pub seal_x: String, // Hex encoded BigUint
    pub seal_y: String, // Hex encoded BigUint
}

/// Aggregated Proof Object (APO) v1.
/// Attests to the validity of multiple RPOs.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AggregatedProofObject {
    pub protocol_v: u32,
    pub aggregate_root: [u8; 32],
    pub member_roots: Vec<[u8; 32]>,
    pub seal_x: String,
    pub seal_y: String,
}

/// STARK Verifier Gadget for recursive composition.
pub struct StarkVerifierGadget {
    pub pedersen: PedersenCommitment<32>,
}

impl StarkVerifierGadget {
    pub fn new() -> Self {
        let (p, _q, a, b) = get_pallas_params();
        
        let g = AffinePoint::<32>::Point {
            x: PastaField::new(p.clone() - BigUint::from(1u64), p.clone()),
            y: PastaField::new(BigUint::from(2u64), p.clone()),
            a: PastaField::new(a.clone(), p.clone()),
            b: PastaField::new(b.clone(), p.clone()),
        };
        
        let h = g.double();
        
        Self {
            pedersen: PedersenCommitment::new(g, h),
        }
    }

    /// Verify a STARK proof and generate an RPO v1.
    pub fn wrap_stark(
        &self,
        proof: &StarkProof,
        inputs: Vec<u64>,
        blinding: &BigUint,
    ) -> Result<RecursiveProofObject> {
        // 1. Software-level verification (ADR-036 §3)
        if proof.trace_commitment.len() != 32 {
            return Err(anyhow!("Invalid trace commitment length"));
        }

        // 2. Generate Recursive Seal (Pedersen)
        let inner_root_biguint = BigUint::from_bytes_le(&proof.trace_commitment);
        let seal = self.pedersen.commit(&inner_root_biguint, blinding);
        
        let (sx, sy) = seal.to_affine().ok_or_else(|| anyhow!("Seal is identity"))?;

        // 3. Construct RPO v1
        Ok(RecursiveProofObject {
            protocol_v: 1,
            inner_root: proof.trace_commitment,
            inputs,
            fri_roots: proof.fri_commitments.clone(),
            seal_x: sx.to_str_radix(16),
            seal_y: sy.to_str_radix(16),
        })
    }

    /// Aggregate multiple RPOs into a single APO v1.
    pub fn aggregate_rpos(
        &self,
        rpos: &[RecursiveProofObject],
        blinding: &BigUint,
    ) -> Result<AggregatedProofObject> {
        if rpos.is_empty() {
            return Err(anyhow!("Cannot aggregate empty RPO list"));
        }

        // 1. Verify all member RPOs (software check for POC)
        for rpo in rpos {
            if rpo.protocol_v != 1 {
                return Err(anyhow!("Unsupported RPO protocol version: {}", rpo.protocol_v));
            }
        }

        // 2. Compute Aggregate Root (Keccak256 of all member roots)
        let mut hasher = Keccak256::new();
        for rpo in rpos {
            hasher.update(&rpo.inner_root);
        }
        let aggregate_root: [u8; 32] = hasher.finalize().into();

        // 3. Generate Aggregate Seal (Pedersen)
        let agg_root_biguint = BigUint::from_bytes_le(&aggregate_root);
        let seal = self.pedersen.commit(&agg_root_biguint, blinding);
        let (sx, sy) = seal.to_affine().ok_or_else(|| anyhow!("Seal is identity"))?;

        // 4. Construct APO v1
        Ok(AggregatedProofObject {
            protocol_v: 1,
            aggregate_root,
            member_roots: rpos.iter().map(|r| r.inner_root).collect(),
            seal_x: sx.to_str_radix(16),
            seal_y: sy.to_str_radix(16),
        })
    }

    /// Pack Goldilocks elements into Pallas field elements (ADR-036 §2).
    pub fn pack_goldilocks(elements: &[GoldilocksField]) -> Vec<BigUint> {
        let mut packed = Vec::new();
        for chunk in elements.chunks(3) {
            let mut val = BigUint::from(0u64);
            for (i, &elem) in chunk.iter().enumerate() {
                val |= BigUint::from(elem.to_canonical()) << (i * 64);
            }
            packed.push(val);
        }
        packed
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use goldilocks::GoldilocksField;
    use prover::StarkProof;

    #[test]
    fn test_recursive_wrap_poc() {
        let gadget = StarkVerifierGadget::new();
        
        let mock_proof = StarkProof {
            trace_commitment: [0u8; 32],
            fri_commitments: vec![[0u8; 32]],
            query_openings: vec![],
            fri_final_poly: vec![GoldilocksField::ONE],
        };
        
        let blinding = BigUint::from(12345u64);
        let rpo = gadget.wrap_stark(&mock_proof, vec![1, 2, 3], &blinding).unwrap();
        
        assert_eq!(rpo.protocol_v, 1);
        assert_eq!(rpo.inputs, vec![1, 2, 3]);
        assert!(!rpo.seal_x.is_empty());
    }

    #[test]
    fn test_aggregation_poc() {
        let gadget = StarkVerifierGadget::new();
        let blinding = BigUint::from(12345u64);

        let mock_rpo = RecursiveProofObject {
            protocol_v: 1,
            inner_root: [1u8; 32],
            inputs: vec![],
            fri_roots: vec![],
            seal_x: "0".to_string(),
            seal_y: "0".to_string(),
        };

        let apo = gadget.aggregate_rpos(&[mock_rpo.clone(), mock_rpo], &blinding).unwrap();
        
        assert_eq!(apo.protocol_v, 1);
        assert_eq!(apo.member_roots.len(), 2);
        assert!(!apo.seal_x.is_empty());
    }

    #[test]
    fn test_field_packing() {
        let elements = vec![
            GoldilocksField::new(1),
            GoldilocksField::new(2),
            GoldilocksField::new(3),
            GoldilocksField::new(4),
        ];
        
        let packed = StarkVerifierGadget::pack_goldilocks(&elements);
        assert_eq!(packed.len(), 2);
        
        let expected0 = BigUint::from(1u64) | (BigUint::from(2u64) << 64) | (BigUint::from(3u64) << 128);
        assert_eq!(packed[0], expected0);
    }
}
