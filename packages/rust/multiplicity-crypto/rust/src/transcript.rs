/// Keccak256-based Fiat-Shamir transcript
/// 
/// Implements the transcript protocol for generating verifier challenges
/// using Keccak256 as the hash function (single-hash policy).

use sha3::{Digest, Keccak256};

pub struct Keccak256Transcript {
    hasher: Keccak256,
}

impl Keccak256Transcript {
    pub fn new(label: &[u8]) -> Self {
        let mut hasher = Keccak256::new();
        hasher.update(label);
        Self { hasher }
    }

    /// Append a message to the transcript
    pub fn append_message(&mut self, label: &[u8], message: &[u8]) {
        self.hasher.update(label);
        self.hasher.update(&(message.len() as u64).to_le_bytes());
        self.hasher.update(message);
    }

    /// Append a 64-bit field element
    pub fn append_u64(&mut self, label: &[u8], value: u64) {
        self.append_message(label, &value.to_le_bytes());
    }

    /// Append a commitment (Merkle root)
    pub fn append_commitment(&mut self, label: &[u8], commitment: &[u8]) {
        self.append_message(label, commitment);
    }

    /// Generate a challenge by squeezing the transcript
    pub fn challenge(&mut self, label: &[u8]) -> u64 {
        let mut challenge_hasher = self.hasher.clone();
        challenge_hasher.update(label);
        let hash = challenge_hasher.finalize();
        
        // Take first 8 bytes as u64
        u64::from_le_bytes(hash[0..8].try_into().unwrap())
    }

    /// Generate multiple challenges
    pub fn challenge_vec(&mut self, label: &[u8], count: usize) -> Vec<u64> {
        (0..count)
            .map(|i| {
                let mut label_i = label.to_vec();
                label_i.extend_from_slice(&i.to_le_bytes());
                self.challenge(&label_i)
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_transcript_deterministic() {
        let mut t1 = Keccak256Transcript::new(b"test");
        t1.append_u64(b"value", 42);
        let c1 = t1.challenge(b"challenge");

        let mut t2 = Keccak256Transcript::new(b"test");
        t2.append_u64(b"value", 42);
        let c2 = t2.challenge(b"challenge");

        assert_eq!(c1, c2);
    }

    #[test]
    fn test_different_messages_different_challenges() {
        let mut t1 = Keccak256Transcript::new(b"test");
        t1.append_u64(b"value", 42);
        let c1 = t1.challenge(b"challenge");

        let mut t2 = Keccak256Transcript::new(b"test");
        t2.append_u64(b"value", 43);
        let c2 = t2.challenge(b"challenge");

        assert_ne!(c1, c2);
    }
}
