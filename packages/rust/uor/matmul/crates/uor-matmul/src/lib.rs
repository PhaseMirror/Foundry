//! Exact matmul on coded operands.
//!
//! > Decode the code, accumulate exactly, encode once.
//!
//! Every entry point in this library is that sentence at a different
//! instantiation. There is no fast path and no careful path, no SIMD kernel and
//! no scalar fallback, and nothing held in reserve for hard cases --- because
//! the exact accumulation has no hard cases.
//!
//! # What it computes
//!
//! For integer operands, the exact value of `sum a_i * d(w_i)`, encoded once
//! into the caller's output type. Byte-identical to any external integer GEMM
//! wherever that library is also exact --- and where it is not, the difference
//! is *its* error, which this library is positioned to measure (§3.4).
//!
//! # What it never does
//!
//! - Allocate. There is no `alloc` dependency in any shipped crate. Working
//!   memory is offered by the caller, and offering none is a supported choice.
//! - Fail. [`gemm`] returns `()`. The only reportable condition in the whole
//!   library is that the requested object does not exist --- non-conforming
//!   shapes, or an output whose strides map two coordinates onto one cell ---
//!   and it is reported at view construction, before any arithmetic is named.
//! - Impose a ceiling. There is no maximum `k`, no maximum magnitude, no shape
//!   restriction, and no alignment requirement. The accumulator's width is a
//!   compile-time function of the element type, sized against the largest `k`
//!   the machine can address, so overflow is unreachable rather than guarded.
//!
//! # Quick start
//!
//! ```
//! use uor_matmul::prelude::*;
//!
//! let a = [1i8, 2, 3, 4];
//! let b = [5i8, 6, 7, 8];
//! let mut c = [0i32; 4];
//!
//! let av = MatView::row_major(as_alphabet_full(&a), 2, 2).unwrap();
//! let bv = MatView::row_major(as_alphabet_full(&b), 2, 2).unwrap();
//! let cv = MatViewMut::row_major(&mut c, 2, 2).unwrap();
//!
//! // The one fallible step: does this product exist?
//! let mut t = Triple::new(av, bv, cv).unwrap();
//!
//! // The operation itself cannot fail, so it returns `()`.
//! gemm(&mut t, &Linear::OVERWRITE, GemmOptions::default(), &mut Scratch::none());
//! assert_eq!(c, [19, 22, 43, 50]);
//! ```
//!
//! # Non-goals
//!
//! See `README.md`, which states N1--N5 normatively. In brief: this library
//! does not reproduce another library's float rounding (it computes the
//! correctly-rounded value of the exact sum instead), contains no proof
//! development (the formalization is upstream and cited), makes no quality
//! claim about any codebook, does not aim to beat `matrixmultiply` on f32
//! throughput, and has no second method for any case however hard.

//! # A note on the `std` feature
//!
//! `std` buys exactly two things: runtime CPU feature detection, and
//! `core::error::Error` impls. Nothing in the numerical path changes when it is
//! off --- the bytes are identical, which `CA-02` asserts across targets.
//!
//! What *does* change is which kernel runs. Without `std` there is nothing to
//! detect, so a backend is available only if the *build* declared its target
//! feature. A hosted build that forgets `std` and does not set
//! `-C target-cpu=native` therefore runs the portable kernel, correctly and
//! several times slower than the machine can manage. On an embedded target
//! that is exactly right, because there is nothing to detect; on a server it is
//! almost certainly not what was meant.
//!
//! `uor_matmul::kernels::available_i8()` reports which kernels a build can
//! actually run, and it is worth printing once if throughput is surprising.

#![no_std]
// The facade carries the raw-pointer face (`CS-05`), whose contract is a
// caller obligation rather than a checkable property, so this crate cannot
// `forbid(unsafe_code)` the way the numerical crates do. Every `unsafe fn`
// below names its obligations, and the safe API is the one everything else
// uses.
#![deny(unsafe_op_in_unsafe_fn)]
#![deny(missing_docs)]

pub mod raw;

pub use uor_matmul_codec as codec;
pub use uor_matmul_core as core_types;
pub use uor_matmul_gemm as driver;

pub use uor_matmul_codec::{
    Book, Codec, CodedMatrix, Grid, Identity, Offset, Packed, Runs, TierId, Transcode,
};
pub use uor_matmul_core::{
    acc_bits, as_alphabet, as_alphabet_full, dot_ref, narrow_cap_for, observe_bound, AccOf,
    Accumulator, Alphabet, Backend, Bnd, Bound, Complex, Decoded, Element, EncodeMode,
    FloatElement, Full, IntegerElement, MatView, MatViewMut, NotAProduct, PackedCode, Shape,
    Strides, Traversal, Triple,
};
pub use uor_matmul_gemm::{
    coded_gemm, gemm, gemm_collapsed, gemm_float, gemm_float_packed, gemm_packed,
    suggested_accumulators, suggested_collapse_index, suggested_collapse_rows, suggested_scratch,
    Bias, CodedTriple, Collapse, Epilogue, GemmOptions, Kernelized, Linear, Partition, Scratch,
    SignedPlace, Tile,
};
pub use uor_matmul_kernels as kernels;

/// Everything a caller ordinarily needs, in one `use`.
pub mod prelude {
    pub use uor_matmul_codec::{Codec, CodedMatrix, Grid, Identity};
    pub use uor_matmul_core::{
        as_alphabet, as_alphabet_full, Alphabet, Bnd, EncodeMode, Full, IntegerElement, MatView,
        MatViewMut, Strides, Triple,
    };
    pub use uor_matmul_gemm::{gemm, GemmOptions, Linear, Scratch};
}

/// The canonical instantiation: `(i8, 127)`, the tier with the most instruction
/// support and the most external oracles.
///
/// Nothing else privileges it. A caller who instantiates `(i16, 4095)` never
/// sees any numeral from this module, and the arithmetic they get is the same
/// arithmetic (§1.1).
pub mod w8a8 {
    use uor_matmul_core::{Alphabet, Bnd};

    /// The W8A8 alphabet bound.
    pub type B = Bnd<{ uor_matmul_core::generated::instantiation::W8A8_BOUND }>;

    /// A W8A8 activation or weight.
    pub type Elem = Alphabet<i8, B>;
}
