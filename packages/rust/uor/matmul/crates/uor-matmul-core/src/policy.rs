//! The three things a caller may choose (§5.5).
//!
//! None of them changes the value computed. [`EncodeMode`] chooses how the one
//! encode step presents that value in a narrower output type; [`Traversal`] and
//! [`Backend`] choose which instructions produce it. `CD-05` and `CB-*` assert
//! that the last two are invisible in the output bytes.

/// How the single encode step presents the exact accumulator in the output
/// type.
///
/// This is the only place in the library where information can be discarded, it
/// happens exactly once per output element, and the caller names it.
/// [`Wrapping`] and [`Saturating`] exist because a caller writing into an `i8`
/// output must say which they want; neither is a fallback, and both are exact
/// functions of the exact accumulator.
///
/// [`Wrapping`]: EncodeMode::Wrapping
/// [`Saturating`]: EncodeMode::Saturating
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default)]
pub enum EncodeMode {
    /// Round a fractional value to the nearest representable one, ties to even;
    /// saturate on range.
    ///
    /// This is the IEEE 754 default rounding mode, and it is what makes the
    /// float path's result *the correctly-rounded value of the exact sum*
    /// (§3.3). An integer accumulator holds an integer, so for that family this
    /// has nothing to round and behaves as [`Saturating`] on range.
    ///
    /// [`Saturating`]: EncodeMode::Saturating
    #[default]
    Nearest,
    /// Round a fractional value toward zero; saturate on range.
    TowardZero,
    /// Clamp to the output type's range; truncate a fractional value toward
    /// zero.
    Saturating,
    /// Reduce modulo the output type's range; truncate a fractional value
    /// toward zero.
    ///
    /// Written explicitly rather than left to a profile-dependent cast, so that
    /// a debug and a release binary are the same function (R5).
    Wrapping,
}

/// Which order the driver walks the output in.
///
/// A traversal is a factorization of the same identity, not a quality tier. The
/// output bytes are identical under every value (`CD-05`), so this is a
/// residency and locality choice and nothing else.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default)]
pub enum Traversal {
    /// One output element at a time, streaming both operands.
    ///
    /// The zero-scratch mode: it needs no packed panel and no decoded row, so
    /// it runs on a target whose RAM cannot hold either (§6.3, S13).
    OutputMajor,
    /// Cache-blocked panels, the shape a conventional GEMM uses.
    #[default]
    Blocked,
}

/// Which factorization of the identity to run.
///
/// [`Auto`] selects the fastest available one. It is not a fallback chain:
/// every entry computes the same value, so there is no ordering by quality,
/// only by speed. Selection cannot fail, because the portable backend is
/// always present and always correct (R6, R13).
///
/// [`Auto`]: Backend::Auto
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default)]
#[non_exhaustive]
pub enum Backend {
    /// The fastest factorization this host can run.
    #[default]
    Auto,
    /// The reference. Always present, always correct, never a fallback.
    Portable,
    /// x86-64 AVX2.
    Avx2,
    /// x86-64 AVX-512 with VNNI.
    Avx512Vnni,
    /// AArch64 NEON.
    Neon,
    /// AArch64 NEON with the ARMv8.2-A dot-product extension.
    NeonDotprod,
    /// WebAssembly SIMD128.
    WasmSimd128,
}

impl Backend {
    /// Every backend, in a stable order, for the differential tests.
    pub const ALL: [Backend; 6] = [
        Backend::Portable,
        Backend::Avx2,
        Backend::Avx512Vnni,
        Backend::Neon,
        Backend::NeonDotprod,
        Backend::WasmSimd128,
    ];

    /// The name used in test IDs and in reports.
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Auto => "auto",
            Self::Portable => "portable",
            Self::Avx2 => "avx2",
            Self::Avx512Vnni => "avx512vnni",
            Self::Neon => "neon",
            Self::NeonDotprod => "neondotprod",
            Self::WasmSimd128 => "wasmsimd128",
        }
    }
}
