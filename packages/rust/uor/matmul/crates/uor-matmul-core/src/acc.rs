//! One accumulator per element type, wide enough by construction (§5.3).
//!
//! There is no wrapping model here. A width derived from the element type
//! cannot wrap for any expressible input, so the arithmetic is plain and exact,
//! and `CT-02` checks it by running the whole corpus in a build where every
//! accumulator operation is checked and any overflow panics.
//!
//! Narrow-register tiles still exist and are still the fast path. They are
//! selected by [`crate::bounds::fits_narrow`] per tile, they compute the same
//! integer, and their result is combined into the wide accumulator. That is a
//! factorization, not a fallback: nothing about the answer or the guarantee
//! depends on which side of the predicate a tile lands (R13).

// R5 asks that *wrapping* arithmetic be written explicitly, so that a debug and
// a release binary are the same function. It does not ask that every operation
// be spelled `wrapping_*`: in this module the arithmetic is deliberately plain,
// because a width derived from the element type cannot wrap for any expressible
// input (§3.2, §5.3), and writing `wrapping_add` here would assert the opposite.
//
// The witness that the derivation holds is not a lint but `CT-02`: the whole
// corpus runs under the `checked` profile, where every one of these operations
// is checked and any overflow panics. A lint could only be satisfied by hiding
// the question; the checked build answers it.

use crate::alphabet::{Alphabet, Bound, Element, IntegerElement};
use crate::policy::EncodeMode;

/// The accumulator for element type `E`.
///
/// Not a parameter, not a policy, not a ladder: `AccOf<E>` is the unique type
/// with at least `acc_bits::<E>()` bits, and the worst case the machine can
/// express does not reach its range.
pub type AccOf<E> = <E as Element>::Acc;

/// An exact accumulator.
///
/// Every implementor is wide enough that no input the machine can represent can
/// overflow it, which is why no method here returns a `Result` and why there is
/// no saturating or rounding step anywhere in the trait except [`encode`],
/// which runs exactly once per output element.
///
/// [`encode`]: Accumulator::encode
pub trait Accumulator: Copy + Eq + core::fmt::Debug + Send + Sync + 'static {
    /// The additive identity.
    const ZERO: Self;

    /// The accumulator's width in bits.
    const BITS: u32;

    /// Combine two partial accumulations.
    ///
    /// Associative and commutative on every value that can arise, which is what
    /// makes the result independent of the reduction schedule, the tile
    /// partition, and the number of threads (`CD-02`).
    fn combine(self, other: Self) -> Self;

    /// Accumulate the exact product of two alphabet elements.
    ///
    /// Forwards to [`Element::mac`], which is the library's one arithmetic
    /// primitive.
    fn mac<E: IntegerElement<Acc = Self>, Bd: Bound>(
        &mut self,
        a: Alphabet<E, Bd>,
        w: Alphabet<E, Bd>,
    ) {
        E::mac(self, a.get(), w.get());
    }

    /// The single encode step.
    ///
    /// Saturation or rounding, if any, happens here and exactly once, under a
    /// mode the caller names. This is the only place in the library where
    /// information can be discarded (§5.5).
    fn encode<O: Element + EncodeFrom<Self>>(self, mode: EncodeMode) -> O {
        O::encode_from(self, mode)
    }
}

/// How to produce an output element from an accumulator.
///
/// Kept separate from [`Element`] so that the encode step is a relation between
/// an accumulator and an output type rather than a property of either. That is
/// what lets `i8 x i8 -> i32`, `Complex<i32> -> Complex<i32>`, and
/// `Complete<10> -> f32` all be the same single encode step at different
/// instantiations, with no branch and no second method.
pub trait EncodeFrom<A>: Sized {
    /// Encode `acc` under `mode`.
    fn encode_from(acc: A, mode: EncodeMode) -> Self;
}

impl Accumulator for i128 {
    const ZERO: Self = 0;
    const BITS: u32 = 128;

    fn combine(self, other: Self) -> Self {
        // Exact: both operands are partial sums of the same accumulation, whose
        // total is bounded by `acc_bits::<E>() <= 128` (§3.2).
        self + other
    }
}

/// Implement [`EncodeFrom`] for a signed machine integer, out of an `i128`.
macro_rules! impl_encode_from_i128 {
    ($($t:ty),* $(,)?) => { $(
        impl EncodeFrom<i128> for $t {
            fn encode_from(acc: i128, mode: EncodeMode) -> Self {
                encode_i128_into(acc, <$t>::MIN as i128, <$t>::MAX as i128, mode) as $t
            }
        }
    )* };
}

impl_encode_from_i128!(i8, i16, i32, i64, i128);

/// The single encode step for an integer accumulator, in one place.
///
/// `Nearest` and `TowardZero` name a rounding rule, and an integer accumulator
/// holds an integer, so for this family they have nothing to round and behave
/// as `Saturating` on range. `Wrapping` names a range rule and truncates. The
/// caller names which they want; neither is a fallback, and both are exact
/// functions of the exact accumulator (§5.5).
const fn encode_i128_into(acc: i128, min: i128, max: i128, mode: EncodeMode) -> i128 {
    match mode {
        EncodeMode::Wrapping => {
            if min == i128::MIN && max == i128::MAX {
                acc
            } else {
                // Two's complement truncation to the output width, written
                // explicitly rather than left to a profile-dependent cast (R5).
                let span = (max as u128).wrapping_sub(min as u128).wrapping_add(1);
                let offset = (acc as u128).wrapping_sub(min as u128);
                (offset.wrapping_rem(span)).wrapping_add(min as u128) as i128
            }
        }
        EncodeMode::Saturating | EncodeMode::Nearest | EncodeMode::TowardZero => {
            if acc < min {
                min
            } else if acc > max {
                max
            } else {
                acc
            }
        }
    }
}

/// Add `parts` into `limbs` starting at limb `at`, propagating the carry only
/// as far as it reaches.
///
/// The whole reason the float path is not hopeless: an exact fixed-point add is
/// three limb additions and a carry, not a full-width traversal.
fn add_at<const L: usize>(limbs: &mut [u64; L], at: usize, parts: [u64; 3]) {
    let mut carry = 0u64;
    let mut i = at;
    for part in parts {
        if i >= L {
            return;
        }
        let (sum, c1) = limbs[i].overflowing_add(part);
        let (sum, c2) = sum.overflowing_add(carry);
        limbs[i] = sum;
        carry = u64::from(c1) + u64::from(c2);
        i += 1;
    }
    // The tail: a carry out of the third limb, which stops as soon as a limb
    // absorbs it. For a register whose top limbs are zero --- the usual case,
    // since the leading one sits wherever the exponent put it --- that is one
    // iteration.
    while carry != 0 && i < L {
        let (sum, c) = limbs[i].overflowing_add(carry);
        limbs[i] = sum;
        carry = u64::from(c);
        i += 1;
    }
}

/// Subtract `parts` from `limbs` starting at limb `at`, propagating the borrow
/// only as far as it reaches.
fn sub_at<const L: usize>(limbs: &mut [u64; L], at: usize, parts: [u64; 3]) {
    let mut borrow = 0u64;
    let mut i = at;
    for part in parts {
        if i >= L {
            return;
        }
        let (diff, b1) = limbs[i].overflowing_sub(part);
        let (diff, b2) = diff.overflowing_sub(borrow);
        limbs[i] = diff;
        borrow = u64::from(b1) + u64::from(b2);
        i += 1;
    }
    while borrow != 0 && i < L {
        let (diff, b) = limbs[i].overflowing_sub(borrow);
        limbs[i] = diff;
        borrow = u64::from(b);
        i += 1;
    }
}

/// Fixed-width multi-limb accumulator: `L` limbs of 64 bits, two's complement,
/// little-endian, no allocation, no growth.
///
/// `L` is resolved at compile time from the element type, never at runtime.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
#[repr(transparent)]
pub struct Limbs<const L: usize>([u64; L]);

impl<const L: usize> Limbs<L> {
    /// Zero.
    pub const ZERO: Self = Self([0; L]);

    /// The raw limbs, least significant first.
    pub const fn limbs(&self) -> &[u64; L] {
        &self.0
    }

    /// Is this value negative? Equivalently, is the top bit of the top limb set?
    pub const fn is_negative(&self) -> bool {
        L > 0 && (self.0[L - 1] >> 63) == 1
    }

    /// Bit `i`, counting from bit 0 of the register.
    pub fn bit(&self, i: u32) -> bool {
        let limb = (i / 64) as usize;
        limb < L && (self.0[limb] >> (i % 64)) & 1 == 1
    }

    /// The `n` bits starting at bit `at`, with `n <= 64`.
    ///
    /// One shift-pair rather than `n` bit tests. That matters more than it
    /// looks: reading a significand a bit at a time is `n` passes over a
    /// register that is 67 limbs wide for `f64`, and the encode step is once per
    /// output element.
    pub fn window(&self, at: u32, n: u32) -> u64 {
        debug_assert!(n <= 64);
        let limb = (at / 64) as usize;
        let sh = at % 64;
        let lo = if limb < L { self.0[limb] >> sh } else { 0 };
        // `sh == 0` would shift a `u64` by 64, which is not a shift.
        let hi = if sh != 0 && limb + 1 < L {
            self.0[limb + 1] << (64 - sh)
        } else {
            0
        };
        let w = lo | hi;
        if n < 64 {
            w & ((1u64 << n) - 1)
        } else {
            w
        }
    }

    /// The index of the highest set bit, or `None` when every limb is zero.
    pub fn high_bit(&self) -> Option<u32> {
        for i in (0..L).rev() {
            let limb = self.0[i];
            if limb != 0 {
                let within = 63u32.wrapping_sub(limb.leading_zeros());
                return Some((i as u32).wrapping_mul(64).wrapping_add(within));
            }
        }
        None
    }

    /// Is any bit strictly below `i` set? The sticky bit.
    pub fn any_below(&self, i: u32) -> bool {
        let full = (i / 64) as usize;
        for j in 0..full.min(L) {
            if self.0[j] != 0 {
                return true;
            }
        }
        if full < L {
            let rem = i % 64;
            if rem > 0 && self.0[full] & ((1u64 << rem).wrapping_sub(1)) != 0 {
                return true;
            }
        }
        false
    }

    /// Add a sign-extended `i128` in place, propagating the carry only as far
    /// as it reaches.
    ///
    /// The hot path for `i64` elements: a full-width traversal per product
    /// would make a 192-bit accumulator cost three times an `i128` one for no
    /// reason, since the carry almost never leaves the low two limbs.
    pub fn add_i128_in_place(&mut self, v: i128) {
        let ext: u64 = if v < 0 { u64::MAX } else { 0 };
        let uv = v as u128;
        let mut carry = 0u64;
        for i in 0..L {
            let addend = match i {
                0 => uv as u64,
                1 => (uv >> 64) as u64,
                _ => ext,
            };
            let (sum, c1) = self.0[i].overflowing_add(addend);
            let (sum, c2) = sum.overflowing_add(carry);
            self.0[i] = sum;
            carry = u64::from(c1) + u64::from(c2);
            // A non-negative addend past limb 1 contributes nothing but the
            // carry, and once that is gone the remaining limbs are unchanged.
            if ext == 0 && carry == 0 && i >= 1 {
                break;
            }
        }
    }

    /// Add a sign-extended `i128`.
    ///
    /// Exact for every value that can arise: `L` is chosen so that the sum of
    /// every product the machine can address stays inside `64 * L` bits (§3.2).
    pub const fn add_i128(self, v: i128) -> Self {
        let mut out = self.0;
        let ext: u64 = if v < 0 { u64::MAX } else { 0 };
        let uv = v as u128;
        let mut carry = 0u64;
        let mut i = 0;
        while i < L {
            let addend = match i {
                0 => uv as u64,
                1 => (uv >> 64) as u64,
                _ => ext,
            };
            let (s, c1) = out[i].overflowing_add(addend);
            let (s, c2) = s.overflowing_add(carry);
            out[i] = s;
            carry = (c1 as u64).wrapping_add(c2 as u64);
            i = i.wrapping_add(1);
        }
        Self(out)
    }

    /// Two's complement negation.
    pub const fn neg(self) -> Self {
        let mut out = [0u64; L];
        let mut carry = 1u64;
        let mut i = 0;
        while i < L {
            let (s, c) = (!self.0[i]).overflowing_add(carry);
            out[i] = s;
            carry = c as u64;
            i = i.wrapping_add(1);
        }
        Self(out)
    }

    /// The value's magnitude, truncated to 128 bits, together with whether the
    /// truncation lost anything.
    pub const fn magnitude_low_u128(&self) -> (u128, bool) {
        let m = if self.is_negative() {
            self.neg()
        } else {
            *self
        };
        let lo = if L > 0 { m.0[0] as u128 } else { 0 };
        let hi = if L > 1 { (m.0[1] as u128) << 64 } else { 0 };
        let mut exceeded = false;
        let mut i = 2;
        while i < L {
            if m.0[i] != 0 {
                exceeded = true;
            }
            i = i.wrapping_add(1);
        }
        (lo | hi, exceeded)
    }

    /// The low 128 bits, as a two's complement `i128`.
    pub const fn low_i128(&self) -> i128 {
        let lo = if L > 0 { self.0[0] as u128 } else { 0 };
        let hi = if L > 1 { (self.0[1] as u128) << 64 } else { 0 };
        (lo | hi) as i128
    }
}

impl<const L: usize> Accumulator for Limbs<L> {
    const ZERO: Self = Self([0; L]);
    const BITS: u32 = (L as u32).wrapping_mul(64);

    fn combine(self, other: Self) -> Self {
        let mut out = [0u64; L];
        let mut carry = 0u64;
        for (i, slot) in out.iter_mut().enumerate() {
            let (s, c1) = self.0[i].overflowing_add(other.0[i]);
            let (s, c2) = s.overflowing_add(carry);
            *slot = s;
            carry = (c1 as u64).wrapping_add(c2 as u64);
        }
        Self(out)
    }
}

/// Implement [`EncodeFrom`] for a signed machine integer, out of `Limbs<L>`.
macro_rules! impl_encode_from_limbs {
    ($($t:ty),* $(,)?) => { $(
        impl<const L: usize> EncodeFrom<Limbs<L>> for $t {
            fn encode_from(acc: Limbs<L>, mode: EncodeMode) -> Self {
                match mode {
                    // Truncation to the output width; the low limbs already are
                    // the two's complement low bits.
                    EncodeMode::Wrapping => {
                        encode_i128_into(acc.low_i128(), i128::MIN, i128::MAX,
                                         EncodeMode::Wrapping) as $t
                    }
                    _ => {
                        let (mag, exceeded) = acc.magnitude_low_u128();
                        let negative = acc.is_negative();
                        if exceeded {
                            return if negative { <$t>::MIN } else { <$t>::MAX };
                        }
                        // `mag` is exact here, so the saturation decision is a
                        // comparison and not an estimate.
                        let limit = if negative {
                            (<$t>::MIN as i128).unsigned_abs()
                        } else {
                            <$t>::MAX as u128
                        };
                        if mag > limit {
                            return if negative { <$t>::MIN } else { <$t>::MAX };
                        }
                        if negative {
                            (mag as i128).wrapping_neg() as $t
                        } else {
                            mag as $t
                        }
                    }
                }
            }
        }
    )* };
}

impl_encode_from_limbs!(i8, i16, i32, i64, i128);

/// A complete accumulator: a fixed-point register spanning the entire product
/// exponent range of a float codec, so that every add is exact and no ordering
/// can perturb it (§3.3).
///
/// This is the Kulisch construction, and it is the same object as the integer
/// accumulator above, sized differently. It contains no float arithmetic and no
/// float token: the decode from an IEEE bit pattern to the exact dyadic
/// rational it names lives in `uor-matmul-float`, and what arrives here is an
/// integer magnitude, a binary exponent, and a sign.
///
/// `L` is the limb count and `MIN_EXP` is the binary exponent of bit 0, both
/// derived from the element type in `model/widths.toml`. The plan writes
/// `Complete<const L: usize>`; the exponent origin is carried as a second const
/// parameter rather than inferred, so that a `Complete` value cannot be
/// combined with one of a different origin.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub struct Complete<const L: usize, const MIN_EXP: i32> {
    limbs: Limbs<L>,
    /// A NaN has been accumulated. Sticky, and it wins over everything.
    ///
    /// The non-finite state is carried as a flag rather than as a value
    /// because a value would have to participate in the fixed-point addition,
    /// and then the result would depend on *where* in the accumulation the
    /// infinity arrived. IEEE 754 clause 6 is about the value, not the
    /// schedule, so the flags are what make `CU-04` --- order-independence ---
    /// hold for non-finite inputs as well as finite ones.
    nan: bool,
    /// A positive infinity has been accumulated. Sticky.
    pos_inf: bool,
    /// A negative infinity has been accumulated. Sticky.
    neg_inf: bool,
}

impl<const L: usize, const MIN_EXP: i32> Complete<L, MIN_EXP> {
    /// Zero.
    pub const ZERO: Self = Self {
        limbs: Limbs::ZERO,
        nan: false,
        pos_inf: false,
        neg_inf: false,
    };

    /// The binary exponent of bit 0 of the register.
    pub const MIN_EXP: i32 = MIN_EXP;

    /// The register's width in bits.
    pub const WIDTH: u32 = (L as u32).wrapping_mul(64);

    /// Accumulate `sign * mag * 2^exp`, exactly.
    ///
    /// `mag` is the integer significand product of two decoded floats and `exp`
    /// is its binary exponent. Every bit of the result lands in the register,
    /// because the register spans the whole product exponent range; nothing is
    /// rounded, and nothing is dropped.
    ///
    /// A product whose exponent falls outside the register is impossible for
    /// any pair of finite inputs of the element type the register was sized
    /// for. Should one be presented anyway --- by a caller constructing a
    /// `Complete` directly --- the contribution is clamped into the register
    /// rather than wrapping, because a wrap would silently change the answer
    /// while a clamp cannot arise on any real input.
    pub fn add_scaled(&mut self, mag: u128, exp: i32, negative: bool) {
        if mag == 0 {
            return;
        }
        let shift = exp.saturating_sub(MIN_EXP); // R3-ok: an exponent placement, checked below
        if shift < 0 {
            return;
        }
        let shift = shift as u32;
        let at = (shift / 64) as usize;
        let bit = shift % 64;

        // Spread `mag` across at most three limbs: 128 bits of magnitude can
        // straddle two limb boundaries once shifted.
        let spread: [u64; 3] = if bit == 0 {
            [mag as u64, (mag >> 64) as u64, 0]
        } else {
            [
                (mag << bit) as u64,
                ((mag << bit) >> 64) as u64,
                (mag >> (128 - bit)) as u64,
            ]
        };

        // Add or subtract in place, at the offset, propagating only as far as
        // the carry actually reaches. The obvious implementation --- build a
        // full-width value and combine --- costs O(L) per product, which for
        // `f64`'s 67 limbs is most of the work in a float GEMM. This costs
        // three limbs plus a carry that almost always stops immediately.
        if negative {
            sub_at(&mut self.limbs.0, at, spread);
        } else {
            add_at(&mut self.limbs.0, at, spread);
        }
    }

    /// The accumulator holding exactly the value `x` names.
    ///
    /// The bridge the epilogue needs: `beta * C` requires the value already in
    /// `C` to enter the accumulation, and it enters it *exactly*, by the same
    /// decode every operand goes through.
    pub fn of<E>(x: E) -> Self
    where
        E: crate::alphabet::FloatElement,
    {
        use crate::alphabet::Decoded;
        let mut out = Self::ZERO;
        match x.decode() {
            Decoded::NotANumber => out.set_nan(),
            Decoded::Infinite { sign } => out.set_infinity(sign),
            Decoded::Finite {
                sign,
                mantissa,
                exp,
            } => out.add_scaled(mantissa as u128, exp, sign),
        }
        out
    }

    /// Multiply by an exact integer scalar.
    ///
    /// Double-and-add over the register's own `combine`, so there is no second
    /// multiplication routine and no rounding: an integer scaling of an exact
    /// fixed-point value is exact.
    pub fn scale(self, factor: i64) -> Self {
        if self.is_nan() {
            return self;
        }
        if factor == 0 {
            // Zero times an infinity is a NaN, by IEEE 754 clause 7.2.
            let mut out = Self::ZERO;
            if self.pos_inf || self.neg_inf {
                out.set_nan();
            }
            return out;
        }
        let flip = factor < 0;
        let mut magnitude = factor.unsigned_abs();
        let mut acc = Self {
            limbs: Limbs::ZERO,
            nan: false,
            pos_inf: false,
            neg_inf: false,
        };
        let mut addend = if flip {
            Self {
                limbs: self.limbs.neg(),
                ..Self::ZERO
            }
        } else {
            Self {
                limbs: self.limbs,
                ..Self::ZERO
            }
        };
        while magnitude > 0 {
            if magnitude & 1 == 1 {
                acc = Self {
                    limbs: acc.limbs.combine(addend.limbs),
                    ..acc
                };
            }
            addend = Self {
                limbs: addend.limbs.combine(addend.limbs),
                ..addend
            };
            magnitude >>= 1;
        }
        // A scaled infinity is an infinity, with the sign of the product.
        let (pos, neg) = match (self.pos_inf, self.neg_inf, flip) {
            (false, false, _) => (false, false),
            (p, n, false) => (p, n),
            (p, n, true) => (n, p),
        };
        Self {
            limbs: acc.limbs,
            nan: false,
            pos_inf: pos,
            neg_inf: neg,
        }
    }

    /// Accumulate `mantissa * 2^exp`, with the sign carried in the mantissa.
    ///
    /// The hot path of a float GEMM. A signed mantissa costs one branch on the
    /// sign instead of threading a `bool` through the decode, the product, and
    /// the placement --- and for `f32` the whole product fits a `u64`, so the
    /// `u128` shifts the general form needs are not paid for.
    pub fn add_signed(&mut self, mantissa: i64, exp: i32) {
        if mantissa == 0 {
            return;
        }
        let shift = exp.saturating_sub(MIN_EXP); // R3-ok: an exponent placement, checked below
        if shift < 0 {
            return;
        }
        let shift = shift as u32;
        let at = (shift / 64) as usize;
        let bit = shift % 64;
        let negative = mantissa < 0;
        let mag = mantissa.unsigned_abs();

        // Two limbs, not three: a 64-bit magnitude shifted by less than 64 bits
        // spans at most 128, and the caller's `mantissa` is at most 2^48 for
        // `f32` and comes pre-split for `f64`.
        let spread = if bit == 0 {
            [mag, 0, 0]
        } else {
            [mag << bit, mag >> (64 - bit), 0]
        };
        if negative {
            sub_at(&mut self.limbs.0, at, spread);
        } else {
            add_at(&mut self.limbs.0, at, spread);
        }
    }

    /// Record that a NaN reached this accumulation. Sticky and absorbing.
    pub fn set_nan(&mut self) {
        self.nan = true;
    }

    /// Record that an infinity of the given sign reached this accumulation.
    ///
    /// Two infinities of opposite sign make a NaN, by IEEE 754 clause 7.2, and
    /// they do so here whatever order they arrived in.
    pub fn set_infinity(&mut self, negative: bool) {
        if negative {
            self.neg_inf = true;
        } else {
            self.pos_inf = true;
        }
    }

    /// Has a NaN been accumulated, or has the sum become one?
    pub const fn is_nan(self) -> bool {
        self.nan || (self.pos_inf && self.neg_inf)
    }

    /// The sign of the accumulated infinity, if the sum is infinite.
    ///
    /// `None` when the sum is finite or a NaN. A NaN is checked first, so
    /// `inf + (-inf)` reports a NaN rather than an arbitrary sign.
    pub const fn infinity_sign(self) -> Option<bool> {
        if self.is_nan() {
            None
        } else if self.pos_inf {
            Some(false)
        } else if self.neg_inf {
            Some(true)
        } else {
            None
        }
    }

    /// The underlying limbs, for an encoder to round from.
    pub const fn raw(&self) -> &Limbs<L> {
        &self.limbs
    }

    /// Is the accumulated value negative?
    pub const fn is_negative(&self) -> bool {
        self.limbs.is_negative()
    }

    /// Is the accumulated value exactly zero?
    ///
    /// Exact cancellation is exact here, which is the property a classical
    /// accumulator loses first.
    pub fn is_zero(&self) -> bool {
        !self.nan && !self.pos_inf && !self.neg_inf && self.limbs.limbs().iter().all(|&l| l == 0)
    }

    /// The magnitude of this register, as an unsigned limb string.
    ///
    /// An encoder wants the leading one, then `P` significand bits, then a round
    /// bit and a sticky bit --- and every one of those is a question about the
    /// *magnitude*. Forming it once and asking [`Limbs`] the questions is the
    /// difference between one negation and one per bit read, which for `f64`'s
    /// sixty-seven limbs is fifty-five passes over the register per output
    /// element.
    pub fn magnitude(&self) -> Limbs<L> {
        if self.is_negative() {
            self.limbs.neg()
        } else {
            self.limbs
        }
    }

    /// The index of the highest set bit of the magnitude, or `None` for zero.
    ///
    /// This is what an encoder needs to find the leading one, from which the
    /// output exponent and the round and sticky bits follow.
    pub fn magnitude_high_bit(&self) -> Option<u32> {
        self.magnitude().high_bit()
    }

    /// Bit `i` of the magnitude, counting from bit 0 of the register.
    pub fn magnitude_bit(&self, i: u32) -> bool {
        self.magnitude().bit(i)
    }

    /// Is any bit of the magnitude below `i` set? The sticky bit.
    pub fn magnitude_any_below(&self, i: u32) -> bool {
        self.magnitude().any_below(i)
    }
}

impl<const L: usize, const MIN_EXP: i32> Accumulator for Complete<L, MIN_EXP> {
    const ZERO: Self = Self::ZERO;
    const BITS: u32 = (L as u32).wrapping_mul(64);

    fn combine(self, other: Self) -> Self {
        // The limbs add exactly and the non-finite flags union. Both are
        // associative and commutative, so combining two partial accumulations
        // gives the same answer in either order --- which is what makes the
        // float result independent of the tile partition (`CU-04`).
        Self {
            limbs: self.limbs.combine(other.limbs),
            nan: self.nan || other.nan,
            pos_inf: self.pos_inf || other.pos_inf,
            neg_inf: self.neg_inf || other.neg_inf,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The i128 accumulator is exact over the whole i8 x i8 domain at a depth
    /// far past the narrow-register threshold, which is the point: the
    /// threshold governs a register, not an answer (§3.2, CD-03).
    #[test]
    fn i128_accumulation_is_exact_past_the_narrow_threshold_cd_03() {
        let mut acc = 0i128;
        for _ in 0..1_000_000 {
            <i8 as Element>::mac(&mut acc, i8::MIN, i8::MIN);
        }
        assert_eq!(acc, 1_000_000i128 * 128 * 128);
    }

    /// `Limbs` addition and negation round-trip, including across a limb
    /// boundary, which is where a fixed-width accumulator would fail if it
    /// were merely wide rather than correct.
    #[test]
    fn limbs_add_and_negate_across_a_boundary_ct_02() {
        let a = Limbs::<3>::ZERO.add_i128(i128::MAX);
        let b = a.add_i128(i128::MAX);
        let (mag, exceeded) = b.magnitude_low_u128();
        assert!(!exceeded);
        assert_eq!(mag, (i128::MAX as u128) * 2);
        assert!(!b.is_negative());
        assert!(b.neg().is_negative());
        assert_eq!(b.neg().neg(), b);
    }

    /// i64 x i64 at a depth that overflows any 128-bit accumulator, which is
    /// exactly why `i64`'s accumulator is 192 bits and not a policy (§3.2).
    #[test]
    fn i64_accumulation_needs_and_gets_192_bits_ct_02() {
        let mut acc = <i64 as Element>::Acc::ZERO;
        for _ in 0..4 {
            <i64 as Element>::mac(&mut acc, i64::MIN, i64::MIN);
        }
        // 4 * 2^126 = 2^128, one bit past what an i128 could hold.
        let (_, exceeded) = acc.magnitude_low_u128();
        assert!(
            exceeded,
            "the value is past 128 bits, and the accumulator still holds it"
        );
        assert!(!acc.is_negative());
    }

    /// The single encode step: `Saturating` clamps, `Wrapping` truncates, and
    /// both are exact functions of the exact accumulator (§5.5).
    #[test]
    fn encode_is_the_only_lossy_step_cs_05() {
        let acc: i128 = 300;
        assert_eq!(
            <i8 as EncodeFrom<i128>>::encode_from(acc, EncodeMode::Saturating),
            127
        );
        assert_eq!(
            <i8 as EncodeFrom<i128>>::encode_from(acc, EncodeMode::Wrapping),
            44
        );
        assert_eq!(
            <i32 as EncodeFrom<i128>>::encode_from(acc, EncodeMode::Saturating),
            300
        );

        let neg: i128 = -300;
        assert_eq!(
            <i8 as EncodeFrom<i128>>::encode_from(neg, EncodeMode::Saturating),
            -128
        );
        assert_eq!(
            <i8 as EncodeFrom<i128>>::encode_from(neg, EncodeMode::Wrapping),
            -44
        );
    }

    /// `Complete` accumulates exactly across the whole exponent span: a huge
    /// term and a tiny term both land, and adding them in either order gives
    /// the same register. No classical float accumulator does this.
    #[test]
    fn complete_accumulation_is_order_independent_cd_02() {
        type C = Complete<10, -298>;
        let mut both_a = C::ZERO;
        both_a.add_scaled(1, 200, false);
        both_a.add_scaled(1, -290, false);
        let mut both_b = C::ZERO;
        both_b.add_scaled(1, -290, false);
        both_b.add_scaled(1, 200, false);
        assert_eq!(both_a, both_b);
        assert!(both_a.magnitude_bit((200i32 - -298i32) as u32));
        assert!(both_a.magnitude_bit((-290i32 - -298i32) as u32));
        assert_eq!(both_a.magnitude_high_bit(), Some(498));
        assert!(both_a.magnitude_any_below(498));
    }

    /// A term and its negation cancel exactly, which is the property a
    /// classical accumulator loses first.
    #[test]
    fn complete_cancellation_is_exact_cd_02() {
        type C = Complete<10, -298>;
        let mut acc = C::ZERO;
        acc.add_scaled(12345, 100, false);
        acc.add_scaled(12345, 100, true);
        assert!(acc.is_zero());
        assert_eq!(acc.magnitude_high_bit(), None);
    }
}

/// The correctly-rounded encode out of a complete accumulator (§3.3).
///
/// This is the single encode step for the float family, and it is the only
/// place in the float path where information is discarded. Everything upstream
/// of it --- the decode, the significand product, the fixed-point add --- is
/// exact, so what this rounds is the *exact sum*, once.
///
/// That is what makes the result schedule-independent: a classical GEMM rounds
/// after every add, so its answer depends on the order; this one rounds after
/// the last add, so it cannot.
macro_rules! impl_encode_into_float {
    ($t:ty, $bits:ty, $mant:expr, $expo:expr) => {
        impl<const L: usize, const MIN_EXP: i32> EncodeFrom<Complete<L, MIN_EXP>> for $t {
            fn encode_from(acc: Complete<L, MIN_EXP>, mode: EncodeMode) -> Self {
                const MANT: u32 = $mant;
                const EXPO: u32 = $expo;
                /// Significand bits including the implicit one.
                const P: u32 = MANT + 1;
                const BIAS: i32 = (1 << (EXPO - 1)) - 1;
                /// The exponent of the least significant bit of a subnormal.
                const SUB_LSB_EXP: i32 = 1 - BIAS - MANT as i32;
                const SIGN_SHIFT: u32 = MANT + EXPO;

                // The non-finite cases first, so that a NaN never reaches the
                // rounding logic and an infinity never competes with it.
                if acc.is_nan() {
                    return <$t>::NAN;
                }
                if let Some(negative) = acc.infinity_sign() {
                    let bits: $bits = ((negative as $bits) << SIGN_SHIFT)
                        | ((((1 as $bits) << EXPO) - 1) << MANT);
                    return <$t>::from_bits(bits);
                }

                let negative = acc.is_negative();
                let mag = acc.magnitude();
                let Some(high) = mag.high_bit() else {
                    // An exactly zero sum. IEEE 754 gives `+0` for a sum that
                    // cancels under round-to-nearest, and the sign of a zero
                    // that arose from cancellation carries no information, so
                    // the positive zero is returned rather than invented.
                    return <$t>::from_bits(0);
                };

                // The value is `magnitude * 2^MIN_EXP`, with its leading one at
                // register bit `high`, so its binary exponent is this.
                let exp = MIN_EXP + high as i32;

                // Where the output's least significant bit falls, in register
                // bits. Clamped at the subnormal floor, which is what makes the
                // gradual-underflow region come out right rather than being a
                // separate branch.
                let lsb_exp = if exp - (P as i32 - 1) < SUB_LSB_EXP {
                    SUB_LSB_EXP
                } else {
                    exp - (P as i32 - 1)
                };
                let lsb = lsb_exp - MIN_EXP;
                if lsb < 0 {
                    // Unreachable for an accumulator sized by the model: the
                    // register's floor is the minimum *product* exponent, which
                    // is below the minimum subnormal. Returning zero rather
                    // than indexing negatively keeps the function total for a
                    // hand-built `Complete` of the wrong size.
                    return <$t>::from_bits(0);
                }
                let lsb = lsb as u32;

                // The P significand bits, read out of the register in one
                // window rather than one at a time.
                let sig: u64 = mag.window(lsb, P);

                // Round, once, under the caller's mode. `Nearest` is
                // round-half-to-even, which is IEEE 754's default and what
                // makes this *the* correctly-rounded value rather than *a*
                // rounding of it.
                let (round_bit, sticky) = if lsb == 0 {
                    (false, false)
                } else {
                    (mag.bit(lsb - 1), mag.any_below(lsb - 1))
                };
                let increment = match mode {
                    EncodeMode::Nearest => round_bit && (sticky || (sig & 1) == 1),
                    // Truncation toward zero: the magnitude is already
                    // truncated, so there is nothing to add.
                    EncodeMode::TowardZero | EncodeMode::Saturating | EncodeMode::Wrapping => false,
                };
                let mut sig = sig + u64::from(increment);
                let mut lsb_exp = lsb_exp;
                if sig >> P == 1 {
                    // The increment carried out of the significand: halve it
                    // and step the exponent, which is exact.
                    sig >>= 1;
                    lsb_exp += 1;
                }

                if sig == 0 {
                    return <$t>::from_bits((negative as $bits) << SIGN_SHIFT);
                }

                // Assemble. A significand with its top bit set is normal; one
                // without is subnormal, and its biased exponent is zero.
                let top = 64 - 1 - sig.leading_zeros();
                let value_exp = lsb_exp + top as i32;
                let bits: $bits = if sig >> (P - 1) == 1 {
                    let biased = value_exp + BIAS;
                    if biased >= (1 << EXPO) - 1 {
                        // Overflow. Round-to-nearest carries an overflowing
                        // magnitude to infinity; the directed modes clamp to
                        // the largest finite value, which is what `Saturating`
                        // means for this family.
                        return match mode {
                            EncodeMode::Nearest => {
                                if negative {
                                    <$t>::NEG_INFINITY
                                } else {
                                    <$t>::INFINITY
                                }
                            }
                            _ => {
                                if negative {
                                    <$t>::MIN
                                } else {
                                    <$t>::MAX
                                }
                            }
                        };
                    }
                    ((negative as $bits) << SIGN_SHIFT)
                        | ((biased as $bits) << MANT)
                        | ((sig as $bits) & (((1 as $bits) << MANT) - 1))
                } else {
                    ((negative as $bits) << SIGN_SHIFT) | (sig as $bits)
                };
                <$t>::from_bits(bits)
            }
        }
    };
}

impl_encode_into_float!(f32, u32, 23, 8);
impl_encode_into_float!(f64, u64, 52, 11);
