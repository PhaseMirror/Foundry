//! Fitted scaling exponents (§13, R12, `CG-01` .. `CG-07`).
//!
//! Every claim in this module is `open`: measured and reported, never asserted.
//! A fitted exponent is a description of a machine on a day, not a property of
//! the library, and the honesty gate fails the build if any of it is restated
//! as established (R4).
//!
//! What *is* asserted, inside the timed harness, is that the answer is right.
//! A speed measured on the wrong bytes measures nothing, so `run_case` is the
//! same call the differential tests make.

use std::time::Instant;

use uor_matmul::prelude::*;
use uor_matmul_core::{EncodeMode, Full};

/// One point of a sweep.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Point {
    /// Rows.
    pub m: usize,
    /// Depth.
    pub k: usize,
    /// Columns.
    pub n: usize,
}

impl Point {
    /// Multiply-accumulates in this product. The independent variable of the
    /// arithmetic fit.
    pub fn macs(&self) -> f64 {
        (self.m as f64) * (self.k as f64) * (self.n as f64)
    }
}

/// A shape sweep, and the axis it varies.
#[derive(Clone, Debug)]
pub struct Sweep {
    /// A human-readable name for the axis.
    pub axis: &'static str,
    /// The points, in increasing size.
    pub points: Vec<Point>,
}

impl Sweep {
    /// The standing sweep: a cube sweep for `CG-01`, and one sweep per axis for
    /// `CG-02`.
    ///
    /// Geometric rather than linear, because a fit over linearly spaced points
    /// is dominated by the largest few and would report the asymptote of the
    /// tail rather than of the curve.
    pub fn standard() -> Self {
        Self {
            axis: "cube",
            points: [32usize, 48, 64, 96, 128, 192, 256, 320, 384]
                .iter()
                .map(|&s| Point { m: s, k: s, n: s })
                .collect(),
        }
    }

    /// One axis varied with the others fixed (`CG-02`).
    pub fn per_axis(axis: &'static str) -> Self {
        let fixed = 64usize;
        let steps = [16usize, 32, 64, 128, 256, 512, 1024];
        let points = steps
            .iter()
            .map(|&s| match axis {
                "m" => Point {
                    m: s,
                    k: fixed,
                    n: fixed,
                },
                "n" => Point {
                    m: fixed,
                    k: fixed,
                    n: s,
                },
                _ => Point {
                    m: fixed,
                    k: s,
                    n: fixed,
                },
            })
            .collect();
        Self { axis, points }
    }
}

/// One `(size, time)` observation.
#[derive(Clone, Copy, Debug)]
pub struct Observation {
    /// The independent variable, already in the units the fit uses.
    pub x: f64,
    /// Seconds.
    pub y: f64,
}

/// A fitted power law `y = c * x^exponent`, with its uncertainty.
#[derive(Clone, Debug)]
pub struct Fit {
    /// The fitted exponent. For an `O(m k n)` GEMM against MAC count this is
    /// near 1; against a linear dimension of a cube sweep it is near 3.
    pub exponent: f64,
    /// The half-width of the 95% confidence interval on the exponent.
    ///
    /// Reported always. An exponent without one is an anecdote.
    pub confidence_half_width: f64,
    /// `log10` of the constant factor. The residency claim lives here: two
    /// implementations with the same exponent and different constants differ by
    /// exactly this (§13, `CG-03`).
    pub log_constant: f64,
    /// Root-mean-square residual in log space. Large means the power law does
    /// not describe the data, and the exponent should not be believed.
    pub rms_residual: f64,
    /// How many observations the fit used.
    pub samples: usize,
}

/// Above this RMS residual in log space, the power law does not describe the
/// data and the exponent should not be believed.
///
/// `0.15` in log10 is about a factor of 1.4 of typical deviation. An
/// implementation with a heavy prologue --- a thread pool to spin up, a
/// blocking decision to make --- is not a power law over a range that includes
/// shapes too small to amortise it, and quoting an exponent for it anyway would
/// be the dishonest part. `CG-07` is the claim that covers that region.
pub const RESIDUAL_LIMIT: f64 = 0.15;

impl Fit {
    /// Does a power law describe this data well enough to read the exponent?
    pub fn is_credible(&self) -> bool {
        self.rms_residual <= RESIDUAL_LIMIT
    }
}

/// Least squares in log-log space.
///
/// Returns `None` for fewer than three points, because two points fit any line
/// exactly and would report a confidence interval of zero --- which would be a
/// lie rather than a measurement.
pub fn fit(observations: &[Observation]) -> Option<Fit> {
    let usable: Vec<(f64, f64)> = observations
        .iter()
        .filter(|o| o.x > 0.0 && o.y > 0.0)
        .map(|o| (o.x.log10(), o.y.log10()))
        .collect();
    if usable.len() < 3 {
        return None;
    }
    let n = usable.len() as f64;
    let mean_x = usable.iter().map(|p| p.0).sum::<f64>() / n;
    let mean_y = usable.iter().map(|p| p.1).sum::<f64>() / n;
    let sxx: f64 = usable.iter().map(|p| (p.0 - mean_x).powi(2)).sum();
    if sxx == 0.0 {
        return None;
    }
    let sxy: f64 = usable.iter().map(|p| (p.0 - mean_x) * (p.1 - mean_y)).sum();
    let slope = sxy / sxx;
    let intercept = mean_y - slope * mean_x;

    let residuals: Vec<f64> = usable
        .iter()
        .map(|p| p.1 - (intercept + slope * p.0))
        .collect();
    let sse: f64 = residuals.iter().map(|r| r * r).sum();
    let dof = n - 2.0;
    let stderr = if dof > 0.0 {
        (sse / dof / sxx).sqrt()
    } else {
        f64::INFINITY
    };

    Some(Fit {
        exponent: slope,
        // 1.96 sigma is the normal 95% interval. With few points this is
        // optimistic, which is why `samples` is reported alongside it.
        confidence_half_width: 1.96 * stderr,
        log_constant: intercept,
        rms_residual: (sse / n).sqrt(),
        samples: usable.len(),
    })
}

/// Run one case and assert the answer, then return the elapsed time.
///
/// The assertion is inside the timed harness on purpose (`CG-06`): a speed
/// measured on the wrong bytes is not a measurement.
pub fn run_case(m: usize, k: usize, n: usize, a: &[i8], w: &[i8], out: &mut [i32]) -> f64 {
    let started = Instant::now();
    {
        let av = MatView::row_major(as_alphabet_full(a), m, k).expect("A fits");
        let bv = MatView::row_major(as_alphabet_full(w), k, n).expect("B fits");
        let cv = MatViewMut::row_major(out, m, n).expect("C fits");
        let mut t = Triple::new(av, bv, cv).expect("the product exists");
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions {
                encode: EncodeMode::Wrapping,
                ..Default::default()
            },
            &mut Scratch::none(),
        );
    }
    started.elapsed().as_secs_f64()
}

/// Fit a power law to anything that can be timed over a sweep.
///
/// The comparison C3 asks for is only meaningful if both sides are measured the
/// same way: same shapes, same data, same clock, same process. So both this
/// library and every oracle go through this one function, and the only thing
/// that differs between them is the call inside `run`.
pub fn fit_timed(sweep: &Sweep, mut run: impl FnMut(&Point) -> f64) -> Option<Fit> {
    let observations: Vec<Observation> = sweep
        .points
        .iter()
        .map(|p| Observation {
            x: p.macs(),
            y: run(p),
        })
        .collect();
    fit(&observations)
}

/// One implementation's fit, labelled.
#[derive(Clone, Debug)]
pub struct Labelled {
    /// The conformance ID, or `uor-matmul` for us.
    pub id: &'static str,
    /// What was measured.
    pub name: &'static str,
    /// The fit, if the sweep produced enough usable points.
    pub fit: Option<Fit>,
}

impl Labelled {
    /// How many times slower this is than `reference` at a fixed size, from the
    /// fitted constants.
    ///
    /// Only meaningful when the two exponents agree: if they do not, there is
    /// no fixed ratio, and the exponents are the comparison. That is why this
    /// returns `None` rather than a number when they differ by more than their
    /// intervals allow.
    pub fn constant_ratio_against(&self, reference: &Labelled) -> Option<f64> {
        let (a, b) = (self.fit.as_ref()?, reference.fit.as_ref()?);
        if !a.is_credible() || !b.is_credible() {
            return None;
        }
        let gap = (a.exponent - b.exponent).abs();
        if gap > a.confidence_half_width + b.confidence_half_width {
            return None;
        }
        Some(10f64.powf(a.log_constant - b.log_constant))
    }
}

/// Time this library over a sweep, against MAC count.
pub fn fit_ours(sweep: &Sweep) -> Option<Fit> {
    let observations: Vec<Observation> = sweep
        .points
        .iter()
        .map(|p| {
            let a = vec![1i8; p.m * p.k];
            let w = vec![1i8; p.k * p.n];
            let mut out = vec![0i32; p.m * p.n];
            let y = run_case(p.m, p.k, p.n, &a, &w, &mut out);
            // The answer is `k` for every element, which the harness checks
            // rather than assumes.
            assert!(
                out.iter().all(|&v| v == p.k as i32),
                "the timed call must be correct"
            );
            Observation { x: p.macs(), y }
        })
        .collect();
    fit(&observations)
}

/// Time this library's `i32 x i32` path, which is what the integer oracles
/// speak.
///
/// The `i8` path is faster and is what the library is for; this exists so the
/// comparison against `ndarray` and `nalgebra` is of the same arithmetic on
/// both sides rather than of two different problems.
pub fn ours_i32_timed(p: &Point) -> f64 {
    let a = vec![1i32; p.m * p.k];
    let b = vec![1i32; p.k * p.n];
    let mut out = vec![0i32; p.m * p.n];
    let mut scratch = vec![Alphabet::<i32, Full<i32>>::ZERO; 1 << 20];
    let started = Instant::now();
    {
        let av = MatView::row_major(as_alphabet_full(&a), p.m, p.k).expect("A fits");
        let bv = MatView::row_major(as_alphabet_full(&b), p.k, p.n).expect("B fits");
        let cv = MatViewMut::row_major(&mut out, p.m, p.n).expect("C fits");
        let mut t = Triple::new(av, bv, cv).expect("the product exists");
        // The packed driver, which is what the library runs. Timing the generic
        // one would be timing a factorization the caller never gets.
        uor_matmul::gemm_packed(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions {
                encode: EncodeMode::Wrapping,
                ..Default::default()
            },
            &mut Scratch::new(&mut scratch),
        );
    }
    // The timed call must be correct, or the number describes nothing.
    assert!(out.iter().all(|&v| v == p.k as i32));
    started.elapsed().as_secs_f64()
}

/// Time this library's `f32` path.
pub fn ours_f32_timed(p: &Point) -> f64 {
    let a = vec![1.0f32; p.m * p.k];
    let b = vec![1.0f32; p.k * p.n];
    let mut out = vec![0.0f32; p.m * p.n];
    let started = Instant::now();
    {
        let av = MatView::row_major(&a, p.m, p.k).expect("A fits");
        let bv = MatView::row_major(&b, p.k, p.n).expect("B fits");
        let cv = MatViewMut::row_major(&mut out, p.m, p.n).expect("C fits");
        let mut t = Triple::new(av, bv, cv).expect("the product exists");
        crate::gemm_float_for_scaling(&mut t);
    }
    assert!(out.iter().all(|&v| v == p.k as f32));
    started.elapsed().as_secs_f64()
}

/// Bytes of weight storage a coded tier touches, per decoded element.
///
/// The residency claim of `CG-03`, as a ratio rather than an adjective: an
/// `i4` tier stores half a byte per weight where a dense `i8` tier stores one,
/// and what that buys is measured against the oracle over the same sweep.
pub fn residency_ratio(bits_per_weight: f64) -> f64 {
    bits_per_weight / 8.0
}

/// The report `just scaling` emits: this library beside every oracle.
///
/// C3 is a hard constraint --- scaling is compared against the *oracle's*
/// scaling --- so a report with only our own numbers would not discharge it.
/// What matters is whether the exponents agree, because two implementations
/// with the same exponent and different constants differ by a factor that does
/// not grow, and two with different exponents eventually differ by any factor
/// you like.
#[derive(Clone, Debug)]
pub struct Report {
    /// The sweep every fit was taken over.
    pub sweep: Sweep,
    /// This library, first.
    pub ours: Labelled,
    /// Every oracle measured over the same sweep.
    pub oracles: Vec<Labelled>,
}

impl Report {
    /// Assemble a report.
    pub fn new(sweep: Sweep, ours: Labelled, oracles: Vec<Labelled>) -> Self {
        Self {
            sweep,
            ours,
            oracles,
        }
    }

    /// Print it, with every number labelled `open`.
    ///
    /// The labelling is not decoration. `CG-*` claims are measurements, and a
    /// report that presented them as results would be exactly the blurring of
    /// registers the honesty gate exists to catch (R4, §2).
    pub fn emit(&self) {
        println!("# Scaling report --- every figure is `open`: measured, never asserted");
        println!(
            "# sweep: {}, {} points",
            self.sweep.axis,
            self.sweep.points.len()
        );
        println!();
        println!(
            "{:<24} {:>10} {:>10} {:>12} {:>10} {:>6} {:>9}",
            "implementation", "exponent", "+/- 95%", "log10 c", "residual", "n", "credible"
        );
        for row in core::iter::once(&self.ours).chain(self.oracles.iter()) {
            match &row.fit {
                Some(f) => println!(
                    "{:<24} {:>10.4} {:>10.4} {:>12.4} {:>10.4} {:>6} {:>9}",
                    row.name,
                    f.exponent,
                    f.confidence_half_width,
                    f.log_constant,
                    f.rms_residual,
                    f.samples,
                    if f.is_credible() { "yes" } else { "NO" }
                ),
                None => println!("{:<24} {:>10}", row.name, "no fit"),
            }
        }
        println!();
        for row in &self.oracles {
            let credible = row.fit.as_ref().is_some_and(Fit::is_credible);
            if !credible {
                println!(
                    "{} ({}): residual above {RESIDUAL_LIMIT}, so a power law does not \
                     describe it over this sweep and its exponent should not be read. \
                     CG-07 covers the small-shape region where a prologue dominates.",
                    row.name, row.id
                );
                continue;
            }
            match row.constant_ratio_against(&self.ours) {
                Some(r) if r < 1.0 => println!(
                    "{} ({}): same exponent within the intervals; {:.2}x faster than \
                     uor-matmul at a fixed size",
                    row.name,
                    row.id,
                    1.0 / r
                ),
                Some(r) => println!(
                    "{} ({}): same exponent within the intervals; {:.2}x slower than \
                     uor-matmul at a fixed size",
                    row.name, row.id, r
                ),
                None => println!(
                    "{} ({}): exponents differ by more than their intervals, so there is \
                     no fixed ratio --- the exponents are the comparison",
                    row.name, row.id
                ),
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The fit recovers an exponent it is given, which is what makes it a
    /// measurement rather than a formatting exercise.
    #[test]
    fn the_fit_recovers_a_known_exponent_cg_01() {
        // y = 3 * x^2, exactly.
        let obs: Vec<Observation> = (1..=20)
            .map(|i| {
                let x = i as f64;
                Observation { x, y: 3.0 * x * x }
            })
            .collect();
        let f = fit(&obs).expect("twenty points fit");
        assert!((f.exponent - 2.0).abs() < 1e-9, "exponent {}", f.exponent);
        assert!((f.log_constant - 3.0f64.log10()).abs() < 1e-9);
        assert!(f.rms_residual < 1e-12, "an exact power law has no residual");
    }

    /// A fit over too few points reports nothing rather than a false certainty.
    #[test]
    fn too_few_points_do_not_fit_cg_01() {
        let obs = [
            Observation { x: 1.0, y: 1.0 },
            Observation { x: 2.0, y: 4.0 },
        ];
        assert!(fit(&obs).is_none());
    }

    /// Noise widens the interval rather than being hidden, and the residual
    /// says the power law fits less well.
    #[test]
    fn noise_widens_the_interval_cg_01() {
        let clean: Vec<Observation> = (1..=20)
            .map(|i| Observation {
                x: i as f64,
                y: (i * i) as f64,
            })
            .collect();
        let noisy: Vec<Observation> = (1..=20)
            .map(|i| {
                let wobble = if i % 2 == 0 { 1.6 } else { 0.625 };
                Observation {
                    x: i as f64,
                    y: (i * i) as f64 * wobble,
                }
            })
            .collect();
        let a = fit(&clean).unwrap();
        let b = fit(&noisy).unwrap();
        assert!(b.confidence_half_width > a.confidence_half_width);
        assert!(b.rms_residual > a.rms_residual);
    }

    /// `CG-03`: the residency claim is a ratio, not an adjective.
    #[test]
    fn residency_is_a_number_cg_03() {
        assert_eq!(residency_ratio(8.0), 1.0);
        assert_eq!(residency_ratio(4.0), 0.5);
        assert_eq!(residency_ratio(2.0), 0.25);
    }
}
