//! Factorizations of one identity (§7).
//!
//! Every kernel here computes the same integer as
//! [`uor_matmul_core::dot_ref`]. They differ in how many instructions it takes,
//! and in nothing else. There is no quality hierarchy, no fallback chain, and
//! no backend that is "good enough": selecting one is a question about
//! *instructions*, never about which function is being computed (R13, C5).
//!
//! The portable kernel is the reference, not a last resort. It is never deleted
//! and never optimized (R6), and `CB-01` checks it against `dot_ref` on the
//! whole corpus while `CB-02` .. `CB-05` check every other backend against it.
//!
//! # Adding an ISA
//!
//! Add a module with a [`KernelSpec`] value and nothing else. The driver reads
//! `MR`, `NR`, `K_GROUP`, and the tile function through that value, so a new
//! ISA touches no driver code (S11).
//!
//! # `unsafe`
//!
//! This is the only crate in the workspace permitted `unsafe`, and every
//! `unsafe fn` carries a `# Safety` block naming its alignment, length, and
//! target-feature preconditions. The safe wrapper [`KernelSpec::mac_tile`]
//! checks the lengths, so a caller outside this crate cannot reach the
//! preconditions unsatisfied.

#![no_std]
#![deny(missing_docs)]
#![deny(clippy::undocumented_unsafe_blocks)]

// `std` is linked for two reasons and no others: runtime CPU feature detection
// behind the `std` feature (C1 --- an embedded build has nothing to detect and
// does not want it), and the heap the tests build panels on. Nothing in a
// shipped code path allocates (R7).
#[cfg(any(feature = "std", test))]
extern crate std;

pub mod isa;
pub mod spec;

pub use spec::{
    available_i16, available_i16_modular, available_i32_exact, available_i32_modular,
    available_i64_exact, available_i64_modular, available_i8, available_i8_narrow,
    available_reduce_i16, available_reduce_i16_modular, available_reduce_i32_exact,
    available_reduce_i32_modular, available_reduce_i64_exact, available_reduce_i64_modular,
    available_reduce_i8, choose, choose_for_rows, packed_slot, portable_i8, Factorization,
    KernelSpec, LaneLayout, MAX_TILE_LANES,
};
