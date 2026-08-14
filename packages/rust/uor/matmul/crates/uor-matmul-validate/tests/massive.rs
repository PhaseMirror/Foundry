//! `CT-06`, `CG-08`: super-massive input.
//!
//! Two different kinds of claim, kept apart on purpose.
//!
//! `CT-06` is `build`: a product whose operands are past the last level of
//! cache, whose depth is past every lane's capacity, and whose extents are past
//! every block, is **exact** --- and exact on every traversal the offer admits,
//! because at this size the driver's choices all change and none of them may
//! change a byte. That is asserted.
//!
//! `CG-08` is `open`: how fast it is. Reported per pass, never asserted. What a
//! per-pass report shows that a single figure cannot is whether the throughput is
//! *sustained*: a driver that thrashes, or that grows a working set as it goes,
//! reads slower on the second pass than the first.
//!
//! The sizes are chosen against the machine, not against the library: the
//! library has no size it stops working at, which is the point, and a test that
//! could only run on one machine would be measuring the machine.

use std::time::Instant;

/// Refuse to report a throughput figure from an unoptimised build.
///
/// `cargo test` builds at `opt-level = 0`. Measured, the shapes below read two
/// hundred times slower there than in the shipped profile, so a figure from a
/// debug build is not a slow figure --- it is a different program. `just massive`
/// passes `--release`; this is what makes forgetting it loud instead of silent.
fn require_optimised() {
    if cfg!(debug_assertions) {
        panic!(
            "CG-08 reports throughput and this is a debug build: run `just massive`, \
             which passes --release. An unoptimised timing is not a measurement."
        );
    }
}

use uor_matmul::prelude::*;
use uor_matmul_core::{Backend, EncodeMode, Full, PackedCode, Shape, Traversal};

/// Deterministic fill: a recorded generator, so a failure reproduces from the
/// seed and the shape alone.
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

/// The exact value of one output cell, in `i128`, sharing no code with the
/// library.
fn expect_at(k: usize, n: usize, a: &[i8], b: &[i8], at: usize) -> i128 {
    let (i, j) = (at / n, at % n);
    (0..k)
        .map(|p| i128::from(a[i * k + p]) * i128::from(b[p * n + j]))
        .sum()
}

/// One `i8` product, timed, with the answer checked outside the timed region.
#[allow(clippy::too_many_arguments)]
fn run_i8(
    m: usize,
    k: usize,
    n: usize,
    a: &[i8],
    b: &[i8],
    c: &mut [i32],
    scratch: &mut [Alphabet<i8, Full<i8>>],
    accs: &mut [uor_matmul_core::AccOf<i8>],
    options: GemmOptions,
) -> f64 {
    let started = Instant::now();
    {
        let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
        let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
        let cv = MatViewMut::row_major(c, m, n).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        uor_matmul::gemm_packed(
            &mut t,
            &Linear::OVERWRITE,
            options,
            &mut Scratch::with_accumulators(scratch, accs),
        );
    }
    started.elapsed().as_secs_f64()
}

/// The shapes. Each is past a different one of the driver's limits.
///
/// `(m, k, n, label)`. Sized so that the operands, the output, and one offer of
/// scratch fit a machine with a couple of gigabytes free --- the library imposes
/// no ceiling of its own, and `CT-01` fuzzes far past these.
const MASSIVE: &[(usize, usize, usize, &str)] = &[
    // Past every block extent in both directions, and past the last level of
    // cache in all three operands.
    (1024, 1024, 1024, "past every block"),
    // A depth past the `i8` exact lane's capacity (133144), so the driver must
    // chunk and the chunks must recombine exactly.
    (16, 400_000, 16, "past the exact lane"),
    // A depth past every lane *and* an output too narrow for a tile, so the
    // reduce factorization runs at a size where nothing is resident.
    (8, 1_048_576, 8, "past the lane, narrow output"),
    // One dot product over four million terms: the accumulator's worst case.
    (1, 4_194_304, 1, "one astronomical dot product"),
    // An extent past every block with almost nothing to reduce, so the epilogue
    // and the output writes are the whole cost.
    (4096, 8, 4096, "past every block, shallow"),
];

/// `CT-06`: a super-massive product is exact, on every traversal.
///
/// The reference is an independent `i128` loop over a spread sample of output
/// cells --- the whole output would cost more than the product does, and what
/// this needs to catch is a traversal that goes wrong at scale, which a sample
/// spanning the output catches.
///
/// Every traversal the offer admits must agree: the streaming reference, the
/// chunked traversal at a deliberately small offer, and the blocked traversal at
/// the suggested one. At these sizes those are three genuinely different walks.
#[test]
#[ignore = "minutes, and gigabytes of operands: `just massive`"]
fn a_super_massive_product_is_exact_ct_06() {
    for &(m, k, n, label) in MASSIVE {
        let a: Vec<i8> = fill(m * k, 1, |v| v as i8);
        let b: Vec<i8> = fill(k * n, 2, |v| v as i8);

        // A spread sample, plus both corners.
        let cells = m * n;
        let count = (2_000_000 / k.max(1)).clamp(1, cells).min(64);
        let stride = cells.div_ceil(count);
        let mut probes: Vec<usize> = (0..cells).step_by(stride).collect();
        if *probes.last().unwrap() != cells - 1 {
            probes.push(cells - 1);
        }
        let want: Vec<(usize, i128)> = probes
            .iter()
            .map(|&at| (at, expect_at(k, n, &a, &b, at)))
            .collect();

        // Three offers: none at all, one too small for a full-depth panel, and
        // the suggested one. `CD-04` and `CD-10` say the bytes are the same; here
        // they are the same at a size where the traversals differ most.
        let suggested = uor_matmul::suggested_scratch(Shape { m, k, n });
        let offers = [0usize, 4096, suggested];
        let mut c = vec![0i32; m * n];
        // Every offer, with and without somewhere to keep exact partial sums: the
        // depth-chunked traversal and the full-depth one must agree.
        let want_accs = uor_matmul::suggested_accumulators(Shape { m, k, n });
        for offer in offers {
            let mut scratch = vec![Alphabet::<i8, Full<i8>>::ZERO; offer];
            for accs_len in [0usize, want_accs] {
                let mut accs = vec![
                        <uor_matmul_core::AccOf<i8> as uor_matmul_core::Accumulator>::ZERO;
                        accs_len
                    ];
                for traversal in [Traversal::Blocked, Traversal::OutputMajor] {
                    c.fill(0);
                    let secs = run_i8(
                        m,
                        k,
                        n,
                        &a,
                        &b,
                        &mut c,
                        &mut scratch,
                        &mut accs,
                        GemmOptions {
                            traversal,
                            encode: EncodeMode::Wrapping,
                            backend: Backend::Auto,
                        },
                    );
                    for &(at, w) in &want {
                        assert_eq!(
                            c[at], w as i32,
                            "{label} {m}x{k}x{n}: cell {at} wrong with offer {offer}, \
                         {accs_len} accumulators, {traversal:?}"
                        );
                    }
                    eprintln!(
                        "CT-06: {label} {m}x{k}x{n} exact, offer {offer}, {accs_len} accs, \
                     {traversal:?} ({:.3} s)",
                        secs
                    );
                    // The streaming traversal at a shape this size is O(m k n) with
                    // no packing; running it for every offer would multiply the test
                    // by the number of offers for no extra coverage, since the offer
                    // is what the *packed* traversal responds to.
                    if offer == 0 {
                        break;
                    }
                }
            }
        }
    }
}

/// `CG-08` (open): sustained throughput on super-massive input, per pass.
///
/// Reported, never asserted. What fails here is a broken measurement: a timed
/// region that produced the wrong bytes, or a pass that took no time at all,
/// which would mean the work was elided.
#[test]
#[ignore = "minutes, and gigabytes of operands: `just massive`"]
fn sustained_throughput_on_super_massive_input_cg_08() {
    require_optimised();
    const PASSES: usize = 4;
    eprintln!();
    eprintln!("CG-08 (open): sustained throughput on super-massive input, Gmac/s per pass");
    eprintln!(
        "{:>32} {:>12} {:>9} {:>9} {:>9} {:>9} {:>9}",
        "shape", "macs", "pass 1", "pass 2", "pass 3", "pass 4", "last/1st"
    );

    for &(m, k, n, label) in MASSIVE {
        let macs = (m as f64) * (k as f64) * (n as f64);
        let a: Vec<i8> = fill(m * k, 1, |v| v as i8);
        let b: Vec<i8> = fill(k * n, 2, |v| v as i8);
        let mut c = vec![0i32; m * n];
        let suggested = uor_matmul::suggested_scratch(Shape { m, k, n });
        let mut scratch = vec![Alphabet::<i8, Full<i8>>::ZERO; suggested];
        let mut accs = vec![
            <uor_matmul_core::AccOf<i8> as uor_matmul_core::Accumulator>::ZERO;
            uor_matmul::suggested_accumulators(Shape { m, k, n })
        ];

        let mut rates = Vec::new();
        for _ in 0..PASSES {
            let secs = run_i8(
                m,
                k,
                n,
                &a,
                &b,
                &mut c,
                &mut scratch,
                &mut accs,
                GemmOptions {
                    encode: EncodeMode::Wrapping,
                    ..Default::default()
                },
            );
            assert!(secs > 0.0, "a pass that took no time did no work");
            rates.push(macs / 1e9 / secs);
        }
        // The answer, once, outside every timed region.
        let probe = expect_at(k, n, &a, &b, m * n - 1) as i32;
        assert_eq!(c[m * n - 1], probe, "{label}: the timed passes were wrong");

        eprintln!(
            "{:>32} {:>12.3e} {:>9.2} {:>9.2} {:>9.2} {:>9.2} {:>9.3}",
            format!("{m}x{k}x{n} ({label})"),
            macs,
            rates[0],
            rates[1],
            rates[2],
            rates[3],
            rates[PASSES - 1] / rates[0]
        );
    }
}

/// `CG-08`, the float half: the same shapes the exact float path can afford.
///
/// The exact float path is two orders of magnitude slower per element than the
/// integer one --- N4 --- so the shapes here are the ones it finishes on. What is
/// reported is the same thing: whether the rate holds across passes.
#[test]
#[ignore = "minutes, and gigabytes of operands: `just massive`"]
fn sustained_float_throughput_on_super_massive_input_cg_08() {
    require_optimised();
    const PASSES: usize = 3;
    eprintln!();
    eprintln!("CG-08 (open): exact f32, Gmac/s per pass");
    for &(m, k, n) in &[(256usize, 4096usize, 256usize), (1, 4_194_304, 1)] {
        let macs = (m as f64) * (k as f64) * (n as f64);
        let a: Vec<f32> = fill(m * k, 5, |v| {
            (v % 2048) as f32 * 2.0f32.powi((v % 19) as i32 - 9)
        });
        let b: Vec<f32> = fill(k * n, 6, |v| {
            (v % 2048) as f32 * 2.0f32.powi((v % 23) as i32 - 11)
        });
        let mut c = vec![0.0f32; m * n];
        let mut pa = vec![PackedCode::default(); k];
        let mut pb = vec![PackedCode::default(); k];

        let mut rates = Vec::new();
        let mut first: Option<Vec<f32>> = None;
        for _ in 0..PASSES {
            let started = Instant::now();
            {
                let av = MatView::row_major(&a, m, k).unwrap();
                let bv = MatView::row_major(&b, k, n).unwrap();
                let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
                let mut t = Triple::new(av, bv, cv).unwrap();
                uor_matmul::gemm_float_packed(
                    &mut t,
                    &Linear::OVERWRITE,
                    GemmOptions::default(),
                    &mut pa,
                    &mut pb,
                );
            }
            let secs = started.elapsed().as_secs_f64();
            assert!(secs > 0.0);
            rates.push(macs / 1e9 / secs);
            match &first {
                None => first = Some(c.clone()),
                Some(f) => assert_eq!(f, &c, "{m}x{k}x{n}: a repeated pass gave different bytes"),
            }
        }
        eprintln!(
            "{:>32} {:>12.3e} {}",
            format!("{m}x{k}x{n}"),
            macs,
            rates
                .iter()
                .map(|r| format!("{r:>9.3}"))
                .collect::<Vec<_>>()
                .join("")
        );
    }
}
