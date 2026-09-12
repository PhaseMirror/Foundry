//! Codecs: the *decode* half of decode-accumulate-encode (§6).
//!
//! A weight tier is a codec `d : Code -> Alphabet(B)`. The codec is not an
//! argument of the arithmetic, which is why the same result survives a change
//! of tier, a change of reduction schedule, and a change of substrate. That is
//! `CL-MM01`, cited from upstream and reproduced here as a `some-true` claim;
//! `CK-02` and `CK-05` are the evidence that these types realize it.
//!
//! Every tier in this crate is an *instantiation* of one trait, not a special
//! case. [`Codec::BLOCK`] unifies the scalar and block cases exactly as the
//! upstream `scalar_eq_block` does: a scalar codec is the block codec of its
//! singletons, so no identity and no kernel is written twice.
//!
//! Every table is **borrowed**, never owned: a codebook lives in the caller's
//! `static`, in flash, or in a `&'static` produced by `include_bytes!`. On an
//! embedded target the E8 table is 2048 bytes of read-only memory and the codec
//! is a pointer (R7, C1).

#![no_std]
#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(clippy::disallowed_types)]

pub mod codecs;
pub mod e8;
pub mod kappa;
pub mod matrix;
pub mod tier;

pub use codecs::{Book, Grid, Identity, Offset, Packed, Runs, Transcode};
pub use e8::{e8_codec, e8_table, E8_I8};
pub use matrix::CodedMatrix;
pub use tier::{Codec, TierId};

pub use kappa::{KappaError, Manifest};
