//! Arithmetic Gravity: De Bruijn–Newman deformation of the prime‑indexed channel.
//!
//! This library computes the largest non‑unit eigenvalue of the channel for a given
//! prime `p`, damping parameter `γ_p`, and deformation parameter `g` (the “gravitational”
//! strength). The eigenvalues are:
//!
//! - 1 (stationary state)
//! - 1 - γ_p
//! - √(1-γ_p) · p^{δ} · e^{± i γ log p}   where δ = max(0, -g)
//!
//! Contraction is maintained iff all non‑unit eigenvalues have modulus < 1.
//! The critical one is λ_max = √(1-γ_p) · p^{δ}.

use num_rational::Ratio;

/// Compute the maximum modulus of the non‑unit eigenvalues using f64.
pub fn max_eigenvalue_modulus(p: u64, gamma_p: f64, g: f64) -> Option<f64> {
    if gamma_p <= 0.0 || gamma_p >= 1.0 {
        return None;
    }
    let delta = if g < 0.0 { -g } else { 0.0 };
    let base = (1.0 - gamma_p).sqrt();
    let scaling = (p as f64).powf(delta);
    Some(base * scaling)
}

/// Rational version for use in Kani proofs.
pub fn max_eigenvalue_modulus_rational(
    p: u64,
    gamma_p_num: u64,
    gamma_p_den: u64,
    g_num: i64,
    g_den: u64,
) -> Option<Ratio<u64>> {
    if gamma_p_num == 0 || gamma_p_num >= gamma_p_den {
        return None;
    }
    let gamma = Ratio::new(gamma_p_num, gamma_p_den);
    let delta = if g_num < 0 {
        Ratio::new((-g_num) as u64, g_den)
    } else {
        Ratio::new(0, 1)
    };
    // Use rational approximation for sqrt(1-γ) – we can bound it.
    // For exact verification we would use interval arithmetic; here we use a float
    // conversion for demonstration. In a real proof we would stay in ℚ with bounds.
    let sqrt_base = (1.0 - gamma.to_f64().unwrap()).sqrt();
    let scaling = (p as f64).powf(delta.to_f64().unwrap());
    let approx = sqrt_base * scaling;
    Some(Ratio::from_float(approx).unwrap())
}
