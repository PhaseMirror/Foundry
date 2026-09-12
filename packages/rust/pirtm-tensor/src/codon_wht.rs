//! Codon-Contrast Walsh-Hadamard Transform (WHT) Adapter
//!
//! Bridges the 64-dimensional discrete biophysical codon space
//! into the continuous, prime-indexed MultiplicitySpace.

use crate::multiplicity_core::{PrimeLabel, Interaction, MultiplicitySpace};

/// Computes the in-place Fast Walsh-Hadamard Transform (FWHT)
/// for a slice whose length is a power of 2 (e.g., 64).
/// This extracts the epistatic interaction coefficients up to the 6th order.
pub fn fwht_in_place(data: &mut [f64]) {
    let n = data.len();
    assert!(n.is_power_of_two(), "FWHT requires power-of-two length");

    let mut h = 1;
    while h < n {
        for i in (0..n).step_by(h * 2) {
            for j in i..i + h {
                let x = data[j];
                let y = data[j + h];
                data[j] = x + y;
                data[j + h] = x - y;
            }
        }
        h *= 2;
    }

    // Normalize the transform (unitary scaling)
    let norm_factor = (n as f64).sqrt();
    for val in data.iter_mut() {
        *val /= norm_factor;
    }
}

/// Maps a 64-element biophysical contrast array (the empirical codon usage)
/// into a prime-indexed MultiplicitySpace.
///
/// # Arguments
/// * `empirical_distribution` - A 64-element array of observed codon frequencies.
/// * `labels` - The verified PrimeLabel mapping (must be initialized to at least N=64).
/// * `threshold` - Spectral noise floor. Coefficients below this are truncated to preserve sparsity.
pub fn project_codon_to_multiplicity(
    empirical_distribution: &[f64; 64],
    labels: &PrimeLabel,
    threshold: f64,
) -> MultiplicitySpace {
    let mut spectral_data = *empirical_distribution;

    // 1. Transform: Boolean Hypercube -> Epistatic Spectral Basis
    fwht_in_place(&mut spectral_data);

    let mut space: MultiplicitySpace = Vec::new();

    // 2. Projection: Map significant spectral coefficients to Prime Interactions
    // Here, we treat the DC component (idx 0) as the central node (vertex 0),
    // and all other indices as interacting features.
    for (i, &coeff) in spectral_data.iter().enumerate() {
        if coeff.abs() >= threshold {
            // Convert the continuous spectral coefficient into a discrete weight mapping
            let weight = (coeff.abs() * 10_000.0) as u64;
            if weight > 0 {
                // Encode the epistatic interaction as a prime product
                // src = 0 (baseline codon anchor), dst = i (specific epistatic feature)
                let interaction = Interaction::new(0, i, weight, labels);
                space.push(interaction);
            }
        }
    }
    space
}

