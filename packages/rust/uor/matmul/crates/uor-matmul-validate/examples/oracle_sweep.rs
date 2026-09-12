//! Throughput, latency, and scaling, against every oracle, from miniscule to
//! astronomical.
//!
//! Four questions, because they have different answers:
//!
//! - **Latency** at sizes where a call is dominated by whatever happens before
//!   the arithmetic. This is where a library with a thread pool or a blocking
//!   decision loses to one with neither.
//! - **Throughput** at sizes where the arithmetic dominates.
//! - **Scaling** across the whole range, which is the only comparison that
//!   survives a change of machine.
//! - **Shape**, because a square is one use-case and not the interesting one. A
//!   deep thin product and a shallow wide one stress different halves of the
//!   driver, and a library that only measures squares does not know what it
//!   does on either.
//!
//! Every figure is `open`: measured and reported, never asserted. What *is*
//! asserted, inside the timed region, is that the answer is right --- a speed
//! measured on the wrong bytes is not a measurement.
//!
//! # Why the operands are not all ones
//!
//! They used to be, and it flattered us twice: every `f32` product shared one
//! exponent, so the complete accumulator's limb window never once had to flush,
//! and every branch in the library was perfectly predicted. The operands below
//! are a recorded pseudo-random fill spanning the alphabet, and the expected
//! answer is computed once, outside the timed region, by a plain `i128` loop
//! that shares no code with the library.

use std::time::Instant;

use uor_matmul::prelude::*;
use uor_matmul_core::{EncodeMode, Full, PackedCode, Shape};

/// Best of as many repetitions as fit a fixed time, in seconds per call.
///
/// The minimum is the run least interfered with: on a shared machine the mean
/// measures the neighbours. The budget is wall-clock rather than a repetition
/// count, so a point that is a nanosecond and a point that is a second both get
/// enough samples for the minimum to mean something --- a fixed count gives the
/// large points two samples, and best-of-two is not a measurement.
fn best(mut run: impl FnMut() -> f64) -> f64 {
    const BUDGET: f64 = 0.35;
    let mut best = f64::INFINITY;
    let mut spent = 0.0;
    let mut reps = 0usize;
    loop {
        let t = run();
        best = best.min(t);
        spent += t;
        reps += 1;
        // No minimum repetition count: a point where one call already exceeds
        // the budget would pay a multiple of it for no extra confidence, and
        // that is exactly the astronomical end of the sweep.
        if spent >= BUDGET || reps >= 2_000_000 {
            return best;
        }
    }
}

/// Deterministic fill. A recorded generator rather than a crate, so any figure
/// reproduces from the seed alone.
fn fill<T, F: Fn(i64) -> T>(len: usize, salt: u64, map: F) -> Vec<T> {
    let mut s = 0x243F_6A88_85A3_08D3u64 ^ salt;
    (0..len)
        .map(|_| {
            s ^= s << 13;
            s ^= s >> 7;
            s ^= s << 17;
            map((s >> 33) as i64)
        })
        .collect()
}

/// Which output cells to check independently.
///
/// The whole output at every shape would cost more than the measurement: an
/// `i128` reference for a `2048` cube is `8.6e9` multiplies. What this assertion
/// is for is catching a timed region fed the wrong bytes or elided by the
/// optimizer, and a spread sample does that. Whether the *value* is right on
/// every shape is the conformance corpus's business, and it checks all of it.
///
/// The count is set by a work budget rather than chosen, so a deep problem
/// checks fewer cells and a shallow one checks more, at the same cost.
fn sample(m: usize, k: usize, n: usize) -> Vec<usize> {
    let cells = m * n;
    let budget = 10_000_000usize;
    let count = (budget / k.max(1)).clamp(1, cells).min(512);
    let stride = cells.div_ceil(count);
    let mut v: Vec<usize> = (0..cells).step_by(stride).collect();
    if *v.last().unwrap() != cells - 1 {
        v.push(cells - 1);
    }
    v
}

/// The exact value of output cell `at`, in `i128`, sharing no code with the
/// library.
fn expect_at(k: usize, n: usize, a: &[i64], b: &[i64], at: usize) -> i128 {
    let (i, j) = (at / n, at % n);
    (0..k)
        .map(|p| i128::from(a[i * k + p]) * i128::from(b[p * n + j]))
        .sum()
}

/// `i8 x i8 -> i32`, the instantiation the SIMD instructions name.
fn ours_i8(
    m: usize,
    k: usize,
    n: usize,
    a: &[i8],
    b: &[i8],
    want: &[(usize, i128)],
    scratch: &mut [Alphabet<i8, Full<i8>>],
) -> f64 {
    let mut c = vec![0i32; m * n];
    let t = best(|| {
        let s = Instant::now();
        {
            let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
            let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
            let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
            let mut tr = Triple::new(av, bv, cv).unwrap();
            uor_matmul::gemm_packed(
                &mut tr,
                &Linear::OVERWRITE,
                GemmOptions {
                    encode: EncodeMode::Wrapping,
                    ..Default::default()
                },
                &mut Scratch::new(scratch),
            );
        }
        s.elapsed().as_secs_f64()
    });
    // Wrapping into `i32` is reduction mod `2^32`, which is what the modular
    // factorization computes; the reference is reduced the same way.
    for &(at, w) in want {
        assert_eq!(c[at], w as i32, "the timed call must be correct at {at}");
    }
    t
}

/// `i32 x i32 -> i32`.
fn ours_i32(
    m: usize,
    k: usize,
    n: usize,
    a: &[i32],
    b: &[i32],
    want: &[(usize, i128)],
    scratch: &mut [Alphabet<i32, Full<i32>>],
) -> f64 {
    let mut c = vec![0i32; m * n];
    let t = best(|| {
        let s = Instant::now();
        {
            let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
            let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
            let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
            let mut tr = Triple::new(av, bv, cv).unwrap();
            uor_matmul::gemm_packed(
                &mut tr,
                &Linear::OVERWRITE,
                GemmOptions {
                    encode: EncodeMode::Wrapping,
                    ..Default::default()
                },
                &mut Scratch::new(scratch),
            );
        }
        s.elapsed().as_secs_f64()
    });
    for &(at, w) in want {
        assert_eq!(c[at], w as i32, "the timed call must be correct at {at}");
    }
    t
}

/// `f32`, computed exactly.
///
/// The expected answer is this same path run once, untimed: what the assertion
/// catches is a timed region fed the wrong bytes or elided by the optimizer.
/// That the value is the correctly-rounded exact sum is `CU-04`'s business, not
/// a benchmark's.
fn ours_f32(
    m: usize,
    k: usize,
    n: usize,
    a: &[f32],
    b: &[f32],
    pa: &mut [PackedCode],
    pb: &mut [PackedCode],
) -> f64 {
    let mut c = vec![0.0f32; m * n];
    let run = |c: &mut Vec<f32>, pa: &mut [PackedCode], pb: &mut [PackedCode]| {
        let av = MatView::row_major(a, m, k).unwrap();
        let bv = MatView::row_major(b, k, n).unwrap();
        let cv = MatViewMut::row_major(c, m, n).unwrap();
        let mut tr = Triple::new(av, bv, cv).unwrap();
        uor_matmul::gemm_float_packed(&mut tr, &Linear::OVERWRITE, GemmOptions::default(), pa, pb);
    };
    run(&mut c, pa, pb);
    let want = c.clone();

    let t = best(|| {
        let s = Instant::now();
        run(&mut c, pa, pb);
        s.elapsed().as_secs_f64()
    });
    assert_eq!(c, want, "the timed call must be correct");
    t
}

fn gmacs(macs: f64, secs: f64) -> f64 {
    macs / 1e9 / secs
}

/// Least squares in log-log space; returns the exponent against MAC count.
fn exponent(points: &[(f64, f64)]) -> f64 {
    let usable: Vec<(f64, f64)> = points
        .iter()
        .filter(|(x, y)| *x > 0.0 && *y > 0.0)
        .map(|(x, y)| (x.log10(), y.log10()))
        .collect();
    if usable.len() < 3 {
        return f64::NAN;
    }
    let n = usable.len() as f64;
    let mx = usable.iter().map(|p| p.0).sum::<f64>() / n;
    let my = usable.iter().map(|p| p.1).sum::<f64>() / n;
    let sxx: f64 = usable.iter().map(|p| (p.0 - mx).powi(2)).sum();
    let sxy: f64 = usable.iter().map(|p| (p.0 - mx) * (p.1 - my)).sum();
    sxy / sxx
}

/// One point of the sweep: every implementation on one shape.
struct Row {
    label: String,
    macs: f64,
    i8: f64,
    i32: f64,
    nd: f64,
    na: f64,
    f32: f64,
    mm: f64,
}

/// Measure every implementation on `m x k x n`.
///
/// `float` selects whether the `f32` oracles run: they are quadratic in memory
/// and there is no point paying for them at a shape whose answer is the same
/// story as the shape before it.
fn point(label: &str, m: usize, k: usize, n: usize) -> Row {
    let macs = (m as f64) * (k as f64) * (n as f64);

    // Spanning the alphabet, not all ones: see the module docs.
    let a8: Vec<i8> = fill(m * k, 1, |v| v as i8);
    let b8: Vec<i8> = fill(k * n, 2, |v| v as i8);
    let a32: Vec<i32> = fill(m * k, 3, |v| v as i32);
    let b32: Vec<i32> = fill(k * n, 4, |v| v as i32);
    // Exponents spread over a decade, so the complete accumulator's limb window
    // has to move --- which is the case the library will actually see.
    let af: Vec<f32> = fill(m * k, 5, |v| {
        (v % 2048) as f32 * 2.0f32.powi((v % 19) as i32 - 9)
    });
    let bf: Vec<f32> = fill(k * n, 6, |v| {
        (v % 2048) as f32 * 2.0f32.powi((v % 23) as i32 - 11)
    });

    let cells = sample(m, k, n);
    let a8w: Vec<i64> = a8.iter().map(|&v| i64::from(v)).collect();
    let b8w: Vec<i64> = b8.iter().map(|&v| i64::from(v)).collect();
    let a32w: Vec<i64> = a32.iter().map(|&v| i64::from(v)).collect();
    let b32w: Vec<i64> = b32.iter().map(|&v| i64::from(v)).collect();
    let w8: Vec<(usize, i128)> = cells
        .iter()
        .map(|&at| (at, expect_at(k, n, &a8w, &b8w, at)))
        .collect();
    let w32: Vec<(usize, i128)> = cells
        .iter()
        .map(|&at| (at, expect_at(k, n, &a32w, &b32w, at)))
        .collect();

    // The panels the library needs. Sized from `suggested_scratch`, which is a
    // query with a closed form and no allocation of its own.
    let want = uor_matmul::suggested_scratch(Shape { m, k, n });
    let mut s8 = vec![Alphabet::<i8, Full<i8>>::ZERO; want];
    let mut s32 = vec![Alphabet::<i32, Full<i32>>::ZERO; want];
    let mut pa = vec![PackedCode::default(); k];
    let mut pb = vec![PackedCode::default(); k * n];

    let i8t = ours_i8(m, k, n, &a8, &b8, &w8, &mut s8);
    let i32t = ours_i32(m, k, n, &a32, &b32, &w32, &mut s32);
    let f32t = ours_f32(m, k, n, &af, &bf, &mut pa, &mut pb);

    #[cfg(feature = "ref-ndarray")]
    let nd = {
        use uor_matmul_validate::oracle::{NdArray, Oracle};
        best(|| {
            let s = Instant::now();
            let c = NdArray::product_i32(m, k, n, &a32, &b32);
            let e = s.elapsed().as_secs_f64();
            assert_eq!(c.len(), m * n);
            std::hint::black_box(&c);
            e
        })
    };
    #[cfg(not(feature = "ref-ndarray"))]
    let nd = f64::NAN;

    #[cfg(feature = "ref-nalgebra")]
    let na = {
        use uor_matmul_validate::oracle::{Nalgebra, Oracle};
        best(|| {
            let s = Instant::now();
            let c = Nalgebra::product_i32(m, k, n, &a32, &b32);
            let e = s.elapsed().as_secs_f64();
            assert_eq!(c.len(), m * n);
            std::hint::black_box(&c);
            e
        })
    };
    #[cfg(not(feature = "ref-nalgebra"))]
    let na = f64::NAN;

    #[cfg(feature = "ref-matrixmultiply")]
    let mm = {
        use uor_matmul_validate::oracle::{FloatOracle, MatrixMultiply};
        best(|| {
            let s = Instant::now();
            let c = MatrixMultiply::product_f32(m, k, n, &af, &bf);
            let e = s.elapsed().as_secs_f64();
            assert_eq!(c.len(), m * n);
            std::hint::black_box(&c);
            e
        })
    };
    #[cfg(not(feature = "ref-matrixmultiply"))]
    let mm = f64::NAN;

    Row {
        label: label.to_string(),
        macs,
        i8: i8t,
        i32: i32t,
        nd,
        na,
        f32: f32t,
        mm,
    }
}

fn header(first: &str) {
    println!();
    println!(
        "{first:>14} {:>12} {:>11} {:>11} {:>11} {:>11} {:>11} {:>11}",
        "macs", "uor i8", "uor i32", "ndarray", "nalgebra", "uor f32", "matrixmul"
    );
}

fn emit(r: &Row) {
    println!(
        "{:>14} {:>12.3e} {:>11.3} {:>11.3} {:>11.3} {:>11.3} {:>11.3} {:>11.3}",
        r.label,
        r.macs,
        gmacs(r.macs, r.i8),
        gmacs(r.macs, r.i32),
        gmacs(r.macs, r.nd),
        gmacs(r.macs, r.na),
        gmacs(r.macs, r.f32),
        gmacs(r.macs, r.mm),
    );
}

/// The square sweep. Geometric, spanning eleven orders of magnitude in MAC
/// count, because a sweep that does not reach both ends measures neither
/// latency nor asymptote.
const SIZES: &[usize] = &[1, 2, 3, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048];

/// Shapes that are not squares. Each is a use-case, and each stresses a
/// different half of the driver.
const SHAPES: &[(&str, usize, usize, usize)] = &[
    // A matrix-vector product: `n = 1`, so no column panel is reused at all and
    // the packing has nothing to amortize against.
    ("1024x1024x1", 1024, 1024, 1),
    ("1x1024x1024", 1, 1024, 1024),
    // Deep and thin: one output block, a reduction far past every lane's depth.
    ("8x262144x8", 8, 262_144, 8),
    ("1x1048576x1", 1, 1_048_576, 1),
    // Shallow and wide: many output blocks, almost nothing to reduce, so the
    // per-tile epilogue is the whole cost.
    ("2048x8x2048", 2048, 8, 2048),
    ("4096x2x4096", 4096, 2, 4096),
    // Rectangular, and prime in every extent, so no blocking divides evenly.
    ("509x1021x257", 509, 1021, 257),
];

fn main() {
    // Say which kernels are actually running. A sweep that silently measured the
    // portable kernel while the reader assumed SIMD would be worse than no
    // sweep at all.
    println!("# Throughput, latency, and scaling --- every figure is `open`, in Gmac/s");
    println!(
        "# i8 kernels available: {}",
        uor_matmul::kernels::available_i8()
            .map(|s| s.backend.as_str())
            .collect::<Vec<_>>()
            .join(", ")
    );
    println!(
        "# i32 modular kernels available: {}",
        uor_matmul::kernels::available_i32_modular()
            .map(|s| s.backend.as_str())
            .collect::<Vec<_>>()
            .join(", ")
    );
    println!("# best of as many repetitions as fit 0.35s; the answer is asserted inside");
    println!("# the timed region; operands are a recorded pseudo-random fill, not ones");

    header("n (cube)");
    let mut rows = Vec::new();
    for &n in SIZES {
        let r = point(&format!("{n}"), n, n, n);
        emit(&r);
        rows.push(r);
    }

    println!();
    println!("# latency at the smallest shapes, in nanoseconds per call");
    println!(
        "{:>14} {:>11} {:>11} {:>11} {:>11}",
        "n (cube)", "uor i8", "uor i32", "ndarray", "matrixmul"
    );
    for r in rows.iter().take(4) {
        println!(
            "{:>14} {:>11.1} {:>11.1} {:>11.1} {:>11.1}",
            r.label,
            r.i8 * 1e9,
            r.i32 * 1e9,
            r.nd * 1e9,
            r.mm * 1e9
        );
    }

    header("m x k x n");
    for &(label, m, k, n) in SHAPES {
        emit(&point(label, m, k, n));
    }

    println!();
    println!("# fitted exponent against MAC count, over the square sweep");
    for (name, pick) in [
        ("uor i8", 0usize),
        ("uor i32", 1),
        ("ndarray", 2),
        ("nalgebra", 3),
        ("uor f32", 4),
        ("matrixmul", 5),
    ] {
        let points: Vec<(f64, f64)> = rows
            .iter()
            .map(|r| {
                let secs = [r.i8, r.i32, r.nd, r.na, r.f32, r.mm][pick];
                (r.macs, gmacs(r.macs, secs))
            })
            .collect();
        println!("{name:<14}{:>8.4}", exponent(&points));
    }
}
