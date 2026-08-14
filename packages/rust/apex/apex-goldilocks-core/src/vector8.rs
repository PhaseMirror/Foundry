use goldilocks::GoldilocksField;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Vector8 {
    pub coords: [GoldilocksField; 8],
}

impl Vector8 {
    pub fn new(coords: [GoldilocksField; 8]) -> Self {
        Self { coords }
    }
}

impl std::hash::Hash for Vector8 {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        for coord in &self.coords {
            coord.to_canonical().hash(state);
        }
    }
}

impl std::ops::Add for Vector8 {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        let mut coords = [GoldilocksField::ZERO; 8];
        for i in 0..8 {
            coords[i] = self.coords[i].add(&rhs.coords[i]);
        }
        Self::new(coords)
    }
}

impl std::ops::Sub for Vector8 {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        let mut coords = [GoldilocksField::ZERO; 8];
        for i in 0..8 {
            coords[i] = self.coords[i].sub(&rhs.coords[i]);
        }
        Self::new(coords)
    }
}

impl std::ops::Neg for Vector8 {
    type Output = Self;
    fn neg(self) -> Self {
        let mut coords = [GoldilocksField::ZERO; 8];
        for i in 0..8 {
            coords[i] = self.coords[i].neg();
        }
        Self::new(coords)
    }
}
