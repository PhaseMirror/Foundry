use crate::utils::keccak::{viem_to_hex_bigint, viem_to_hex_str, viem_keccak256};

pub struct MerkleAccumulator;

impl MerkleAccumulator {
    pub fn build_root(leaves: &[String]) -> String {
        build_root(leaves)
    }
}

/// Rebuilds the tree from a list of leaves (Accumulator style).
pub fn build_root(leaves: &[String]) -> String {
    if leaves.is_empty() {
        return viem_keccak256(&viem_to_hex_bigint(0));
    }

    let mut current_level = leaves.to_vec();
    current_level.sort();

    while current_level.len() > 1 {
        let mut next_level = Vec::new();
        let len = current_level.len();
        for i in (0..len).step_by(2) {
            let left = &current_level[i];
            let right = if i + 1 < len { &current_level[i + 1] } else { left };

            // Concatenate and hash. Strip "0x" prefix from the second operand.
            let clean_right = right.strip_prefix("0x").unwrap_or(right);
            let concat = format!("{}{}", left, clean_right);
            let hash = viem_keccak256(&viem_to_hex_str(&concat));
            next_level.push(hash);
        }
        current_level = next_level;
    }

    current_level[0].clone()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_merkle_accumulator_empty() {
        let root = build_root(&[]);
        assert_eq!(root, viem_keccak256(&viem_to_hex_bigint(0)));
    }

    #[test]
    fn test_merkle_accumulator_single() {
        let leaves = vec!["0x1234".to_string()];
        let root = build_root(&leaves);
        assert_eq!(root, "0x1234");
    }

    #[test]
    fn test_merkle_accumulator_multiple() {
        let leaves = vec!["0x1234".to_string(), "0x5678".to_string()];
        let root = build_root(&leaves);
        
        // Sorting means "0x1234" is left, "0x5678" is right (stripped to "5678")
        // concat = "0x12345678"
        let expected = viem_keccak256(&viem_to_hex_str("0x12345678"));
        assert_eq!(root, expected);
    }
}
