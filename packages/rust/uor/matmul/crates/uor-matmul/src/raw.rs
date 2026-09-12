//! The raw-pointer face (`CS-05`).
//!
//! Signature-identical to `matrixmultiply`'s `sgemm` / `dgemm`, so that
//! existing numerical code can call this library without changing its call
//! sites. The bytes are the same bytes the safe API produces on the same
//! inputs, which is what `CS-05` asserts --- there is no separate path here,
//! only a different way of naming the same operands.
//!
//! What is *not* the same is the arithmetic, and that is the point (N1): the
//! float entry points below compute the correctly-rounded value of the exact
//! sum, not an order-dependent approximation of it.

use uor_matmul_core::{MatView, MatViewMut, Strides, Triple};
use uor_matmul_gemm::epilogue::{AbsorbPrior, ScaleExact};
use uor_matmul_gemm::{gemm_float, GemmOptions, Linear};

/// `C := alpha * A * B + beta * C`, over `f32`, computed exactly.
///
/// # Safety
///
/// The caller must uphold `matrixmultiply`'s contract, which this signature
/// mirrors:
///
/// - `a` points to a readable `m x k` matrix with strides `(rsa, csa)`.
/// - `b` points to a readable `k x n` matrix with strides `(rsb, csb)`.
/// - `c` points to a writable `m x n` matrix with strides `(rsc, csc)`.
/// - The three regions those strides describe are within allocated objects, and
///   `c` does not overlap `a` or `b`.
/// - `(rsc, csc)` do not map two output coordinates onto one cell. The safe API
///   reports that at view construction; here it is the caller's obligation,
///   because a raw pointer carries no shape to check it against.
///
/// # Panics
///
/// Never on the values in the buffers. `alpha` and `beta` are exact integer
/// scalars for the same reason the safe API's are: the epilogue evaluates in
/// the accumulator's width, which cannot overflow.
#[allow(clippy::too_many_arguments)]
pub unsafe fn sgemm(
    m: usize,
    k: usize,
    n: usize,
    alpha: i64,
    a: *const f32,
    rsa: isize,
    csa: isize,
    b: *const f32,
    rsb: isize,
    csb: isize,
    beta: i64,
    c: *mut f32,
    rsc: isize,
    csc: isize,
) {
    // SAFETY: the caller guaranteed each region is readable or writable at the
    // extent its strides describe, which is exactly what these slices span.
    unsafe { raw_gemm(m, k, n, alpha, a, rsa, csa, b, rsb, csb, beta, c, rsc, csc) }
}

/// `C := alpha * A * B + beta * C`, over `f64`, computed exactly.
///
/// # Safety
///
/// As [`sgemm`].
#[allow(clippy::too_many_arguments)]
pub unsafe fn dgemm(
    m: usize,
    k: usize,
    n: usize,
    alpha: i64,
    a: *const f64,
    rsa: isize,
    csa: isize,
    b: *const f64,
    rsb: isize,
    csb: isize,
    beta: i64,
    c: *mut f64,
    rsc: isize,
    csc: isize,
) {
    // SAFETY: as `sgemm`.
    unsafe { raw_gemm(m, k, n, alpha, a, rsa, csa, b, rsb, csb, beta, c, rsc, csc) }
}

/// The one body both entry points share.
///
/// # Safety
///
/// As [`sgemm`].
#[allow(clippy::too_many_arguments)]
unsafe fn raw_gemm<E>(
    m: usize,
    k: usize,
    n: usize,
    alpha: i64,
    a: *const E,
    rsa: isize,
    csa: isize,
    b: *const E,
    rsb: isize,
    csb: isize,
    beta: i64,
    c: *mut E,
    rsc: isize,
    csc: isize,
) where
    E: uor_matmul_core::FloatElement + uor_matmul_core::EncodeFrom<uor_matmul_core::AccOf<E>>,
    uor_matmul_core::AccOf<E>: ScaleExact + AbsorbPrior<E> + uor_matmul_gemm::float::SignedPlace,
{
    if m == 0 || n == 0 {
        return;
    }
    let sa = Strides { rs: rsa, cs: csa };
    let sb = Strides { rs: rsb, cs: csb };
    let sc = Strides { rs: rsc, cs: csc };

    // SAFETY: the caller guaranteed these extents are inside allocated objects
    // and that `c` is disjoint from `a` and `b`.
    let (a, b, c) = unsafe {
        (
            core::slice::from_raw_parts(a.offset(low(sa, m, k)), span(sa, m, k)),
            core::slice::from_raw_parts(b.offset(low(sb, k, n)), span(sb, k, n)),
            core::slice::from_raw_parts_mut(c.offset(low(sc, m, n)), span(sc, m, n)),
        )
    };

    let Some(av) = MatView::new(a, m, k, sa) else {
        return;
    };
    let Some(bv) = MatView::new(b, k, n, sb) else {
        return;
    };
    let Some(cv) = MatViewMut::new(c, m, n, sc) else {
        return;
    };
    let Ok(mut t) = Triple::new(av, bv, cv) else {
        return;
    };
    gemm_float(&mut t, &Linear { alpha, beta }, GemmOptions::default());
}

/// The lowest offset an `rows x cols` strided view reaches, as a negative
/// adjustment to the caller's base pointer.
const fn low(s: Strides, rows: usize, cols: usize) -> isize {
    if rows == 0 || cols == 0 {
        return 0;
    }
    let r = if s.rs < 0 {
        (rows as isize - 1) * s.rs
    } else {
        0
    };
    let c = if s.cs < 0 {
        (cols as isize - 1) * s.cs
    } else {
        0
    };
    r + c
}

/// The number of elements between the lowest and highest offsets, inclusive.
const fn span(s: Strides, rows: usize, cols: usize) -> usize {
    if rows == 0 || cols == 0 {
        return 0;
    }
    let r = (rows as isize - 1) * s.rs;
    let c = (cols as isize - 1) * s.cs;
    let hi = (if r > 0 { r } else { 0 }) + (if c > 0 { c } else { 0 });
    (hi - low(s, rows, cols)) as usize + 1
}
