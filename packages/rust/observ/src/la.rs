//! Exact linear algebra over `Q` — the measurement-map engine.
//!
//! Implements the ADR-0027/0028 substrate: cumulative maps F_j = A_j … A_1,
//! null filtration K_j = ker F_j, witness spaces W_j = Ann(K_j) = im F_j^*,
//! target survival (K_j ⊆ ker C), the obstruction dimension
//! `d_C(A) = dim C(ker A)`, stacked-probe kernel intersection
//! (`ker A_stack = ⋂ ker A_i`), and constructive dual counterexamples
//! (`v ∈ ker A_E` with `Cv ≠ 0`).
//!
//! Everything is exact rational; there is no LAPACK, no float, no tolerance.

use super::rat::Q;

pub type Row = Vec<Q>;

/// Identity on dimension `n`.
pub fn identity(n: usize) -> Vec<Row> {
    (0..n).map(|i| row_e(i, n)).collect()
}

/// The `i`-th standard basis row of length `n`.
pub fn row_e(i: usize, n: usize) -> Row {
    let mut r = vec![Q::ZERO; n];
    r[i] = Q::ONE;
    r
}

/// Height of a matrix (0 for empty).
pub fn height(m: &[Row]) -> usize {
    m.len()
}

/// Width of a matrix (0 for empty rows).
pub fn width(m: &[Row]) -> usize {
    m.first().map(Row::len).unwrap_or(0)
}

/// Row-reduced echelon form. Returns the RREF and the pivot columns.
pub fn rref(m: &[Row]) -> (Vec<Row>, Vec<usize>) {
    let cols = width(m);
    let mut a: Vec<Row> = m.to_vec();
    let mut pivots: Vec<usize> = Vec::new();
    let mut r = 0usize;
    for c in 0..cols {
        // Find a pivot in column c at row >= r.
        let mut pr = None;
        for (i, row) in a.iter().enumerate().skip(r) {
            if !row[c].is_zero() {
                pr = Some(i);
                break;
            }
        }
        let Some(pivot) = pr else { continue };
        a.swap(r, pivot);
        // Normalize the pivot row.
        let scale = a[r][c].recip();
        for v in a[r].iter_mut() {
            *v = *v * scale;
        }
        // Eliminate column c from every other row.
        let pivot_row: Row = a[r].clone();
        for (i, row) in a.iter_mut().enumerate() {
            if i != r && !row[c].is_zero() {
                let factor = row[c];
                for (x, y) in row.iter_mut().zip(pivot_row.iter()) {
                    *x = *x - factor * *y;
                }
            }
        }
        pivots.push(c);
        r += 1;
    }
    (a, pivots)
}

/// Rank of a matrix over `Q`.
pub fn rank(m: &[Row]) -> usize {
    rref(m).1.len()
}

/// A basis of `ker A` as row vectors (length = width(A)).
pub fn kernel_basis(a: &[Row]) -> Vec<Row> {
    let rows = height(a);
    let cols = width(a);
    let (red, pivots) = rref(a);
    let pivot_set: std::collections::BTreeSet<usize> = pivots.iter().copied().collect();
    let mut basis: Vec<Row> = Vec::new();
    for free in 0..cols {
        if pivot_set.contains(&free) {
            continue;
        }
        let mut v = vec![Q::ZERO; cols];
        v[free] = Q::ONE;
        // For each pivot row r with pivot p, v[p] = - red[r][free].
        for (r, &p) in pivots.iter().enumerate() {
            if r < rows && !red[r][free].is_zero() {
                v[p] = -red[r][free];
            }
        }
        basis.push(v);
    }
    basis
}

/// A basis of `im A` (column space) from a basis of the row space of `Aᵀ`.
/// We take the non-zero rows of the transpose's RREF restricted to pivots.
pub fn image_basis(a: &[Row]) -> Vec<Row> {
    let cols = width(a);
    // Build Aᵀ as rows.
    let mut t: Vec<Row> = vec![Vec::new(); cols];
    for row in a {
        for (j, v) in row.iter().enumerate() {
            t[j].push(*v);
        }
    }
    let (red, pivots) = rref(&t);
    pivots.into_iter().map(|r| red[r].clone()).collect()
}

/// Whether every `v ∈ ker A` satisfies `C v = 0` (i.e. `ker A ⊆ ker C`).
pub fn target_survives(a: &[Row], c: &[Row]) -> bool {
    kernel_basis(a)
        .iter()
        .all(|v| apply(c, v).iter().all(Q::is_zero))
}

/// `dim C(ker A)`: the obstruction dimension. A constructive dual
/// counterexample `v` (with `A v = 0`, `C v ≠ 0`) is returned when non-zero.
pub struct Obstruction {
    pub dimension: usize,
    /// A witness `v ∈ ker A` with `C v ≠ 0`, when `dimension > 0`.
    pub counterexample: Option<Row>,
}

pub fn obstruction_dimension(a: &[Row], c: &[Row]) -> Obstruction {
    let basis = kernel_basis(a);
    let mut images: Vec<Row> = Vec::new();
    let mut witness: Option<Row> = None;
    for v in &basis {
        let img = apply(c, v);
        if img.iter().any(|q| !q.is_zero()) && witness.is_none() {
            witness = Some(v.clone());
        }
        images.push(img);
    }
    let dimension = rank(&images);
    Obstruction {
        dimension,
        counterexample: if dimension > 0 { witness } else { None },
    }
}

/// Stacked map: vertical concatenation A = [A1; A2; …].
pub fn stack(maps: &[&[Row]]) -> Vec<Row> {
    let mut out = Vec::new();
    for m in maps {
        out.extend_from_slice(m);
    }
    out
}

/// Matrix product `A * B` (A is `rA × k`, B is `k × cB`).
pub fn matmul(a: &[Row], b: &[Row]) -> Vec<Row> {
    let k = width(a);
    debug_assert_eq!(k, height(b));
    let r = height(a);
    let c = width(b);
    let mut out = vec![vec![Q::ZERO; c]; r];
    for i in 0..r {
        for j in 0..c {
            let mut acc = Q::ZERO;
            for t in 0..k {
                acc = acc + a[i][t] * b[t][j];
            }
            out[i][j] = acc;
        }
    }
    out
}

/// Apply matrix `m` to the column vector `v`; returns a row of length height(m).
pub fn apply(m: &[Row], v: &[Q]) -> Row {
    m.iter().map(|row| dot(row, v)).collect()
}

/// Dot product of two equal-width vectors.
pub fn dot(a: &[Q], b: &[Q]) -> Q {
    a.iter()
        .zip(b.iter())
        .fold(Q::ZERO, |acc, (x, y)| acc + *x * *y)
}

/// Cumulative maps F_j = a_j · a_{j-1} · … · a_1, with F_0 = I.
/// `stages` is ordered first-applied first: S, R, P, A, T in the paper's
/// M = T ∘ A ∘ P ∘ R ∘ S notation. Every stage must be square `dim × dim`
/// (enforced by program validation).
pub fn cumulative_maps(dim: usize, stages: &[Vec<Row>]) -> Vec<Vec<Row>> {
    let mut out = Vec::with_capacity(stages.len() + 1);
    let mut f = identity(dim);
    for s in stages {
        debug_assert_eq!(height(s), dim);
        debug_assert_eq!(width(s), dim);
        f = matmul(s, &f);
        out.push(f.clone());
    }
    out
}

/// The null filtration K_j = ker F_j, one basis per cumulative stage.
pub fn null_filtration(cumulative: &[Vec<Row>]) -> Vec<Vec<Row>> {
    cumulative.iter().map(|f| kernel_basis(f)).collect()
}

/// The dual witness filtration W_j = im F_j^* (as basis rows).
pub fn witness_filtration(cumulative: &[Vec<Row>]) -> Vec<Vec<Row>> {
    cumulative.iter().map(|f| image_basis(f)).collect()
}

/// Filtration in the sense `K_0 ⊆ K_1 ⊆ … ⊆ K_n` (each a subspace inclusion).
pub fn is_nested(chain: &[Vec<Row>]) -> bool {
    chain.windows(2).all(|w| subspace_contains(&w[0], &w[1]))
}

/// Whether every vector of `inner` lies in `span(outer)`.
pub fn subspace_contains(outer: &[Row], inner: &[Row]) -> bool {
    inner.iter().all(|v| vector_in_span(outer, v))
}

/// Whether a single vector lies in the span of the basis rows.
pub fn vector_in_span(basis: &[Row], v: &[Q]) -> bool {
    if basis.is_empty() {
        return v.iter().all(Q::is_zero);
    }
    let mut aug: Vec<Row> = basis.to_vec();
    aug.push(v.to_vec());
    let base_rank = rank(basis);
    let aug_rank = rank(&aug);
    base_rank == aug_rank
}

/// Number of children in a stage decomposition: `dim(K_j) − dim(K_{j−1})`.
pub fn new_direction_count(kj: &[Row], kj_prev: &[Row]) -> usize {
    let mut fresh = 0usize;
    for v in kj {
        if !vector_in_span(kj_prev, v) {
            fresh += 1;
        }
    }
    fresh
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::rat::const_q;

    fn m(rows: &[&[i128]]) -> Vec<Row> {
        rows.iter()
            .map(|r| r.iter().map(|&x| const_q(x)).collect())
            .collect()
    }

    #[test]
    fn rank_and_kernel_of_singleton() {
        let a = m(&[&[1, 0]]);
        assert_eq!(rank(&a), 1);
        let ker = kernel_basis(&a);
        assert_eq!(ker.len(), 1);
        assert_eq!(ker[0], vec![const_q(0), const_q(1)]);
    }

    #[test]
    fn kernel_of_zero_map_is_whole_space() {
        let a = m(&[&[0, 0]]);
        assert_eq!(rank(&a), 0);
        assert_eq!(kernel_basis(&a).len(), 2);
    }

    #[test]
    fn obstruction_dimension_matches_paper6() {
        // A_E = [0 1]: target C = [1 0]. d_C = 1; counterexample (1,0).
        let ae = m(&[&[0, 1]]);
        let c = m(&[&[1, 0]]);
        let ob = obstruction_dimension(&ae, &c);
        assert_eq!(ob.dimension, 1);
        let v = ob.counterexample.expect("witness exists");
        assert_eq!(v, vec![const_q(1), const_q(0)]);
    }

    #[test]
    fn stacked_intersection_is_kernel_intersection() {
        // Two maps whose kernels intersect trivially.
        let a1 = m(&[&[1, 1]]);
        let a2 = m(&[&[1, -1]]);
        let stacked = stack(&[&a1, &a2]);
        assert_eq!(rank(&stacked), 2);
        let ker = kernel_basis(&stacked);
        assert!(ker.is_empty());
    }

    #[test]
    fn survival_holds_when_kernel_in_kernel() {
        // A = [[1,0]] kills nothing that C = [[1,0]] doesn't.
        let a = m(&[&[1, 0]]);
        let c = m(&[&[1, 0]]);
        assert!(target_survives(&a, &c));
        // And the witness filtration is 1-dimensional.
        let w = image_basis(&a);
        assert_eq!(w.len(), 1);
    }

    #[test]
    fn cumulative_maps_compose_left_applied_first() {
        // F_1 = [[1,0],[0,0]] ; F_2 = T∘F_1 with T = I, so F_2 = F_1.
        let s = m(&[&[1, 0], &[0, 0]]);
        let t = identity(2);
        let cum = cumulative_maps(2, &[s, t]);
        assert_eq!(cum.len(), 2);
        assert_eq!(rank(&cum[0]), 1);
        assert_eq!(rank(&cum[1]), 1);
        let ker = kernel_basis(&cum[1]);
        assert_eq!(ker, vec![vec![const_q(0), const_q(1)]]);
    }

    #[test]
    fn factor_filtration_invariants_of_refactorization() {
        // Paper 6 Table I: same total map M = [1 0] ⊗ 0 (rank 1), two
        // factorizations over square stages.
        // A: A1 = diag(1,0) kills e2 already, then A2 = I.
        // B: B1 = I preserves everything, then B2 = diag(1,0).
        let a1 = m(&[&[1, 0], &[0, 0]]);
        let a2 = identity(2);
        let b1 = identity(2);
        let b2 = m(&[&[1, 0], &[0, 0]]);

        let ca = cumulative_maps(2, &[a1, a2]);
        let cb = cumulative_maps(2, &[b1, b2]);
        // Same total fibers: same K_2.
        assert_eq!(rank(&ca[1]), rank(&cb[1]));
        assert_eq!(kernel_basis(&ca[1]), kernel_basis(&cb[1]));
        // Different stage attribution: K_1 differs.
        assert_eq!(kernel_basis(&ca[0]).len(), 1);
        assert_eq!(kernel_basis(&cb[0]).len(), 0);
    }
}
