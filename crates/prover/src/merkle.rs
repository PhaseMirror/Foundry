/// Optimized Merkle tree implementation with parallel Keccak256
/// 
/// Binary Merkle tree using a flat buffer for better cache locality.

use sha3::{Digest, Keccak256};
#[cfg(feature = "parallel")]
use rayon::prelude::*;

pub struct MerkleTree {
    /// Flat buffer containing all nodes [leaves..., layer1..., ..., root]
    pub nodes: Vec<[u8; 32]>,
    
    /// Number of leaves
    pub leaf_count: usize,
}

impl MerkleTree {
    /// Build a Merkle tree from leaf data
    pub fn new(leaf_data: Vec<Vec<u8>>) -> Self {
        let leaf_count = leaf_data.len();
        assert!(leaf_count.is_power_of_two(), "Currently requires power-of-2 leaves");
        
        let node_count = 2 * leaf_count - 1;
        let mut nodes = vec![[0u8; 32]; node_count];
        
        // 1. Hash all leaves
        #[cfg(feature = "parallel")]
        nodes[..leaf_count].par_iter_mut().enumerate().for_each(|(i, node)| {
            *node = Keccak256::digest(&leaf_data[i]).into();
        });
        #[cfg(not(feature = "parallel"))]
        nodes[..leaf_count].iter_mut().enumerate().for_each(|(i, node)| {
            *node = Keccak256::digest(&leaf_data[i]).into();
        });
        
        // 2. Build tree bottom-up
        let mut layer_start = 0;
        let mut layer_len = leaf_count;
        
        while layer_len > 1 {
            let next_layer_start = layer_start + layer_len;
            let next_layer_len = layer_len / 2;
            
            let (prev_layer, next_layer) = nodes.split_at_mut(next_layer_start);
            let prev_layer = &prev_layer[layer_start..];
            let next_layer = &mut next_layer[..next_layer_len];
            
            #[cfg(feature = "parallel")]
            next_layer.par_iter_mut().enumerate().for_each(|(i, parent)| {
                let left = &prev_layer[2 * i];
                let right = &prev_layer[2 * i + 1];
                *parent = hash_pair(left, right);
            });
            #[cfg(not(feature = "parallel"))]
            next_layer.iter_mut().enumerate().for_each(|(i, parent)| {
                let left = &prev_layer[2 * i];
                let right = &prev_layer[2 * i + 1];
                *parent = hash_pair(left, right);
            });
            
            layer_start = next_layer_start;
            layer_len = next_layer_len;
        }
        
        Self {
            nodes,
            leaf_count,
        }
    }

    /// Get root hash
    pub fn root(&self) -> [u8; 32] {
        *self.nodes.last().expect("Tree must have nodes")
    }

    /// Generate authentication path for a leaf
    pub fn prove(&self, index: usize) -> Vec<[u8; 32]> {
        let mut path = Vec::new();
        let mut layer_start = 0;
        let mut layer_len = self.leaf_count;
        let mut idx = index;
        
        while layer_len > 1 {
            let sibling_idx = idx ^ 1;
            path.push(self.nodes[layer_start + sibling_idx]);
            
            layer_start += layer_len;
            layer_len /= 2;
            idx /= 2;
        }
        
        path
    }

    /// Verify an authentication path
    pub fn verify(root: &[u8; 32], leaf_hash: &[u8; 32], index: usize, path: &[[u8; 32]]) -> bool {
        let mut current = *leaf_hash;
        let mut idx = index;
        
        for sibling in path {
            current = if idx % 2 == 0 {
                hash_pair(&current, sibling)
            } else {
                hash_pair(sibling, &current)
            };
            idx /= 2;
        }
        
        &current == root
    }
}

#[inline(always)]
fn hash_pair(left: &[u8; 32], right: &[u8; 32]) -> [u8; 32] {
    let mut hasher = Keccak256::new();
    hasher.update(left);
    hasher.update(right);
    hasher.finalize().into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_merkle_tree() {
        let leaves = vec![
            b"leaf0".to_vec(),
            b"leaf1".to_vec(),
            b"leaf2".to_vec(),
            b"leaf3".to_vec(),
        ];
        
        let tree = MerkleTree::new(leaves.clone());
        let root = tree.root();
        
        for (i, leaf) in leaves.iter().enumerate() {
            let leaf_hash: [u8; 32] = Keccak256::digest(leaf).into();
            let path = tree.prove(i);
            assert!(MerkleTree::verify(&root, &leaf_hash, i, &path));
        }
    }
}
