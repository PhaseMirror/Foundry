//! The driver: the operation with a conventional GEMM face on it.
//!
//! [`gemm`] returns `()`. Not `Result<(), _>`, not `Result<(), Infallible>`:
//! `()`. The type signature carries the totality claim, and there is no second
//! place for a condition to arise, because every question a classical GEMM
//! answers with an error --- depth, magnitude, alignment, host capability ---
//! has an answer here for every input (R14, C6, `CT-05`).
//!
//! Non-existence of the requested object is reported once, at view
//! construction, by [`uor_matmul_core::Triple::new`] and [`CodedTriple::new`].
//! Those are the library's only two fallible constructors and they share the
//! same two failures.
//!
//! # One method
//!
//! Everything below is *decode, accumulate exactly, encode once* at a different
//! instantiation. The traversals differ in which order they walk the output and
//! how much working memory they use; they do not differ in what they compute,
//! and `CD-05` asserts it byte for byte.

#![no_std]
#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(clippy::disallowed_types)]

// The unit tests below build operands on the heap. That is a property of the
// tests, not of the library: nothing in the shipped code path can allocate,
// which is what `CA-01` witnesses with a counting allocator.
#[cfg(test)]
extern crate std;

pub mod coded;
pub mod collapse;
pub mod driver;
pub mod epilogue;
pub mod float;
pub mod kernel;
pub mod partition;
pub mod scratch;

pub use coded::{coded_gemm, CodedTriple};
pub use collapse::{gemm_collapsed, suggested_collapse_index, suggested_collapse_rows, Collapse};
pub use driver::{gemm, GemmOptions};
pub use epilogue::{Bias, Epilogue, Linear};
pub use float::{gemm_float, gemm_float_packed, SignedPlace};
pub use kernel::{gemm_packed, Kernelized};
pub use partition::{Partition, Tile};
pub use scratch::{suggested_accumulators, suggested_scratch, Scratch};
