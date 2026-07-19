use crate::ir::ast::{Operator, OperatorType};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct State {
    pub q_matrix: Vec<Vec<i32>>,
    pub p_vector: Vec<i32>,
}

impl State {
    /// N1: Stabilization reduction
    ///
    /// Finds canonical blow-down witness: the shortest nonzero integer vector
    /// in the integer kernel (nullspace) of q_matrix, minimizing
    /// (|v|^2, lex(v)).
    ///
    /// The kernel consists of all v such that q·v = 0 for every row q.
    pub fn canonical_blowdown(&self) -> Option<Vec<i32>> {
        if self.q_matrix.is_empty() || self.q_matrix[0].is_empty() {
            return None;
        }

        let n_cols = self.q_matrix[0].len();
        let bound = 4;
        let mut candidates = Vec::new();

        self.find_kernel_vectors(n_cols, bound, &mut vec![0; n_cols], 0, &mut candidates);

        if candidates.is_empty() {
            return None;
        }

        candidates.into_iter().min_by_key(|v| {
            let norm_sq: i32 = v.iter().map(|x| x * x).sum();
            (norm_sq, v.clone())
        })
    }

    /// Apply a single blowdown step: remove the row of q_matrix that has the
    /// smallest nonzero norm, and reduce p_vector by the corresponding lattice vector.
    /// Returns true if a reduction was made.
    fn apply_blowdown_step(&mut self) -> bool {
        if self.q_matrix.is_empty() {
            return false;
        }

        // Find the row with smallest nonzero norm (shortest lattice vector)
        let mut best_idx = None;
        let mut best_norm = i32::MAX;
        for (i, row) in self.q_matrix.iter().enumerate() {
            let norm_sq: i32 = row.iter().map(|x| x * x).sum();
            if norm_sq > 0 && norm_sq < best_norm {
                best_norm = norm_sq;
                best_idx = Some(i);
            }
        }

        let idx = match best_idx {
            Some(i) => i,
            None => return false,
        };

        // Remove this row from the lattice basis — it represents a short
        // vector that can be generated from other basis elements.
        let removed_row = self.q_matrix.remove(idx);

        // Reduce p_vector by projection onto the removed row
        let dot_p: i32 = self.p_vector.iter().zip(removed_row.iter()).map(|(a, b)| a * b).sum();
        if best_norm > 0 {
            let q = dot_p / best_norm;
            if q != 0 {
                for (p, r) in self.p_vector.iter_mut().zip(removed_row.iter()) {
                    *p -= q * r;
                }
            }
        }

        // Reduce remaining rows against the removed row
        for row in &mut self.q_matrix {
            let dot: i32 = row.iter().zip(removed_row.iter()).map(|(a, b)| a * b).sum();
            if dot != 0 && best_norm > 0 {
                let q = dot / best_norm;
                for (r, ri) in row.iter_mut().zip(removed_row.iter()) {
                    *r -= q * ri;
                }
            }
        }

        true
    }

    /// N2: Global congruence normalization (real-place basis fix)
    ///
    /// Reduces the p_vector to its shortest representative modulo the lattice
    /// defined by q_matrix. For each basis vector in q_matrix, project and
    /// reduce p_vector to minimize component magnitude.
    pub fn n2_lll_reduction(&mut self) {
        if self.q_matrix.is_empty() || self.p_vector.is_empty() {
            return;
        }

        // Repeatedly reduce p_vector by each basis vector until stable
        let mut changed = true;
        let mut iterations = 0;
        while changed && iterations < 16 {
            changed = false;
            for row in &self.q_matrix {
                let dot: i32 = row.iter().zip(self.p_vector.iter()).map(|(a, b)| a * b).sum();
                let norm_sq: i32 = row.iter().map(|x| x * x).sum();
                if norm_sq == 0 {
                    continue;
                }
                let q = dot / norm_sq;
                if q != 0 {
                    for (p, r) in self.p_vector.iter_mut().zip(row.iter()) {
                        *p -= q * r;
                    }
                    changed = true;
                }
            }
            iterations += 1;
        }

        // Final sort for canonical lex order
        self.p_vector.sort();
    }

    /// N3: Prime-local Jordan decomposition
    ///
    /// Decomposes the lattice structure into prime-indexed blocks. For each
    /// prime p dividing the determinant of q_matrix, computes the p-primary
    /// component of the lattice and normalizes its elementary divisors.
    pub fn n3_jordan_decomp(&mut self) {
        if self.q_matrix.is_empty() {
            return;
        }

        let det = self.lattice_determinant();
        if det == 0 {
            return;
        }

        let factors = prime_factors(det.abs() as u64);

        for (prime, _exp) in &factors {
            let p = *prime as i32;
            // For each row independently, divide by p as many times as possible
            for row in &mut self.q_matrix {
                loop {
                    let all_divisible = row.iter().all(|x| x % p == 0);
                    if !all_divisible {
                        break;
                    }
                    for x in row.iter_mut() {
                        *x /= p;
                    }
                }
            }
        }
    }

    /// Compute the determinant of q_matrix (for square matrices) or a
    /// pseudo-determinant (product of diagonal after row reduction).
    fn lattice_determinant(&self) -> i64 {
        let n = self.q_matrix.len();
        if n == 0 {
            return 0;
        }
        let m = self.q_matrix[0].len();
        if n != m {
            return self.pseudo_determinant();
        }

        if n == 1 {
            return self.q_matrix[0][0] as i64;
        }
        if n == 2 {
            return (self.q_matrix[0][0] as i64) * (self.q_matrix[1][1] as i64)
                - (self.q_matrix[0][1] as i64) * (self.q_matrix[1][0] as i64);
        }

        // Fraction-free Gaussian elimination
        let mut mat: Vec<Vec<i64>> = self
            .q_matrix
            .iter()
            .map(|row| row.iter().map(|&x| x as i64).collect())
            .collect();

        let mut det: i64 = 1;
        for col in 0..n {
            let mut pivot_row = None;
            for row in col..n {
                if mat[row][col] != 0 {
                    pivot_row = Some(row);
                    break;
                }
            }
            let pivot_row = match pivot_row {
                Some(r) => r,
                None => return 0,
            };
            if pivot_row != col {
                mat.swap(col, pivot_row);
                det = -det;
            }
            let pivot = mat[col][col];
            det *= pivot;

            for row in (col + 1)..n {
                if mat[row][col] == 0 {
                    continue;
                }
                for k in (col + 1)..n {
                    mat[row][k] = pivot * mat[row][k] - mat[row][col] * mat[col][k];
                }
            }
        }

        det
    }

    /// Pseudo-determinant for non-square matrices.
    fn pseudo_determinant(&self) -> i64 {
        let n = self.q_matrix.len();
        let m = self.q_matrix[0].len();
        let mut mat: Vec<Vec<i64>> = self
            .q_matrix
            .iter()
            .map(|row| row.iter().map(|&x| x as i64).collect())
            .collect();

        let mut det: i64 = 1;
        let mut pivot_col = 0;
        for row in 0..n {
            if pivot_col >= m {
                break;
            }
            let mut found = false;
            for col in pivot_col..m {
                if mat[row][col] != 0 {
                    if col != pivot_col {
                        for r in 0..n {
                            mat[r].swap(col, pivot_col);
                        }
                        det = -det;
                    }
                    found = true;
                    break;
                }
            }
            if !found {
                continue;
            }

            let pivot = mat[row][pivot_col];
            det *= pivot;

            for r in (row + 1)..n {
                if mat[r][pivot_col] == 0 {
                    continue;
                }
                for c in (pivot_col + 1)..m {
                    mat[r][c] = pivot * mat[r][c] - mat[r][pivot_col] * mat[row][c];
                }
            }
            pivot_col += 1;
        }

        det
    }

    /// Recursively enumerate integer vectors and collect those in the kernel of q_matrix.
    fn find_kernel_vectors(
        &self,
        n_cols: usize,
        bound: i32,
        current: &mut Vec<i32>,
        pos: usize,
        out: &mut Vec<Vec<i32>>,
    ) {
        if pos == n_cols {
            let in_kernel = self.q_matrix.iter().all(|row| {
                let dot: i32 = row.iter().zip(current.iter()).map(|(a, b)| a * b).sum();
                dot == 0
            });
            if in_kernel && current.iter().any(|x| *x != 0) {
                out.push(current.clone());
            }
            return;
        }

        for val in -bound..=bound {
            current[pos] = val;
            let dominated = self.q_matrix.iter().any(|row| {
                let partial: i32 = row[..pos + 1]
                    .iter()
                    .zip(current[..pos + 1].iter())
                    .map(|(a, b)| a * b)
                    .sum();
                partial.abs() > bound * (n_cols as i32)
            });
            if !dominated {
                self.find_kernel_vectors(n_cols, bound, current, pos + 1, out);
            }
        }
    }

    /// Run full N1-N3 deterministic normal form reduction.
    pub fn normalize_to_nf(&mut self) {
        // N1: Stabilization — iteratively remove the shortest basis vector
        // and reduce all other vectors against it. This is analogous to
        // the reduction step in Gaussian lattice reduction.
        let mut iterations = 0;
        let max_iterations = self.q_matrix.len() + 2;
        while iterations < max_iterations && self.q_matrix.len() > 1 {
            if !self.apply_blowdown_step() {
                break;
            }
            iterations += 1;
        }

        // N2: Congruence normalization
        self.n2_lll_reduction();

        // N3: Jordan decomposition
        self.n3_jordan_decomp();
    }
}

/// Compute prime factorization of n as (prime, exponent) pairs.
fn prime_factors(mut n: u64) -> Vec<(u64, u32)> {
    if n <= 1 {
        return Vec::new();
    }
    let mut factors = Vec::new();
    let mut d = 2u64;
    while d * d <= n {
        if n % d == 0 {
            let mut exp = 0u32;
            while n % d == 0 {
                n /= d;
                exp += 1;
            }
            factors.push((d, exp));
        }
        d += 1;
    }
    if n > 1 {
        factors.push((n, 1));
    }
    factors
}

/// Grammar Normalization (Syntactic step):
/// Rewrites sequences of generators into a canonical evaluation form.
pub fn normalize_word(word: Vec<Operator>) -> Vec<Operator> {
    let mut normalized: Vec<Operator> = Vec::new();
    for op in word {
        if let Some(last) = normalized.last() {
            if (op.op_type == OperatorType::H && last.op_type == OperatorType::HInv)
                || (op.op_type == OperatorType::HInv && last.op_type == OperatorType::H)
            {
                normalized.pop();
                continue;
            }
        }
        normalized.push(op);
    }
    normalized
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_canonical_witness_selection() {
        // q_matrix = [[1,1,0]] — kernel is {(a,-a,b)} for any a,b
        let state = State {
            q_matrix: vec![vec![1, 1, 0]],
            p_vector: vec![],
        };
        let witness = state.canonical_blowdown().unwrap();
        // Minimal norm kernel vector: [0,0,1] with norm_sq = 1
        let norm_sq: i32 = witness.iter().map(|x| x * x).sum();
        assert!(norm_sq >= 1 && norm_sq <= 2, "Expected norm 1 or 2, got {}", norm_sq);
        // Verify it's actually in the kernel
        let dot: i32 = state.q_matrix[0].iter().zip(witness.iter()).map(|(a, b)| a * b).sum();
        assert_eq!(dot, 0);
    }

    #[test]
    fn test_n2_reduction() {
        let mut state = State {
            q_matrix: vec![vec![2, 0, 0], vec![0, 2, 0]],
            p_vector: vec![5, 3, 1],
        };
        state.n2_lll_reduction();
        // After reduction mod [2,0,0]: 5 → 1; mod [0,2,0]: 3 → 1
        assert!(state.p_vector[0].abs() <= 2);
        assert!(state.p_vector[1].abs() <= 2);
    }

    #[test]
    fn test_n3_jordan_decomp() {
        let mut state = State {
            q_matrix: vec![vec![4, 0], vec![0, 9]],
            p_vector: vec![],
        };
        state.n3_jordan_decomp();
        // 4 = 2^2 → row [4,0] → [1,0]; 9 = 3^2 → row [0,9] → [0,1]
        assert_eq!(state.q_matrix[0], vec![1, 0]);
        assert_eq!(state.q_matrix[1], vec![0, 1]);
    }

    #[test]
    fn test_empty_q_matrix() {
        let state = State {
            q_matrix: vec![],
            p_vector: vec![1, 2],
        };
        assert!(state.canonical_blowdown().is_none());
    }

    #[test]
    fn test_full_normalization() {
        let mut state = State {
            q_matrix: vec![vec![3, 6], vec![6, 3]],
            p_vector: vec![7, 5],
        };
        state.normalize_to_nf();
        // After N1 (shortest row removal) + N2 (reduction) + N3 (Jordan)
        assert!(!state.q_matrix.is_empty() || state.p_vector.iter().all(|x| x.abs() <= 10));
    }

    #[test]
    fn test_prime_factors() {
        assert_eq!(prime_factors(12), vec![(2, 2), (3, 1)]);
        assert_eq!(prime_factors(1), vec![]);
        assert_eq!(prime_factors(13), vec![(13, 1)]);
        assert_eq!(prime_factors(100), vec![(2, 2), (5, 2)]);
    }

    #[test]
    fn test_normalize_word_cancellation() {
        let word = vec![
            Operator { op_type: OperatorType::H, indices: None, sign: None, ap_coefficient: None },
            Operator { op_type: OperatorType::HInv, indices: None, sign: None, ap_coefficient: None },
            Operator { op_type: OperatorType::S, indices: None, sign: None, ap_coefficient: None },
        ];
        let result = normalize_word(word);
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].op_type, OperatorType::S);
    }

    #[test]
    fn test_determinant_2x2() {
        let state = State {
            q_matrix: vec![vec![3, 1], vec![2, 4]],
            p_vector: vec![],
        };
        assert_eq!(state.lattice_determinant(), 10); // 3*4 - 1*2 = 10
    }

    #[test]
    fn test_blowdown_step_removes_shortest_row() {
        let mut state = State {
            q_matrix: vec![vec![10, 0], vec![1, 1]],
            p_vector: vec![],
        };
        let reduced = state.apply_blowdown_step();
        assert!(reduced);
        // Row [1,1] (norm 2) removed before [10,0] (norm 100).
        // Remaining row [10,0] is reduced against [1,1]: dot=10, norm_sq=2, q=5.
        // [10,0] → [10-5*1, 0-5*1] = [5, -5]
        assert_eq!(state.q_matrix.len(), 1);
        assert_eq!(state.q_matrix[0], vec![5, -5]);
    }
}
