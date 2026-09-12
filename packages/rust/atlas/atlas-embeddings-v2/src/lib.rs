use apex_goldilocks_core::Vector8;
use goldilocks::GoldilocksField;
use std::collections::HashMap;

/// E₈ Root System implementation using GoldilocksField (integer-only)
pub struct E8RootSystem {
    roots: Vec<Vector8>,
    root_index: HashMap<Vector8, usize>,
    negation_table: Vec<usize>,
}

impl E8RootSystem {
    pub fn new() -> Self {
        let roots = Self::generate_all_roots();
        let mut root_index = HashMap::new();
        for (i, root) in roots.iter().enumerate() {
            root_index.insert(*root, i);
        }

        let mut negation_table = vec![0; roots.len()];
        for (i, root) in roots.iter().enumerate() {
            let neg_root = -(*root);
            if let Some(&neg_idx) = root_index.get(&neg_root) {
                negation_table[i] = neg_idx;
            } else {
                panic!("Negation of root not found in E8 system");
            }
        }

        Self {
            roots,
            root_index,
            negation_table,
        }
    }

    pub fn num_roots(&self) -> usize {
        240
    }

    pub fn roots(&self) -> &[Vector8] {
        &self.roots
    }

    pub fn get_root(&self, index: usize) -> &Vector8 {
        &self.roots[index]
    }

    pub fn get_negation(&self, index: usize) -> usize {
        self.negation_table[index]
    }

    pub fn find_root(&self, root: &Vector8) -> Option<usize> {
        self.root_index.get(root).copied()
    }

    pub fn inner_product(&self, i: usize, j: usize) -> GoldilocksField {
        let r1 = &self.roots[i];
        let r2 = &self.roots[j];
        let mut sum = GoldilocksField::ZERO;
        for k in 0..8 {
            let term = r1.coords[k].mul(&r2.coords[k]);
            sum = sum.add(&term);
        }
        sum
    }

    fn generate_all_roots() -> Vec<Vector8> {
        let mut roots = Vec::with_capacity(240);
        roots.extend(Self::generate_integer_roots());
        roots.extend(Self::generate_half_integer_roots());
        assert_eq!(roots.len(), 240);
        roots
    }

    fn generate_integer_roots() -> Vec<Vector8> {
        let mut roots = Vec::with_capacity(112);
        let one = GoldilocksField::ONE;
        let neg_one = GoldilocksField::ONE.neg();

        for i in 0..8 {
            for j in (i + 1)..8 {
                for &val_i in &[one, neg_one] {
                    for &val_j in &[one, neg_one] {
                        let mut coords = [GoldilocksField::ZERO; 8];
                        coords[i] = val_i;
                        coords[j] = val_j;
                        roots.push(Vector8::new(coords));
                    }
                }
            }
        }
        assert_eq!(roots.len(), 112);
        roots
    }

    fn generate_half_integer_roots() -> Vec<Vector8> {
        let mut roots = Vec::with_capacity(128);
        let half = GoldilocksField::new(2).inverse().unwrap();
        let neg_half = half.neg();

        for pattern in 0..256_u16 {
            let mut coords = [half; 8];
            let mut num_negatives = 0;

            for i in 0..8 {
                if (pattern >> i) & 1 == 1 {
                    coords[i] = neg_half;
                    num_negatives += 1;
                }
            }

            if num_negatives % 2 == 0 {
                roots.push(Vector8::new(coords));
            }
        }
        assert_eq!(roots.len(), 128);
        roots
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_e8_root_system_properties() {
        let system = E8RootSystem::new();
        assert_eq!(system.num_roots(), 240);

        // Check that all roots have norm-squared = 2 in GoldilocksField
        let two = GoldilocksField::new(2);
        for i in 0..240 {
            let norm_sq = system.inner_product(i, i);
            assert_eq!(norm_sq, two);
        }

        // Check that negation table is self-inverse and holds no self-negations
        for i in 0..240 {
            let neg_idx = system.get_negation(i);
            assert_ne!(i, neg_idx);
            assert_eq!(system.get_negation(neg_idx), i);
        }
    }
}
