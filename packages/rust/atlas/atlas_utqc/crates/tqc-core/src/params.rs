//! The use-case parameters and every quantity derived from them.
//!
//! This is the DRY heart: each Atlas quantity is defined here *once*, as a function of the
//! parameters. The Atlas instance supplies `(4, 3, 8)`; an arbitrary use-case supplies any
//! valid triple.

use core::fmt;

/// Parameters defining an Atlas-style modular use-case.
///
/// - `scope` (`q`): the order of the rotation generator `σ`.
/// - `modality` (`T`): the cyclic modality.
/// - `context` (`O`): the order of the rotation generator `τ`; also the carrier's second factor.
///
/// The canonical UOR Atlas instance is `{ scope: 4, modality: 3, context: 8 }`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct UseCaseParams {
    /// Scope `q` (order of `σ`).
    pub scope: u32,
    /// Modality `T`.
    pub modality: u32,
    /// Context `O` (order of `τ`).
    pub context: u32,
}

/// An invalid parameter combination.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ParamError(&'static str);

impl fmt::Display for ParamError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "invalid use-case parameters: {}", self.0)
    }
}

impl UseCaseParams {
    /// Construct parameters without validation (`const`).
    #[must_use]
    pub const fn new(scope: u32, modality: u32, context: u32) -> Self {
        Self {
            scope,
            modality,
            context,
        }
    }

    /// Construct parameters, rejecting degenerate values.
    ///
    /// # Errors
    /// Returns [`ParamError`] if any parameter is `0`, if `context` would overflow the belt
    /// shift, or if the class count would overflow `u64`.
    pub fn checked(scope: u32, modality: u32, context: u32) -> Result<Self, ParamError> {
        if scope == 0 || modality == 0 || context == 0 {
            return Err(ParamError("scope, modality and context must be >= 1"));
        }
        if context > 63 {
            return Err(ParamError("context must be <= 63 (belt shift bound)"));
        }
        let p = Self {
            scope,
            modality,
            context,
        };
        // Probe the largest derived quantity for overflow.
        if (scope as u64)
            .checked_mul(modality as u64)
            .and_then(|x| x.checked_mul(context as u64))
            .and_then(|count| count.checked_mul(1u64 << (context - 1)))
            .is_none()
        {
            return Err(ParamError("belt extent overflows u64"));
        }
        Ok(p)
    }

    /// Number of object/anyon classes: `scope · modality · context`.
    #[must_use]
    pub const fn class_count(&self) -> u64 {
        self.scope as u64 * self.modality as u64 * self.context as u64
    }

    /// Class stride: `modality · context`.
    #[must_use]
    pub const fn stride(&self) -> u64 {
        self.modality as u64 * self.context as u64
    }

    /// Carrier dimension `V_T ⊗ V_O`: `modality · context`.
    #[must_use]
    pub const fn carrier_dim(&self) -> u64 {
        self.stride()
    }

    /// Order of the rotation generator `σ` (= `scope`).
    #[must_use]
    pub const fn sigma_order(&self) -> u32 {
        self.scope
    }

    /// Order of the rotation generator `τ` (= `context`).
    #[must_use]
    pub const fn tau_order(&self) -> u32 {
        self.context
    }

    /// Order of the mirror generator `μ` (always `2` for non-degenerate modality).
    #[must_use]
    pub const fn mu_order(&self) -> u32 {
        if self.modality >= 2 {
            2
        } else {
            1
        }
    }

    /// `classIndex(h2, d, l) = stride·h2 + context·d + l`, defined iff the coordinates are in range.
    #[must_use]
    pub fn class_index(&self, h2: u32, d: u32, l: u32) -> Option<u64> {
        if h2 >= self.scope || d >= self.modality || l >= self.context {
            return None;
        }
        Some(self.stride() * h2 as u64 + self.context as u64 * d as u64 + l as u64)
    }

    /// Inverse of [`class_index`](Self::class_index): decode an index into `(h2, d, l)`.
    #[must_use]
    pub fn class_coords(&self, index: u64) -> Option<(u32, u32, u32)> {
        if index >= self.class_count() {
            return None;
        }
        let h2 = index / self.stride();
        let rem = index % self.stride();
        let d = rem / self.context as u64;
        let l = rem % self.context as u64;
        Some((h2 as u32, d as u32, l as u32))
    }

    /// Belt extent: `class_count · 2^(context-1)`.
    #[must_use]
    pub const fn belt_extent(&self) -> u64 {
        self.class_count() * (1u64 << (self.context - 1))
    }

    /// The two canonical belt factorizations `[(count, 2^(O-1)), (count/2, 2^O)]`.
    ///
    /// For the Atlas this is `[(96, 128), (48, 256)]`.
    #[must_use]
    pub fn belt_factorizations(&self) -> alloc::vec::Vec<(u64, u64)> {
        let count = self.class_count();
        let extent = self.belt_extent();
        let mut out = alloc::vec![(count, extent / count)];
        if count % 2 == 0 {
            let half = count / 2;
            out.push((half, extent / half));
        }
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const ATLAS: UseCaseParams = UseCaseParams::new(4, 3, 8);

    #[test]
    fn atlas_derived_quantities() {
        assert_eq!(ATLAS.class_count(), 96);
        assert_eq!(ATLAS.stride(), 24);
        assert_eq!(ATLAS.carrier_dim(), 24);
        assert_eq!(ATLAS.sigma_order(), 4);
        assert_eq!(ATLAS.tau_order(), 8);
        assert_eq!(ATLAS.mu_order(), 2);
        assert_eq!(ATLAS.belt_extent(), 12288);
        assert_eq!(ATLAS.belt_factorizations(), std::vec![(96, 128), (48, 256)]);
    }

    #[test]
    fn index_and_coords_roundtrip() {
        for idx in 0..ATLAS.class_count() {
            let (h2, d, l) = ATLAS.class_coords(idx).unwrap();
            assert_eq!(ATLAS.class_index(h2, d, l), Some(idx));
        }
        assert_eq!(ATLAS.class_coords(96), None);
        assert_eq!(ATLAS.class_index(4, 0, 0), None);
    }

    #[test]
    fn parametricity_holds_for_arbitrary_instance() {
        let p = UseCaseParams::checked(2, 2, 4).unwrap();
        assert_eq!(p.class_count(), 16);
        assert_eq!(p.stride(), 8);
        assert_eq!(p.belt_extent(), 128);
    }
}
