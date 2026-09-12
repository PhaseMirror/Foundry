//! # Apex Goldilocks Core
//! Foundation for prime-indexed arithmetic in the new stack.

pub mod boundary_lattice;
pub mod vector8;

pub use vector8::Vector8;
use goldilocks::{GoldilocksField, ResonanceWord};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct GoldVector {
    pub elements: Vec<GoldilocksField>,
}

impl GoldVector {
    pub fn new(elements: Vec<GoldilocksField>) -> Self {
        Self { elements }
    }

    pub fn dimension(&self) -> usize {
        self.elements.len()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Resonance(pub ResonanceWord);

impl Resonance {
    pub fn new(class: u8, payload: u64) -> Self {
        Self(ResonanceWord::pack(class, payload))
    }

    pub fn unpack(&self) -> (u8, u64) {
        self.0.unpack()
    }
}

pub fn validate_field_arithmetic(a: GoldilocksField, b: GoldilocksField) -> GoldilocksField {
    a.add(&b)
}
