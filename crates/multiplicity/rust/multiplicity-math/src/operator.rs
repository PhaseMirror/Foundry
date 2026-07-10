//! Multiplicity Knot Theory (MKT) Bridge - Canonical SU(2) Operators

use anyhow::Result;
use num_complex::Complex64;
use crate::axis::canonical_eigenmode_axis;

/// Construct the canonical SU(2) operator for a prime number.
///
/// The operator is built from the canonical eigenmode axis with the
/// parameter-free angle log(prime).
pub fn construct_su2_operator(prime: u64) -> Result<[[Complex64; 2]; 2]> {
    let (n_x, n_y, n_z) = canonical_eigenmode_axis(prime)?;
    let angle = (prime as f64).ln();

    let half_angle = angle / 2.0;
    let cos_half = half_angle.cos();
    let sin_half = half_angle.sin();

    // Construct SU(2) operator: exp(i * angle) * SU(2) rotation matrix
    // Note: Python code returns exp(i * angle) * matrix
    let phase = Complex64::from_polar(1.0, angle);

    let m00 = Complex64::new(cos_half, n_z * sin_half);
    let m01 = Complex64::new(n_y * sin_half, n_x * sin_half); // i * (nx - i*ny) = i*nx + ny
    let m10 = Complex64::new(-n_y * sin_half, n_x * sin_half); // i * (nx + i*ny) = i*nx - ny
    let m11 = Complex64::new(cos_half, -n_z * sin_half);

    Ok([
        [phase * m00, phase * m01],
        [phase * m10, phase * m11]
    ])
}
