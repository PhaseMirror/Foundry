//! The complete error surface of the library (§5.5, R14, C6).
//!
//! Two variants, both meaning *the requested object does not exist*. Neither
//! can be caused by the size, depth, magnitude, or distribution of the data,
//! nor by the host. They are reported once, at view construction, before any
//! arithmetic is named --- which is why `gemm` returns `()` and not a `Result`.
//!
//! # What is deliberately absent, and why each absence is load-bearing
//!
//! | Absent | Why |
//! | --- | --- |
//! | a depth or size limit | the accumulator cannot overflow (§3.2) |
//! | an alphabet violation | every value of `E` is in `Alphabet<E, Full<E>>` |
//! | a scratch error | scratch is an offer; too little means a different traversal, not a failure |
//! | an accumulator-policy error | there is no policy |
//! | an epilogue capacity error | the epilogue evaluates in the accumulator's width, which cannot overflow |
//! | a backend-unavailable error | the portable backend is always present and always correct |
//! | a non-finite-input error | non-finite floats are codes with IEEE-defined behaviour (§3.3) |

/// The requested product does not exist.
///
/// Not "the library declined", and not "the host could not". There is no
/// assignment of values to the output that satisfies the definition of a matrix
/// product for these arguments, so there is nothing for any implementation to
/// return.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[non_exhaustive]
pub enum NotAProduct {
    /// A is `m x k` and B is `p x n` with `k != p`, so `A*B` is undefined.
    Nonconformant {
        /// A's shape, as `(rows, cols)`.
        a: (usize, usize),
        /// B's shape, as `(rows, cols)`.
        b: (usize, usize),
    },
    /// The output strides make two output coordinates the same memory cell, so
    /// no assignment satisfies the definition.
    ///
    /// A zero stride on an *input* is fine and is supported (S7): reading the
    /// same value twice is well defined. A zero or colliding stride on the
    /// *output* is not, because two distinct results would have to occupy one
    /// cell.
    OutputAliasesItself {
        /// Output rows.
        m: usize,
        /// Output columns.
        n: usize,
        /// Output row stride.
        rs: isize,
        /// Output column stride.
        cs: isize,
    },
}

impl core::fmt::Display for NotAProduct {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Nonconformant { a, b } => write!(
                f,
                "no such product: A is {}x{} and B is {}x{}, so A*B is undefined",
                a.0, a.1, b.0, b.1
            ),
            Self::OutputAliasesItself { m, n, rs, cs } => write!(
                f,
                "no such product: a {m}x{n} output with row stride {rs} and column \
                 stride {cs} maps two coordinates onto one cell, so no assignment \
                 satisfies the definition"
            ),
        }
    }
}
