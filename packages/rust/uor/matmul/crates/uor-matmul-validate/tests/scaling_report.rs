//! `CG-01` .. `CG-07`: the scaling axis (§13, R12, C3).
//!
//! Every figure below is `open`: measured and reported, never asserted. None of
//! these tests fails on a performance number, and the honesty meta-gate would
//! fail the build if the documentation said one of them established anything.
//!
//! What they *do* fail on is a broken measurement --- a fit that cannot recover
//! a known exponent, a residency ratio that is not a ratio, a timed harness
//! that timed the wrong answer. A measurement apparatus that cannot be wrong is
//! not measuring.

use uor_matmul_validate::scaling::{self, Labelled, Observation, Point, Sweep};

/// `CG-01`: the arithmetic scaling exponent, ours **and every oracle's**, over
/// the same sweep.
///
/// C3 is a hard constraint: scaling is compared against the oracle's scaling,
/// not reported alone. A throughput table with no asymptotic content would say
/// nothing about whether the two implementations have the same shape, which is
/// the only comparison that survives a change of machine.
#[test]
fn arithmetic_scaling_exponent_cg_01() {
    let sweep = Sweep::standard();

    let ours = Labelled {
        id: "uor-matmul",
        name: "uor-matmul i32",
        fit: scaling::fit_timed(&sweep, scaling::ours_i32_timed),
    };

    let mut oracles: Vec<Labelled> = Vec::new();

    #[cfg(feature = "ref-ndarray")]
    {
        use uor_matmul_validate::oracle::{NdArray, Oracle};
        oracles.push(Labelled {
            id: "CX-01",
            name: "ndarray i32",
            fit: scaling::fit_timed(&sweep, |p: &Point| {
                let a = vec![1i32; p.m * p.k];
                let b = vec![1i32; p.k * p.n];
                let started = std::time::Instant::now();
                let out = NdArray::product_i32(p.m, p.k, p.n, &a, &b);
                let elapsed = started.elapsed().as_secs_f64();
                // The timed call must be correct on the oracle's side too.
                assert!(out.iter().all(|&v| v == p.k as i32));
                elapsed
            }),
        });
    }

    #[cfg(feature = "ref-nalgebra")]
    {
        use uor_matmul_validate::oracle::{Nalgebra, Oracle};
        oracles.push(Labelled {
            id: "CX-02",
            name: "nalgebra i32",
            fit: scaling::fit_timed(&sweep, |p: &Point| {
                let a = vec![1i32; p.m * p.k];
                let b = vec![1i32; p.k * p.n];
                let started = std::time::Instant::now();
                let out = Nalgebra::product_i32(p.m, p.k, p.n, &a, &b);
                let elapsed = started.elapsed().as_secs_f64();
                assert!(out.iter().all(|&v| v == p.k as i32));
                elapsed
            }),
        });
    }

    let report = scaling::Report::new(sweep, ours.clone(), oracles);
    report.emit();

    let f = ours
        .fit
        .expect("the standard sweep has enough points to fit");
    // An O(m k n) implementation fits near 1.0 against MAC count. The interval
    // is reported rather than asserted narrow, because a shared runner is a
    // noisy machine and pretending otherwise would be the dishonest part.
    assert!(f.samples >= 3, "the fit must have used the sweep");
    assert!(f.exponent.is_finite(), "the fit must produce a number");
}

/// `CG-01`, float half: our exact `f32` path against the classical ones.
///
/// The exponents are what to compare. The constant is expected to favour the
/// oracles --- exact accumulation into a 619-bit register costs more per
/// element than one FMA, which is non-goal N4 stated as a number rather than as
/// an excuse.
#[test]
fn float_scaling_exponent_cg_01() {
    let sweep = Sweep::standard();

    let ours = Labelled {
        id: "uor-matmul",
        name: "uor-matmul f32 exact",
        fit: scaling::fit_timed(&sweep, scaling::ours_f32_timed),
    };

    let mut oracles: Vec<Labelled> = Vec::new();

    #[cfg(feature = "ref-matrixmultiply")]
    {
        use uor_matmul_validate::oracle::{FloatOracle, MatrixMultiply};
        oracles.push(Labelled {
            id: "CX-05",
            name: "matrixmultiply f32",
            fit: scaling::fit_timed(&sweep, |p: &Point| {
                let a = vec![1.0f32; p.m * p.k];
                let b = vec![1.0f32; p.k * p.n];
                let started = std::time::Instant::now();
                let out = MatrixMultiply::product_f32(p.m, p.k, p.n, &a, &b);
                let elapsed = started.elapsed().as_secs_f64();
                assert!(out.iter().all(|&v| v == p.k as f32));
                elapsed
            }),
        });
    }

    #[cfg(feature = "ref-faer")]
    {
        use uor_matmul_validate::oracle::{Faer, FloatOracle};
        oracles.push(Labelled {
            id: "CX-06",
            name: "faer f32",
            fit: scaling::fit_timed(&sweep, |p: &Point| {
                let a = vec![1.0f32; p.m * p.k];
                let b = vec![1.0f32; p.k * p.n];
                let started = std::time::Instant::now();
                let out = Faer::product_f32(p.m, p.k, p.n, &a, &b);
                let elapsed = started.elapsed().as_secs_f64();
                assert!(out.iter().all(|&v| v == p.k as f32));
                elapsed
            }),
        });
    }

    scaling::Report::new(sweep, ours.clone(), oracles).emit();
    assert!(ours.fit.expect("fits").exponent.is_finite());
}

/// `CG-02`: per-axis exponents for `m`, `n`, and `k` separately.
///
/// A cube sweep cannot distinguish an implementation that is linear in `k` and
/// quadratic in `m` from one that is the reverse. Varying one axis at a time is
/// what makes the claim about *shape* rather than about size.
#[test]
fn per_axis_scaling_exponents_cg_02() {
    for axis in ["m", "k", "n"] {
        let sweep = Sweep::per_axis(axis);
        let f = scaling::fit_ours(&sweep).expect("each axis sweep fits");
        eprintln!(
            "CG-02 (open): axis {axis}: exponent {:.4} +/- {:.4}, n = {}",
            f.exponent, f.confidence_half_width, f.samples
        );
        assert!(f.exponent.is_finite());
    }
}

/// `CG-03`: residency, per codec, as a ratio.
#[test]
fn residency_scaling_cg_03() {
    for (name, bits) in [("i8 dense", 8.0), ("i4 grid", 4.0), ("E8 codebook", 1.0)] {
        let r = scaling::residency_ratio(bits);
        eprintln!("CG-03 (open): {name} touches {r:.3} bytes per decoded weight");
        assert!(r > 0.0);
    }
    // E8 stores one byte per eight decoded weights.
    assert_eq!(scaling::residency_ratio(1.0), 0.125);
}

/// `CG-04`: working-set scaling --- `suggested_scratch` against the shape.
///
/// The comparison the plan asks for is against each oracle's *measured internal
/// allocation*. Ours is a query with a closed form and no allocation at all, so
/// what is reported is that closed form; `CG-05` reports the allocation count
/// that makes the comparison one-sided.
#[test]
fn working_set_scaling_cg_04() {
    use uor_matmul_core::Shape;
    let mut previous = 0usize;
    for s in [16usize, 32, 64, 128, 256, 512] {
        let want = uor_matmul::suggested_scratch(Shape { m: s, k: s, n: s });
        let operands = s * s * 2;
        eprintln!(
            "CG-04 (open): {s}^3 suggests {want} scratch elements, \
             {:.3} of the operands",
            want as f64 / operands as f64
        );
        assert!(
            want >= previous,
            "the suggestion must not shrink as the shape grows"
        );
        previous = want;
    }

    // The suggestion asks for one block of each operand at the full depth, so it
    // grows with `k` --- and the bound that matters is that it is never more
    // than the operands themselves, because `MC <= m` and `NC <= n` after the
    // clamps. A caller who wants less offers less and gets the same bytes from
    // the chunked traversal (`CD-04`, `CD-10`), which is what makes this a query
    // and not a requirement.
    for (m, k, n) in [
        (1usize, 1usize << 30, 1usize),
        (1 << 20, 1 << 20, 1 << 20),
        (4, 1 << 24, 4),
        (1 << 16, 3, 1 << 16),
    ] {
        let want = uor_matmul::suggested_scratch(Shape { m, k, n });
        let operands = k.saturating_mul(m) + k.saturating_mul(n);
        eprintln!("CG-04 (open): {m}x{k}x{n} suggests {want}, operands are {operands}");
        assert!(
            want <= operands,
            "the suggestion never exceeds the operands it packs from"
        );
    }
}

/// `CG-05`: allocation count and peak bytes. Zero here, whatever an oracle does.
#[test]
fn allocation_scaling_cg_05() {
    // This is a `build` claim elsewhere --- `CA-01` measures it with a counting
    // allocator. Here it is reported as the constant it is, because a scaling
    // report with a blank in this row would invite the reader to guess.
    eprintln!("CG-05 (open): uor-matmul allocates 0 times and 0 bytes, at every shape");
    eprintln!("CG-05 (open): the figure is structural (R7), and CA-01 observes it");
}

/// `CG-06`: parallel speedup against tile count, with byte-equality asserted
/// inside the timed harness.
///
/// The library spawns nothing, so what is measured is the partition: how the
/// work divides, and that dividing it does not change the answer. A speedup
/// number from a harness that did not check the bytes would be a measurement of
/// the wrong program.
#[test]
fn parallel_speedup_against_tile_count_cg_06() {
    use uor_matmul::prelude::*;
    use uor_matmul_core::{dot_ref, EncodeMode, Shape};
    use uor_matmul_gemm::Partition;

    let (m, k, n) = (48usize, 64usize, 48usize);
    let a: Vec<i8> = (0..m * k).map(|i| ((i * 17) % 255) as i8).collect();
    let b: Vec<i8> = (0..k * n).map(|i| ((i * 23) % 255) as i8).collect();
    let reference = uor_matmul_validate::ours_i8_i32(m, k, n, &a, &b, EncodeMode::Wrapping);

    for tiles in [1usize, 2, 4, 8, 16] {
        let side = (m / tiles).max(1);
        let part = Partition::new(Shape { m, k, n }, side, n);
        let started = std::time::Instant::now();
        let mut out = vec![0i32; m * n];
        for t in part {
            for i in t.row..t.row + t.rows {
                for j in t.col..t.col + t.cols {
                    let row: Vec<i8> = (0..k).map(|p| a[i * k + p]).collect();
                    let col: Vec<i8> = (0..k).map(|p| b[p * n + j]).collect();
                    out[i * n + j] = dot_ref(as_alphabet_full(&row), as_alphabet_full(&col)) as i32;
                }
            }
        }
        let elapsed = started.elapsed().as_secs_f64();
        // The assertion is inside the harness, not after it.
        assert_eq!(out, reference, "{tiles} tiles must give the same bytes");
        eprintln!(
            "CG-06 (open): {} tile(s), {elapsed:.6}s, bytes identical",
            part.len()
        );
    }
}

/// `CG-07`: small-shape latency, where a heavyweight prologue costs more than
/// an asymptote.
#[test]
fn small_shape_latency_cg_07() {
    for s in [1usize, 2, 4, 8, 16] {
        let a = vec![1i8; s * s];
        let b = vec![1i8; s * s];
        let mut out = vec![0i32; s * s];
        // Several repetitions, because one call at this size measures the clock.
        let started = std::time::Instant::now();
        for _ in 0..1000 {
            scaling::run_case(s, s, s, &a, &b, &mut out);
        }
        let per_call = started.elapsed().as_secs_f64() / 1000.0;
        eprintln!("CG-07 (open): {s}x{s}x{s} costs {:.9}s per call", per_call);
        assert!(
            out.iter().all(|&v| v == s as i32),
            "the timed call must be correct"
        );
    }
}

/// The apparatus is falsifiable: the fit recovers a known exponent, and fails
/// to fit what it should not.
#[test]
fn the_scaling_apparatus_is_falsifiable_cg_01() {
    let cubic: Vec<Observation> = (1..=20)
        .map(|i| Observation {
            x: i as f64,
            y: 7.0 * (i as f64).powi(3),
        })
        .collect();
    let f = scaling::fit(&cubic).expect("fits");
    assert!((f.exponent - 3.0).abs() < 1e-9, "exponent {}", f.exponent);
    assert!(
        scaling::fit(&cubic[..2]).is_none(),
        "two points must not fit"
    );
}

/// `CG-09`: throughput against the *degeneracy* of the operand.
///
/// Every classical GEMM issues `m * k * n` products whatever the operands hold.
/// The collapse traversal issues one accumulation per distinct row of `A`, so
/// its cost tracks how many meanings the operand carries rather than how many
/// expressions it is written in. This measures that, and --- in the last row of
/// each shape --- what it costs when there is nothing to find.
///
/// `open`: reported, never asserted. What it *does* fail on is a broken
/// measurement, and the whole output of both traversals is compared inside the
/// harness, because a speed that came from a different answer is not a speed.
#[test]
fn throughput_against_degeneracy_cg_09() {
    use uor_matmul_core::{
        as_alphabet_full, Alphabet, EncodeMode, Full, MatView, MatViewMut, Shape, Triple,
    };
    use uor_matmul_gemm::{
        gemm_collapsed, gemm_packed, suggested_collapse_index, suggested_collapse_rows,
        suggested_scratch, Collapse, GemmOptions, Linear, Scratch,
    };

    // Modest, because this runs inside `just vv`. The wide sweep lives in the
    // `collapse_sweep` example, which is where the large shapes are measured.
    let (m, k, n) = (1024usize, 128usize, 128usize);
    let shape = Shape { m, k, n };
    let macs = (m * k * n) as f64;
    let options = GemmOptions {
        encode: EncodeMode::Wrapping,
        ..Default::default()
    };

    // A recorded generator rather than an arithmetic pattern: an arithmetic one
    // repeats, and a sweep over degeneracy whose operand has its own accidental
    // degeneracy measures nothing.
    let fill = |len: usize, salt: u64| -> Vec<i8> {
        let mut s = 0x243F_6A88_85A3_08D3u64 ^ salt;
        (0..len)
            .map(|_| {
                s ^= s << 13;
                s ^= s >> 7;
                s ^= s << 17;
                ((s >> 33) as i64 % 251 - 125) as i8
            })
            .collect()
    };

    let b: Vec<i8> = fill(k * n, 0xb1a5);
    let mut scratch = vec![Alphabet::<i8, Full<i8>>::ZERO; suggested_scratch(shape)];
    let mut index = vec![0usize; suggested_collapse_index(m)];
    let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; suggested_collapse_rows(shape)];

    for meanings in [1usize, 32, 256, m] {
        let base = fill(meanings * k, 0x5eed);
        let a: Vec<i8> = (0..m * k)
            .map(|x| base[(x / k % meanings) * k + x % k])
            .collect();

        let mut c = vec![0i32; m * n];
        let time = |run: &mut dyn FnMut()| {
            // Warm, then measure: the first touch of an output is a page fault
            // rate and not a copy rate.
            run();
            let s = std::time::Instant::now();
            for _ in 0..3 {
                run();
            }
            s.elapsed().as_secs_f64() / 3.0
        };

        let t_collapsed = {
            let (a, b, c, scratch, index, rows) =
                (&a, &b, &mut c, &mut scratch, &mut index, &mut rows);
            time(&mut || {
                let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
                let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
                let cv = MatViewMut::row_major(c, m, n).unwrap();
                let mut t = Triple::new(av, bv, cv).unwrap();
                gemm_collapsed(
                    &mut t,
                    &Linear::OVERWRITE,
                    options,
                    &mut Scratch::new(scratch),
                    &mut Collapse::new(index, rows),
                );
            })
        };
        let collapsed = c.clone();

        let t_packed = {
            let (a, b, c, scratch) = (&a, &b, &mut c, &mut scratch);
            time(&mut || {
                let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
                let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
                let cv = MatViewMut::row_major(c, m, n).unwrap();
                let mut t = Triple::new(av, bv, cv).unwrap();
                gemm_packed(
                    &mut t,
                    &Linear::OVERWRITE,
                    options,
                    &mut Scratch::new(scratch),
                );
            })
        };

        // Not a spot check: the whole output, both traversals.
        assert_eq!(
            collapsed, c,
            "the timed traversals must agree byte for byte at {meanings} meanings"
        );

        eprintln!(
            "CG-09 (open): {m}x{k}x{n}, {meanings} distinct rows: collapsed {:.1} Gmac/s, packed {:.1} Gmac/s ({:.2}x)",
            macs / t_collapsed / 1e9,
            macs / t_packed / 1e9,
            t_packed / t_collapsed,
        );
    }
}
