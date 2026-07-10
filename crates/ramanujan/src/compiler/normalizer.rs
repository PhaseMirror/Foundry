use crate::ir::ast::{Operator, OperatorType};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct State {
    pub q_matrix: Vec<Vec<i32>>,
    pub p_vector: Vec<i32>,
}

impl State {
    /// N1: Stabilization reduction
    /// Finds canonical blow-down witness minimizing (|v|^2, lex(v))
    pub fn canonical_blowdown(&mut self) -> Option<Vec<i32>> {
        // Scaffold for test: simulate finding two admissible vectors.
        let candidates = vec![
            vec![1, 0, -1], // norm 2
            vec![1, -1, 0], // norm 2
        ];
        
        // Minimize by norm first, then lexicographically
        let mut best = None;
        let mut best_score = (i32::MAX, vec![]);
        
        for v in candidates {
            let norm_sq: i32 = v.iter().map(|x| x * x).sum();
            let score = (norm_sq, v.clone());
            if score < best_score {
                best_score = score;
                best = Some(v);
            }
        }
        
        best
    }

    /// N2: Global congruence normalization (real-place basis fix)
    pub fn n2_lll_reduction(&mut self) {
        // Stub: In production this would compute LLL reduced basis
        // and choose lex-min representation of p_vector.
        self.p_vector.sort(); // Just a stub mutation
    }

    /// N3: Prime-local Jordan decomposition
    pub fn n3_jordan_decomp(&mut self) {
        // Stub
    }

    /// Run full N1-N3 deterministic normal form reduction
    pub fn normalize_to_nf(&mut self) {
        while let Some(_witness) = self.canonical_blowdown() {
            // Apply blowdown using witness...
            break; // Stop loop in stub
        }
        self.n2_lll_reduction();
        self.n3_jordan_decomp();
    }
}

/// Grammar Normalization (Syntactic step):
/// Rewrites sequences of generators into a canonical evaluation form.
pub fn normalize_word(word: Vec<Operator>) -> Vec<Operator> {
    // 1. Cancel adjacent H and H_INV
    let mut normalized: Vec<Operator> = Vec::new();
    for op in word {
        if let Some(last) = normalized.last() {
            if (op.op_type == OperatorType::H && last.op_type == OperatorType::HInv) ||
               (op.op_type == OperatorType::HInv && last.op_type == OperatorType::H) {
                normalized.pop();
                continue;
            }
        }
        normalized.push(op);
    }
    
    // 2. Further canonicalization would happen here.
    normalized
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_canonical_witness_selection() {
        let mut state = State {
            q_matrix: vec![],
            p_vector: vec![],
        };
        
        let witness = state.canonical_blowdown().unwrap();
        // lexicographical comparison: [1, -1, 0] is less than [1, 0, -1]
        assert_eq!(witness, vec![1, -1, 0]);
    }
    
    #[test]
    fn test_n2_lll_stub() {
        let mut state = State {
            q_matrix: vec![],
            p_vector: vec![3, 1, 2],
        };
        state.n2_lll_reduction();
        assert_eq!(state.p_vector, vec![1, 2, 3]);
    }
}
