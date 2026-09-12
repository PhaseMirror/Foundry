use apex_goldilocks_core::boundary_lattice::LatticeElement;
use goldilocks::GoldilocksField;
use serde::{Deserialize, Serialize};

/// PhiAddress for O(1) resolution in the hologram compute layer.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PhiAddress(pub u64);

impl PhiAddress {
    pub fn from_lattice(element: LatticeElement) -> Self {
        Self(element.to_index() as u64)
    }
}

/// Sigmatics Circuit Engine element over GoldilocksField.
pub struct HologramCircuit {
    pub cells: Vec<GoldilocksField>,
}

impl HologramCircuit {
    pub fn new(size: usize) -> Self {
        Self {
            cells: vec![GoldilocksField::ZERO; size],
        }
    }

    pub fn resolve(&self, addr: PhiAddress) -> Option<GoldilocksField> {
        self.cells.get(addr.0 as usize).copied()
    }
}

/// Recursive Proof Structure (RPO/APO v1).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecursiveProof {
    pub layer: u32,
    pub root_hash: [u8; 32],
    pub prev_proof: Option<Box<RecursiveProof>>,
}

impl RecursiveProof {
    pub fn new_initial(hash: [u8; 32]) -> Self {
        Self {
            layer: 0,
            root_hash: hash,
            prev_proof: None,
        }
    }

    pub fn recurse(&self, new_hash: [u8; 32]) -> Self {
        Self {
            layer: self.layer + 1,
            root_hash: new_hash,
            prev_proof: Some(Box::new(self.clone())),
        }
    }
}

/// Atlas-Embedding Proof (AEP).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AtlasEmbeddingProof {
    pub proof: RecursiveProof,
    pub domain_tag: u64,
}
