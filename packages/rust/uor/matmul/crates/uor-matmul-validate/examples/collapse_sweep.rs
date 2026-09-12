//! What a product costs against how many distinct things it contains.
//!
//! Every classical GEMM issues `m * k * n` products whatever the operands hold.
//! That is not a property of the identity; it is a property of the traversal.
//! The collapse traversal issues one accumulation per *distinct* row of `A`, so
//! its cost tracks the number of meanings the operand carries rather than the
//! number of expressions it is written in.
//!
//! This sweep is the measurement of that, and of its price when there is nothing
//! to find. The `d = m` row is the one to read first: it is the case the
//! traversal exists for and does not get, and it says what the pass costs.
//!
//! Throughput is reported against the *nominal* MAC count, `m * k * n` --- what
//! the caller asked for --- and not against the products actually issued, which
//! would report the same number in every row and hide the whole effect.
//!
//! Every figure is `open`: measured and reported, never asserted. The answer is
//! checked inside the timed region against an independent `i128` reference, and
//! checked to be the *same bytes* the packed traversal gives.

use std::time::Instant;

use uor_matmul::prelude::*;
use uor_matmul_core::{EncodeMode, Full, Shape, Strides};
use uor_matmul_gemm::{
    gemm_collapsed, suggested_collapse_index, suggested_collapse_rows, Collapse,
};

/// Best of as many repetitions as fit a fixed wall-clock budget.
fn best(mut run: impl FnMut() -> f64) -> f64 {
    const BUDGET: f64 = 0.30;
    let mut best = f64::INFINITY;
    let mut spent = 0.0;
    loop {
        let t = run();
        best = best.min(t);
        spent += t;
        if spent >= BUDGET {
            return best;
        }
    }
}

/// A recorded generator, so any figure reproduces from the seed alone.
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

/// An `m x k` operand carrying exactly `meanings` distinct rows.
///
/// Row `i` is a copy of row `i % meanings`, which is the shape a batch of
/// activations over a small vocabulary has: the rows repeat because the *inputs*
/// repeat, not because the numbers are special.
fn operand(m: usize, k: usize, meanings: usize) -> Vec<i8> {
    let base: Vec<i8> = fill(meanings * k, 0x5eed, |x| (x % 255 - 127) as i8);
    (0..m * k)
        .map(|x| base[(x / k % meanings) * k + x % k])
        .collect()
}

fn sample(m: usize, n: usize) -> Vec<usize> {
    let cells = m * n;
    let stride = cells.div_ceil(256);
    (0..cells).step_by(stride).chain([cells - 1]).collect()
}

fn expect_at(k: usize, n: usize, a: &[i8], b: &[i8], at: usize) -> i32 {
    let (i, j) = (at / n, at % n);
    (0..k)
        .map(|p| i128::from(a[i * k + p]) * i128::from(b[p * n + j]))
        .sum::<i128>() as i32
}

fn main() {
    // Deep enough that the pass is a small share of the product, wide enough
    // that a row is worth sharing, and tall enough to hold a wide range of
    // degeneracies.
    const SHAPES: &[(usize, usize, usize)] = &[(4096, 512, 512), (4096, 64, 64), (65536, 128, 128)];

    println!("# The collapse traversal");
    println!();
    println!("Gmac/s against the nominal `m * k * n`. `d` is the number of");
    println!("distinct rows of `A`; `d = m` is an operand with nothing to share.");

    for &(m, k, n) in SHAPES {
        let macs = (m * k * n) as f64;
        let shape = Shape { m, k, n };
        let b: Vec<i8> = fill(k * n, 0xb1a5, |x| (x % 255 - 127) as i8);
        let bv_src = b.clone();

        let mut scratch =
            vec![Alphabet::<i8, Full<i8>>::ZERO; uor_matmul::suggested_scratch(shape)];
        let mut index = vec![0usize; suggested_collapse_index(m)];
        let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; suggested_collapse_rows(shape)];

        println!();
        println!("## `{m} x {k} x {n}`");
        println!();
        println!("| `d` | degeneracy | uor collapsed | uor packed | ndarray | speedup |");
        println!("| --- | --- | --- | --- | --- | --- |");

        let mut degrees: Vec<usize> = Vec::new();
        let mut d = 1;
        while d < m {
            degrees.push(d);
            d *= 8;
        }
        degrees.push(m);

        for &meanings in &degrees {
            let a = operand(m, k, meanings);
            let cells = sample(m, n);
            let want: Vec<(usize, i32)> = cells
                .iter()
                .map(|&at| (at, expect_at(k, n, &a, &bv_src, at)))
                .collect();

            let mut c = vec![0i32; m * n];
            let options = GemmOptions {
                encode: EncodeMode::Wrapping,
                ..Default::default()
            };

            let t_collapsed = best(|| {
                let s = Instant::now();
                {
                    let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                    let bv = MatView::row_major(as_alphabet_full(&bv_src), k, n).unwrap();
                    let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
                    let mut tr = Triple::new(av, bv, cv).unwrap();
                    gemm_collapsed(
                        &mut tr,
                        &Linear::OVERWRITE,
                        options,
                        &mut Scratch::new(&mut scratch),
                        &mut Collapse::new(&mut index, &mut rows),
                    );
                }
                s.elapsed().as_secs_f64()
            });
            for &(at, w) in &want {
                assert_eq!(c[at], w, "the timed collapse must be correct at {at}");
            }
            let collapsed = c.clone();

            let t_packed = best(|| {
                let s = Instant::now();
                {
                    let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                    let bv = MatView::row_major(as_alphabet_full(&bv_src), k, n).unwrap();
                    let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
                    let mut tr = Triple::new(av, bv, cv).unwrap();
                    uor_matmul::gemm_packed(
                        &mut tr,
                        &Linear::OVERWRITE,
                        options,
                        &mut Scratch::new(&mut scratch),
                    );
                }
                s.elapsed().as_secs_f64()
            });
            // Not a spot check: the whole output, both traversals, every
            // degeneracy. A speed that came from a different answer is not a
            // speed.
            assert_eq!(collapsed, c, "the two traversals must agree byte for byte");

            let t_nd = ndarray_i32(m, k, n, &a, &bv_src);

            let g = |t: f64| macs / t / 1e9;
            println!(
                "| {meanings} | {:.0}x | {:.1} | {:.1} | {} | {:.1}x |",
                m as f64 / meanings as f64,
                g(t_collapsed),
                g(t_packed),
                t_nd.map(|t| format!("{:.2}", g(t))).unwrap_or("-".into()),
                t_packed / t_collapsed,
            );
        }
    }

    columns(false);
    columns(true);
}

/// The same traversal on the transposed triple: equal *columns* of `B`.
///
/// No second pass and no second driver --- `(A * B)^T = B^T * A^T`, and
/// transposition is a stride. What differs is the expansion, which walks the
/// output's columns; for a row-major `C` those are not runs, and the table says
/// what that costs.
fn columns(col_major_b: bool) {
    let (m, k, n) = (512usize, 512usize, 4096usize);
    let macs = (m * k * n) as f64;
    let shape = Shape { m, k, n };
    let a: Vec<i8> = fill(m * k, 0xa11, |x| (x % 255 - 127) as i8);

    let mut scratch = vec![Alphabet::<i8, Full<i8>>::ZERO; uor_matmul::suggested_scratch(shape)];
    let mut index = vec![0usize; suggested_collapse_index(n)];
    let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; n * k];

    println!();
    let layout = if col_major_b {
        "column-major"
    } else {
        "row-major"
    };
    println!("## `{m} x {k} x {n}`, collapsing columns of a {layout} `B`");
    println!();
    println!("| `d` | degeneracy | uor collapsed | uor packed | speedup |");
    println!("| --- | --- | --- | --- | --- |");

    let mut degrees: Vec<usize> = Vec::new();
    let mut d = 1;
    while d < n {
        degrees.push(d);
        d *= 8;
    }
    degrees.push(n);

    for &meanings in &degrees {
        // `B` with `meanings` distinct columns, laid out row-major as usual.
        let base: Vec<i8> = fill(meanings * k, 0xc01, |x| (x % 255 - 127) as i8);
        // The same matrix in both layouts: element `(p, j)` is
        // `base[(j % meanings) * k + p]`.
        let b: Vec<i8> = if col_major_b {
            (0..k * n)
                .map(|x| base[(x / k % meanings) * k + x % k])
                .collect()
        } else {
            (0..k * n)
                .map(|x| base[(x % n % meanings) * k + x / n])
                .collect()
        };
        let strides = if col_major_b {
            Strides::col_major(k)
        } else {
            Strides::row_major(n)
        };
        fn bview<'v>(
            b: &'v [i8],
            k: usize,
            n: usize,
            strides: Strides,
        ) -> MatView<'v, Alphabet<i8, Full<i8>>> {
            MatView::new(as_alphabet_full(b), k, n, strides).unwrap()
        }

        let mut c = vec![0i32; m * n];
        let options = GemmOptions {
            encode: EncodeMode::Wrapping,
            ..Default::default()
        };

        let t_collapsed = best(|| {
            let s = Instant::now();
            {
                let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                let bv = bview(&b, k, n, strides);
                let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
                let mut tr = Triple::new(av, bv, cv).unwrap();
                gemm_collapsed(
                    &mut tr.transposed(),
                    &Linear::OVERWRITE,
                    options,
                    &mut Scratch::new(&mut scratch),
                    &mut Collapse::new(&mut index, &mut rows),
                );
            }
            s.elapsed().as_secs_f64()
        });
        let collapsed = c.clone();

        let t_packed = best(|| {
            let s = Instant::now();
            {
                let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                let bv = bview(&b, k, n, strides);
                let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
                let mut tr = Triple::new(av, bv, cv).unwrap();
                uor_matmul::gemm_packed(
                    &mut tr,
                    &Linear::OVERWRITE,
                    options,
                    &mut Scratch::new(&mut scratch),
                );
            }
            s.elapsed().as_secs_f64()
        });
        assert_eq!(collapsed, c, "the two traversals must agree byte for byte");

        let g = |t: f64| macs / t / 1e9;
        println!(
            "| {meanings} | {:.0}x | {:.1} | {:.1} | {:.1}x |",
            n as f64 / meanings as f64,
            g(t_collapsed),
            g(t_packed),
            t_packed / t_collapsed,
        );
    }
}

#[cfg(feature = "ref-ndarray")]
fn ndarray_i32(m: usize, k: usize, n: usize, a: &[i8], b: &[i8]) -> Option<f64> {
    use ndarray::Array2;
    // The oracle sees the same operand, in the element type it multiplies in.
    let a = Array2::from_shape_vec((m, k), a.iter().map(|&x| i32::from(x)).collect()).unwrap();
    let b = Array2::from_shape_vec((k, n), b.iter().map(|&x| i32::from(x)).collect()).unwrap();
    // One repetition: this is the row the sweep exists to be compared against,
    // and at these shapes it already exceeds the budget several times over.
    let s = Instant::now();
    let c = a.dot(&b);
    let t = s.elapsed().as_secs_f64();
    std::hint::black_box(&c);
    Some(t)
}

#[cfg(not(feature = "ref-ndarray"))]
fn ndarray_i32(_: usize, _: usize, _: usize, _: &[i8], _: &[i8]) -> Option<f64> {
    None
}
