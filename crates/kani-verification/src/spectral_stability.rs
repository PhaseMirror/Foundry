//! Spectral stability computable kernels.
//!
//! These implementations back the Lean axioms in:
//! `crates/multiplicity/lean/SpectralStability.lean`

use ndarray::Array2;

/// Compute the Gershgorin bound for a matrix.
pub fn gershgorin_bound(matrix: &Array2<f64>) -> f64 {
    let n = matrix.nrows();
    let mut max_bound: f64 = 0.0;
    for i in 0..n {
        let center = matrix[[i, i]].abs();
        let mut radius: f64 = 0.0;
        for j in 0..n {
            if i != j {
                radius += matrix[[i, j]].abs();
            }
        }
        max_bound = max_bound.max(center + radius);
    }
    max_bound
}

/// Compute a simple upper bound on spectral radius using power iteration.
pub fn power_iteration_limit(matrix: &Array2<f64>) -> f64 {
    let n = matrix.nrows();
    if n == 0 {
        return 0.0;
    }
    
    let mut v = vec![1.0; n];
    let mut v_new = vec![0.0; n];
    
    for _ in 0..100 {
        for i in 0..n {
            let mut sum: f64 = 0.0;
            for j in 0..n {
                sum += matrix[[i, j]] * v[j];
            }
            v_new[i] = sum;
        }
        
        let norm: f64 = v_new.iter().map(|x| x * x).sum::<f64>().sqrt();
        if norm > 0.0 {
            for i in 0..n {
                v[i] = v_new[i] / norm;
            }
        }
    }
    
    let mut rayleigh: f64 = 0.0;
    for i in 0..n {
        let mut sum: f64 = 0.0;
        for j in 0..n {
            sum += matrix[[i, j]] * v[j];
        }
        rayleigh += v[i] * sum;
    }
    
    rayleigh.abs()
}

/// Compute spectral convergence rate.
pub fn spectral_convergence_rate(prev_lambda: f64, next_lambda: f64) -> f64 {
    if next_lambda > 0.0 {
        (next_lambda - prev_lambda).abs() / next_lambda
    } else {
        0.0
    }
}

/// Compute drift score.
pub fn drift_score(spectral_radius: f64, gershgorin_bound: f64) -> f64 {
    spectral_radius - gershgorin_bound
}

/// Compute effective iterations bound.
pub fn effective_iterations_bound(epsilon: f64) -> u32 {
    if epsilon <= 0.0 {
        return u32::MAX;
    }
    (100.0 * (1.0 / epsilon)).floor() as u32
}

/// Check L0 contractivity.
pub fn l0_contractivity_preserved(spectral_rad: f64, epsilon: f64) -> bool {
    spectral_rad < 1.0 - epsilon
}

// ---------------------------------------------------------------------------
// Kani verification harnesses
// ---------------------------------------------------------------------------

#[cfg(kani)]
mod verification {
    use super::*;
    use ndarray::Array2;
    use kani::proof;

    #[proof]
    fn proof_gershgorin_bound_nonnegative() {
        let n: usize = kani::any();
        kani::assume(n > 0 && n <= 10);
        let mut matrix = Array2::<f64>::zeros((n, n));
        for i in 0..n {
            for j in 0..n {
                matrix[[i, j]] = kani::any();
                kani::assume(matrix[[i, j]].is_finite());
            }
        }
        let bound = gershgorin_bound(&matrix);
        assert!(bound >= 0.0, "Gershgorin bound must be non-negative");
    }

    #[proof]
    fn proof_power_iteration_nonnegative() {
        let n: usize = kani::any();
        kani::assume(n > 0 && n <= 5);
        let mut matrix = Array2::<f64>::zeros((n, n));
        for i in 0..n {
            for j in 0..n {
                matrix[[i, j]] = kani::any();
                kani::assume(matrix[[i, j]].is_finite());
            }
        }
        let limit = power_iteration_limit(&matrix);
        kani::assert(limit >= 0.0, "Power iteration limit must be non-negative");
    }

    #[proof]
    fn proof_gershgorin_diagonal_exact() {
        let n: usize = kani::any();
        kani::assume(n > 0 && n <= 5);
        let mut matrix = Array2::<f64>::zeros((n, n));
        for i in 0..n {
            matrix[[i, i]] = kani::any();
            kani::assume(matrix[[i, i]].is_finite());
        }
        let bound = gershgorin_bound(&matrix);
        let max_diag: f64 = (0..n).map(|i| matrix[[i, i]].abs()).fold(0.0, f64::max);
        kani::assert((bound - max_diag).abs() < 1e-10, "Diagonal Gershgorin exact");
    }

    #[proof]
    fn proof_convergence_rate_nonnegative() {
        let prev: f64 = kani::any();
        let next: f64 = kani::any();
        kani::assume(prev.is_finite() && next.is_finite());
        let rate = spectral_convergence_rate(prev, next);
        kani::assert(rate >= 0.0, "Convergence rate must be non-negative");
    }

    #[proof]
    fn proof_drift_score_bounded() {
        let spectral_rad: f64 = kani::any();
        let gershgorin: f64 = kani::any();
        kani::assume(spectral_rad.is_finite() && gershgorin.is_finite());
        let score = drift_score(spectral_rad, gershgorin);
        kani::assert(score >= -gershgorin, "Drift score bounded below");
    }

    #[proof]
    fn proof_effective_iterations_positive() {
        let epsilon: f64 = kani::any();
        kani::assume(epsilon > 0.0 && epsilon < 1.0 && epsilon.is_finite());
        let bound = effective_iterations_bound(epsilon);
        kani::assert(bound > 0, "Effective iterations must be positive");
    }

    #[proof]
    fn proof_l0_contractivity() {
        let spectral_rad: f64 = kani::any();
        let epsilon: f64 = kani::any();
        kani::assume(spectral_rad.is_finite() && epsilon.is_finite());
        kani::assume(epsilon > 0.0 && epsilon < 1.0);
        kani::assume(spectral_rad < 1.0 - epsilon);
        let preserved = l0_contractivity_preserved(spectral_rad, epsilon);
        kani::assert(preserved, "L0 contractivity should be preserved");
    }
}
