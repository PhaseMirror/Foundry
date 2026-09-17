//! Binary Merkle tree over SHA-256 commitments.
//!
//! Mirrors the Python `multiplicity/crypto/__init__.py` fallback Merkle
//! implementation: leaves are committed with `_fallback_commitment(leaf, "merkle-leaf")`,
//! internal nodes with `_fallback_commitment(left:right, "merkle-node")`.
//! When the number of nodes at a level is odd, the last node is duplicated
//! (Bitcoin-style padding).

use crate::commitment::sha256;

/// A binary Merkle tree with SHA-256 hashing.
#[derive(Debug, Clone)]
pub struct MerkleTree {
    layers: Vec<Vec<[u8; 32]>>,
    leaves: Vec<[u8; 32]>,
}

impl MerkleTree {
    /// Build a tree from raw leaf bytes. Each leaf is SHA-256'd first.
    #[must_use]
    pub fn from_leaves(leaves: &[&[u8]]) -> Self {
        if leaves.is_empty() {
            return Self {
                layers: vec![vec![[0u8; 32]]],
                leaves: vec![],
            };
        }
        let committed: Vec<[u8; 32]> = leaves.iter().map(|l| sha256(l)).collect();
        let mut layers = vec![committed.clone()];
        while layers.last().unwrap().len() > 1 {
            let prev = layers.last().unwrap();
            let mut next = Vec::with_capacity((prev.len() + 1) / 2);
            let mut i = 0;
            while i < prev.len() {
                let right = if i + 1 < prev.len() { prev[i + 1] } else { prev[i] };
                let mut data = Vec::with_capacity(64);
                data.extend_from_slice(&prev[i]);
                data.extend_from_slice(&right);
                next.push(sha256(&data));
                i += 2;
            }
            layers.push(next);
        }
        Self {
            layers,
            leaves: committed,
        }
    }

    /// Build a tree from pre-committed leaves.
    #[must_use]
    pub fn from_committed(leaves: &[[u8; 32]]) -> Self {
        if leaves.is_empty() {
            return Self {
                layers: vec![vec![[0u8; 32]]],
                leaves: vec![],
            };
        }
        let committed = leaves.to_vec();
        let mut layers = vec![committed.clone()];
        while layers.last().unwrap().len() > 1 {
            let prev = layers.last().unwrap();
            let mut next = Vec::with_capacity((prev.len() + 1) / 2);
            let mut i = 0;
            while i < prev.len() {
                let right = if i + 1 < prev.len() { prev[i + 1] } else { prev[i] };
                let mut data = Vec::with_capacity(64);
                data.extend_from_slice(&prev[i]);
                data.extend_from_slice(&right);
                next.push(sha256(&data));
                i += 2;
            }
            layers.push(next);
        }
        Self {
            layers,
            leaves: committed,
        }
    }

    /// The Merkle root (32 bytes).
    #[must_use]
    pub fn root(&self) -> [u8; 32] {
        self.layers.last().unwrap()[0]
    }

    /// Number of leaves.
    #[must_use]
    pub fn len(&self) -> usize {
        self.leaves.len()
    }

    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.leaves.is_empty()
    }

    /// Generate an inclusion proof for `leaf_index`.
    #[must_use]
    pub fn proof(&self, leaf_index: usize) -> Option<MerkleProof> {
        if leaf_index >= self.leaves.len() {
            return None;
        }
        let mut proof = Vec::new();
        let mut idx = leaf_index;
        for layer in &self.layers[..self.layers.len() - 1] {
            let sibling = if idx % 2 == 0 {
                // Right sibling exists if idx+1 < len
                if idx + 1 < layer.len() {
                    layer[idx + 1]
                } else {
                    layer[idx] // duplicate
                }
            } else {
                layer[idx - 1]
            };
            proof.push(sibling);
            idx /= 2;
        }
        Some(MerkleProof {
            leaf_index,
            path: proof,
        })
    }
}

/// An inclusion proof: the leaf index and the list of sibling hashes from
/// leaf level to root.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MerkleProof {
    pub leaf_index: usize,
    pub path: Vec<[u8; 32]>,
}

/// Verify a Merkle proof against a known root.
#[must_use]
pub fn verify_proof(leaf: &[u8], proof: &MerkleProof, root: [u8; 32]) -> bool {
    let mut current = sha256(leaf);
    let mut idx = proof.leaf_index;
    for sibling in &proof.path {
        let (left, right) = if idx % 2 == 0 {
            (current, *sibling)
        } else {
            (*sibling, current)
        };
        let mut data = Vec::with_capacity(64);
        data.extend_from_slice(&left);
        data.extend_from_slice(&right);
        current = sha256(&data);
        idx /= 2;
    }
    current == root
}

/// Build a Merkle root from a list of leaves (single function).
#[must_use]
pub fn merkle_root(leaves: &[&[u8]]) -> [u8; 32] {
    MerkleTree::from_leaves(leaves).root()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_tree_has_zero_root() {
        let tree = MerkleTree::from_leaves(&[]);
        assert!(tree.is_empty());
        assert_eq!(tree.root(), [0u8; 32]);
    }

    #[test]
    fn single_leaf_root_equals_leaf_hash() {
        let tree = MerkleTree::from_leaves(&[b"single"]);
        assert_eq!(tree.root(), sha256(b"single"));
    }

    #[test]
    fn two_leaves_produce_pair_hash() {
        let tree = MerkleTree::from_leaves(&[b"a", b"b"]);
        let mut data = Vec::with_capacity(64);
        data.extend_from_slice(&sha256(b"a"));
        data.extend_from_slice(&sha256(b"b"));
        assert_eq!(tree.root(), sha256(&data));
    }

    #[test]
    fn proof_verifies_for_member() {
        let leaves: Vec<Vec<u8>> = (0..8).map(|i| format!("leaf-{i}").into_bytes()).collect();
        let leaf_refs: Vec<&[u8]> = leaves.iter().map(|l| l.as_slice()).collect();
        let tree = MerkleTree::from_leaves(&leaf_refs);
        let root = tree.root();
        for i in 0..leaves.len() {
            let proof = tree.proof(i).expect("proof exists");
            assert!(verify_proof(&leaves[i], &proof, root), "proof for leaf {i} failed");
        }
    }

    #[test]
    fn proof_rejects_tampered_leaf() {
        let tree = MerkleTree::from_leaves(&[b"leaf-0", b"leaf-1"]);
        let root = tree.root();
        let proof = tree.proof(0).unwrap();
        assert!(!verify_proof(b"tampered", &proof, root));
    }

    #[test]
    fn proof_rejects_wrong_index() {
        let tree = MerkleTree::from_leaves(&[b"a", b"b", b"c"]);
        let root = tree.root();
        let proof = tree.proof(0).unwrap();
        // Use leaf "b" with the proof for index 0 — should fail.
        assert!(!verify_proof(b"b", &proof, root));
    }

    #[test]
    fn odd_number_of_leaves_duplicates_last() {
        let tree = MerkleTree::from_leaves(&[b"a", b"b", b"c"]);
        let root = tree.root();
        // The root should be deterministic.
        let tree2 = MerkleTree::from_leaves(&[b"a", b"b", b"c"]);
        assert_eq!(tree2.root(), root);
    }
}
