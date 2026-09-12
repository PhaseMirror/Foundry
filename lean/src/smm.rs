use ndarray::{Array1, Array2};

pub struct SparseMemory {
    pub m: Array2<f32>,      // D x K, unit-norm columns
    pub memory: Array1<f32>, // accumulated D-vector
    pub lambda: f32,
    pub tau: f32,
}

impl SparseMemory {
    pub fn read(&self) -> Vec<usize> {
        self.m.t().dot(&self.memory)
            .iter()
            .enumerate()
            .filter(|(_, &v)| v >= self.tau)
            .map(|(i, _)| i)
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::{arr1, arr2};
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_retrieval_bounds_proptest(
            noise in -0.1f32..0.1f32
        ) {
            let smm = SparseMemory {
                m: arr2(&[[1.0, 0.0], [0.0, 1.0]]), // Orthogonal
                memory: arr1(&[1.0 + noise, 0.0]),  // Query matches index 0
                lambda: 0.1,
                tau: 0.5,
            };
            
            let retrieved = smm.read();
            // Assert only the first pattern is retrieved if noise is small
            prop_assert_eq!(retrieved, vec![0]);
        }
    }

    #[cfg(kani)]
    #[kani::proof]
    fn verify_smm_retrieval() {
        let smm = SparseMemory {
            m: arr2(&[[1.0, 0.0], [0.0, 1.0]]),
            memory: arr1(&[kani::any(), kani::any()]),
            lambda: 0.1,
            tau: 0.5,
        };
        
        kani::assume(smm.memory[0] >= 0.0 && smm.memory[0] <= 1.0);
        kani::assume(smm.memory[1] >= 0.0 && smm.memory[1] <= 1.0);
        
        let retrieved = smm.read();
        
        // Assert we never return indices out of bounds (which is 0 or 1 for K=2)
        for &idx in &retrieved {
            assert!(idx < 2);
        }
    }
}
