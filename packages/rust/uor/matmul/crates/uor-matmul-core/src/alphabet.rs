//! The parametric working alphabet (§5.2).
//!
//! The upstream formalization's `InAlphabet` hypothesis is [`Alphabet`]'s
//! invariant and [`Bound::VALUE`] is its `B`. Every kernel entry point takes
//! `&[Alphabet<E, Bd>]`, so the alphabet hypothesis is discharged by the type
//! system at the boundary, once, rather than per element per kernel.

use core::marker::PhantomData;

use bytemuck::TransparentWrapper;

use crate::acc::{Accumulator, EncodeFrom};

/// A machine value usable as an alphabet element and as a coded weight.
///
/// Adding an element type is an impl, not a branch anywhere else. Nothing in
/// the library matches on which element type it was handed.
pub trait Element: Copy + PartialEq + Send + Sync + core::fmt::Debug + 'static {
    /// The accumulator for this element type.
    ///
    /// Not a parameter and not a choice: exactly one type, wide enough that the
    /// worst case the machine can express does not reach its range (§3.2).
    type Acc: Accumulator;

    /// Width of one component, in bits.
    const BITS: u32;

    /// Element-products summed by one [`Element::mac`].
    ///
    /// One for a scalar type. Two for a complex type, whose real part is
    /// `a.re * w.re - a.im * w.im`. The accumulator derivation reads this so
    /// that a complex alphabet needs no separate width table and no branch.
    const PRODUCT_TERMS: u32 = 1;

    /// The additive identity, which is what a padded position decodes to.
    ///
    /// Zero padding is exact, which is why an unaligned or prime shape takes
    /// the same path as any other and not a different one (S8).
    const ZERO: Self;

    /// The one arithmetic primitive: accumulate the exact product `a * w`.
    ///
    /// Exact, total, and free of any rounding or saturating step. Everything
    /// else in the library is a traversal over this (R3, R13).
    ///
    /// In place, by `&mut`, rather than by value. For an `i128` that is a wash;
    /// for a complete accumulator it is the difference between a float GEMM
    /// that works and one that spends most of its time copying an 88- or
    /// 536-byte register in and out of this call, twice per product.
    fn mac(acc: &mut Self::Acc, a: Self, w: Self);

    /// Does this element type have a narrow register at all?
    ///
    /// `false` means every tile takes the wide accumulator. That changes
    /// nothing about the answer --- only about how many instructions produce
    /// it --- which is the whole content of the narrow/wide distinction (R13).
    const HAS_NARROW: bool = false;

    /// Accumulate into the narrow register.
    ///
    /// Only called for a tile whose depth [`crate::bounds::fits_narrow`] has
    /// admitted against [`NARROW_CAP`], so this is exact wherever it is
    /// reached. The default is unreachable and is never called, because a type
    /// with `HAS_NARROW = false` is never offered a narrow tile.
    fn mac_narrow(acc: i64, _a: Self, _w: Self) -> i64 {
        acc
    }

    /// Fold a completed narrow partial into the wide accumulator.
    fn combine_narrow(acc: Self::Acc, narrow: i64) -> Self::Acc;
}

/// Elements with a magnitude, and therefore an alphabet.
///
/// [`Alphabet`] and [`Bound`] are defined only over these. A float has an
/// exponent range rather than a magnitude bound, which is why it implements
/// [`FloatElement`] instead and carries no alphabet (§5.2b).
pub trait IntegerElement: Element {
    /// The largest magnitude this type can hold.
    ///
    /// [`Full<Self>`] is the bound that admits every value of the type, so no
    /// value is ever outside its own alphabet and the default path cannot
    /// reject anything. `i8::MIN` is an element of `Alphabet<i8, Full<i8>>`,
    /// whose bound is 128; refusing a representable value would be an arbitrary
    /// limitation dressed as rigour (R8).
    const FULL: u128;

    /// The magnitude of this value, for [`observe_bound`] and for the alphabet
    /// declaration check. Never used by an accumulation.
    fn magnitude(self) -> u128;

    /// Exact difference, for the one codec that needs one.
    ///
    /// Used only by `Offset`, whose constructor establishes in O(1) that
    /// `BdIn + |zero|` fits both the declared output bound and the element
    /// type, so the subtraction cannot leave the type's range. It is spelled
    /// `wrapping_sub` because R5 requires the overflow behaviour to be written
    /// rather than inherited from the build profile --- not because a wrap can
    /// occur.
    fn sub(self, other: Self) -> Self;
}

/// What an IEEE code names.
///
/// The decode is total on every bit pattern: there is no `f32` for which it
/// fails, which is why non-finite inputs are codes rather than an error
/// condition (`CT-03`).
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Decoded {
    /// An exact dyadic rational: `(-1)^sign * mantissa * 2^exp`.
    ///
    /// Exact, with no rounding anywhere in the decode. Zero is this with a
    /// mantissa of zero.
    Finite {
        /// True for a negative value, including negative zero.
        sign: bool,
        /// The integer significand, subnormals included.
        mantissa: u64,
        /// The binary exponent of bit 0 of `mantissa`.
        exp: i32,
    },
    /// A signed infinity.
    Infinite {
        /// True for negative infinity.
        sign: bool,
    },
    /// A NaN. The payload is not preserved: IEEE 754 does not require it to be,
    /// and preserving it would make the result depend on the accumulation order
    /// of the NaNs, which is the one thing this library refuses to let happen.
    NotANumber,
}

/// A decoded float code, flattened for the inner loop.
///
/// Named for what it is rather than `Packed`, which in this workspace is a
/// codec tier --- a different thing that would otherwise share the name.
///
/// Sixteen bytes: a signed significand and an exponent. The sign lives in the
/// mantissa, so a product is one signed multiply; the non-finite kinds live in
/// a sentinel exponent, so the struct needs no flag bytes and a packed panel
/// costs half the cache it otherwise would. Both matter: this array is read
/// once per multiply-accumulate.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct PackedCode {
    /// The signed integer significand, or the sign for a non-finite code.
    pub mantissa: i64,
    /// The binary exponent of bit 0 of `mantissa`, or a sentinel.
    pub exp: i32,
}

/// The exponent that marks an infinity. Below every real product exponent, and
/// distinct from [`PackedCode::NAN_EXP`].
const INF_EXP: i32 = i32::MIN + 1;
/// The exponent that marks a NaN.
const NAN_EXP: i32 = i32::MIN;

impl PackedCode {
    /// The sentinel exponent of an infinity.
    pub const INF_EXP: i32 = INF_EXP;
    /// The sentinel exponent of a NaN.
    pub const NAN_EXP: i32 = NAN_EXP;

    /// Pack a decoded code.
    pub const fn of(d: Decoded) -> Self {
        match d {
            Decoded::Finite {
                sign,
                mantissa,
                exp,
            } => Self {
                mantissa: if sign {
                    -(mantissa as i64)
                } else {
                    mantissa as i64
                },
                exp,
            },
            // The sign of an infinity rides in the mantissa, as `-1` or `1`,
            // so the product's sign is the product of the two mantissas and
            // needs no separate rule.
            Decoded::Infinite { sign } => Self {
                mantissa: if sign { -1 } else { 1 },
                exp: INF_EXP,
            },
            Decoded::NotANumber => Self {
                mantissa: 0,
                exp: NAN_EXP,
            },
        }
    }

    /// Is this an ordinary finite value?
    ///
    /// The overwhelmingly common case, and the one the inner loop is written
    /// straight-line for. One comparison, because both sentinels are below
    /// every real exponent.
    pub const fn is_finite(&self) -> bool {
        self.exp > INF_EXP
    }

    /// Is this a NaN?
    pub const fn is_nan(&self) -> bool {
        self.exp == NAN_EXP
    }

    /// Is this an infinity?
    pub const fn is_infinite(&self) -> bool {
        self.exp == INF_EXP
    }
}

/// Elements that are IEEE codes.
///
/// A float is a code, and this trait is its codec: the decode from a bit
/// pattern to the exact dyadic rational it names. It is total, it never rounds,
/// and it is the same shape as any other codec in `uor-matmul-codec` (§3.3).
pub trait FloatElement: Element {
    /// Bits in a significand, implicit bit included: 24 for `f32`, 53 for `f64`.
    ///
    /// What it decides is whether a product of two of them can leave an `i64`,
    /// which is a question about the *type* and never about the data.
    const SIGNIFICAND_BITS: u32;

    /// Twice the minimum subnormal exponent: the lowest exponent a product of
    /// two values of this type can reach.
    const MIN_PRODUCT_EXP: i32;
    /// Twice the maximum finite exponent.
    const MAX_PRODUCT_EXP: i32;
    /// The codec. Total on all bit patterns, non-finite ones included.
    fn decode(self) -> Decoded;

    /// The codec's output in packed form, for a driver that decodes once and
    /// multiplies many times.
    fn pack(self) -> PackedCode {
        PackedCode::of(self.decode())
    }
}

/// The largest magnitude the portable reference's narrow register holds.
///
/// This is a property of the register, not of the library: on a backend the
/// same predicate is evaluated against that backend's lane width instead
/// (§7.2). Nothing anywhere reads it as a limit.
pub const NARROW_CAP: u128 = i64::MAX as u128;

/// The alphabet bound, carried as a sealed trait with an associated const
/// rather than a `const B: u128` parameter (D-7).
///
/// This encoding compiles on stable, which the const-generic form does not,
/// because [`Full`] needs an associated const in what would otherwise be a
/// const-generic argument.
pub trait Bound: Copy + Send + Sync + core::fmt::Debug + 'static {
    /// `B`: every element of the alphabet has magnitude at most this.
    const VALUE: u128;
}

/// The bound that admits every value of `E`. Zero-sized.
///
/// This is the default, and it is why the library has no alphabet-violation
/// error: under `Full<E>` there is nothing to violate.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub struct Full<E: IntegerElement>(PhantomData<E>);

impl<E: IntegerElement> Bound for Full<E> {
    const VALUE: u128 = E::FULL;
}

/// A declared narrower bound, e.g. `Bnd<127>` for W8A8.
///
/// A narrower bound lets more tiles take the narrow-register path (§5.1), and
/// nothing else changes. It is a declaration about the data, not a restriction
/// on it.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub struct Bnd<const V: u128>;

impl<const V: u128> Bound for Bnd<V> {
    const VALUE: u128 = V;
}

/// An element of the symmetric alphabet `{-B..B}`.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default, TransparentWrapper)]
#[repr(transparent)]
#[transparent(E)]
pub struct Alphabet<E: IntegerElement, Bd: Bound>(E, PhantomData<Bd>);

impl<E: IntegerElement, Bd: Bound> Alphabet<E, Bd> {
    /// `B`, the bound this alphabet declares.
    pub const BOUND: u128 = Bd::VALUE;

    /// The alphabet's zero, which is what a padded position decodes to.
    pub const ZERO: Self = Self(E::ZERO, PhantomData);

    /// The underlying value.
    pub const fn get(self) -> E {
        self.0
    }

    /// Admit a value whose magnitude is within the declared bound.
    ///
    /// Returns the observed magnitude rather than a unit error, so a caller who
    /// guessed wrong learns what the data actually is.
    pub fn new(value: E) -> Result<Self, ObservedBound> {
        let observed = value.magnitude();
        if observed <= Bd::VALUE {
            Ok(Self(value, PhantomData))
        } else {
            Err(ObservedBound {
                declared: Bd::VALUE,
                observed,
            })
        }
    }
}

impl<E: IntegerElement> Alphabet<E, Full<E>> {
    /// Admit any value of `E`. Infallible, because `Full<E>` admits everything.
    pub const fn of(value: E) -> Self {
        Self(value, PhantomData)
    }
}

/// What the data actually is, returned when a bound declaration is wrong.
///
/// This is not the operation failing. It is a *declaration* being checked at
/// the boundary, before any product exists. Being wrong about your own data is
/// not a reason for a matmul to fail (C6), so the recovery is to use
/// [`as_alphabet_full`] --- which cannot fail --- or to widen the declaration
/// to the observed value.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct ObservedBound {
    /// The bound the caller declared.
    pub declared: u128,
    /// The tightest bound the data actually satisfies at or beyond `declared`.
    pub observed: u128,
}

impl core::fmt::Display for ObservedBound {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(
            f,
            "declared alphabet bound {} but the data reaches {}; \
             use as_alphabet_full, which admits every value of the element type",
            self.declared, self.observed
        )
    }
}

/// The total entry point, and the one every convenience API uses.
///
/// Infallible for every slice of every element type, including `i8::MIN`.
/// Zero-copy, allocation-free, and with no validating pass: `Full<E>` admits
/// every value of `E`, so there is nothing to check.
pub fn as_alphabet_full<E: IntegerElement>(xs: &[E]) -> &[Alphabet<E, Full<E>>] {
    Alphabet::wrap_slice(xs)
}

/// The mutable twin of [`as_alphabet_full`].
pub fn as_alphabet_full_mut<E: IntegerElement>(xs: &mut [E]) -> &mut [Alphabet<E, Full<E>>] {
    Alphabet::wrap_slice_mut(xs)
}

/// The declared-bound entry point, for a caller who knows their data is
/// narrower and wants more tiles on the narrow-register path.
///
/// Returns the observed bound rather than an error when the declaration is
/// wrong, because being wrong about your own data is not a reason for a matmul
/// to fail (C6).
pub fn as_alphabet<E: IntegerElement, Bd: Bound>(
    xs: &[E],
) -> Result<&[Alphabet<E, Bd>], ObservedBound> {
    let mut worst = 0u128;
    for x in xs {
        let m = x.magnitude();
        if m > worst {
            worst = m;
        }
    }
    if worst <= Bd::VALUE {
        Ok(Alphabet::wrap_slice(xs))
    } else {
        Err(ObservedBound {
            declared: Bd::VALUE,
            observed: worst,
        })
    }
}

/// One pass, returning the tightest bound the data actually satisfies.
///
/// Callers who want the narrow-register path without guessing use this.
pub fn observe_bound<E: IntegerElement>(xs: &[E]) -> u128 {
    let mut worst = 0u128;
    for x in xs {
        let m = x.magnitude();
        if m > worst {
            worst = m;
        }
    }
    worst
}

/// Implement [`Element`] for a signed machine integer.
///
/// Every impl is the same three facts --- the width, the largest magnitude, and
/// the exact product --- which is why adding an element type is an impl and not
/// a branch anywhere else.
macro_rules! impl_element_for_signed {
    ($($t:ty),* $(,)?) => { $(
        impl Element for $t {
            type Acc = i128;
            const BITS: u32 = <$t>::BITS;
            const ZERO: Self = 0;

            fn mac(acc: &mut i128, a: Self, w: Self) {
                // Exact by construction: the product of two values of this type
                // needs at most `2 * BITS` bits, and `acc_bits::<Self>()` leaves
                // room for every `k` the machine can address (§3.2). No
                // wrapping, no saturation, no rounding (R3).
                *acc += (a as i128) * (w as i128);
            }

            // The product of two values of this type needs at most 64 bits, so
            // an i64 register can hold a run of them --- for exactly as long as
            // `fits_narrow` says, and not one step longer.
            const HAS_NARROW: bool = 2 * <$t>::BITS <= 63;

            fn mac_narrow(acc: i64, a: Self, w: Self) -> i64 {
                acc + (a as i64) * (w as i64)
            }

            fn combine_narrow(acc: i128, narrow: i64) -> i128 {
                acc + narrow as i128
            }
        }

        impl IntegerElement for $t {
            const FULL: u128 = 1u128 << (<$t>::BITS - 1);

            fn magnitude(self) -> u128 {
                self.unsigned_abs() as u128
            }

            fn sub(self, other: Self) -> Self {
                self.wrapping_sub(other)
            }
        }
    )* };
}

impl_element_for_signed!(i8, i16, i32);

impl Element for i64 {
    type Acc = crate::acc::Limbs<3>;
    const BITS: u32 = i64::BITS;
    const ZERO: Self = 0;

    fn mac(acc: &mut Self::Acc, a: Self, w: Self) {
        // The product of two i64 needs at most 128 bits and is therefore exact
        // in an i128; the 192-bit accumulator absorbs every `k` on top of it.
        acc.add_i128_in_place((a as i128) * (w as i128));
    }

    // A single i64 x i64 product does not fit in an i64, so there is no narrow
    // register for this element type and every tile takes the wide one. The
    // answer is the same either way, which is the point.
    const HAS_NARROW: bool = false;

    fn combine_narrow(acc: Self::Acc, narrow: i64) -> Self::Acc {
        acc.add_i128(narrow as i128)
    }
}

impl IntegerElement for i64 {
    const FULL: u128 = 1u128 << 63;

    fn magnitude(self) -> u128 {
        self.unsigned_abs() as u128
    }

    fn sub(self, other: Self) -> Self {
        self.wrapping_sub(other)
    }
}

/// A complex element. Its real and imaginary parts are drawn from the same
/// alphabet, and its bound bounds both.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default)]
#[repr(C)]
pub struct Complex<T> {
    /// The real part.
    pub re: T,
    /// The imaginary part.
    pub im: T,
}

impl<T> Complex<T> {
    /// Construct from parts.
    pub const fn new(re: T, im: T) -> Self {
        Self { re, im }
    }
}

/// A complex accumulator: two independent exact accumulators, one per part.
///
/// Not a special case. `combine` and `mac` are the scalar operations applied
/// componentwise, so the same identity holds and the same tests apply.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct ComplexAcc<A> {
    /// The real part's accumulator.
    pub re: A,
    /// The imaginary part's accumulator.
    pub im: A,
}

impl<A: Accumulator> Accumulator for ComplexAcc<A> {
    const ZERO: Self = Self {
        re: A::ZERO,
        im: A::ZERO,
    };
    const BITS: u32 = A::BITS;

    fn combine(self, other: Self) -> Self {
        Self {
            re: self.re.combine(other.re),
            im: self.im.combine(other.im),
        }
    }
}

/// Implement [`Element`] for `Complex<T>` over a signed machine integer.
macro_rules! impl_element_for_complex {
    ($($t:ty => $acc:ty),* $(,)?) => { $(
        impl Element for Complex<$t> {
            type Acc = ComplexAcc<$acc>;
            const BITS: u32 = <$t>::BITS;
            // (a.re * w.re - a.im * w.im) sums two element-products, so the
            // accumulator derivation gets one more bit than the scalar case.
            const PRODUCT_TERMS: u32 = 2;
            const ZERO: Self = Complex { re: 0, im: 0 };

            fn mac(acc: &mut Self::Acc, a: Self, w: Self) {
                <$t as Element>::mac(&mut acc.re, a.re, w.re);
                <$t as Element>::mac(&mut acc.re, a.im, -w.im);
                <$t as Element>::mac(&mut acc.im, a.re, w.im);
                <$t as Element>::mac(&mut acc.im, a.im, w.re);
            }

            // Two independent accumulators; a single i64 register would have to
            // carry both, so there is no narrow path here either.
            const HAS_NARROW: bool = false;

            fn combine_narrow(acc: Self::Acc, narrow: i64) -> Self::Acc {
                ComplexAcc {
                    re: <$t as Element>::combine_narrow(acc.re, narrow),
                    im: acc.im,
                }
            }

        }

        impl IntegerElement for Complex<$t> {
            const FULL: u128 = 1u128 << (<$t>::BITS - 1);

            fn magnitude(self) -> u128 {
                // The bound bounds both parts, so the magnitude of the pair is
                // the larger of the two. This is not an approximation of the
                // complex modulus and is not used as one: it is the quantity
                // the accumulator width is derived against (§5.2b).
                let re = (self.re.unsigned_abs()) as u128;
                let im = (self.im.unsigned_abs()) as u128;
                if re > im { re } else { im }
            }

            fn sub(self, other: Self) -> Self {
                Complex {
                    re: <$t as IntegerElement>::sub(self.re, other.re),
                    im: <$t as IntegerElement>::sub(self.im, other.im),
                }
            }
        }
    )* };
}

impl_element_for_complex!(i32 => i128, i64 => crate::acc::Limbs<3>);

impl<A, O> EncodeFrom<ComplexAcc<A>> for Complex<O>
where
    A: Accumulator,
    O: EncodeFrom<A>,
{
    fn encode_from(acc: ComplexAcc<A>, mode: crate::policy::EncodeMode) -> Self {
        Complex {
            re: O::encode_from(acc.re, mode),
            im: O::encode_from(acc.im, mode),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// §5.2: `i8::MIN` is not rejected. It is an element of its own alphabet,
    /// whose bound is 128, and refusing a representable value would be an
    /// arbitrary limitation dressed as rigour (R8, C6).
    #[test]
    fn i8_min_is_in_its_own_alphabet_ct_01() {
        let data = [i8::MIN, -1, 0, 1, i8::MAX];
        let a = as_alphabet_full(&data);
        assert_eq!(a.len(), 5);
        assert_eq!(a[0].get(), i8::MIN);
        assert_eq!(Alphabet::<i8, Full<i8>>::BOUND, 128);
    }

    /// §5.2: a wrong declaration reports what the data is, not merely that the
    /// caller was wrong, and the recovery never involves failing the operation.
    #[test]
    fn a_wrong_declaration_reports_the_observed_bound_cs_03() {
        let data = [1i8, -100, 7];
        let err = as_alphabet::<i8, Bnd<63>>(&data).unwrap_err();
        assert_eq!(
            err,
            ObservedBound {
                declared: 63,
                observed: 100
            }
        );
        assert_eq!(observe_bound(&data), 100);
        // The recovery: the total entry point, which cannot fail.
        assert_eq!(as_alphabet_full(&data).len(), 3);
    }

    /// The wrap is zero-copy: the alphabet is a transparent wrapper, so no
    /// buffer is produced and nothing is allocated (R7, CA-01).
    #[test]
    fn wrapping_is_zero_copy_ca_01() {
        let data = [1i32, 2, 3, 4];
        let a = as_alphabet_full(&data);
        assert_eq!(a.as_ptr() as usize, data.as_ptr() as usize);
        assert_eq!(core::mem::size_of::<Alphabet<i32, Full<i32>>>(), 4);
    }

    /// The complex `mac` is the scalar one applied componentwise; it is not a
    /// second method (R13).
    #[test]
    fn complex_mac_is_componentwise_ck_01() {
        let a = Complex::new(3i32, 4);
        let w = Complex::new(5i32, -2);
        let mut acc = ComplexAcc::ZERO;
        <Complex<i32> as Element>::mac(&mut acc, a, w);
        // (3 + 4i)(5 - 2i) = 15 - 6i + 20i + 8 = 23 + 14i
        assert_eq!(acc.re, 23);
        assert_eq!(acc.im, 14);
    }
}

// ---------------------------------------------------------------------------
// The float family: a float is a code (§3.3, §5.2b)
// ---------------------------------------------------------------------------
//
// R2 forbids float *arithmetic*, not the float *types*. `f32` and `f64` appear
// here as element types being decoded, and in the encode step, and nowhere
// else: the decode below is bit manipulation on `to_bits()` output, and the
// accumulation it feeds is the same integer accumulation every other element
// family uses. No float is ever added to a float (`CU-01`).

/// Implement the float family for one IEEE interchange format.
macro_rules! impl_float_element {
    ($t:ty, $bits:ty, $mant:expr, $expo:expr, $limbs:expr, $min_prod:expr, $max_prod:expr) => {
        impl Element for $t {
            type Acc = crate::acc::Complete<{ $limbs }, { $min_prod }>;
            const BITS: u32 = <$t>::MANTISSA_DIGITS + $expo;
            const ZERO: Self = 0.0;

            fn mac(acc: &mut Self::Acc, a: Self, w: Self) {
                // Decode, multiply the significands as integers, place the
                // exact product in the complete accumulator. Every step is
                // exact and none of them is a float operation.
                match (a.decode(), w.decode()) {
                    (Decoded::NotANumber, _) | (_, Decoded::NotANumber) => acc.set_nan(),
                    (Decoded::Infinite { sign: sa }, other)
                    | (other, Decoded::Infinite { sign: sa }) => match other {
                        // Infinity times zero is NaN, by IEEE 754 clause 7.2.
                        Decoded::Finite { mantissa: 0, .. } => acc.set_nan(),
                        Decoded::Finite { sign: sb, .. } => acc.set_infinity(sa ^ sb),
                        Decoded::Infinite { sign: sb } => acc.set_infinity(sa ^ sb),
                        Decoded::NotANumber => acc.set_nan(),
                    },
                    (
                        Decoded::Finite {
                            sign: sa,
                            mantissa: ma,
                            exp: ea,
                        },
                        Decoded::Finite {
                            sign: sb,
                            mantissa: mb,
                            exp: eb,
                        },
                    ) => {
                        // Both significands fit in 53 bits, so their product
                        // fits in 106 and the u128 multiply is exact.
                        acc.add_scaled((ma as u128) * (mb as u128), ea + eb, sa != sb);
                    }
                }
            }

            fn combine_narrow(acc: Self::Acc, _narrow: i64) -> Self::Acc {
                // A complete accumulator has no narrow register: the whole
                // point of it is that every product lands at full width.
                acc
            }
        }

        impl FloatElement for $t {
            const MIN_PRODUCT_EXP: i32 = $min_prod;
            const MAX_PRODUCT_EXP: i32 = $max_prod;
            // The stored fraction plus the implicit leading bit.
            const SIGNIFICAND_BITS: u32 = $mant + 1;

            fn decode(self) -> Decoded {
                // Total on all bit patterns. No branch here can fail, and none
                // rounds: an IEEE value *names* a dyadic rational exactly, and
                // this reads the name (`CT-03`).
                const MANT_BITS: u32 = $mant;
                const EXP_BITS: u32 = $expo;
                const BIAS: i32 = (1 << (EXP_BITS - 1)) - 1;

                let bits = self.to_bits();
                let sign = (bits >> (MANT_BITS + EXP_BITS)) & 1 == 1;
                let biased = ((bits >> MANT_BITS) & ((1 << EXP_BITS) - 1)) as i32;
                let frac = bits & ((1 << MANT_BITS) - 1);

                if biased == (1 << EXP_BITS) - 1 {
                    return if frac == 0 {
                        Decoded::Infinite { sign }
                    } else {
                        Decoded::NotANumber
                    };
                }
                if biased == 0 {
                    // Subnormal, or zero. The exponent is that of the smallest
                    // normal, and there is no implicit leading one.
                    return Decoded::Finite {
                        sign,
                        mantissa: frac as u64,
                        exp: 1 - BIAS - MANT_BITS as i32,
                    };
                }
                Decoded::Finite {
                    sign,
                    mantissa: (frac | (1 << MANT_BITS)) as u64,
                    exp: biased - BIAS - MANT_BITS as i32,
                }
            }
        }
    };
}

impl_float_element!(f32, u32, 23, 8, 10, -298, 256);
impl_float_element!(f64, u64, 52, 11, 67, -2148, 2048);

#[cfg(test)]
mod float_tests {
    use super::*;

    /// The decode is exact: reading the name of a dyadic rational and
    /// reconstructing it must round-trip, for every kind of finite value.
    #[test]
    fn the_float_decode_is_exact_ct_03() {
        for x in [
            1.0f32,
            -1.0,
            0.5,
            3.0,
            1e30,
            -1e-30,
            f32::MIN_POSITIVE,
            0.0,
            -0.0,
        ] {
            let Decoded::Finite {
                sign,
                mantissa,
                exp,
            } = x.decode()
            else {
                panic!("{x} is finite");
            };
            // Reconstruct without float arithmetic: compare against the
            // magnitude the bits describe.
            let reconstructed = (mantissa as f64) * (2f64).powi(exp);
            let expected = x as f64;
            assert_eq!(reconstructed, if sign { -expected } else { expected }.abs());
        }
        // The smallest subnormal is the unit in the last place of the format.
        let tiny = f32::from_bits(1);
        assert_eq!(
            tiny.decode(),
            Decoded::Finite {
                sign: false,
                mantissa: 1,
                exp: -149
            }
        );
    }

    /// CT-03: non-finite codes are codes. The decode is total on all of them
    /// and never errors.
    #[test]
    fn non_finite_codes_decode_and_never_error_ct_03() {
        assert_eq!(f32::INFINITY.decode(), Decoded::Infinite { sign: false });
        assert_eq!(f32::NEG_INFINITY.decode(), Decoded::Infinite { sign: true });
        assert_eq!(f32::NAN.decode(), Decoded::NotANumber);
        assert_eq!(f64::NAN.decode(), Decoded::NotANumber);
        // A signalling NaN pattern is a NaN like any other; nothing traps.
        assert_eq!(f32::from_bits(0x7F80_0001).decode(), Decoded::NotANumber);
        // Every one of the 2^16 patterns in the exponent-boundary region
        // decodes without panicking, which is what "total" means here.
        for hi in 0u32..=0xFFFF {
            let _ = f32::from_bits(hi << 16).decode();
        }
    }

    /// §3.3: the product exponent range in `model/widths.toml` is the range
    /// this decode actually produces.
    #[test]
    fn the_product_exponent_range_matches_the_model_cm_01() {
        let smallest = f32::from_bits(1).decode();
        let Decoded::Finite { exp, .. } = smallest else {
            panic!()
        };
        assert_eq!(exp * 2, <f32 as FloatElement>::MIN_PRODUCT_EXP);
        assert_eq!(
            <f32 as FloatElement>::MIN_PRODUCT_EXP,
            crate::generated::complete_width::F32_MIN_PRODUCT_EXP
        );
        assert_eq!(
            <f64 as FloatElement>::MIN_PRODUCT_EXP,
            crate::generated::complete_width::F64_MIN_PRODUCT_EXP
        );
    }
}
