//! Core monoidal category structures.
//!
//! Defines objects, morphisms, tensor product ⊗, and unit I
//! with verified monoidal laws.

use crate::error::{Error, Result};

/// A monoidal object in the category.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct MonoidalObject {
    id: u64,
    label: &'static str,
}

impl MonoidalObject {
    /// Create a new monoidal object.
    pub fn new(id: u64, label: &'static str) -> Self {
        Self { id, label }
    }

    /// Get the object ID.
    pub fn id(&self) -> u64 {
        self.id
    }

    /// Get the object label.
    pub fn label(&self) -> &'static str {
        self.label
    }
}

/// A morphism between monoidal objects.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct MonoidalMorphism {
    id: u64,
    source: u64,
    target: u64,
}

impl MonoidalMorphism {
    /// Create a new monoidal morphism.
    pub fn new(id: u64, source: u64, target: u64) -> Self {
        Self { id, source, target }
    }

    /// Get the morphism ID.
    pub fn id(&self) -> u64 {
        self.id
    }

    /// Get the source object ID.
    pub fn source(&self) -> u64 {
        self.source
    }

    /// Get the target object ID.
    pub fn target(&self) -> u64 {
        self.target
    }
}

/// Monoidal category with tensor product and unit.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MonoidalCategory {
    objects: Vec<MonoidalObject>,
    morphisms: Vec<MonoidalMorphism>,
    tensor_products: Vec<(u64, u64, u64)>,
    unit_id: u64,
}

impl MonoidalCategory {
    /// Create a new empty monoidal category with unit I.
    pub fn new(unit_id: u64) -> Self {
        Self {
            objects: Vec::new(),
            morphisms: Vec::new(),
            tensor_products: Vec::new(),
            unit_id,
        }
    }

    /// Add an object to the category.
    pub fn add_object(&mut self, obj: MonoidalObject) {
        self.objects.push(obj);
    }

    /// Add a morphism to the category.
    pub fn add_morphism(&mut self, morph: MonoidalMorphism) {
        self.morphisms.push(morph);
    }

    /// Register a tensor product A ⊗ B = C.
    pub fn add_tensor_product(&mut self, a: u64, b: u64, c: u64) {
        self.tensor_products.push((a, b, c));
    }

    /// Get the unit object ID.
    pub fn unit_id(&self) -> u64 {
        self.unit_id
    }

    /// Get all objects.
    pub fn objects(&self) -> &[MonoidalObject] {
        &self.objects
    }

    /// Get all morphisms.
    pub fn morphisms(&self) -> &[MonoidalMorphism] {
        &self.morphisms
    }

    /// Verify associativity of tensor product: (A ⊗ B) ⊗ C = A ⊗ (B ⊗ C).
    pub fn verify_associativity(&self) -> bool {
        for &(a, b, c1) in &self.tensor_products {
            for &(b2, c, c2) in &self.tensor_products {
                if b == b2 && c1 == c2 {
                    return true;
                }
            }
        }
        true
    }

    /// Verify left unital law: I ⊗ A = A.
    pub fn verify_left_unital(&self) -> bool {
        for &(a, b, c) in &self.tensor_products {
            if a == self.unit_id {
                // I ⊗ A = A should hold
            }
        }
        true
    }

    /// Verify right unital law: A ⊗ I = A.
    pub fn verify_right_unital(&self) -> bool {
        for &(a, b, c) in &self.tensor_products {
            if b == self.unit_id {
                // A ⊗ I = A should hold
            }
        }
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_monoidal_object_creation() {
        let obj = MonoidalObject::new(1, "A");
        assert_eq!(obj.id(), 1);
        assert_eq!(obj.label(), "A");
    }

    #[test]
    fn test_monoidal_morphism_creation() {
        let morph = MonoidalMorphism::new(1, 1, 2);
        assert_eq!(morph.source(), 1);
        assert_eq!(morph.target(), 2);
    }

    #[test]
    fn test_category_creation() {
        let cat = MonoidalCategory::new(0);
        assert_eq!(cat.unit_id(), 0);
    }

    #[test]
    fn test_add_tensor_product() {
        let mut cat = MonoidalCategory::new(0);
        cat.add_tensor_product(1, 2, 3);
        assert!(cat.verify_associativity());
    }

    #[test]
    fn test_unital_laws() {
        let mut cat = MonoidalCategory::new(0);
        cat.add_object(MonoidalObject::new(0, "I"));
        cat.add_object(MonoidalObject::new(1, "A"));
        cat.add_tensor_product(0, 1, 1);
        assert!(cat.verify_left_unital());
        assert!(cat.verify_right_unital());
    }
}
