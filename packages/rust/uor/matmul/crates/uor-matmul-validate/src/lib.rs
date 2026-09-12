//! External validation (§3.3-oracles, §10).
//!
//! This crate is dev and CI infrastructure. It is never a dependency of a
//! shipped crate, it may use `std` and `alloc`, and every oracle lives behind a
//! feature so that a validation run declares which outside witnesses it called.
//!
//! # What agreement means here (§3.4)
//!
//! **Integer oracles: bit-identical everywhere, including past their own
//! ceiling.** Reduction modulo `2^w` is a ring homomorphism, so reducing the
//! exact sum once at the end equals reducing at every step.
//! [`EncodeMode::Wrapping`] into a `w`-bit output therefore reproduces a
//! classical wrapping accumulator's bytes exactly, at every depth, including
//! depths where that accumulator has wrapped many times. There is no region
//! where an integer oracle and this library are permitted to differ, and
//! `CX-01..04` asserts byte equality over the whole corpus with **no
//! exemption**.
//!
//! A caller who wants the mathematical value rather than the wrapped one asks
//! for [`EncodeMode::Saturating`] or reads the accumulator directly. Both
//! answers come from one accumulation, which is the practical payoff of holding
//! the exact value.
//!
//! **Float oracles: agreement is not expected and deviation is the
//! measurement.** A classical `f32` GEMM computes an order-dependent
//! approximation; we compute the correctly-rounded value of the exact sum.
//! Where they differ the harness records [`Agreement::OracleInexact`] with the
//! deviation in ulps. That status never fails the gate and always appears in
//! the report.
//!
//! The inversion is the point: we hold the exact value, so the oracle's
//! deviation is measurable, and "how far off is this library at k = 4096"
//! becomes a number we publish rather than a difference we explain away.
//!
//! # A note on the crate oracles and overflow
//!
//! `ndarray` and `nalgebra` accumulate `i32` in an `i32`, so under a
//! debug-assertions build they *panic* rather than wrap once the sum leaves
//! `i32`. That is a property of those crates, not of the claim: the claim is
//! about bytes, and bytes are what a wrapping accumulator produces.
//! [`reference_wrapping_i32`] is therefore the oracle for the deep cases --- an
//! independently written classical accumulator that wraps explicitly --- and
//! the crates corroborate it over every case where they are defined.

use uor_matmul::prelude::*;
use uor_matmul_core::EncodeMode;

pub mod corpus;
pub mod counting;
pub mod oracle;
pub mod scaling;

pub use corpus::{Case, Corpus};
pub use counting::Counting;
pub use oracle::{Agreement, Oracle};

/// Compute a product with this library, row-major, `beta = 0`, under `mode`.
///
/// The shape every oracle adapter is compared against. Deliberately the most
/// boring possible call: the point of a differential test is that the two sides
/// disagree about nothing except their arithmetic.
pub fn ours_i8_i32(m: usize, k: usize, n: usize, a: &[i8], b: &[i8], mode: EncodeMode) -> Vec<i32> {
    let mut c = vec![0i32; m * n];
    {
        let av = MatView::row_major(as_alphabet_full(a), m, k).expect("A fits its buffer");
        let bv = MatView::row_major(as_alphabet_full(b), k, n).expect("B fits its buffer");
        let cv = MatViewMut::row_major(&mut c, m, n).expect("C fits its buffer");
        let mut t = Triple::new(av, bv, cv).expect("the product exists");
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions {
                encode: mode,
                ..Default::default()
            },
            &mut Scratch::none(),
        );
    }
    c
}

/// The same product with `i32` operands, for the oracles that only speak `i32`.
pub fn ours_i32_i32(
    m: usize,
    k: usize,
    n: usize,
    a: &[i32],
    b: &[i32],
    mode: EncodeMode,
) -> Vec<i32> {
    let mut c = vec![0i32; m * n];
    {
        let av = MatView::row_major(as_alphabet_full(a), m, k).expect("A fits its buffer");
        let bv = MatView::row_major(as_alphabet_full(b), k, n).expect("B fits its buffer");
        let cv = MatViewMut::row_major(&mut c, m, n).expect("C fits its buffer");
        let mut t = Triple::new(av, bv, cv).expect("the product exists");
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions {
                encode: mode,
                ..Default::default()
            },
            &mut Scratch::none(),
        );
    }
    c
}

/// A classical `i32` GEMM that wraps, written independently of the library.
///
/// This is the oracle for §3.4's claim, and it is deliberately the dumbest
/// possible implementation: three loops and a `wrapping_add`. If our
/// [`EncodeMode::Wrapping`] output ever differs from this at any depth, the
/// ring-homomorphism argument is wrong, or the library does not implement it.
///
/// It exists because the crate oracles panic rather than wrap under a
/// debug-assertions build, so they cannot witness the deep half of the claim.
pub fn reference_wrapping_i32(m: usize, k: usize, n: usize, a: &[i32], b: &[i32]) -> Vec<i32> {
    let mut c = vec![0i32; m * n];
    for i in 0..m {
        for j in 0..n {
            let mut acc: i32 = 0;
            for p in 0..k {
                acc = acc.wrapping_add(a[i * k + p].wrapping_mul(b[p * n + j]));
            }
            c[i * n + j] = acc;
        }
    }
    c
}

/// Run the float driver with the overwriting epilogue.
///
/// A shim so the scaling module can time the float path without repeating the
/// epilogue and options at every call site.
pub fn gemm_float_for_scaling<E, O>(triple: &mut Triple<'_, '_, '_, E, O>)
where
    E: uor_matmul_core::FloatElement,
    O: uor_matmul_core::EncodeFrom<uor_matmul_core::AccOf<E>>,
    uor_matmul_core::AccOf<E>: uor_matmul_gemm::epilogue::ScaleExact
        + uor_matmul_gemm::epilogue::AbsorbPrior<O>
        + uor_matmul_gemm::SignedPlace,
    O: Copy,
{
    uor_matmul::gemm_float(triple, &Linear::OVERWRITE, GemmOptions::default());
}

/// Byte equality on the output buffer --- not `==` on floats, and not an
/// epsilon (§3.3-oracles).
///
/// On a mismatch the report names the linear index and both values, so a red
/// differential test says *which element* rather than *something differs*.
pub fn bytes_equal<T: bytemuck::Pod + Copy + core::fmt::Debug + PartialEq>(
    ours: &[T],
    theirs: &[T],
) -> Result<(), String> {
    if ours.len() != theirs.len() {
        return Err(format!("length {} vs {}", ours.len(), theirs.len()));
    }
    let a: &[u8] = bytemuck::cast_slice(ours);
    let b: &[u8] = bytemuck::cast_slice(theirs);
    if a == b {
        return Ok(());
    }
    for (i, (x, y)) in ours.iter().zip(theirs).enumerate() {
        if x != y {
            return Err(format!("index {i}: ours {x:?}, theirs {y:?}"));
        }
    }
    Err("buffers differ in their bytes but not in their values".to_string())
}

/// Does an `i32`-accumulating oracle stay inside `i32` for this case?
///
/// **Not** a question about whether it may differ from us --- under
/// [`EncodeMode::Wrapping`] it may not, at any depth (§3.4). It is a question
/// about whether the *crate* oracles are defined: `ndarray` and `nalgebra`
/// panic on overflow under a debug-assertions build, so past this point the
/// witness is [`reference_wrapping_i32`] instead.
pub fn oracle_stays_in_range(k: usize, bound_a: u128, bound_b: u128) -> bool {
    let Some(per_step) = bound_a.checked_mul(bound_b) else {
        return false;
    };
    let Some(worst) = per_step.checked_mul(k as u128) else {
        return false;
    };
    worst <= i32::MAX as u128
}
