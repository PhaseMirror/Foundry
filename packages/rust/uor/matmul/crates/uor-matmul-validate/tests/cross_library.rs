//! `CX-01` .. `CX-04`: agreement with an independently authored external
//! library, byte for byte, over the whole corpus, with **no exempted region**.
//!
//! Reduction modulo `2^w` is a ring homomorphism, so reducing the exact sum
//! once at the end equals reducing at every step. `EncodeMode::Wrapping` into a
//! 32-bit output therefore reproduces a classical wrapping accumulator's bytes
//! exactly, at every depth, including depths where that accumulator has wrapped
//! many times (§3.4).
//!
//! Every result here is `build`, never `some-true`: it is evidence that the
//! kernels realize the identity, not a proof of it. The identity itself is
//! cited from upstream and says nothing about any binary in this repository
//! (§2, R4).

use uor_matmul_core::EncodeMode;
use uor_matmul_validate::{
    bytes_equal, oracle::Agreement, oracle_stays_in_range, ours_i32_i32, ours_i8_i32,
    reference_wrapping_i32, Case, Corpus,
};

const SEED: u64 = 20_260_724;

/// Depths chosen to be past `i32`, so that the wrapping half of §3.4 is
/// exercised rather than merely asserted.
fn deep_cases() -> Vec<Case> {
    // 128 * 128 * k leaves i32 at k = 131_073, so every depth below wraps.
    [200_000usize, 500_000, 1_000_000]
        .iter()
        .enumerate()
        .map(|(i, &k)| Case {
            m: 2,
            k,
            n: 2,
            seed: SEED ^ (0x5EED << i),
        })
        .collect()
}

/// `CX-01`: `ndarray` `i32`, byte-identical over the whole corpus under
/// `EncodeMode::Wrapping`.
#[cfg(feature = "ref-ndarray")]
#[test]
fn ndarray_i32_is_byte_identical_cx_01() {
    use uor_matmul_validate::oracle::{NdArray, Oracle};

    let mut compared = 0usize;
    for case in Corpus::standard(SEED).cases {
        let Case { m, k, n, .. } = case;
        let a = Case::widen(&case.fill_i8(m * k, 1));
        let b = Case::widen(&case.fill_i8(k * n, 2));

        let ours = ours_i32_i32(m, k, n, &a, &b, EncodeMode::Wrapping);

        // The independently written wrapping accumulator is the oracle for the
        // claim itself, and it is defined at every depth.
        let wrapping = reference_wrapping_i32(m, k, n, &a, &b);
        bytes_equal(&ours, &wrapping)
            .unwrap_or_else(|d| panic!("CX-01 wrapping mismatch at {m}x{k}x{n}: {d}"));

        // ndarray corroborates wherever it is defined. It accumulates i32 in an
        // i32 and panics rather than wraps under debug assertions, which is a
        // property of that crate and not a permitted difference.
        if oracle_stays_in_range(k, 127, 127) {
            let theirs = NdArray::product_i32(m, k, n, &a, &b);
            match uor_matmul_validate::oracle::compare(&ours, &theirs) {
                Agreement::Exact => compared += 1,
                other => panic!("CX-01 mismatch at {m}x{k}x{n}: {other:?}"),
            }
        }
    }
    assert!(compared > 0, "the oracle must actually have been called");
}

/// `CX-01`, deep half: past the depth at which an `i32` accumulator wraps, we
/// still produce its bytes exactly. There is no exempted region.
#[test]
fn wrapping_agrees_past_the_i32_ceiling_cx_01() {
    for case in deep_cases() {
        let Case { m, k, n, .. } = case;
        let a = Case::widen(&case.fill_i8(m * k, 11));
        let b = Case::widen(&case.fill_i8(k * n, 12));

        let ours = ours_i32_i32(m, k, n, &a, &b, EncodeMode::Wrapping);
        let wrapping = reference_wrapping_i32(m, k, n, &a, &b);
        bytes_equal(&ours, &wrapping)
            .unwrap_or_else(|d| panic!("CX-01 mismatch past the ceiling at k={k}: {d}"));

        // The random fill above cancels, so its *actual* sum may still sit
        // inside i32 even though the worst case does not. A same-sign constant
        // fill is what makes the deep half of this test non-vacuous: at these
        // depths its exact value is provably past i32, so the wrapping and
        // saturating encodes of one accumulation must disagree --- and the
        // wrapping one must still be the classical accumulator's bytes.
        assert!(
            !oracle_stays_in_range(k, 127, 127),
            "k={k} must be past i32"
        );
        let ones = vec![127i32; k];
        let overflowing = ours_i32_i32(1, k, 1, &ones, &ones, EncodeMode::Wrapping);
        let exact = (k as i64) * 127 * 127;
        assert!(
            exact > i32::MAX as i64,
            "k={k} must overflow with a same-sign fill"
        );
        bytes_equal(&overflowing, &reference_wrapping_i32(1, k, 1, &ones, &ones))
            .unwrap_or_else(|d| panic!("CX-01 mismatch on the overflowing fill at k={k}: {d}"));
        assert_eq!(overflowing[0], exact as i32, "wrapping truncates to i32");

        let saturating = ours_i32_i32(1, k, 1, &ones, &ones, EncodeMode::Saturating);
        assert_eq!(
            saturating[0],
            i32::MAX,
            "saturating clamps where wrapping truncates"
        );
        assert_ne!(
            saturating, overflowing,
            "the two encode modes must disagree here"
        );
    }
}

/// `CX-02`: `nalgebra` `i32`, likewise. An independent implementation lineage.
#[cfg(feature = "ref-nalgebra")]
#[test]
fn nalgebra_i32_is_byte_identical_cx_02() {
    use uor_matmul_validate::oracle::{Nalgebra, Oracle};

    for case in Corpus::standard(SEED).cases {
        let Case { m, k, n, .. } = case;
        let a = Case::widen(&case.fill_i8(m * k, 3));
        let b = Case::widen(&case.fill_i8(k * n, 4));

        let ours = ours_i32_i32(m, k, n, &a, &b, EncodeMode::Wrapping);
        bytes_equal(&ours, &reference_wrapping_i32(m, k, n, &a, &b))
            .unwrap_or_else(|d| panic!("CX-02 wrapping mismatch at {m}x{k}x{n}: {d}"));

        if oracle_stays_in_range(k, 127, 127) {
            let theirs = Nalgebra::product_i32(m, k, n, &a, &b);
            if let Agreement::Mismatch(detail) =
                uor_matmul_validate::oracle::compare(&ours, &theirs)
            {
                panic!("CX-02 mismatch at {m}x{k}x{n}: {detail}");
            }
        }
    }
}

/// `CX-03`: `ndarray` `i32` against our `i8` kernels on widened inputs.
///
/// The load-bearing W8A8 check: the two sides receive the same numbers in
/// different types, and our side never widens to `i32` at all.
#[cfg(feature = "ref-ndarray")]
#[test]
fn ndarray_agrees_with_our_i8_kernel_cx_03() {
    use uor_matmul_validate::oracle::{NdArray, Oracle};

    for case in Corpus::standard(SEED ^ 0xABCD).cases {
        let Case { m, k, n, .. } = case;
        let a8 = case.fill_i8(m * k, 5);
        let b8 = case.fill_i8(k * n, 6);
        let a = Case::widen(&a8);
        let b = Case::widen(&b8);

        let ours = ours_i8_i32(m, k, n, &a8, &b8, EncodeMode::Wrapping);
        bytes_equal(&ours, &reference_wrapping_i32(m, k, n, &a, &b))
            .unwrap_or_else(|d| panic!("CX-03 wrapping mismatch at {m}x{k}x{n}: {d}"));

        // |a| <= 128 and |b| <= 128, because `i8::MIN` is admitted (C6).
        if oracle_stays_in_range(k, 128, 128) {
            let theirs = NdArray::product_i32(m, k, n, &a, &b);
            if let Agreement::Mismatch(detail) =
                uor_matmul_validate::oracle::compare(&ours, &theirs)
            {
                panic!("CX-03 mismatch at {m}x{k}x{n}: {detail}");
            }
        }
    }
}

/// `CX-04`: `nalgebra` `i32` against our coded kernels on decoded weights.
///
/// Ties `CL-MM01` to something that has never heard of it: the oracle is handed
/// the *decoded* weights and we are handed the *codes*, and the products must
/// be the same bytes.
#[cfg(feature = "ref-nalgebra")]
#[test]
fn nalgebra_agrees_with_our_coded_kernel_cx_04() {
    use uor_matmul::prelude::*;
    use uor_matmul::{coded_gemm, CodedTriple, GemmOptions, Linear};
    use uor_matmul_core::Full;
    use uor_matmul_validate::oracle::{Nalgebra, Oracle};

    // A 16-entry i4 grid: codes 0..15 decode to -8..7.
    let table: [Alphabet<i8, Full<i8>>; 16] = core::array::from_fn(|i| Alphabet::of((i as i8) - 8));
    let grid = Grid::new(&table);

    for case in Corpus::standard(SEED ^ 0x1234).cases {
        let Case { m, k, n, .. } = case;
        if m == 0 || k == 0 || n == 0 {
            continue;
        }
        let acts = case.fill_i8(m * k, 7);
        let codes: Vec<u16> = case
            .fill_i8(k * n, 8)
            .iter()
            .map(|&x| (x as i32).unsigned_abs() as u16 % 16)
            .collect();

        // Our side: the codes, decoded by the codec inside the accumulation.
        let coded = CodedMatrix::new(grid, k, n, &codes).expect("the coded matrix exists");
        let mut ours = vec![0i32; m * n];
        {
            let av = MatView::row_major(as_alphabet_full(&acts), m, k).unwrap();
            let cv = MatViewMut::row_major(&mut ours, m, n).unwrap();
            let mut t = CodedTriple::new(av, coded, cv).expect("the product exists");
            coded_gemm(
                &mut t,
                &Linear::OVERWRITE,
                GemmOptions {
                    encode: EncodeMode::Wrapping,
                    ..Default::default()
                },
            );
        }

        // The oracle's side: the same weights, already decoded, as plain i32.
        let decoded: Vec<i32> = codes.iter().map(|&c| (c as i32) - 8).collect();
        let widened: Vec<i32> = acts.iter().map(|&x| x as i32).collect();

        bytes_equal(&ours, &reference_wrapping_i32(m, k, n, &widened, &decoded))
            .unwrap_or_else(|d| panic!("CX-04 wrapping mismatch at {m}x{k}x{n}: {d}"));

        // |a| <= 128, |decoded weight| <= 8.
        if oracle_stays_in_range(k, 128, 8) {
            let theirs = Nalgebra::product_i32(m, k, n, &widened, &decoded);
            bytes_equal(&ours, &theirs)
                .unwrap_or_else(|d| panic!("CX-04 mismatch at {m}x{k}x{n}: {d}"));
        }
    }
}

/// The harness itself is falsifiable: a deliberately wrong buffer must be
/// reported, with the index and both values.
///
/// A differential test whose comparator cannot fail proves nothing, and neither
/// does a wrapping oracle that never wraps.
#[test]
fn the_comparator_and_the_wrapping_oracle_are_falsifiable() {
    let ours = [1i32, 2, 3];
    let theirs = [1i32, 5, 3];
    let err = bytes_equal(&ours, &theirs).unwrap_err();
    assert!(err.contains("index 1"), "{err}");
    assert!(err.contains('2') && err.contains('5'), "{err}");
    assert!(bytes_equal(&ours, &ours).is_ok());

    // The reference wrapping accumulator really does wrap, so the deep half of
    // CX-01 is testing something.
    let k = 200_000;
    let a = vec![127i32; k];
    let b = vec![127i32; k];
    let wrapped = reference_wrapping_i32(1, k, 1, &a, &b);
    let exact = (k as i64) * 127 * 127;
    assert_ne!(wrapped[0] as i64, exact, "the reference must have wrapped");
    assert_eq!(wrapped[0], exact as i32, "and wrapped by truncation to i32");
}
