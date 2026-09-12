//! The reference accumulation (§5.4).
//!
//! This is the whole method, written plainly: decode is already done by the
//! time a slice of [`Alphabet`] exists, so what remains is *accumulate
//! exactly*, and the encode step happens once, later, in the driver.
//!
//! [`dot_ref`] is never optimized and never removed (R6). Every backend in
//! `uor-matmul-kernels` is differentially tested against it, and every backend
//! is a factorization of it rather than a rival to it.

use crate::alphabet::{Alphabet, Bound, Element, IntegerElement, NARROW_CAP};
use crate::bounds::fits_narrow;

/// The reference. Zip-truncating, exactly the upstream `dot`.
///
/// Total: no input of any length or magnitude can make it fail. The accumulator
/// is wide enough that overflow is unreachable (§3.2), so there is no length at
/// which this returns something other than the exact sum.
///
/// The accumulation is factored into narrow-register runs wherever
/// [`fits_narrow`] admits one, and the runs are combined into the wide
/// accumulator. The factorization is invisible: [`dot_wide`] computes the same
/// value without it, and `CD-03` asserts the two agree on every input.
///
/// # Examples
///
/// ```
/// # use uor_matmul_core::{as_alphabet_full, dot_ref};
/// let a = as_alphabet_full(&[1i8, 2, 3]);
/// let w = as_alphabet_full(&[4i8, 5, 6]);
/// assert_eq!(dot_ref(a, w), 32);
///
/// // Zip-truncating: the shorter operand sets the depth.
/// let short = as_alphabet_full(&[4i8, 5]);
/// assert_eq!(dot_ref(a, short), 14);
/// ```
pub fn dot_ref<E: IntegerElement, Bd: Bound>(
    a: &[Alphabet<E, Bd>],
    w: &[Alphabet<E, Bd>],
) -> <E as Element>::Acc {
    let k = a.len().min(w.len());
    let mut acc = <E::Acc as crate::acc::Accumulator>::ZERO;

    let Some(run) = narrow_run::<E, Bd>() else {
        for i in 0..k {
            E::mac(&mut acc, a[i].get(), w[i].get());
        }
        return acc;
    };

    let mut i = 0usize;
    while i < k {
        let end = k.min(i.saturating_add(run)); // R3-ok: cursor, clamped by `min`
        let mut narrow = 0i64;
        for j in i..end {
            narrow = E::mac_narrow(narrow, a[j].get(), w[j].get());
        }
        acc = E::combine_narrow(acc, narrow);
        i = end;
    }
    acc
}

/// The same accumulation forced through the wide register, ignoring
/// [`fits_narrow`].
///
/// Used to witness that the narrow-tile path agrees. If this and [`dot_ref`]
/// ever disagree, the narrow path has become a second method, and `CD-03`
/// fails before anything ships.
pub fn dot_wide<E: IntegerElement, Bd: Bound>(
    a: &[Alphabet<E, Bd>],
    w: &[Alphabet<E, Bd>],
) -> <E as Element>::Acc {
    let k = a.len().min(w.len());
    let mut acc = <E::Acc as crate::acc::Accumulator>::ZERO;
    for i in 0..k {
        E::mac(&mut acc, a[i].get(), w[i].get());
    }
    acc
}

/// Instrumented: the result, the maximum partial-sum magnitude reached, and the
/// number of tiles that took the narrow path.
///
/// `CD-03` and `CU-02` are measurements rather than inspections because of
/// this function: the claim "the narrow path was actually exercised" is a
/// number the test reads, not a property someone eyeballed in the source.
pub fn dot_instrumented<E: IntegerElement, Bd: Bound>(
    a: &[Alphabet<E, Bd>],
    w: &[Alphabet<E, Bd>],
) -> (<E as Element>::Acc, u128, usize) {
    let k = a.len().min(w.len());
    let mut acc = <E::Acc as crate::acc::Accumulator>::ZERO;
    let mut peak = 0u128;
    let mut narrow_tiles = 0usize;

    let run = narrow_run::<E, Bd>();
    let mut i = 0usize;
    while i < k {
        let end = match run {
            Some(r) => {
                narrow_tiles = narrow_tiles.saturating_add(1); // R3-ok: a counter
                k.min(i.saturating_add(r)) // R3-ok: cursor, clamped by `min`
            }
            None => k.min(i.saturating_add(1)), // R3-ok: cursor, clamped by `min`
        };
        let mut narrow = 0i64;
        for j in i..end {
            if run.is_some() {
                narrow = E::mac_narrow(narrow, a[j].get(), w[j].get());
                let m = narrow.unsigned_abs() as u128;
                if m > peak {
                    peak = m;
                }
            } else {
                E::mac(&mut acc, a[j].get(), w[j].get());
            }
        }
        if run.is_some() {
            acc = E::combine_narrow(acc, narrow);
        }
        i = end;
    }
    (acc, peak, narrow_tiles)
}

/// The longest run of products the narrow register can hold for this
/// instantiation, or `None` if this element type has no narrow register.
///
/// This is the only place the reference consults [`fits_narrow`], and what it
/// gets back is a run length, never a permission to proceed. A `None`, or a run
/// of one, produces the same integer as a run of a million.
fn narrow_run<E: IntegerElement, Bd: Bound>() -> Option<usize> {
    if !E::HAS_NARROW {
        return None;
    }
    // The largest `n` with `n * B^2 <= NARROW_CAP`, found by the same predicate
    // the kernels use, so that the reference and the backends factor the
    // accumulation the same way and `CB-*` compares like with like.
    let b = Bd::VALUE;
    if b == 0 {
        return Some(usize::MAX);
    }
    let per_step = b.checked_mul(b)?;
    let run = NARROW_CAP.checked_div(per_step)?;
    if run == 0 {
        return None;
    }
    let run = usize::try_from(run).unwrap_or(usize::MAX);
    debug_assert!(fits_narrow(b, NARROW_CAP, run));
    Some(run)
}

#[cfg(test)]
extern crate std;

#[cfg(test)]
// R7 governs the library, not its tests: these build operands on the heap so
// that depths past every threshold can be generated. `CA-01` witnesses the
// library's own zero-allocation claim with a counting allocator.
#[allow(clippy::disallowed_types)]
mod tests {
    use super::*;
    use crate::alphabet::{as_alphabet_full, Bnd, Full};
    use std::vec::Vec;

    /// CD-03: the narrow factorization is invisible. Whatever the bound, the
    /// two functions agree, so `fits_narrow` never reaches the answer.
    #[test]
    fn narrow_and_wide_agree_cd_03() {
        let a: [i8; 512] = core::array::from_fn(|i| ((i as i32 % 255) - 127) as i8);
        let w: [i8; 512] = core::array::from_fn(|i| ((i as i32 * 7 % 255) - 127) as i8);

        let af = as_alphabet_full(&a);
        let wf = as_alphabet_full(&w);
        assert_eq!(dot_ref(af, wf), dot_wide(af, wf));

        // A tighter declaration lengthens the narrow run. The run length is the
        // only thing that changes; the integer is the same one.
        let a7 = crate::alphabet::as_alphabet::<i8, Bnd<127>>(&a).unwrap();
        let w7 = crate::alphabet::as_alphabet::<i8, Bnd<127>>(&w).unwrap();
        assert_eq!(dot_ref(a7, w7), dot_wide(a7, w7));
        assert_eq!(dot_ref(a7, w7), dot_ref(af, wf));
        assert!(narrow_run::<i8, Bnd<127>>() > narrow_run::<i8, Full<i8>>());
    }

    /// `CD-09`: the narrow-register tile path agrees with `dot_wide`, over
    /// depths on both sides of every threshold.
    ///
    /// This is the claim that makes the narrow path an optimization rather than
    /// a fallback: if it ever disagreed, the library would have two answers.
    #[test]
    fn the_narrow_tile_path_agrees_with_dot_wide_cd_09() {
        for k in [0usize, 1, 2, 3, 127, 128, 129, 1_000, 4_096, 10_007] {
            let a: Vec<i8> = (0..k)
                .map(|i| ((i * 31 % 255) as i32 - 127) as i8)
                .collect();
            let w: Vec<i8> = (0..k)
                .map(|i| ((i * 71 % 255) as i32 - 127) as i8)
                .collect();
            assert_eq!(
                dot_ref(as_alphabet_full(&a), as_alphabet_full(&w)),
                dot_wide(as_alphabet_full(&a), as_alphabet_full(&w)),
                "k={k}"
            );
            // And with the extremes, where the lane fills fastest.
            let ext = std::vec![i8::MIN; k];
            assert_eq!(
                dot_ref(as_alphabet_full(&ext), as_alphabet_full(&ext)),
                dot_wide(as_alphabet_full(&ext), as_alphabet_full(&ext)),
                "k={k} at the extremes"
            );
        }
    }

    /// CU-02: the narrow path is exercised, and the test reads the count rather
    /// than trusting the source.
    #[test]
    fn the_narrow_path_is_measured_cu_02() {
        let a: [i8; 300] = core::array::from_fn(|i| (i % 127) as i8);
        let w: [i8; 300] = core::array::from_fn(|i| (i % 63) as i8);
        let (value, peak, tiles) = dot_instrumented(as_alphabet_full(&a), as_alphabet_full(&w));
        assert_eq!(value, dot_wide(as_alphabet_full(&a), as_alphabet_full(&w)));
        assert!(tiles >= 1, "the narrow path must actually be taken for i8");
        assert!(peak > 0);
    }

    /// CT-01: zero depth and one-element depth are not special cases.
    #[test]
    fn empty_and_singleton_are_not_special_ct_04() {
        let empty: [i8; 0] = [];
        assert_eq!(
            dot_ref(as_alphabet_full(&empty), as_alphabet_full(&empty)),
            0
        );
        assert_eq!(
            dot_ref(as_alphabet_full(&[7i8]), as_alphabet_full(&[6i8])),
            42
        );
    }

    /// CT-01: a depth past every narrow-register threshold still returns the
    /// exact sum, because there is no threshold on the answer (§3.2).
    #[test]
    fn depth_past_every_threshold_is_exact_ct_01() {
        const K: usize = 200_000;
        let a = [i8::MIN; K];
        let w = [i8::MIN; K];
        let expected = (K as i128) * 128 * 128;
        assert_eq!(
            dot_ref(as_alphabet_full(&a), as_alphabet_full(&w)),
            expected
        );
        assert_eq!(
            dot_wide(as_alphabet_full(&a), as_alphabet_full(&w)),
            expected
        );
    }
}
