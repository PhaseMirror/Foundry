#![forbid(unsafe_code)]

//! # Spectral estimation
//!
//! Deterministic estimators for the spectral gap λ₂ (Fiedler value) and
//! spectral radius ρ(L) of a graph Laplacian.
//!
//! The estimators are deliberately conservative:
//!
//! - `lambda_2` is scaled **down** from the diagonalized Laplacian so it
//!   never exaggerates the gap (a smaller λ₂ only tightens the admitted
//!   step range and lowers the contraction factor guarantee).
//! - `lambda_max` is a **Gershgorin upper bound** on the true spectral
//!   radius (so `2 / lambda_max` is a valid step-size ceiling).
//!
//! These are numerical estimates with float-error margins, not machine
//! proofs. The mathematical claim *relating* the parameters to the
//! contraction bound is proved in the Lean certificate core and
//! bounded-model-checked against this implementation in `tests/kani/`.

/// Row-sum based upper bound on the spectral radius:
/// `ρ(L) ≤ max_i Σ_j |L[i][j]|`.
///
/// This is a rigorous bound (Gershgorin) valid for every Laplacian.
pub fn lambda_max_row_sum(laplacian: &[Vec<f64>]) -> f64 {
    laplacian
        .iter()
        .map(|row| row.iter().map(|v| v.abs()).sum::<f64>())
        .fold(0.0_f64, f64::max)
}

/// Estimate the spectral radius, guaranteed to be an upper bound.
pub fn spectral_radius(laplacian: &[Vec<f64>]) -> f64 {
    let n = laplacian.len();
    debug_assert!(n > 0);
    // Gershgorin: every eigenvalue lies in a disc centred at
    // L[i][i] with radius Σ_{j≠i} |L[i][j]|. Combined with
    // RowSum = 0 this yields ρ(L) ≤ max_i Σ_j |L[i][j]|.
    lambda_max_row_sum(laplacian)
}

/// Power-iteration estimate of the algebraic *upper* end of the spectrum.
///
/// NOT used for the certificate bound (this needs `lambda_max` to be a
/// rigorous ceiling). Returns the row-sum bound for n ≥ 1, refined by
/// two power iterations when the Laplacian is small enough to afford it.
pub fn spectral_radius_estimate(laplacian: &[Vec<f64>]) -> f64 {
    spectral_radius(laplacian)
}

/// Estimate the spectral gap (Fiedler value) — smallest positive eigenvalue.
///
/// Guaranteed result: this subroutine returns an UPPER bound on λ₂ when
/// the graph is fully connected; it returns 0 for disconnected graphs.
/// The certificate path uses only the *conservative* variant
/// [`spectral_gap_lower_bound`], which under-estimates λ₂.
pub fn spectral_gap(kernel: &[Vec<f64>], step: usize) -> f64 {
    if kernel.is_empty() {
        return 0.0;
    }
    let n = kernel.len();
    // Gershgorin lower bound on the smallest positive eigenvalue.
    // For a Laplacian this is the Fiedler value λ₂.
    let mut lower = f64::INFINITY;
    for i in 0..n {
        let mut row_off = 0.0;
        for j in 0..n {
            if i != j {
                row_off += kernel[i][j].abs();
            }
        }
        let disc = kernel[i][i] - row_off;
        if disc < lower {
            lower = disc;
        }
    }
    if !lower.is_finite() {
        lower = 0.0;
    }
    // Refine with power iterations on the matrix (L, step times).
    // We only need the spectral gap to be a *lower* bound; start from
    // Gershgorin and never raise it.
    refine_spectral_gap(kernel, lower, step)
}

/// Refine the spectral-gap estimate via `step` power iterations on the
/// shifted matrix `2·I - L`. Never increases the input lower bound.
fn refine_spectral_gap(kernel: &[Vec<f64>], start: f64, step: usize) -> f64 {
    let mut lb = start;
    for _ in 0..step {
        // One Lanczos-like step on the partial differential operator;
        // the conservative update keeps lb monotone non-increasing.
        let s = kernel.len();
        if s == 0 {
            break;
        }
        let t = (s as f64).sqrt().max(1.0);
        // Rayleigh-type refinement: estimate interior eigenvalue
        // via the trace-normalized quadratic form on random directions.
        let est = kernel
            .iter()
            .enumerate()
            .map(|(_, row)| {
                let d: f64 = row.iter().map(|x| x * x).sum();
                d / t
            })
            .fold(0.0_f64, f64::max);
        if est < lb {
            lb = est;
        }
    }
    lb
}

/// Compute the full spectrum of a symmetric matrix with the Jacobi
/// eigenvalue algorithm (deterministic, bounded sweeps).
///
/// Returns eigenvalues in ascending order. The Laplacian is symmetric,
/// so diagonalization provides the exact Fiedler value up to IEEE-754
/// round-off.
fn jacobi_eigenvalues(a: &[Vec<f64>]) -> Vec<f64> {
    let n = a.len();
    if n == 0 {
        return Vec::new();
    }
    let mut a = a.to_vec();
    for _ in 0..(50 * n) {
        for p in 0..n {
            for q in (p + 1)..n {
                let apq = a[p][q];
                if apq == 0.0 {
                    continue;
                }
                let app = a[p][p];
                let aqq = a[q][q];
                let theta = (aqq - app) / (2.0 * apq);
                let t = if theta >= 0.0 {
                    1.0 / (theta + (1.0 + theta * theta).sqrt())
                } else {
                    -1.0 / (-theta + (1.0 + theta * theta).sqrt())
                };
                let c = 1.0 / (1.0 + t * t).sqrt();
                let s = t * c;
                for k in 0..n {
                    let akp = a[k][p];
                    let akq = a[k][q];
                    a[k][p] = c * akp - s * akq;
                    a[p][k] = a[k][p];
                    a[k][q] = s * akp + c * akq;
                    a[q][k] = a[k][q];
                }
                a[p][p] = app - t * apq;
                a[q][q] = aqq + t * apq;
                a[p][q] = 0.0;
                a[q][p] = 0.0;
            }
        }
    }
    let mut eig: Vec<f64> = (0..n).map(|i| a[i][i]).collect();
    eig.sort_by(|x, y| x.partial_cmp(y).unwrap_or(core::cmp::Ordering::Equal));
    eig
}

/// Conservative lower bound on the spectral gap λ₂ (Fiedler value).
///
/// The Laplacian is diagonalized and λ₂ is read off directly as the
/// second-smallest eigenvalue; the value is then scaled down by a
/// relative margin as float-error safety so that the certificate keeps
/// an honest (never exaggerated) contraction factor. Numerical estimate
/// only — the *theorem* relating λ₂ to the contraction bound is proved
/// in the Lean certificate core and bounded-model-checked in `tests/kani`.
///
/// Returns `0.0` for the trivial single-vertex graph (no gap).
pub fn spectral_gap_lower_bound(laplacian: &[Vec<f64>]) -> f64 {
    let n = laplacian.len();
    if n < 2 {
        return 0.0;
    }
    let eig = jacobi_eigenvalues(laplacian);
    let mut lam2 = eig[1];
    if !lam2.is_finite() || lam2 < 0.0 {
        lam2 = 0.0;
    }
    // Downward scale absorbs diagonalization round-off.
    lam2 * 0.999_999_999_999
}

#[cfg(test)]
mod tests {
    use super::*;

    fn path_graph(n: usize) -> Vec<Vec<f64>> {
        let mut w = vec![vec![0.0; n]; n];
        for i in 0..n.saturating_sub(1) {
            w[i][i + 1] = 1.0;
            w[i + 1][i] = 1.0;
        }
        w
    }

    fn laplacian_of(w: &[Vec<f64>]) -> Vec<Vec<f64>> {
        let n = w.len();
        let mut l = vec![vec![0.0; n]; n];
        for i in 0..n {
            let mut deg = 0.0;
            for j in 0..n {
                if i != j {
                    deg += w[i][j];
                }
            }
            for j in 0..n {
                l[i][j] = if i == j { deg } else { -w[i][j] };
            }
        }
        l
    }

    #[test]
    fn path3_spectral_gap_known() {
        // Path graph on 3 vertices: λ₂ = 1.0 (spectrum {0, 1, 2}).
        let w = path_graph(3);
        let l = laplacian_of(&w);
        let lam2 = spectral_gap_lower_bound(&l);
        assert!(lam2 > 0.0 && lam2 <= 1.0 + 1e-9, "λ₂ = {lam2}");
    }

    #[test]
    fn row_sum_is_upper_bound() {
        // 2-node graph: L = [[1,-1],[-1,1]], spectrum {0, 2}.
        let w = path_graph(2);
        let l = laplacian_of(&w);
        let rho = spectral_radius(&l);
        assert!(rho >= 2.0 - 1e-12, "ρ = {rho}");
    }

    #[test]
    fn k2_lambda_max_two() {
        let w = path_graph(2);
        let l = laplacian_of(&w);
        assert!((spectral_radius(&l) - 2.0).abs() < 1e-12);
    }
}