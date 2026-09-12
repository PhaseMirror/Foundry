//! Multiplicity Knot Theory (MKT) - Canonical Eigenmode Axis Computation
//!
//! This module implements the canonical multiplicity eigenmode axis computation
//! for prime-indexed SU(2) operators.

use anyhow::{Result, anyhow};

/// Compute the canonical multiplicity eigenmode axis for a prime number.
///
/// The axis is constructed from three components that span all canonical
/// spectral layers: oscillatory phase, direct amplitude, and decay envelope.
pub fn canonical_eigenmode_axis(prime: u64) -> Result<(f64, f64, f64)> {
    if prime < 2 {
        return Err(anyhow!("Prime must be ≥ 2, got {}", prime));
    }

    let p_f = prime as f64;
    let ln_p = p_f.ln();

    // Component 1: Oscillatory phase (imaginary, odd sector)
    let oscillatory = ln_p.sin();

    // Component 2: Direct amplitude (real, even sector)
    let direct = ln_p.cos();

    // Component 3: Primorial decay envelope (asymptotic damping)
    let decay = p_f.powf(-0.5);

    // Normalize to unit vector
    let norm = (oscillatory.powi(2) + direct.powi(2) + decay.powi(2)).sqrt();

    Ok((
        oscillatory / norm,
        direct / norm,
        decay / norm
    ))
}

pub fn validate_axis_normalization(prime: u64, tolerance: f64) -> bool {
    if let Ok((x, y, z)) = canonical_eigenmode_axis(prime) {
        let norm_squared = x.powi(2) + y.powi(2) + z.powi(2);
        (norm_squared - 1.0).abs() < tolerance
    } else {
        false
    }
}
