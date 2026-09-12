//! The parametric core of `uor-matmul`.
//!
//! One method, used everywhere: **decode, accumulate exactly, encode once.**
//! Every entry point in the library is that sentence at a different
//! instantiation. There is no fast path and no careful path, no SIMD kernel and
//! no scalar fallback, and nothing held in reserve for cases the library finds
//! hard --- because the exact accumulation has no hard cases (R13, C5).
//!
//! # What this crate contains
//!
//! - [`Alphabet`], the working alphabet, parametric in its element type and its
//!   bound. The bound is a *declaration about the data*, not a restriction on
//!   it: [`Full`] admits every value of the element type, so no representable
//!   value is ever outside its own alphabet (§5.2).
//! - [`Accumulator`], sized so that overflow is unreachable. Not a ladder, not
//!   a policy, not a runtime choice: the width is a compile-time function of
//!   the element type alone, evaluated against the largest `k` the machine can
//!   address (§3.2).
//! - [`dot_ref`], the reference accumulation. Never optimized, never removed
//!   (R6); every backend is differentially tested against it.
//! - [`Triple`], where the only two reportable conditions in the whole library
//!   are reported --- once, at view construction, before any arithmetic is
//!   named (R14, C6).
//!
//! # What this crate does not contain
//!
//! No `f32` or `f64` token appears anywhere in it (R2). A float is a code, and
//! its codec --- the decode from a bit pattern to the exact dyadic rational it
//! names --- lives in `uor-matmul-float`. The accumulator that receives the
//! products of that decode, [`Complete`], is here, because it is a fixed-point
//! integer register and contains no float arithmetic. The library never
//! executes a float addition (§3.3, `CU-01`).
//!
//! No allocation happens here, and none is possible: there is no `alloc`
//! dependency (R7, C1).

#![no_std]
#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(clippy::disallowed_types)]

pub mod acc;
pub mod alphabet;
pub mod bounds;
pub mod dot;
pub mod error;
pub mod generated;
pub mod layout;
pub mod policy;

pub use acc::{AccOf, Accumulator, Complete, EncodeFrom, Limbs};
pub use alphabet::{
    as_alphabet, as_alphabet_full, as_alphabet_full_mut, observe_bound, Alphabet, Bnd, Bound,
    Complex, ComplexAcc, Decoded, Element, FloatElement, Full, IntegerElement, ObservedBound,
    PackedCode, NARROW_CAP,
};
pub use bounds::{acc_bits, narrow_cap_for, NARROW_CAPS};
pub use dot::{dot_instrumented, dot_ref, dot_wide};
pub use error::NotAProduct;
pub use layout::{MatView, MatViewMut, Shape, Strides, Triple, Walk};
pub use policy::{Backend, EncodeMode, Traversal};
