//! The balanced spectral operator `M = (O+2)·I − T·Π_T − O·Π_O` and its spectrum.
//!
//! Realizes the `spectrum` dictionary row. The four block eigenvalues are derived
//! parametrically; multiplicities are sourced from F1 and validated for mutual consistency
//! (their sum is the carrier dimension; the signed sum is the trace; the signature follows).

use crate::params::UseCaseParams;

/// The signature `(positive_dims, negative_dims)` of the spectral operator.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Signature {
    /// Number of positive eigendirections.
    pub positive: u64,
    /// Number of negative eigendirections.
    pub negative: u64,
}

/// A failure to reconcile parametric eigenvalues with sourced multiplicities.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SpectrumError {
    /// `eigenvalues.len() != multiplicities.len()`.
    LengthMismatch,
    /// `Σ mult ≠ carrier_dim`.
    DimMismatch,
    /// `Σ eig·mult ≠ carrier_dim` (trace).
    TraceMismatch,
    /// The operator is not indefinite (no negative eigendirection).
    NotIndefinite,
}

/// The four block eigenvalues of `M`, in canonical order
/// `[(O+2), (O+2)-T, (O+2)-O, (O+2)-T-O]`.
///
/// For the Atlas `(T=3, O=8)` this is `[10, 7, 2, -1]`.
#[must_use]
pub fn block_eigenvalues(p: &UseCaseParams) -> [i64; 4] {
    let base = i64::from(p.context) + 2;
    let t = i64::from(p.modality);
    let o = i64::from(p.context);
    [base, base - t, base - o, base - t - o]
}

/// Reconcile parametric eigenvalues with sourced multiplicities, returning the signature.
///
/// `Σ mult = carrier_dim`, `Σ eig·mult = trace = carrier_dim`, and the operator is
/// indefinite. This is the runtime analogue of F1's `atlasMult` / `atlasM_signature` /
/// `atlasM_indefinite`.
///
/// # Errors
/// Returns [`SpectrumError`] if any consistency check fails.
pub fn reconcile(
    p: &UseCaseParams,
    eigenvalues: &[i64],
    multiplicities: &[u64],
) -> Result<Signature, SpectrumError> {
    if eigenvalues.len() != multiplicities.len() {
        return Err(SpectrumError::LengthMismatch);
    }
    let dim = i128::from(p.carrier_dim());
    let mut sum_mult: i128 = 0;
    let mut trace: i128 = 0;
    let mut positive: u64 = 0;
    let mut negative: u64 = 0;
    for (&e, &m) in eigenvalues.iter().zip(multiplicities) {
        sum_mult += i128::from(m);
        trace += i128::from(e) * i128::from(m);
        if e > 0 {
            positive += m;
        } else if e < 0 {
            negative += m;
        }
    }
    if sum_mult != dim {
        return Err(SpectrumError::DimMismatch);
    }
    if trace != dim {
        return Err(SpectrumError::TraceMismatch);
    }
    if negative == 0 {
        return Err(SpectrumError::NotIndefinite);
    }
    Ok(Signature { positive, negative })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn atlas_block_eigenvalues() {
        assert_eq!(
            block_eigenvalues(&UseCaseParams::new(4, 3, 8)),
            [10, 7, 2, -1]
        );
    }

    #[test]
    fn atlas_multiplicities_are_consistent() {
        let p = UseCaseParams::new(4, 3, 8);
        let sig = reconcile(&p, &[10, 7, 2, -1], &[1, 2, 7, 14]).unwrap();
        assert_eq!(
            sig,
            Signature {
                positive: 10,
                negative: 14
            }
        );
    }

    #[test]
    fn inconsistent_multiplicities_are_rejected() {
        let p = UseCaseParams::new(4, 3, 8);
        assert_eq!(
            reconcile(&p, &[10, 7, 2, -1], &[1, 2, 7, 13]),
            Err(SpectrumError::DimMismatch)
        );
    }
}
