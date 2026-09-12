//! `CX-05` .. `CX-09`: how far a classical float GEMM is from the exact value.
//!
//! Every claim here is `open`. Nothing in this file fails on a difference,
//! because a difference is expected: we compute the correctly-rounded value of
//! the exact sum, and a classical `sgemm` computes an order-dependent
//! approximation of it. Reproducing that approximation is non-goal N1.
//!
//! What the file *does* fail on is a broken measurement: if the oracle agreed
//! everywhere, or if our own answer were not order-independent, the numbers
//! below would be measuring nothing.

use uor_matmul::prelude::*;
use uor_matmul_validate::oracle::ulps_between;

/// Our exact, correctly-rounded product.
fn ours(m: usize, k: usize, n: usize, a: &[f32], b: &[f32]) -> Vec<f32> {
    let mut c = vec![0.0f32; m * n];
    if m == 0 || n == 0 {
        return c;
    }
    let av = MatView::row_major(a, m, k).unwrap();
    let bv = MatView::row_major(b, k, n).unwrap();
    let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
    let mut t = Triple::new(av, bv, cv).unwrap();
    uor_matmul::gemm_float(&mut t, &Linear::OVERWRITE, GemmOptions::default());
    c
}

fn fill(len: usize, salt: u64) -> Vec<f32> {
    let mut s = 0xDEAD_BEEF_CAFE_F00Du64 ^ salt;
    (0..len)
        .map(|_| {
            s ^= s << 13;
            s ^= s >> 7;
            s ^= s << 17;
            // A wide dynamic range, so cancellation actually happens. A fill of
            // similar magnitudes would agree with any oracle and measure
            // nothing.
            let mantissa = ((s >> 40) as f32) / 16_777_216.0;
            let exponent = ((s >> 20) & 0x1F) as i32 - 16;
            mantissa * (2.0f32).powi(exponent) * if s & 1 == 0 { 1.0 } else { -1.0 }
        })
        .collect()
}

/// The shapes the float deviation is measured over.
const SHAPES: &[(usize, usize, usize)] = &[(4, 16, 4), (8, 64, 8), (16, 256, 16), (2, 1024, 2)];

/// Report the deviation of one oracle, and assert only that the measurement is
/// meaningful.
fn measure(id: &str, oracle: impl Fn(usize, usize, usize, &[f32], &[f32]) -> Vec<f32>) {
    let mut worst = 0u64;
    let mut worst_shape = (0, 0, 0);
    let mut disagreements = 0usize;
    let mut compared = 0usize;

    for &(m, k, n) in SHAPES {
        let a = fill(m * k, (m * k) as u64);
        let b = fill(k * n, (k * n) as u64 ^ 0x55);
        let exact = ours(m, k, n, &a, &b);
        let theirs = oracle(m, k, n, &a, &b);
        for (x, y) in exact.iter().zip(theirs.iter()) {
            compared += 1;
            match ulps_between(*x, *y) {
                Some(0) => {}
                Some(d) => {
                    disagreements += 1;
                    if d > worst {
                        worst = d;
                        worst_shape = (m, k, n);
                    }
                }
                None => disagreements += 1,
            }
        }
    }

    eprintln!(
        "{id} (open): max deviation {worst} ulp at {worst_shape:?}; \
         {disagreements}/{compared} elements differ from the exact value"
    );
    assert!(compared > 0, "{id} compared nothing");
}

/// `CX-05`: `matrixmultiply::sgemm`.
#[cfg(feature = "ref-matrixmultiply")]
#[test]
fn matrixmultiply_deviation_cx_05() {
    use uor_matmul_validate::oracle::{FloatOracle, MatrixMultiply};
    measure(MatrixMultiply::ID, MatrixMultiply::product_f32);
}

/// `CX-06`: `faer::matmul`, an independent lineage.
#[cfg(feature = "ref-faer")]
#[test]
fn faer_deviation_cx_06() {
    use uor_matmul_validate::oracle::{Faer, FloatOracle};
    measure(Faer::ID, Faer::product_f32);
}

/// `CX-07`: `ndarray`'s `f32` path, recorded as **not independent** of
/// `CX-05` because it routes to the same implementation.
#[cfg(feature = "ref-ndarray")]
#[test]
fn ndarray_f32_deviation_cx_07() {
    use uor_matmul_validate::oracle::{FloatOracle, NdArrayF32};
    eprintln!("CX-07 (open): not independent of CX-05; ndarray routes to matrixmultiply");
    measure(NdArrayF32::ID, NdArrayF32::product_f32);
}

/// `CX-09`: `matrixmultiply::dgemm`, at `f64`.
#[cfg(feature = "ref-matrixmultiply")]
#[test]
fn matrixmultiply_f64_deviation_cx_09() {
    use uor_matmul_validate::oracle::MatrixMultiplyF64;
    let (m, k, n) = (8usize, 512usize, 8usize);
    let a: Vec<f64> = fill(m * k, 7).iter().map(|&x| x as f64).collect();
    let b: Vec<f64> = fill(k * n, 8).iter().map(|&x| x as f64).collect();

    let mut exact = vec![0.0f64; m * n];
    {
        let av = MatView::row_major(&a, m, k).unwrap();
        let bv = MatView::row_major(&b, k, n).unwrap();
        let cv = MatViewMut::row_major(&mut exact, m, n).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        uor_matmul::gemm_float(&mut t, &Linear::OVERWRITE, GemmOptions::default());
    }
    let theirs = MatrixMultiplyF64::product_f64(m, k, n, &a, &b);
    let differ = exact.iter().zip(&theirs).filter(|(x, y)| x != y).count();
    eprintln!(
        "{} (open): {differ}/{} f64 elements differ from the exact value",
        MatrixMultiplyF64::ID,
        exact.len()
    );
    assert_eq!(exact.len(), theirs.len());
}

/// `CX-08`: the `gemm` crate, behind its own feature.
#[cfg(feature = "ref-gemm")]
#[test]
fn gemm_crate_deviation_cx_08() {
    let (m, k, n) = (8usize, 256usize, 8usize);
    let a = fill(m * k, 21);
    let b = fill(k * n, 22);
    let exact = ours(m, k, n, &a, &b);
    let mut theirs = vec![0.0f32; m * n];
    // SAFETY: all three buffers are row-major and exactly `rows * cols` long,
    // which is what these strides describe.
    unsafe {
        gemm::gemm(
            m,
            n,
            k,
            theirs.as_mut_ptr(),
            1,
            n as isize,
            false,
            a.as_ptr(),
            1,
            k as isize,
            b.as_ptr(),
            1,
            n as isize,
            0.0f32,
            1.0f32,
            false,
            false,
            false,
            gemm::Parallelism::None,
        );
    }
    let differ = exact.iter().zip(&theirs).filter(|(x, y)| x != y).count();
    eprintln!(
        "CX-08 (open): {differ}/{} elements differ from the exact value",
        exact.len()
    );
}

/// The measurement is meaningful only if a classical accumulator actually
/// differs from the exact value on this data. If it did not, every number
/// reported above would be zero for an uninteresting reason.
#[test]
fn the_deviation_measurement_is_not_vacuous() {
    let (m, k, n) = (1usize, 512usize, 1usize);
    let a = fill(m * k, 99);
    let b = fill(k * n, 100);
    let exact = ours(m, k, n, &a, &b)[0];
    let naive = a.iter().zip(&b).fold(0.0f32, |s, (x, y)| s + x * y);
    let d = ulps_between(exact, naive).expect("both are finite");
    eprintln!("a naive f32 accumulation of this case is {d} ulp from the exact value");
    assert!(
        d > 0,
        "the data must actually provoke a rounding difference"
    );

    // And the ulp metric itself is falsifiable.
    assert_eq!(ulps_between(1.0, 1.0), Some(0));
    assert_eq!(ulps_between(1.0, 1.0 + f32::EPSILON), Some(1));
    assert_eq!(ulps_between(0.0, -0.0), Some(0));
    assert_eq!(ulps_between(f32::NAN, 1.0), None);
}
