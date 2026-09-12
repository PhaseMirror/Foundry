//! Oracle adapters and the agreement verdict.

/// What a comparison against an external library established.
///
/// Three outcomes, not two. The third applies to *float* oracles only: a
/// classical `f32` GEMM computes an order-dependent approximation of the value
/// we compute exactly, so recording how far off it is beats both failing the
/// gate and quietly skipping. An **integer** oracle never reaches it --- under
/// `EncodeMode::Wrapping` there is no depth at which it may differ (§3.4).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Agreement {
    /// The oracle is exact for this case and returned our bytes.
    Exact,
    /// The oracle is not exact for this case. The deviation from our exact
    /// value is recorded and reported; this never fails the gate.
    OracleInexact {
        /// The largest absolute deviation observed.
        max_deviation: i128,
        /// Where it was.
        at_index: usize,
    },
    /// The oracle is exact for this case and did **not** return our bytes.
    ///
    /// A bug in one of the two libraries. This always fails the gate.
    Mismatch(String),
}

impl Agreement {
    /// Does this verdict fail the acceptance gate?
    pub fn is_failure(&self) -> bool {
        matches!(self, Self::Mismatch(_))
    }
}

/// One external library, adapted to a common shape.
pub trait Oracle {
    /// The conformance ID this oracle discharges.
    const ID: &'static str;
    /// The crate name, for the report.
    const CRATE: &'static str;

    /// The oracle's own `i32` product, row-major.
    fn product_i32(m: usize, k: usize, n: usize, a: &[i32], b: &[i32]) -> Vec<i32>;
}

/// `CX-01`, `CX-03`: `ndarray`.
///
/// `i32` satisfies `LinalgScalar`, and ndarray dispatches integer types to its
/// own generic kernel rather than to `matrixmultiply`, which is what makes this
/// an independent witness for the integer path.
#[cfg(feature = "ref-ndarray")]
pub struct NdArray;

#[cfg(feature = "ref-ndarray")]
impl Oracle for NdArray {
    const ID: &'static str = "CX-01";
    const CRATE: &'static str = "ndarray";

    fn product_i32(m: usize, k: usize, n: usize, a: &[i32], b: &[i32]) -> Vec<i32> {
        use ndarray::Array2;
        let a = Array2::from_shape_vec((m, k), a.to_vec()).expect("A conforms");
        let b = Array2::from_shape_vec((k, n), b.to_vec()).expect("B conforms");
        a.dot(&b).into_raw_vec_and_offset().0
    }
}

/// `CX-02`, `CX-04`: `nalgebra`.
///
/// An implementation lineage independent of ndarray's, which is why both are
/// registered rather than one.
#[cfg(feature = "ref-nalgebra")]
pub struct Nalgebra;

#[cfg(feature = "ref-nalgebra")]
impl Oracle for Nalgebra {
    const ID: &'static str = "CX-02";
    const CRATE: &'static str = "nalgebra";

    fn product_i32(m: usize, k: usize, n: usize, a: &[i32], b: &[i32]) -> Vec<i32> {
        use nalgebra::DMatrix;
        // nalgebra is column-major; transposing on the way in and out keeps the
        // comparison row-major on both sides without touching the arithmetic.
        let a = DMatrix::from_row_slice(m, k, a);
        let b = DMatrix::from_row_slice(k, n, b);
        let c = a * b;
        let mut out = vec![0i32; m * n];
        for i in 0..m {
            for j in 0..n {
                out[i * n + j] = c[(i, j)];
            }
        }
        out
    }
}

/// Compare our product against an integer oracle's.
///
/// There is no exactness parameter, because an integer oracle has no permitted
/// difference: under `EncodeMode::Wrapping` we reproduce its bytes at every
/// depth, by ring homomorphism (§3.4). A mismatch is a bug in one of the two
/// libraries.
pub fn compare(ours: &[i32], theirs: &[i32]) -> Agreement {
    match crate::bytes_equal(ours, theirs) {
        Ok(()) => Agreement::Exact,
        Err(detail) => Agreement::Mismatch(detail),
    }
}

/// Compare our exact float product against a classical GEMM's, and measure the
/// deviation.
///
/// Never a failure. A classical `f32` GEMM computes an order-dependent
/// approximation of the value we compute exactly, so what is interesting is how
/// far off it is, not whether it differs (N1, `CX-05` .. `CX-09`).
pub fn measure_deviation(ours: &[i32], theirs: &[i32]) -> Agreement {
    let mut max_deviation = 0i128;
    let mut at_index = 0usize;
    for (i, (x, y)) in ours.iter().zip(theirs).enumerate() {
        let d = (*x as i128 - *y as i128).abs();
        if d > max_deviation {
            max_deviation = d;
            at_index = i;
        }
    }
    Agreement::OracleInexact {
        max_deviation,
        at_index,
    }
}

/// A classical `f32` GEMM, adapted to a common shape.
///
/// Every implementor computes an order-dependent approximation of the value
/// this library computes exactly. The harness measures the difference in ulps
/// and reports it; it never fails a gate on it (N1, `CX-05` .. `CX-09`).
pub trait FloatOracle {
    /// The conformance ID this oracle discharges.
    const ID: &'static str;
    /// The crate name, for the report.
    const CRATE: &'static str;
    /// The oracle's own `f32` product, row-major.
    fn product_f32(m: usize, k: usize, n: usize, a: &[f32], b: &[f32]) -> Vec<f32>;
}

/// `CX-05`: `matrixmultiply::sgemm`.
#[cfg(feature = "ref-matrixmultiply")]
pub struct MatrixMultiply;

#[cfg(feature = "ref-matrixmultiply")]
impl FloatOracle for MatrixMultiply {
    const ID: &'static str = "CX-05";
    const CRATE: &'static str = "matrixmultiply";

    fn product_f32(m: usize, k: usize, n: usize, a: &[f32], b: &[f32]) -> Vec<f32> {
        let mut c = vec![0.0f32; m * n];
        if m == 0 || k == 0 || n == 0 {
            return c;
        }
        // SAFETY: all three buffers are row-major and exactly `rows * cols`
        // long, which is what these strides describe.
        unsafe {
            matrixmultiply::sgemm(
                m,
                k,
                n,
                1.0,
                a.as_ptr(),
                k as isize,
                1,
                b.as_ptr(),
                n as isize,
                1,
                0.0,
                c.as_mut_ptr(),
                n as isize,
                1,
            );
        }
        c
    }
}

/// `CX-09`: `matrixmultiply::dgemm`, at `f64`.
#[cfg(feature = "ref-matrixmultiply")]
pub struct MatrixMultiplyF64;

#[cfg(feature = "ref-matrixmultiply")]
impl MatrixMultiplyF64 {
    /// The conformance ID this oracle discharges.
    pub const ID: &'static str = "CX-09";

    /// The oracle's own `f64` product, row-major.
    pub fn product_f64(m: usize, k: usize, n: usize, a: &[f64], b: &[f64]) -> Vec<f64> {
        let mut c = vec![0.0f64; m * n];
        if m == 0 || k == 0 || n == 0 {
            return c;
        }
        // SAFETY: as `MatrixMultiply::product_f32`.
        unsafe {
            matrixmultiply::dgemm(
                m,
                k,
                n,
                1.0,
                a.as_ptr(),
                k as isize,
                1,
                b.as_ptr(),
                n as isize,
                1,
                0.0,
                c.as_mut_ptr(),
                n as isize,
                1,
            );
        }
        c
    }
}

/// `CX-06`: `faer::matmul`. An independent lineage from matrixmultiply.
#[cfg(feature = "ref-faer")]
pub struct Faer;

#[cfg(feature = "ref-faer")]
impl FloatOracle for Faer {
    const ID: &'static str = "CX-06";
    const CRATE: &'static str = "faer";

    fn product_f32(m: usize, k: usize, n: usize, a: &[f32], b: &[f32]) -> Vec<f32> {
        use faer::{Mat, Par};
        if m == 0 || k == 0 || n == 0 {
            return vec![0.0f32; m * n];
        }
        let am = Mat::from_fn(m, k, |i, j| a[i * k + j]);
        let bm = Mat::from_fn(k, n, |i, j| b[i * n + j]);
        let mut cm = Mat::<f32>::zeros(m, n);
        faer::linalg::matmul::matmul(
            cm.as_mut(),
            faer::Accum::Replace,
            am.as_ref(),
            bm.as_ref(),
            1.0f32,
            Par::Seq,
        );
        (0..m)
            .flat_map(|i| (0..n).map(move |j| (i, j)))
            .map(|(i, j)| cm[(i, j)])
            .collect()
    }
}

/// `CX-07`: `ndarray`'s `f32` path, which routes to matrixmultiply.
///
/// Registered and reported as **not independent** of `CX-05`. Two measurements
/// of the same implementation are one measurement, and saying so is the
/// difference between a validation and a tally.
#[cfg(feature = "ref-ndarray")]
pub struct NdArrayF32;

#[cfg(feature = "ref-ndarray")]
impl FloatOracle for NdArrayF32 {
    const ID: &'static str = "CX-07";
    const CRATE: &'static str = "ndarray";

    fn product_f32(m: usize, k: usize, n: usize, a: &[f32], b: &[f32]) -> Vec<f32> {
        use ndarray::Array2;
        let a = Array2::from_shape_vec((m, k), a.to_vec()).expect("A conforms");
        let b = Array2::from_shape_vec((k, n), b.to_vec()).expect("B conforms");
        a.dot(&b).into_raw_vec_and_offset().0
    }
}

/// `CX-08`: the `gemm` crate. Behind its own feature.
#[cfg(feature = "ref-gemm")]
pub struct GemmCrate;

/// How far apart two `f32` are, in units in the last place.
///
/// The unit the float claims are reported in. Counting representable values
/// between two floats is the only comparison that means the same thing across
/// magnitudes, which an absolute or relative epsilon does not.
pub fn ulps_between(ours: f32, theirs: f32) -> Option<u64> {
    if ours.is_nan() || theirs.is_nan() {
        return None;
    }
    if ours.is_infinite() || theirs.is_infinite() {
        return if ours == theirs { Some(0) } else { None };
    }
    // Map the sign-magnitude bit pattern onto a monotone integer line, so that
    // "how many representable values apart" is a subtraction.
    let order = |x: f32| -> i64 {
        // The sign lives in the top bit of the *pattern*, not in the sign of
        // the widened integer --- `to_bits` is unsigned, so a negative float
        // widens to a large positive number. Mirroring the magnitude around
        // zero is what makes the two halves of the line meet at +/-0.
        let b = x.to_bits();
        if b & 0x8000_0000 != 0 {
            -i64::from(b & 0x7FFF_FFFF)
        } else {
            i64::from(b)
        }
    };
    Some((order(ours) - order(theirs)).unsigned_abs())
}
