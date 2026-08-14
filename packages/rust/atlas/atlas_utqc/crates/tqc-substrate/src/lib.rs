//! The substrate facade: the single place that imports the holospaces substrate and the
//! uor-addr composition operations.
//!
//! It exposes the holospaces content-addressing surface (κ-labels) and the realized uor-addr
//! composition (`g2`), dual (`f4`), and the `e6`/`e7`/`e8` structure — on
//! all five σ-axes. Keeping every substrate symbol behind this one crate means a substrate API
//! or revision change has a blast radius of exactly one crate; the math crates stay
//! substrate-free and offline-testable.

#![forbid(unsafe_code)]

/// The hash-axis selector from holospaces (Blake3 / Sha256 / Sha3_256 / Keccak256 / Sha512).
pub use holospaces::Axis;
/// The content-addressing label type from holospaces (`KappaLabel71`).
pub use holospaces::Kappa;

use uor_addr::codemodule;
use uor_addr::composition as comp;

/// Dynamic execution of gates as `.holo` artifacts.
pub mod holo;
pub use holo::execute_holo_gate;

/// Address canonical bytes to a content κ on the default (Blake3) axis (holospaces).
#[must_use]
pub fn kappa(canonical_bytes: &[u8]) -> Kappa {
    holospaces::address(canonical_bytes)
}

/// Verify that bytes re-derive to an expected κ (Law L5: re-derive, never trust).
///
/// # Errors
/// Returns the formatted axis error if the κ axis is unknown.
pub fn verify(canonical_bytes: &[u8], expected: &Kappa) -> Result<bool, String> {
    holospaces::verify(canonical_bytes, expected).map_err(fmt_err)
}

/// A σ-axis for the uor-addr composition operations.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CompositionAxis {
    /// SHA-256 (NIST FIPS 180-4).
    Sha256,
    /// BLAKE3.
    Blake3,
    /// SHA3-256 (NIST FIPS 202).
    Sha3_256,
    /// Keccak-256.
    Keccak256,
    /// SHA-512 (NIST FIPS 180-4).
    Sha512,
}

/// All five composition σ-axes (for "no narrowing" coverage).
pub const COMPOSITION_AXES: [CompositionAxis; 5] = [
    CompositionAxis::Sha256,
    CompositionAxis::Blake3,
    CompositionAxis::Sha3_256,
    CompositionAxis::Keccak256,
    CompositionAxis::Sha512,
];

impl CompositionAxis {
    /// The σ-axis token.
    #[must_use]
    pub fn token(self) -> &'static str {
        match self {
            Self::Sha256 => "sha256",
            Self::Blake3 => "blake3",
            Self::Sha3_256 => "sha3-256",
            Self::Keccak256 => "keccak256",
            Self::Sha512 => "sha512",
        }
    }
}

fn fmt_err<E: core::fmt::Debug>(e: E) -> String {
    format!("{e:?}")
}

/// Mint a label κ-string from canonical bytes on the given σ-axis.
///
/// # Errors
/// Returns the formatted addressing error.
pub fn label(axis: CompositionAxis, bytes: &[u8]) -> Result<String, String> {
    Ok(match axis {
        CompositionAxis::Sha256 => codemodule::address(bytes)
            .map_err(fmt_err)?
            .address
            .as_str()
            .to_owned(),
        CompositionAxis::Blake3 => codemodule::address_blake3(bytes)
            .map_err(fmt_err)?
            .address
            .as_str()
            .to_owned(),
        CompositionAxis::Sha3_256 => codemodule::address_sha3_256(bytes)
            .map_err(fmt_err)?
            .address
            .as_str()
            .to_owned(),
        CompositionAxis::Keccak256 => codemodule::address_keccak256(bytes)
            .map_err(fmt_err)?
            .address
            .as_str()
            .to_owned(),
        CompositionAxis::Sha512 => codemodule::address_sha512(bytes)
            .map_err(fmt_err)?
            .address
            .as_str()
            .to_owned(),
    })
}

/// Composition: the CS-G2 commutative product of two labels, returned as a κ-string.
///
/// # Errors
/// Returns the formatted addressing/composition error.
pub fn fuse(axis: CompositionAxis, a: &[u8], b: &[u8]) -> Result<String, String> {
    Ok(match axis {
        CompositionAxis::Sha256 => {
            let (la, lb) = (
                codemodule::address(a).map_err(fmt_err)?.address,
                codemodule::address(b).map_err(fmt_err)?.address,
            );
            comp::compose_g2_product(&la, &lb)
                .map_err(fmt_err)?
                .address
                .as_str()
                .to_owned()
        }
        CompositionAxis::Blake3 => {
            let (la, lb) = (
                codemodule::address_blake3(a).map_err(fmt_err)?.address,
                codemodule::address_blake3(b).map_err(fmt_err)?.address,
            );
            comp::compose_g2_product_blake3(&la, &lb)
                .map_err(fmt_err)?
                .address
                .as_str()
                .to_owned()
        }
        CompositionAxis::Sha3_256 => {
            let (la, lb) = (
                codemodule::address_sha3_256(a).map_err(fmt_err)?.address,
                codemodule::address_sha3_256(b).map_err(fmt_err)?.address,
            );
            comp::compose_g2_product_sha3_256(&la, &lb)
                .map_err(fmt_err)?
                .address
                .as_str()
                .to_owned()
        }
        CompositionAxis::Keccak256 => {
            let (la, lb) = (
                codemodule::address_keccak256(a).map_err(fmt_err)?.address,
                codemodule::address_keccak256(b).map_err(fmt_err)?.address,
            );
            comp::compose_g2_product_keccak256(&la, &lb)
                .map_err(fmt_err)?
                .address
                .as_str()
                .to_owned()
        }
        CompositionAxis::Sha512 => {
            let (la, lb) = (
                codemodule::address_sha512(a).map_err(fmt_err)?.address,
                codemodule::address_sha512(b).map_err(fmt_err)?.address,
            );
            comp::compose_g2_product_sha512(&la, &lb)
                .map_err(fmt_err)?
                .address
                .as_str()
                .to_owned()
        }
    })
}

/// Generate a unary-composition facade function across all five σ-axes.
macro_rules! unary_op {
    ($(#[$m:meta])* $name:ident, $s256:path, $blake:path, $sha3:path, $keccak:path, $sha512:path) => {
        $(#[$m])*
        ///
        /// # Errors
        /// Returns the formatted addressing/composition error.
        pub fn $name(axis: CompositionAxis, bytes: &[u8]) -> Result<String, String> {
            Ok(match axis {
                CompositionAxis::Sha256 => { let l = codemodule::address(bytes).map_err(fmt_err)?.address; $s256(&l).map_err(fmt_err)?.address.as_str().to_owned() }
                CompositionAxis::Blake3 => { let l = codemodule::address_blake3(bytes).map_err(fmt_err)?.address; $blake(&l).map_err(fmt_err)?.address.as_str().to_owned() }
                CompositionAxis::Sha3_256 => { let l = codemodule::address_sha3_256(bytes).map_err(fmt_err)?.address; $sha3(&l).map_err(fmt_err)?.address.as_str().to_owned() }
                CompositionAxis::Keccak256 => { let l = codemodule::address_keccak256(bytes).map_err(fmt_err)?.address; $keccak(&l).map_err(fmt_err)?.address.as_str().to_owned() }
                CompositionAxis::Sha512 => { let l = codemodule::address_sha512(bytes).map_err(fmt_err)?.address; $sha512(&l).map_err(fmt_err)?.address.as_str().to_owned() }
            })
        }
    };
}

unary_op!(
    /// Dual / conjugation: the CS-F4 ±mirror involution of a label.
    dual,
    comp::compose_f4_quotient,
    comp::compose_f4_quotient_blake3,
    comp::compose_f4_quotient_sha3_256,
    comp::compose_f4_quotient_keccak256,
    comp::compose_f4_quotient_sha512
);
unary_op!(
    /// CS-E6 degree-partition filtration.
    grade_e6,
    comp::compose_e6_filtration,
    comp::compose_e6_filtration_blake3,
    comp::compose_e6_filtration_sha3_256,
    comp::compose_e6_filtration_keccak256,
    comp::compose_e6_filtration_sha512
);
unary_op!(
    /// CS-E7 S4-orbit augmentation.
    orbit_e7,
    comp::compose_e7_augmentation,
    comp::compose_e7_augmentation_blake3,
    comp::compose_e7_augmentation_sha3_256,
    comp::compose_e7_augmentation_keccak256,
    comp::compose_e7_augmentation_sha512
);
unary_op!(
    /// CS-E8 direct embedding.
    embed_e8,
    comp::compose_e8_embedding,
    comp::compose_e8_embedding_blake3,
    comp::compose_e8_embedding_sha3_256,
    comp::compose_e8_embedding_keccak256,
    comp::compose_e8_embedding_sha512
);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kappa_is_stable_and_reverifies() {
        let bytes = b"the same content has the same address";
        let k = kappa(bytes);
        assert_eq!(k, kappa(bytes), "addressing must be deterministic");
        assert_eq!(
            verify(bytes, &k),
            Ok(true),
            "content must re-derive to its kappa"
        );
        assert_ne!(k, kappa(b"different content"));
    }

    #[test]
    fn composition_is_commutative_on_every_axis() {
        for axis in COMPOSITION_AXES {
            let a = b"anyon-a";
            let b = b"anyon-b";
            assert_eq!(
                fuse(axis, a, b).unwrap(),
                fuse(axis, b, a).unwrap(),
                "g2 commutative on {}",
                axis.token()
            );
        }
    }

    #[test]
    fn dual_is_involutive_via_label_roundtrip() {
        // f4 is the ±mirror; applying it is deterministic on every axis.
        for axis in COMPOSITION_AXES {
            let once = dual(axis, b"anyon-a").unwrap();
            let again = dual(axis, b"anyon-a").unwrap();
            assert_eq!(once, again);
        }
    }
}
