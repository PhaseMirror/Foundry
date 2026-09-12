//! The UOR Atlas use-case instance, and the registry that turns any modelled use-case into
//! [`UseCaseParams`].
//!
//! This crate is the bridge between the typed conceptual model ([`tqc_model`]) and the
//! parametric framework ([`tqc_core`]). It contains **no formulas** — it only selects
//! parameters; every derived quantity comes from `tqc-core` (DRY).

#![forbid(unsafe_code)]

use tqc_core::UseCaseParams;
use tqc_model::{Model, UseCase};

/// An error resolving a use-case.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AtlasError {
    /// No canonical use-case (or more than one) is declared.
    NoCanonical,
    /// No use-case with the requested id.
    Unknown(String),
}

impl core::fmt::Display for AtlasError {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::NoCanonical => write!(f, "no unique canonical use-case in the model"),
            Self::Unknown(id) => write!(f, "no use-case with id `{id}`"),
        }
    }
}

impl std::error::Error for AtlasError {}

/// Parameters for a modelled use-case.
#[must_use]
pub fn to_params(uc: &UseCase) -> UseCaseParams {
    UseCaseParams::new(uc.scope, uc.modality, uc.context)
}

/// The canonical (Atlas) use-case parameters.
///
/// # Errors
/// [`AtlasError::NoCanonical`] if the model lacks a unique canonical use-case.
pub fn canonical(model: &Model) -> Result<UseCaseParams, AtlasError> {
    model
        .canonical_usecase()
        .map(to_params)
        .ok_or(AtlasError::NoCanonical)
}

/// The standard E8 Cartan matrix (Bourbaki), diagonal `2`, adjacency `-1`.
#[must_use]
pub fn e8_cartan() -> [[i64; 8]; 8] {
    [
        [2, 0, -1, 0, 0, 0, 0, 0],
        [0, 2, 0, -1, 0, 0, 0, 0],
        [-1, 0, 2, -1, 0, 0, 0, 0],
        [0, -1, -1, 2, -1, 0, 0, 0],
        [0, 0, 0, -1, 2, -1, 0, 0],
        [0, 0, 0, 0, -1, 2, -1, 0],
        [0, 0, 0, 0, 0, -1, 2, -1],
        [0, 0, 0, 0, 0, 0, -1, 2],
    ]
}

/// The E8 root-lattice Gram matrix `= scale × Cartan` (the Atlas PSD anchor uses `scale = 4`).
#[must_use]
pub fn e8_gram(scale: i64) -> Vec<Vec<i64>> {
    e8_cartan()
        .iter()
        .map(|row| row.iter().map(|&x| scale * x).collect())
        .collect()
}

/// Parameters for a use-case by id.
///
/// # Errors
/// [`AtlasError::Unknown`] if no such use-case exists.
pub fn by_id(model: &Model, id: &str) -> Result<UseCaseParams, AtlasError> {
    model
        .usecases
        .iter()
        .find(|u| u.id == id)
        .map(to_params)
        .ok_or_else(|| AtlasError::Unknown(id.to_owned()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_atlas_instance_is_4_3_8() {
        let model = Model::load().unwrap();
        let p = canonical(&model).unwrap();
        assert_eq!((p.scope, p.modality, p.context), (4, 3, 8));
        assert_eq!(p.class_count(), 96);
    }

    #[test]
    fn an_arbitrary_use_case_resolves() {
        let model = Model::load().unwrap();
        let p = by_id(&model, "demo-small").unwrap();
        assert_eq!(p.class_count(), 16);
        assert!(by_id(&model, "nope").is_err());
    }
}
