//! The scaling harness (§13, R12, C3).
//!
//! Scaling is a V&V axis, not a benchmark. Every claim here is a **fitted
//! exponent with a confidence interval**, measured for this library and for
//! each oracle over the *same* sweep, and reported together with its residuals.
//! A throughput table with no asymptotic content would say nothing about
//! whether the two implementations have the same shape, which is the only
//! comparison that survives a change of machine.
//!
//! Every `CG-*` claim is `open`: measured and reported, never asserted (R4).
//! Nothing in this file fails a gate on a *performance* number. What it does
//! assert, inside the timed harness, is byte-equality --- because a speed
//! measured on the wrong answer is not a measurement of anything (`CG-06`).

// `criterion_group!` generates a function this crate cannot document, and the
// workspace denies `missing_docs`. The exemption is scoped to this file, which
// is a bench harness rather than a shipped crate.
#![allow(missing_docs)]

use criterion::{criterion_group, criterion_main, Criterion};
use uor_matmul_validate::scaling::{self, Labelled, Sweep};

/// Emit the fitted exponents, then time a few shapes so `cargo bench` has
/// something to report alongside them.
fn scaling_report(c: &mut Criterion) {
    let sweep = Sweep::standard();

    // `CG-01`: the arithmetic scaling exponent. The oracle columns live in the
    // test harness, which has the `ref-*` features; this emits our side so that
    // `cargo bench` and `cargo test` report the same fit for the same sweep.
    let ours = Labelled {
        id: "uor-matmul",
        name: "uor-matmul i8",
        fit: scaling::fit_ours(&sweep),
    };
    scaling::Report::new(sweep.clone(), ours, Vec::new()).emit();

    // A single criterion benchmark so `cargo bench` has something to time; the
    // asymptotic content is in the report above, which is what R12 asks for.
    let mut group = c.benchmark_group("gemm");
    for &n in &[64usize, 128, 256] {
        group.bench_function(format!("i8_i32_{n}cubed"), |b| {
            let a = vec![1i8; n * n];
            let w = vec![1i8; n * n];
            let mut out = vec![0i32; n * n];
            b.iter(|| scaling::run_case(n, n, n, &a, &w, &mut out));
        });
    }
    group.finish();
}

criterion_group!(benches, scaling_report);
criterion_main!(benches);
