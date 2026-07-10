use serde::{Deserialize, Serialize};
use crate::resonance::ResonanceWord;
use anyhow::{Result, bail};

/// Represents a STARK proof from an individual party.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PartyProof {
    pub party_id: String,
    pub resonance: ResonanceWord,
    pub stark_proof_bytes: Vec<u8>,
    pub vdf_proof: Option<crate::pell_vdf::PellVDFProof>,
}

/// The aggregated multi-party consensus proof.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AggregateWitness {
    /// The individual party proofs that were recursively verified.
    pub party_proofs: Vec<PartyProof>,
    /// The number of 'approved' votes required.
    pub threshold: u64,
    /// The aggregated master proof (in a real system, the output of a recursive FRI protocol).
    pub master_proof: Option<Vec<u8>>,
}

/// A simplified placeholder statement for the Master STARK.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MasterStatement {
    pub action_hash: [u8; 32],
}

impl AggregateWitness {
    pub fn new(threshold: u64) -> Self {
        Self {
            party_proofs: Vec::new(),
            threshold,
            master_proof: None,
        }
    }

    pub fn add_party(&mut self, proof: PartyProof) {
        self.party_proofs.push(proof);
    }

    /// Aggregates all party proofs into a single master proof.
    /// In the complete implementation, this constructs a log-depth recursion tree
    /// checking each STARK inside the Goldilocks circuit.
    pub fn aggregate(&mut self) -> Result<Vec<u8>> {
        if (self.party_proofs.len() as u64) < self.threshold {
            bail!("Not enough proofs to meet the threshold.");
        }

        // Use the test modulus for now
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
        let n = num_bigint::BigUint::parse_bytes(n_str.as_bytes(), 16).unwrap();
        let vdf = crate::pell_vdf::PellVDF::new(n, 100);

        // Circuit simulation: check each proof and accumulate approvals
        let mut approved_count = 0;
        for party in &self.party_proofs {
            // Check VDF proof to prevent rushing attacks
            if let Some(vdf_proof) = &party.vdf_proof {
                let (_, payload) = party.resonance.unpack();
                let seed = payload.to_le_bytes();
                // Hash party_id string to u64
                use std::hash::{Hash, Hasher};
                let mut hasher = std::collections::hash_map::DefaultHasher::new();
                party.party_id.hash(&mut hasher);
                let pid = hasher.finish();

                if vdf.verify(&seed, pid, vdf_proof).is_err() {
                    bail!("VDF timing verification failed for party: {}", party.party_id);
                }
            } else {
                bail!("Missing VDF proof for party: {}", party.party_id);
            }

            // Unpack resonance: 0b0000001 (class 1) signifies approval
            let (class, _payload) = party.resonance.unpack();
            
            // In a real circuit, we verify party.stark_proof_bytes using hash-based FRI
            if class == 1 {
                approved_count += 1;
            }
        }

        if approved_count < self.threshold {
            bail!("Threshold not met: required {}, got {}", self.threshold, approved_count);
        }

        // Mock master proof generation
        let mock_master_proof = vec![0xCA, 0xFE, 0xBA, 0xBE];
        self.master_proof = Some(mock_master_proof.clone());

        Ok(mock_master_proof)
    }

    /// Verifies the master proof. Since it is recursive, verification cost is O(1)
    /// regardless of the number of parties.
    pub fn verify_master(proof: &[u8], _statement: &MasterStatement) -> bool {
        // In the real system, run the STARK verifier.
        proof == [0xCA, 0xFE, 0xBA, 0xBE]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::resonance::ResonanceWord;

    fn get_test_vdf() -> crate::pell_vdf::PellVDF {
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
        let n = num_bigint::BigUint::parse_bytes(n_str.as_bytes(), 16).unwrap();
        crate::pell_vdf::PellVDF::new(n, 100)
    }

    fn hash_pid(pid: &str) -> u64 {
        use std::hash::{Hash, Hasher};
        let mut hasher = std::collections::hash_map::DefaultHasher::new();
        pid.hash(&mut hasher);
        hasher.finish()
    }

    #[test]
    fn test_aggregate_witness_threshold_met() {
        let mut agg = AggregateWitness::new(2);
        let vdf = get_test_vdf();

        agg.add_party(PartyProof {
            party_id: "NodeA".to_string(),
            resonance: ResonanceWord::pack(1, 12345),
            stark_proof_bytes: vec![0x1, 0x2, 0x3],
            vdf_proof: Some(vdf.evaluate(&12345u64.to_le_bytes(), hash_pid("NodeA")).unwrap()),
        });

        agg.add_party(PartyProof {
            party_id: "NodeB".to_string(),
            resonance: ResonanceWord::pack(1, 67890),
            stark_proof_bytes: vec![0x4, 0x5, 0x6],
            vdf_proof: Some(vdf.evaluate(&67890u64.to_le_bytes(), hash_pid("NodeB")).unwrap()),
        });

        let proof = agg.aggregate().unwrap();
        assert_eq!(proof, vec![0xCA, 0xFE, 0xBA, 0xBE]);
        assert!(AggregateWitness::verify_master(&proof, &MasterStatement { action_hash: [0; 32] }));
    }

    #[test]
    fn test_aggregate_witness_threshold_fails() {
        let mut agg = AggregateWitness::new(2);
        let vdf = get_test_vdf();

        agg.add_party(PartyProof {
            party_id: "NodeA".to_string(),
            resonance: ResonanceWord::pack(1, 12345),
            stark_proof_bytes: vec![0x1, 0x2, 0x3],
            vdf_proof: Some(vdf.evaluate(&12345u64.to_le_bytes(), hash_pid("NodeA")).unwrap()),
        });

        agg.add_party(PartyProof {
            party_id: "NodeB".to_string(),
            resonance: ResonanceWord::pack(2, 67890),
            stark_proof_bytes: vec![0x4, 0x5, 0x6],
            vdf_proof: Some(vdf.evaluate(&67890u64.to_le_bytes(), hash_pid("NodeB")).unwrap()),
        });

        let res = agg.aggregate();
        assert!(res.is_err());
        assert_eq!(res.unwrap_err().to_string(), "Threshold not met: required 2, got 1");
    }
}
