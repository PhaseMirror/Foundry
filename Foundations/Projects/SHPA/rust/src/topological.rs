//! Topological Signatures for Fractal Trees (Non-Commutative)

use crate::bcs::BcsSerializer;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum FractalTree {
    Leaf {
        operator_hash: [u8; 32],
    },
    Node {
        operator_hash: [u8; 32],
        children: Vec<FractalTree>,
    },
}

pub struct TopologicalEngine;

impl TopologicalEngine {
    /// BCS encode a topological node: operator_hash || uleb128(len(children)) || child_sig_1 || ...
    pub fn bcs_encode_node(op_hash: &[u8; 32], child_sigs: &[[u8; 32]]) -> Vec<u8> {
        let mut buf = Vec::with_capacity(32 + 4 + child_sigs.len() * 32);
        buf.extend_from_slice(op_hash);
        let len_bytes = BcsSerializer::uleb128_encode(child_sigs.len());
        buf.extend_from_slice(&len_bytes);
        for sig in child_sigs {
            buf.extend_from_slice(sig);
        }
        buf
    }

    /// Compute recursive topological signature of a fractal tree node.
    pub fn compute_signature(tree: &FractalTree) -> [u8; 32] {
        match tree {
            FractalTree::Leaf { operator_hash } => {
                let encoded = Self::bcs_encode_node(operator_hash, &[]);
                let mut hasher = Sha256::new();
                hasher.update(&encoded);
                hasher.finalize().into()
            }
            FractalTree::Node {
                operator_hash,
                children,
            } => {
                let child_sigs: Vec<[u8; 32]> =
                    children.iter().map(Self::compute_signature).collect();
                let encoded = Self::bcs_encode_node(operator_hash, &child_sigs);
                let mut hasher = Sha256::new();
                hasher.update(&encoded);
                hasher.finalize().into()
            }
        }
    }
}
