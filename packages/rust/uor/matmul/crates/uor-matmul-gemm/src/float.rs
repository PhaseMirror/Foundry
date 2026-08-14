//! GEMM over float operands (§3.3, S6).
//!
//! Not a second driver, and not a second method. A float is a code; it decodes
//! to an exact dyadic rational; the products land in a complete accumulator
//! where every add is exact; and the result is rounded once, at the end. That
//! is the same sentence [`crate::gemm`] realizes, at a different instantiation
//! of the same three steps.
//!
//! The library never adds two floats. Every addition below happens in a
//! fixed-point integer register, which is why the result is
//! schedule-independent, tile-independent, and substrate-independent --- and
//! why it is *not* bit-identical to a classical `sgemm` (N1).

use uor_matmul_core::{AccOf, Accumulator, Complete, EncodeFrom, FloatElement, PackedCode, Triple};

use crate::driver::GemmOptions;
use crate::epilogue::Epilogue;

/// `C := epilogue(A * B, C)`, over float operands, computed exactly.
///
/// Returns `()`, for the same reason [`crate::gemm`] does: the requested
/// product exists, because a [`Triple`] exists (R14, C6). Non-finite inputs are
/// codes and propagate by the IEEE rules; they are not an error condition
/// (`CT-03`).
pub fn gemm_float<E, O, Ep>(
    triple: &mut Triple<'_, '_, '_, E, O>,
    epilogue: &Ep,
    options: GemmOptions,
) where
    E: FloatElement,
    O: EncodeFrom<AccOf<E>> + Copy,
    Ep: Epilogue<E, O>,
    AccOf<E>: SignedPlace,
{
    gemm_float_packed(triple, epilogue, options, &mut [], &mut [])
}

/// The same operation, with somewhere to decode into.
///
/// A float is a code, and decoding it is real work: a bit test, two shifts, a
/// mask, and a branch. The naive traversal decodes `B[p][j]` once for every row
/// of `A`, so every element of `B` is decoded `m` times and every element of
/// `A` is decoded `n` times. Decoding once into a panel and multiplying many
/// times removes both factors, which is the same structural point the integer
/// driver makes by packing --- and here it is worth more, because a decode
/// costs far more than a copy.
///
/// The panels are the caller's, so this still allocates nothing. Offering none
/// runs the streaming traversal, which decodes per element and gives the same
/// bytes (S13, `CD-04`).
pub fn gemm_float_packed<E, O, Ep>(
    triple: &mut Triple<'_, '_, '_, E, O>,
    epilogue: &Ep,
    options: GemmOptions,
    pa: &mut [PackedCode],
    pb: &mut [PackedCode],
) where
    E: FloatElement,
    O: EncodeFrom<AccOf<E>> + Copy,
    Ep: Epilogue<E, O>,
    AccOf<E>: SignedPlace,
{
    let shape = triple.shape();
    if shape.m == 0 || shape.n == 0 {
        return;
    }
    let reads_c = epilogue.reads_c();
    let (a, b, c) = triple.parts();

    // One row of `A` and one column of `B` is the smallest offer that removes a
    // whole factor of redundant decoding; below it, the streaming traversal
    // runs. The same identity, walked differently (S13).
    if pa.len() < shape.k || pb.len() < shape.k {
        for i in 0..shape.m {
            for j in 0..shape.n {
                let mut acc = <AccOf<E> as Accumulator>::ZERO;
                for p in 0..shape.k {
                    acc.accumulate_one(a.at(i, p).pack(), b.at(p, j).pack());
                }
                let prior = if reads_c { Some(*c.at(i, j)) } else { None };
                *c.at_mut(i, j) = epilogue.finish(acc, prior, options.encode);
            }
        }
        return;
    }

    // Columns of `B` that fit the offer at once. Every column decodes `B`'s
    // whole depth once and then serves every row of `A`.
    let block = (pb.len() / shape.k).min(shape.n).max(1);

    // The element type's significand width decides whether a product of two of
    // them can leave an `i64`. It is a constant of the type, not of the data.
    let product_fits = 2 * E::SIGNIFICAND_BITS <= 63;

    let mut j0 = 0;
    while j0 < shape.n {
        let cols = block.min(shape.n - j0);
        // Whether this block of `B` is finite is settled here, while its codes
        // are being walked anyway, rather than once per product afterwards.
        let mut b_finite = true;
        for (jj, j) in (j0..j0 + cols).enumerate() {
            let dst = &mut pb[jj * shape.k..jj * shape.k + shape.k];
            for (slot, v) in dst.iter_mut().zip(b.column_walk(0, j, shape.k)) {
                *slot = v.pack();
                b_finite &= slot.is_finite();
            }
        }

        for i in 0..shape.m {
            // Decode row `i` of `A` once, and serve every column of this block
            // from it. Walking rather than indexing, for the reason the integer
            // packer walks: two multiplies per element is most of the cost of a
            // decode that is otherwise a handful of bit operations.
            let mut a_finite = true;
            for (slot, v) in pa[..shape.k].iter_mut().zip(a.row_walk(i, 0, shape.k)) {
                *slot = v.pack();
                a_finite &= slot.is_finite();
            }
            let panels = PanelFacts {
                finite: a_finite && b_finite,
                product_fits,
            };
            for (jj, j) in (j0..j0 + cols).enumerate() {
                let mut acc = <AccOf<E> as Accumulator>::ZERO;
                acc.accumulate_panels(
                    &pa[..shape.k],
                    &pb[jj * shape.k..jj * shape.k + shape.k],
                    panels,
                );
                let prior = if reads_c { Some(*c.at(i, j)) } else { None };
                *c.at_mut(i, j) = epilogue.finish(acc, prior, options.encode);
            }
        }
        j0 += cols;
    }
}

/// A limb window over a complete accumulator (D-12).
///
/// Every product must land at its own position for the sum to be exact, and
/// that is what makes a complete accumulator expensive: a spread across limbs
/// and a carry, per product.
///
/// But a *run* of products whose exponents share a limb can be summed in one
/// 128-bit register first and placed once. For weights and activations of
/// similar magnitude --- which is the ordinary case, and the whole reason
/// quantization works --- that is nearly every product, and the cost per
/// product falls to one shift and one add.
///
/// It is not an approximation and not a fast path. The window holds an exact
/// integer at a known scale; flushing it adds that integer at that scale. What
/// changes is how often the wide register is touched, and nothing else.
struct Window<'a, const L: usize, const MIN_EXP: i32> {
    acc: &'a mut Complete<L, MIN_EXP>,
    /// The limb the window sits at, or `usize::MAX` when it is empty.
    at: usize,
    /// The window's contents, at scale `64 * at`.
    bits: i128,
}

impl<const L: usize, const MIN_EXP: i32> Window<'_, L, MIN_EXP> {
    #[inline(always)]
    fn place(&mut self, mantissa: i64, exp: i32) {
        if mantissa == 0 {
            return;
        }
        let shift = exp.wrapping_sub(MIN_EXP);
        if shift < 0 {
            // Below the register's floor. Unreachable for any pair of finite
            // values of the element type this register was sized for.
            return;
        }
        let at = (shift as u32 / 64) as usize;
        let bit = shift as u32 % 64;
        let value = i128::from(mantissa) << bit;

        if at == self.at {
            // The window's own capacity decides when to flush, and it is asked
            // rather than assumed. A term reaches `2^125` for `f64`, so any
            // fixed count would be either wrong or needlessly small --- and a
            // fixed count is an arbitrary ceiling, which R8 does not permit.
            // `checked_add` is the exact question, and its `None` branch is
            // taken about once per `2^60` products for realistic data.
            if let Some(sum) = self.bits.checked_add(value) {
                self.bits = sum;
                return;
            }
        }
        self.flush();
        self.at = at;
        self.bits = value;
    }

    #[inline]
    fn flush(&mut self) {
        if self.at == usize::MAX || self.bits == 0 {
            return;
        }
        // The window holds an exact integer at scale `64 * at`, and placing a
        // magnitude at a scale is exactly what `add_scaled` does: one three-limb
        // spread and one carry, against the four separate `add_signed` calls
        // this used to make by cutting the window into 63-bit pieces. Realistic
        // data flushes whenever the product exponent crosses a limb boundary, so
        // this is not a rare path.
        self.acc.add_scaled(
            self.bits.unsigned_abs(),
            MIN_EXP + (self.at as i32) * 64,
            self.bits < 0,
        );
        self.bits = 0;
    }
}

/// Accumulate a whole dot product of two decoded panels.
///
/// Straight-line for the finite case, which is every product in every ordinary
/// matrix, with one predictable branch guarding the IEEE clause 6 rules.
#[inline]
fn accumulate_run<const L: usize, const MIN_EXP: i32>(
    acc: &mut Complete<L, MIN_EXP>,
    pa: &[PackedCode],
    pb: &[PackedCode],
    panels: PanelFacts,
) {
    let mut window = Window {
        acc,
        at: usize::MAX,
        bits: 0,
    };

    // Both panels finite, and the element type's significands narrow enough that
    // no product can leave an `i64`: then the loop is the three lines it should
    // be, with no per-product test of anything. Both are facts about the *panel*
    // and the *type*, established once, so this is the same arithmetic asked
    // fewer questions --- not a second method (R13). `CU-04` compares it against
    // the per-product traversal on the same operands.
    if panels.finite && panels.product_fits {
        for (a, b) in pa.iter().zip(pb) {
            window.place(a.mantissa * b.mantissa, a.exp + b.exp);
        }
        window.flush();
        return;
    }

    for (a, b) in pa.iter().zip(pb) {
        if a.is_finite() && b.is_finite() {
            // Does the product fit a signed 64-bit mantissa? For `f32` it
            // always does --- two 24-bit significands make 48 bits --- and for
            // `f64` it sometimes does. `checked_mul` asks exactly that
            // question, so there is no width constant to get wrong and no
            // element type this branch is tuned for.
            if let Some(product) = a.mantissa.checked_mul(b.mantissa) {
                window.place(product, a.exp + b.exp);
            } else {
                let sign = (a.mantissa < 0) != (b.mantissa < 0);
                let (ua, ub) = (a.mantissa.unsigned_abs(), b.mantissa.unsigned_abs());
                let (lo, hi) = (ua & 0xFFFF_FFFF, ua >> 32);
                let sgn = |v: u128| {
                    if sign {
                        -((v & ((1 << 62) - 1)) as i64)
                    } else {
                        (v & ((1 << 62) - 1)) as i64
                    }
                };
                let l = u128::from(lo) * u128::from(ub);
                let h = u128::from(hi) * u128::from(ub);
                let e = a.exp + b.exp;
                window.place(sgn(l), e);
                window.place(sgn(l >> 62), e + 62);
                window.place(sgn(h), e + 32);
                window.place(sgn(h >> 62), e + 94);
            }
            continue;
        }
        window.flush();
        if a.is_nan() || b.is_nan() {
            window.acc.set_nan();
            continue;
        }
        // An infinity times a zero is a NaN, by IEEE 754 clause 7.2; otherwise
        // the sign is the product of the two mantissa signs, which the packing
        // already arranged.
        let (inf, other) = if a.is_infinite() { (a, b) } else { (b, a) };
        if other.is_finite() && other.mantissa == 0 {
            window.acc.set_nan();
        } else {
            window
                .acc
                .set_infinity((inf.mantissa < 0) != (other.mantissa < 0));
        }
    }
    window.flush();
}

/// What a caller has already established about a pair of decoded panels.
///
/// Neither field can change a value. `finite` says the IEEE clause 6 rules have
/// nothing to do here, and `product_fits` is a property of the element type's
/// significand width --- `2 * 24 <= 63` for `f32`. Both are asked once instead
/// of once per product.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct PanelFacts {
    /// Every code in both panels is finite.
    pub finite: bool,
    /// Every product of two significands of this element type fits an `i64`.
    pub product_fits: bool,
}

impl PanelFacts {
    /// Establish nothing. Always admissible, and always the same answer.
    pub const UNKNOWN: Self = Self {
        finite: false,
        product_fits: false,
    };
}

/// What the packed float loop needs from an accumulator.
///
/// A trait rather than an inherent method so that `gemm_float_packed` stays
/// generic over the element type while the hot path stays monomorphic.
pub trait SignedPlace {
    /// Accumulate a whole dot product of two decoded panels, exactly.
    fn accumulate_panels(&mut self, pa: &[PackedCode], pb: &[PackedCode], panels: PanelFacts);
    /// Accumulate one product of two decoded codes.
    fn accumulate_one(&mut self, a: PackedCode, b: PackedCode);
}

impl<const L: usize, const MIN_EXP: i32> SignedPlace for Complete<L, MIN_EXP> {
    #[inline]
    fn accumulate_panels(&mut self, pa: &[PackedCode], pb: &[PackedCode], panels: PanelFacts) {
        accumulate_run(self, pa, pb, panels);
    }

    #[inline]
    fn accumulate_one(&mut self, a: PackedCode, b: PackedCode) {
        accumulate_run(self, &[a], &[b], PanelFacts::UNKNOWN);
    }
}

#[cfg(test)]
// R7 governs the library, not its tests: these build operands on the heap so
// that awkward shapes and long reduction orders can be generated. `CA-01`
// witnesses the library's own zero-allocation claim with a counting allocator.
#[allow(clippy::disallowed_types)]
mod tests {
    use super::*;
    use crate::epilogue::Linear;
    use std::vec;
    use std::vec::Vec;
    use uor_matmul_core::{EncodeMode, MatView, MatViewMut};

    fn product(m: usize, k: usize, n: usize, a: &[f32], b: &[f32]) -> Vec<f32> {
        let mut c = vec![0.0f32; m * n];
        {
            let av = MatView::row_major(a, m, k).unwrap();
            let bv = MatView::row_major(b, k, n).unwrap();
            let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            gemm_float(&mut t, &Linear::OVERWRITE, GemmOptions::default());
        }
        c
    }

    /// The ordinary case is ordinary: an exact small product is exactly right.
    #[test]
    fn small_exact_products_are_exact_cs_01() {
        let a = [1.0f32, 2.0, 3.0, 4.0];
        let b = [5.0f32, 6.0, 7.0, 8.0];
        assert_eq!(product(2, 2, 2, &a, &b), vec![19.0, 22.0, 43.0, 50.0]);
    }

    /// `CU-04`: the classic catastrophic-cancellation case. A classical `sgemm`
    /// gets `0.0` or `1.0` here depending on the order it happens to add in;
    /// the exact sum is `1.0` and there is no order in which this returns
    /// anything else.
    #[test]
    fn catastrophic_cancellation_is_exact_cu_04() {
        let big = 1.0e30f32;
        // 1e30 + 1.0 - 1e30. In f32, `1e30 + 1.0` rounds back to `1e30`, so a
        // classical accumulator loses the 1.0 entirely.
        let a = [1.0f32, 1.0, 1.0];
        let b = [big, 1.0, -big];
        assert_eq!(product(1, 3, 1, &a, &b), vec![1.0f32]);

        // And the naive float sum really does lose it, so this is not a
        // vacuous comparison.
        let naive = a.iter().zip(b.iter()).fold(0.0f32, |s, (x, y)| s + x * y);
        assert_eq!(naive, 0.0f32, "a classical accumulator loses the 1.0");
    }

    /// `CU-04`: shuffling the reduction order cannot change the answer, because
    /// nothing is rounded until the end. No classical `f32` GEMM has this
    /// property.
    #[test]
    fn float_accumulation_is_order_independent_cu_04() {
        let k = 257;
        let a: Vec<f32> = (0..k).map(|i| ((i * 37 % 1000) as f32) * 1.0e-3).collect();
        let b: Vec<f32> = (0..k).map(|i| ((i * 53 % 997) as f32) * 1.0e3).collect();
        let reference = product(1, k, 1, &a, &b);

        // The same terms in a different order.
        let mut order: Vec<usize> = (0..k).collect();
        for round in 0..8 {
            order.rotate_left(round * 7 + 1);
            let a2: Vec<f32> = order.iter().map(|&i| a[i]).collect();
            let b2: Vec<f32> = order.iter().map(|&i| b[i]).collect();
            assert_eq!(product(1, k, 1, &a2, &b2), reference, "round {round}");
        }
    }

    /// `CT-03`: non-finite codes propagate by the IEEE rules and never error.
    #[test]
    fn non_finite_codes_propagate_ct_03() {
        let inf = f32::INFINITY;
        assert!(product(1, 1, 1, &[inf], &[2.0])[0].is_infinite());
        assert!(product(1, 1, 1, &[-inf], &[2.0])[0] == f32::NEG_INFINITY);
        // Infinity times zero is a NaN, by clause 7.2.
        assert!(product(1, 1, 1, &[inf], &[0.0])[0].is_nan());
        // Opposite infinities in one sum are a NaN, whatever order they arrive.
        assert!(product(1, 2, 1, &[1.0, 1.0], &[inf, -inf])[0].is_nan());
        assert!(product(1, 2, 1, &[1.0, 1.0], &[-inf, inf])[0].is_nan());
        // A NaN anywhere absorbs.
        assert!(product(1, 3, 1, &[1.0, 1.0, 1.0], &[1.0, f32::NAN, 1.0])[0].is_nan());
    }

    /// `CD-05`: the encode mode is the only thing that changes the bytes for a
    /// fixed accumulation. `Nearest` rounds half to even; `TowardZero`
    /// truncates.
    #[test]
    fn the_encode_mode_is_the_only_variable_cd_05() {
        // A sum that needs rounding: 2^-24 past 1.0 is exactly half an ulp.
        let a = [1.0f32, 1.0];
        let b = [1.0f32, f32::from_bits(0x3380_0000)]; // 2^-24
        let nearest = {
            let mut c = [0.0f32];
            let av = MatView::row_major(&a, 1, 2).unwrap();
            let bv = MatView::row_major(&b, 2, 1).unwrap();
            let cv = MatViewMut::row_major(&mut c, 1, 1).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            gemm_float(&mut t, &Linear::OVERWRITE, GemmOptions::default());
            c[0]
        };
        let toward_zero = {
            let mut c = [0.0f32];
            let av = MatView::row_major(&a, 1, 2).unwrap();
            let bv = MatView::row_major(&b, 2, 1).unwrap();
            let cv = MatViewMut::row_major(&mut c, 1, 1).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            gemm_float(
                &mut t,
                &Linear::OVERWRITE,
                GemmOptions {
                    encode: EncodeMode::TowardZero,
                    ..Default::default()
                },
            );
            c[0]
        };
        // Exactly halfway: nearest-even keeps 1.0, truncation also keeps 1.0.
        assert_eq!(nearest, 1.0);
        assert_eq!(toward_zero, 1.0);

        // Just past halfway: nearest rounds up, truncation does not.
        let b2 = [1.0f32, f32::from_bits(0x3400_0000)]; // 2^-23, a full ulp
        let mut c = [0.0f32];
        let av = MatView::row_major(&a, 1, 2).unwrap();
        let bv = MatView::row_major(&b2, 2, 1).unwrap();
        let cv = MatViewMut::row_major(&mut c, 1, 1).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm_float(&mut t, &Linear::OVERWRITE, GemmOptions::default());
        assert_eq!(c[0], 1.0 + f32::EPSILON);
    }

    /// Subnormals are not a special case: gradual underflow falls out of the
    /// same clamp that puts the least significant bit at its floor.
    #[test]
    fn subnormals_round_correctly_ct_03() {
        let tiny = f32::from_bits(1); // 2^-149, the smallest subnormal
                                      // tiny * 1.0 is exactly tiny.
        assert_eq!(product(1, 1, 1, &[tiny], &[1.0]), vec![tiny]);
        // Four of them sum to 4 * 2^-149, still subnormal and still exact.
        let a = [1.0f32; 4];
        let b = [tiny; 4];
        assert_eq!(product(1, 4, 1, &a, &b), vec![f32::from_bits(4)]);
        // A product below the subnormal floor rounds to zero, once.
        let half_tiny = product(1, 1, 1, &[tiny], &[0.25]);
        assert_eq!(half_tiny, vec![0.0f32]);
    }

    /// Overflow reaches infinity under `Nearest` and clamps under the directed
    /// modes. Either way it happens once, in the encode step.
    #[test]
    fn overflow_happens_once_in_the_encode_step_cs_05() {
        let big = f32::MAX;
        let a = [1.0f32, 1.0];
        let b = [big, big];
        assert_eq!(product(1, 2, 1, &a, &b), vec![f32::INFINITY]);

        let mut c = [0.0f32];
        let av = MatView::row_major(&a, 1, 2).unwrap();
        let bv = MatView::row_major(&b, 2, 1).unwrap();
        let cv = MatViewMut::row_major(&mut c, 1, 1).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm_float(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions {
                encode: EncodeMode::Saturating,
                ..Default::default()
            },
        );
        assert_eq!(c[0], f32::MAX);
    }

    /// f64 takes the same path at a different instantiation.
    #[test]
    fn f64_takes_the_same_path_cu_05() {
        let a = [1.0f64, 1.0, 1.0];
        let b = [1.0e300f64, 1.0, -1.0e300];
        let mut c = [0.0f64];
        let av = MatView::row_major(&a, 1, 3).unwrap();
        let bv = MatView::row_major(&b, 3, 1).unwrap();
        let cv = MatViewMut::row_major(&mut c, 1, 1).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm_float(&mut t, &Linear::OVERWRITE, GemmOptions::default());
        assert_eq!(c[0], 1.0f64);
    }
}

#[cfg(test)]
#[allow(clippy::disallowed_types)]
mod window_tests {
    use super::*;
    use std::vec;
    use std::vec::Vec;
    use uor_matmul_core::{MatView, MatViewMut};

    /// The window is exact for adversarial exponents.
    ///
    /// A window holds an exact integer at a known scale, and a term reaches
    /// `2^125` for `f64`. Any fixed flush count would be wrong for some input;
    /// this is the input that finds it. The exponents are chosen so that every
    /// product lands in the same limb with the largest possible shift within
    /// it, which is the worst case for the window's capacity.
    #[test]
    fn the_window_is_exact_at_full_width_cu_04() {
        for k in [1usize, 2, 3, 4, 5, 8, 17, 64, 1000] {
            // Significands with every bit set, so each product is full width.
            let a: Vec<f64> = (0..k)
                .map(|i| f64::from_bits(0x433F_FFFF_FFFF_FFFF - (i as u64 % 3)))
                .collect();
            let b: Vec<f64> = (0..k)
                .map(|i| f64::from_bits(0x433F_FFFF_FFFF_FFFF - (i as u64 % 5)))
                .collect();

            let mut packed = [0.0f64];
            {
                let av = MatView::row_major(&a, 1, k).unwrap();
                let bv = MatView::row_major(&b, k, 1).unwrap();
                let cv = MatViewMut::row_major(&mut packed, 1, 1).unwrap();
                let mut t = Triple::new(av, bv, cv).unwrap();
                let mut pa = vec![uor_matmul_core::PackedCode::default(); k];
                let mut pb = vec![uor_matmul_core::PackedCode::default(); k];
                gemm_float_packed(
                    &mut t,
                    &crate::epilogue::Linear::OVERWRITE,
                    GemmOptions::default(),
                    &mut pa,
                    &mut pb,
                );
            }

            // The streaming traversal, which places every product on its own
            // and never fills a window. If the two disagree, the window lost a
            // carry.
            let mut streamed = [0.0f64];
            {
                let av = MatView::row_major(&a, 1, k).unwrap();
                let bv = MatView::row_major(&b, k, 1).unwrap();
                let cv = MatViewMut::row_major(&mut streamed, 1, 1).unwrap();
                let mut t = Triple::new(av, bv, cv).unwrap();
                gemm_float_packed(
                    &mut t,
                    &crate::epilogue::Linear::OVERWRITE,
                    GemmOptions::default(),
                    &mut [],
                    &mut [],
                );
            }
            assert_eq!(
                packed, streamed,
                "k={k}: the window disagreed with per-product placement"
            );
        }
    }

    /// `CU-04`: what a panel establishes cannot change what it computes.
    ///
    /// The packed traversal settles two facts once per panel --- that every code
    /// is finite, and that this element type's products fit an `i64` --- and then
    /// runs a loop with no per-product test. The streaming traversal establishes
    /// neither and tests everything. They must agree on every input, including
    /// the ones where the facts are false: a non-finite code anywhere, and `f64`
    /// significands wide enough that a product leaves an `i64`.
    #[test]
    fn what_a_panel_establishes_cannot_change_it_cu_04() {
        fn both_ways_agree_f32(k: usize, a: &[f32], b: &[f32]) {
            let mut packed = vec![0.0f32; 1];
            let mut streamed = vec![0.0f32; 1];
            let mut pa = vec![uor_matmul_core::PackedCode::default(); k];
            let mut pb = vec![uor_matmul_core::PackedCode::default(); k];
            for (out, offer) in [(&mut packed, true), (&mut streamed, false)] {
                let av = MatView::row_major(a, 1, k).unwrap();
                let bv = MatView::row_major(b, k, 1).unwrap();
                let cv = MatViewMut::row_major(out.as_mut_slice(), 1, 1).unwrap();
                let mut t = Triple::new(av, bv, cv).unwrap();
                let (x, y): (&mut [_], &mut [_]) = if offer {
                    (&mut pa, &mut pb)
                } else {
                    (&mut [], &mut [])
                };
                gemm_float_packed(
                    &mut t,
                    &crate::epilogue::Linear::OVERWRITE,
                    GemmOptions::default(),
                    x,
                    y,
                );
            }
            assert_eq!(
                packed[0].to_bits(),
                streamed[0].to_bits(),
                "the panel facts changed the answer"
            );
        }

        let k = 64usize;
        // Finite, full significand width, exponents spread across limbs.
        let a: Vec<f32> = (0..k)
            .map(|i| f32::from_bits(0x4B7F_FFFF - (i as u32 % 7) - ((i as u32 % 11) << 23)))
            .collect();
        let b: Vec<f32> = (0..k)
            .map(|i| f32::from_bits(0x3F7F_FFFF - (i as u32 % 5) - ((i as u32 % 13) << 23)))
            .collect();
        both_ways_agree_f32(k, &a, &b);

        // A non-finite code makes `finite` false, so the general loop runs; it
        // must still agree with the streaming one it is compared against.
        for at in [0usize, 1, 31, 63] {
            for bad in [f32::INFINITY, f32::NEG_INFINITY, f32::NAN, 0.0] {
                let mut a2 = a.clone();
                a2[at] = bad;
                both_ways_agree_f32(k, &a2, &b);
                let mut b2 = b.clone();
                b2[at] = bad;
                both_ways_agree_f32(k, &a, &b2);
            }
        }

        // `f64`, where two significands make 106 bits and no product fits an
        // `i64`, so `product_fits` is false for the whole type.
        let a: Vec<f64> = (0..k)
            .map(|i| f64::from_bits(0x433F_FFFF_FFFF_FFFF - (i as u64 % 7)))
            .collect();
        let b: Vec<f64> = (0..k)
            .map(|i| f64::from_bits(0x3FEF_FFFF_FFFF_FFFF - (i as u64 % 5)))
            .collect();
        let mut packed = [0.0f64];
        let mut streamed = [0.0f64];
        let mut pa = vec![uor_matmul_core::PackedCode::default(); k];
        let mut pb = vec![uor_matmul_core::PackedCode::default(); k];
        for (out, offer) in [(&mut packed, true), (&mut streamed, false)] {
            let av = MatView::row_major(&a, 1, k).unwrap();
            let bv = MatView::row_major(&b, k, 1).unwrap();
            let cv = MatViewMut::row_major(out.as_mut_slice(), 1, 1).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            let (x, y): (&mut [_], &mut [_]) = if offer {
                (&mut pa, &mut pb)
            } else {
                (&mut [], &mut [])
            };
            gemm_float_packed(
                &mut t,
                &crate::epilogue::Linear::OVERWRITE,
                GemmOptions::default(),
                x,
                y,
            );
        }
        assert_eq!(packed[0].to_bits(), streamed[0].to_bits());
    }

    /// The window carries exactly across a limb boundary, where a term in one
    /// limb and a term in the next must not be added to each other.
    #[test]
    fn the_window_carries_across_limbs_cu_04() {
        // Exponents 64 apart put consecutive products in different limbs.
        let k = 128usize;
        let a: Vec<f64> = (0..k).map(|i| (2.0f64).powi(i as i32 * 8 - 500)).collect();
        let b: Vec<f64> = vec![1.0; k];

        let mut packed = [0.0f64];
        let mut pa = vec![uor_matmul_core::PackedCode::default(); k];
        let mut pb = vec![uor_matmul_core::PackedCode::default(); k];
        {
            let av = MatView::row_major(&a, 1, k).unwrap();
            let bv = MatView::row_major(&b, k, 1).unwrap();
            let cv = MatViewMut::row_major(&mut packed, 1, 1).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            gemm_float_packed(
                &mut t,
                &crate::epilogue::Linear::OVERWRITE,
                GemmOptions::default(),
                &mut pa,
                &mut pb,
            );
        }
        let mut streamed = [0.0f64];
        {
            let av = MatView::row_major(&a, 1, k).unwrap();
            let bv = MatView::row_major(&b, k, 1).unwrap();
            let cv = MatViewMut::row_major(&mut streamed, 1, 1).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            gemm_float_packed(
                &mut t,
                &crate::epilogue::Linear::OVERWRITE,
                GemmOptions::default(),
                &mut [],
                &mut [],
            );
        }
        assert_eq!(packed, streamed);
    }
}
