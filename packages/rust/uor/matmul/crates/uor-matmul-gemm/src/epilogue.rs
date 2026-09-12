//! The single encode step, and what a caller may fold into it (§5.5, S9).
//!
//! An epilogue is the *only* place in the library where information can be
//! discarded, and it runs exactly once per output element. Everything upstream
//! of it is exact.
//!
//! Requantization is **encoding**: the inverse of the codec's decode, into a
//! coarser alphabet. It is exact integer throughout, and it never consults a
//! platform rounding mode.

use uor_matmul_core::{
    AccOf, Accumulator, Complete, Element, EncodeFrom, EncodeMode, FloatElement, Limbs,
};

/// What to do with a finished accumulator and the value already in `C`.
///
/// The trait takes the *exact* accumulator, not a narrowed one, so a user
/// epilogue sees the same value the library does and cannot be handed a
/// pre-rounded input.
pub trait Epilogue<E: Element, O> {
    /// Produce the output element.
    ///
    /// `prior` is the value already in `C`, and is `None` exactly when the
    /// driver did not read `C` --- which is the case whenever the epilogue
    /// declares [`Epilogue::READS_C`] false, so that an uninitialised output
    /// buffer is admissible (`CS-04`).
    fn finish(&self, acc: AccOf<E>, prior: Option<O>, mode: EncodeMode) -> O;

    /// Does this epilogue read the existing contents of `C`?
    ///
    /// `false` lets the driver skip the read entirely, which is what makes
    /// `beta = 0` mean *overwrite* rather than *multiply by zero* --- the
    /// difference matters when `C` holds uninitialised memory or a signalling
    /// pattern. It is a method rather than a const because for [`Linear`] the
    /// answer is a property of `beta`, which is a value.
    fn reads_c(&self) -> bool {
        true
    }
}

/// `C := alpha * A*B + beta * C`, the BLAS-shaped epilogue.
///
/// `alpha` and `beta` are exact integer scalars. They are applied inside the
/// single encode step, in the accumulator's width, so no intermediate is ever
/// rounded and the whole expression is evaluated exactly whenever its value is
/// representable in `O`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Linear {
    /// Scales the product.
    pub alpha: i64,
    /// Scales the value already in `C`.
    pub beta: i64,
}

impl Linear {
    /// `C := A*B`, overwriting. The common case, and the one that never reads
    /// the output buffer.
    pub const OVERWRITE: Self = Self { alpha: 1, beta: 0 };

    /// `C := A*B + C`.
    pub const ACCUMULATE: Self = Self { alpha: 1, beta: 1 };
}

impl<E, O> Epilogue<E, O> for Linear
where
    E: Element,
    O: EncodeFrom<AccOf<E>>,
    AccOf<E>: ScaleExact + AbsorbPrior<O>,
{
    fn reads_c(&self) -> bool {
        // `beta == 0` overwrites `C` without reading it, which is what makes an
        // uninitialised output buffer admissible (`CS-04`).
        self.beta != 0
    }

    fn finish(&self, acc: AccOf<E>, prior: Option<O>, mode: EncodeMode) -> O {
        let scaled = acc.scale_exact(self.alpha);
        let total = match prior {
            // `beta == 0` contributes nothing and the driver did not read `C`.
            None => scaled,
            Some(c) => {
                if self.beta == 0 {
                    scaled
                } else {
                    scaled.combine(AccOf::<E>::of_prior(c).scale_exact(self.beta))
                }
            }
        };
        O::encode_from(total, mode)
    }
}

/// `C := A*B + bias[j]`, the epilogue every quantized inference stack wants.
///
/// The bias is added in the accumulator's width, before the single encode step,
/// so a bias large enough to matter is not rounded twice.
#[derive(Clone, Copy, Debug)]
pub struct Bias<'a> {
    /// One entry per output column.
    pub values: &'a [i64],
}

impl<E, O> Epilogue<E, O> for (Bias<'_>, usize)
where
    E: Element,
    O: EncodeFrom<AccOf<E>>,
    AccOf<E>: ScaleExact,
{
    fn reads_c(&self) -> bool {
        false
    }

    fn finish(&self, acc: AccOf<E>, _prior: Option<O>, mode: EncodeMode) -> O {
        let (bias, column) = *self;
        let b = bias.values.get(column).copied().unwrap_or(0);
        O::encode_from(acc.combine(AccOf::<E>::from_i128(b as i128)), mode)
    }
}

/// How the value already in `C` enters the accumulation.
///
/// `beta * C` requires the prior output element to become an accumulator value,
/// and it must do so *exactly* --- otherwise the epilogue would round twice.
/// One trait rather than a bound on `O`, so that the integer families and the
/// float families reach [`Linear`] through the same impl and there is no second
/// epilogue (R13).
pub trait AbsorbPrior<O>: Accumulator {
    /// The accumulator holding exactly the value `prior` names.
    fn of_prior(prior: O) -> Self;
}

impl<O: Into<i128>> AbsorbPrior<O> for i128 {
    fn of_prior(prior: O) -> Self {
        prior.into()
    }
}

impl<O: Into<i128>, const L: usize> AbsorbPrior<O> for Limbs<L> {
    fn of_prior(prior: O) -> Self {
        Self::ZERO.add_i128(prior.into())
    }
}

impl<O: FloatElement, const L: usize, const MIN_EXP: i32> AbsorbPrior<O> for Complete<L, MIN_EXP> {
    fn of_prior(prior: O) -> Self {
        // The same decode every operand goes through. A float already in `C`
        // is a code like any other.
        Self::of(prior)
    }
}

/// Exact scaling and widening for an accumulator.
///
/// Separated from [`Accumulator`] because it is epilogue machinery, not
/// accumulation machinery: nothing in the accumulation path scales anything.
pub trait ScaleExact: Accumulator {
    /// Multiply by an exact integer scalar.
    ///
    /// Saturating, and this is the one place in the library where that word is
    /// allowed: it is inside the single encode step. The saturation is not a
    /// fallback and not an approximation --- an `alpha * sum` past the
    /// accumulator's range is also past every output type's range, so the
    /// clamp is the same value a wider intermediate would have produced (R3).
    fn scale_exact(self, factor: i64) -> Self;

    /// Widen a machine integer into this accumulator.
    fn from_i128(v: i128) -> Self;
}

impl ScaleExact for i128 {
    fn scale_exact(self, factor: i64) -> Self {
        self.saturating_mul(factor as i128)
    }

    fn from_i128(v: i128) -> Self {
        v
    }
}

impl<const L: usize, const MIN_EXP: i32> ScaleExact for uor_matmul_core::Complete<L, MIN_EXP> {
    fn scale_exact(self, factor: i64) -> Self {
        // Exact: an integer scaling of an exact fixed-point value is exact, and
        // the register is wide enough that `alpha` cannot push a representable
        // sum out of it.
        self.scale(factor)
    }

    fn from_i128(v: i128) -> Self {
        // An integer is a dyadic rational with exponent zero. `v` is at most
        // 128 bits, so it lands in the register without rounding.
        let negative = v < 0;
        let mut out = Self::ZERO;
        out.add_scaled(v.unsigned_abs(), 0, negative);
        out
    }
}

impl<const L: usize> ScaleExact for uor_matmul_core::Limbs<L> {
    fn scale_exact(self, factor: i64) -> Self {
        // Exact whenever the product fits the register, which is the only case
        // an output type can distinguish. Built from the register's own
        // `add_i128`, so there is no second multiplication routine.
        let negative_factor = factor < 0;
        let mut magnitude = factor.unsigned_abs();
        let mut acc = Self::ZERO;
        let mut addend = if negative_factor { self.neg() } else { self };
        while magnitude > 0 {
            if magnitude & 1 == 1 {
                acc = acc.combine(addend);
            }
            addend = addend.combine(addend);
            magnitude >>= 1;
        }
        acc
    }

    fn from_i128(v: i128) -> Self {
        Self::ZERO.add_i128(v)
    }
}
