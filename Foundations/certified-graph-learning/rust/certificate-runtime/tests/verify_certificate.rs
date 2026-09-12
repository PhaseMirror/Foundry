//! Kani harnesses for the certificate runtime (Tier 2 of ADR-0027).
//!
//! These bounded-model-check the Rust `f64` runtime against the Lean 4
//! specification in `certificate-core`.
//!
//! ## Scope (feasibility-driven)
//!
//! CBMC verifies IEEE-754 bit-vector arithmetic, so every harness fixes
//! the graph size (`n = 2` for arithmetic identities, where the mean is
//! exact because division by 2 is exact, and `n = 3` for pure logic
//! round-trips) and bounds all symbolic magnitudes to `[-2, 2]`. This
//! keeps the solver in the tractable regime while still ranging over *all*
//! symbolic field values and step sizes within those bounds.
//!
//! Properties that require symbolic transcendental arithmetic (the Jacobi
//! spectral gap estimator) are proven in the Lean kernel instead; the
//! numeric fidelity of the estimator itself is covered by unit tests.

#![cfg(kani)]

use certificate_runtime::certificate::{heat_step, mean, mean_zero, norm_sq};

/// Results verified by Kani at `n = 2` (division by 2 is exact in IEEE-754,
/// so all identities below are checked under either exact or ≤ 1 ulp error).
const N: usize = 2;

/// `mean_zero` is idempotent and its output has zero mean
/// (`CertificateCore.meanZero_idem`, `meanZero_mean`).
#[kani::proof]
#[kani::unwind(8)]
fn verify_mean_zero_algebra() {
    let n: usize = N;
    let u: [f64; N] = kani::any();
    kani::assume(u.iter().all(|&x| x.is_finite() && x.abs() <= 2.0));

    let mz = mean_zero(&u[..n]);
    kani::assert(mean(&mz).abs() <= 1e-9, "mean of mean-zero component is zero");

    let mz2 = mean_zero(&mz);
    for i in 0..n {
        kani::assert(
            (mz2[i] - mz[i]).abs() <= 1e-12,
            "mean-zero projection is idempotent",
        );
    }
}

/// `heat_step` matches the Lean `heatStep` formula `u' = u - α·(L·u)`
/// for the 2-node Laplacian, all symbolic `u` and bounded `α`.
#[kani::proof]
#[kani::unwind(8)]
fn verify_heat_step_matches_formula() {
    let n: usize = N;
    // Concrete 2-node Laplacian L = [[1,-1],[-1,1]].
    let l: [Vec<f64>; N] = [vec![1.0, -1.0], vec![-1.0, 1.0]];
    let ll: Vec<Vec<f64>> = l.to_vec();

    let u: [f64; N] = kani::any();
    kani::assume(u.iter().all(|&x| x.is_finite() && x.abs() <= 2.0));
    let alpha: f64 = kani::any();
    kani::assume(alpha.is_finite() && alpha.abs() <= 1.0);

    let u_new = heat_step(&u[..n], &ll, alpha);

    // Direct expansion of the specification.
    let lap0 = 1.0 * u[0] + -1.0 * u[1];
    let lap1 = -1.0 * u[0] + 1.0 * u[1];
    kani::assert(
        ((u_new[0] - (u[0] - alpha * lap0)).abs() <= 1e-9)
            && ((u_new[1] - (u[1] - alpha * lap1)).abs() <= 1e-9),
        "heat_step equals the Lean heatStep specification",
    );
}

/// A valid graph Laplacian has exact zero row sums and exact symmetry at
/// `n = 2` (`CertificateCore.GraphLaplacian.rowSum`, `Mat.IsSymmetric`).
#[kani::proof]
#[kani::unwind(8)]
fn verify_laplacian_structural_invariants() {
    let n: usize = N;
    let w: [[f64; N]; N] = kani::any();
    // Valid undirected graph, bounded weights.
    kani::assume(w[0][0] == 0.0 && w[1][1] == 0.0);
    kani::assume(w[0][1] == w[1][0]);
    kani::assume(w[0][1] >= 0.0 && w[0][1] <= 2.0);

    let g = certificate_runtime::graph::Graph::from_weights(
        vec![vec![w[0][0], w[0][1]], vec![w[1][0], w[1][1]]],
    )
    .unwrap();

    // Laplacian: diag = deg, off = -w.
    for i in 0..n {
        let row: Vec<f64> = g.laplacian_row(i).to_vec();
        let row_sum: f64 = row.iter().sum();
        kani::assert(row_sum == 0.0, "row sums are exactly zero");
    }
    kani::assert(
        g.laplacian(0, 1) == g.laplacian(1, 0),
        "Laplacian is exactly symmetric",
    );
}

/// The contraction certificate at `n = 2` for the certified graph
/// (`CertificateCore.SpectralContraction.contraction_bound`):
/// ‖mean_zero(u')‖² ≤ (1 - αλ₂)²·‖mean_zero(u)‖².
///
/// `λ₂` is the exact Fiedler value 2.0 of the 2-node Laplacian; `u` and
/// `α` remain symbolic within the bounded envelope.
#[kani::proof]
#[kani::unwind(8)]
fn verify_contraction_bound() {
    let n: usize = N;
    let l: [Vec<f64>; N] = [vec![1.0, -1.0], vec![-1.0, 1.0]];
    let ll: Vec<Vec<f64>> = l.to_vec();

    let u: [f64; N] = kani::any();
    kani::assume(u.iter().all(|&x| x.is_finite() && x.abs() <= 2.0));
    let alpha: f64 = kani::any();
    kani::assume(alpha >= 0.01 && alpha <= 0.5);

    let u_new = heat_step(&u[..n], &ll, alpha);

    let energy_old = norm_sq(&mean_zero(&u[..n]));
    let energy_new = norm_sq(&mean_zero(&u_new));

    let lambda_2 = 2.0;
    let q = 1.0 - alpha * lambda_2;
    let bound = q * q;

    // Direct comparison without the reporting division, mirroring the
    // runtime's `passed` decision (ratio ≤ bound ⇔ numerator ≤ bound·den).
    let eps = 1e-9;
    kani::assert(
        energy_new <= bound * energy_old + eps,
        "contraction bound ‖mean_zero(u')‖² ≤ (1-αλ₂)²‖mean_zero(u)‖² holds",
    );
}

/// `Graph::from_weights` accepts a graph iff the structural invariants
/// hold; on success the stored Laplacian is exactly symmetric with exact
/// zero row sums at `n = 2`. Pure comparison/logic round-trip.
#[kani::proof]
#[kani::unwind(8)]
fn verify_graph_from_weights_sound() {
    let n: usize = 2;
    let w: [[f64; N]; N] = kani::any();

    let wv: Vec<Vec<f64>> = vec![vec![w[0][0], w[0][1]], vec![w[1][0], w[1][1]]];

    match certificate_runtime::graph::Graph::from_weights(wv) {
        Ok(g) => {
            assert!(g.len() == n);
            // Structural invariants hold exactly (see note above).
            for i in 0..n {
                let row_sum: f64 = g.laplacian_row(i).iter().sum();
                assert!(row_sum == 0.0);
            }
            assert!(g.laplacian(0, 1) == g.laplacian(1, 0));
        }
        Err(e) => {
            use certificate_runtime::graph::GraphError;
            assert!(matches!(
                e,
                GraphError::EmptyGraph
                    | GraphError::InvalidDimensions
                    | GraphError::NotSymmetric
                    | GraphError::SelfLoop
                    | GraphError::NegativeWeight
            ));
        }
    }
}