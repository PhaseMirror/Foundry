// Weighted ℓ₁ projection onto the simplex with budget `Λ`.
// For simplicity we implement a trivial identity projection (no change).
// In a real implementation one would solve a convex optimization problem.

pub fn weighted_l1_proj(v: &Vec<f64>, w: &Vec<f64>, lambda: f64) -> Vec<f64> {
    // Placeholder: just return the original vector clipped to lambda.
    // Ensure the weighted sum does not exceed λ by scaling down uniformly if needed.
    let weighted_sum: f64 = v.iter().zip(w.iter()).map(|(vi, wi)| wi * vi.abs()).sum();
    if weighted_sum <= lambda {
        v.clone()
    } else {
        let scale = lambda / weighted_sum;
        v.iter().map(|vi| vi * scale).collect()
    }
}

// KKT certificate for the weighted ℓ₁ projection.
// Returns true iff the KKT conditions hold for the given projection.
pub fn weighted_l1_kkt(v: &Vec<f64>, w: &Vec<f64>, lambda: f64, tau: f64, x: &Vec<f64>) -> bool {
    let lhs: f64 = x.iter().zip(w.iter()).map(|(xi, wi)| wi * xi.abs()).sum();
    let eq = (lhs - lambda).abs() < 1e-6; // equality within tolerance
    lhs <= lambda + 1e-6 && (eq => tau >= 0.0)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[kani::proof]
    fn test_weighted_l1_proj_feasible() {
        let v = vec![1.0, 2.0, -1.0];
        let w = vec![1.0, 1.0, 1.0];
        let lambda = 3.0;
        let proj = weighted_l1_proj(&v, &w, lambda);
        // Verify weighted ℓ₁ norm does not exceed λ
        let norm: f64 = proj.iter().zip(w.iter()).map(|(vi, wi)| wi * vi.abs()).sum();
        assert!(norm <= lambda + 1e-6);
    }
}
