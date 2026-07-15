//! ADR-100 — ACE-SCN certified spectral-perturbation driver (Mode 3 / F₃).
//!
//! This module is the production-grade Rust counterpart of the Lean formalization
//! in `docs/adr/ADR-099_lean_20260715_54d4e4.md`. It implements the continuous
//! mathematics that the Lean side proves:
//!
//! * `gauge_fix`          — kernel telemetry → Arakelov normalization.
//! * `mode3_feasibility`  — the F₃ map (Hermitianize → Hecke-project → residual
//!                          clip to `η` → global clip to `ε`).
//! * `certified_perturbation` — full driver: features → SCN proposal → raw
//!                          perturbation → F₃ feasibility.
//!
//! A 2×2 array-based reference (`mode3_feasibility_2x2`) is provided for Kani
//! verification, mirroring the existing `mode1_feasibility_map` strategy. The
//! deep negative-definiteness preservation theorem itself is proven in Lean
//! (`Mode3.atlasM_Mode3_wrapper`); see that module for the formal guarantee.

use nalgebra::{DMatrix, DVector};
use serde::de::Deserializer;
use serde::ser::SerializeStruct;
use serde::{Deserialize, Serialize, Serializer};
use sha3::{Digest, Sha3_256};
use std::sync::OnceLock;

/// Kernel telemetry contract (mirrors the Lean `KernelTelemetry` structure).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct KernelTelemetry {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
}

/// Arakelov normalization parameters produced by `gauge_fix`.
#[derive(Debug, Clone, PartialEq)]
pub struct ArakelovParams {
    pub gamma: f64,
    pub scale: f64,
    pub is_normalized: bool,
}

/// SCN proposal: coefficients for the Hecke-span and random-projection terms,
/// plus a commitment hash binding the proposal to its inputs.
#[derive(Debug, Clone)]
pub struct SCNProposal {
    pub alpha: DVector<f64>, // Hecke-span coefficients
    pub beta: DVector<f64>,  // random-projection coefficients
    pub commitment_hash: Vec<u8>, // SHA3-256 commitment (Poseidon2 placeholder)
}

impl Serialize for SCNProposal {
    fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
        let mut st = s.serialize_struct("SCNProposal", 3)?;
        st.serialize_field("alpha", &self.alpha.as_slice().to_vec())?;
        st.serialize_field("beta", &self.beta.as_slice().to_vec())?;
        st.serialize_field("commitment_hash", &self.commitment_hash)?;
        st.end()
    }
}

impl<'de> Deserialize<'de> for SCNProposal {
    fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
        #[derive(Deserialize)]
        struct Helper {
            alpha: Vec<f64>,
            beta: Vec<f64>,
            commitment_hash: Vec<u8>,
        }
        let h = Helper::deserialize(d)?;
        Ok(SCNProposal {
            alpha: DVector::from_vec(h.alpha),
            beta: DVector::from_vec(h.beta),
            commitment_hash: h.commitment_hash,
        })
    }
}

/// Frobenius norm of a square matrix, defined as `sqrt(trace(Mᵀ M))`.
/// Using an explicit definition avoids any ambiguity about `Matrix::norm`.
pub fn frobenius_norm(m: &DMatrix<f64>) -> f64 {
    (m.transpose() * m).trace().sqrt()
}

/// `gauge_fix`: map kernel telemetry to Arakelov normalization.
///
/// Mirrors the Lean `Mode3.gaugeFix`. The `+ 1e-12` guards against division by
/// zero; `gamma = exp(-protection_zeta)` and `scale = 1/(xn + protection_zeta + ε)`.
pub fn gauge_fix(kt: &KernelTelemetry) -> ArakelovParams {
    ArakelovParams {
        gamma: (-kt.protection_zeta).exp(),
        scale: 1.0 / (kt.xn_kernel + kt.protection_zeta + 1e-12),
        is_normalized: true,
    }
}

/// Orthogonal (least-squares) projection of `target` onto the span of
/// `basis`, using the Frobenius inner product `⟨A, B⟩ = trace(Aᵀ B)`.
///
/// Solves the normal equations `G c = r` via SVD, where
/// `G_{ij} = ⟨basis_i, basis_j⟩` and `r_i = ⟨basis_i, target⟩`.
pub fn project_onto_hecke_span(target: &DMatrix<f64>, basis: &[DMatrix<f64>]) -> DMatrix<f64> {
    let k = basis.len();
    let (n, m) = (target.nrows(), target.ncols());
    if k == 0 {
        return DMatrix::zeros(n, m);
    }
    let frob = |a: &DMatrix<f64>, b: &DMatrix<f64>| (a.transpose() * b).trace();
    let mut g = DMatrix::<f64>::zeros(k, k);
    let mut rhs = DVector::<f64>::zeros(k);
    for i in 0..k {
        rhs[i] = frob(&basis[i], target);
        for j in 0..k {
            g[(i, j)] = frob(&basis[i], &basis[j]);
        }
    }
    let c = g
        .svd(true, true)
        .solve(&rhs, 1e-12)
        .unwrap_or_else(|_| DVector::zeros(k));
    let mut h = DMatrix::<f64>::zeros(n, m);
    for i in 0..k {
        h += basis[i].clone() * c[i];
    }
    h
}

/// Mode 3 (F₃) feasibility map.
///
/// 1. Hermitianize: `H = (X + Xᵀ) / 2`.
/// 2. Project onto the Hecke span: `h = Π_Hecke(H)`.
/// 3. Residual `r = H - h`, clipped to Frobenius norm ≤ `η`.
/// 4. `x1 = h + r'`, then clipped to Frobenius norm ≤ `ε`.
///
/// The Lean theorem `Mode3.atlasM_Mode3_wrapper` guarantees that when `η` is
/// smaller than the spectral margin on the diagonal complement, the resulting
/// matrix preserves the negative-definiteness of `H`.
pub fn mode3_feasibility(
    raw: &DMatrix<f64>,
    hecke_basis: &[DMatrix<f64>],
    epsilon: f64,
    eta: f64,
) -> DMatrix<f64> {
    // Hermitianize.
    let herm = raw.clone() * 0.5 + raw.transpose() * 0.5;
    // Project onto Hecke span (least squares).
    let h = project_onto_hecke_span(&herm, hecke_basis);
    let r = &herm - &h;
    let r_norm = frobenius_norm(&r);
    let r_clipped = if r_norm > eta { r * (eta / r_norm) } else { r };
    let x1 = &h + &r_clipped;
    let x1_norm = frobenius_norm(&x1);
    if x1_norm > epsilon {
        x1 * (epsilon / x1_norm)
    } else {
        x1
    }
}

/// SCN controller: produces a raw perturbation from features.
///
/// Placeholder neural-network inference. A real deployment trains a model that
/// maps kernel telemetry + eigenvalue summaries to Hecke-span / random
/// coefficients; here we return the zero proposal so the driver stays
/// deterministic and the perturbation is driven by caller-supplied proposals in
/// tests. The commitment hash binds alpha, beta, and telemetry.
pub fn scn_propose(features: &DVector<f64>, kernel_telemetry: &KernelTelemetry) -> SCNProposal {
    let n = features.len().max(10);
    let alpha = DVector::zeros(n);
    let beta = DVector::zeros(n);
    let commitment_hash = {
        let mut hasher = Sha3_256::new();
        for &x in features.iter() {
            hasher.update(x.to_le_bytes());
        }
        hasher.update(kernel_telemetry.xn_kernel.to_le_bytes());
        hasher.update(kernel_telemetry.wt_max_kernel.to_le_bytes());
        hasher.update(kernel_telemetry.protection_zeta.to_le_bytes());
        hasher.finalize().to_vec()
    };
    SCNProposal {
        alpha,
        beta,
        commitment_hash,
    }
}

/// Build the full perturbation matrix from a proposal:
/// `Δ = Σ_j α_j A_j + Σ_l β_l u_l u_lᵀ`.
pub fn build_perturbation(
    proposal: &SCNProposal,
    hecke_basis: &[DMatrix<f64>],
    rand_vectors: &[DVector<f64>],
) -> DMatrix<f64> {
    let dim = rand_vectors.first().map_or(0, |v| v.len());
    let mut delta = DMatrix::<f64>::zeros(dim, dim);
    for (i, a) in proposal.alpha.iter().enumerate().take(hecke_basis.len()) {
        delta += hecke_basis[i].clone() * *a;
    }
    for (i, b) in proposal.beta.iter().enumerate().take(rand_vectors.len()) {
        let u = &rand_vectors[i];
        delta += *b * (u * u.transpose());
    }
    delta
}

/// Global pool of deterministic random vectors, initialized lazily.
static RAND_VECTORS: OnceLock<Vec<DVector<f64>>> = OnceLock::new();

/// Deterministically initialize the random-vector pool of `count` vectors of
/// dimension `dim`. Idempotent.
pub fn init_rand_vectors(dim: usize, count: usize) {
    let _ = RAND_VECTORS.get_or_init(|| {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        (0..count)
            .map(|s| {
                let mut v = DVector::<f64>::zeros(dim);
                for i in 0..dim {
                    let mut hsh = DefaultHasher::new();
                    (s, i).hash(&mut hsh);
                    let bits = hsh.finish();
                    v[i] = ((bits % 1000) as f64 / 1000.0) * 2.0 - 1.0;
                }
                v
            })
            .collect()
    });
}

/// Access the global random-vector pool. Panics if `init_rand_vectors` has not
/// been called.
pub fn rand_vectors() -> &'static Vec<DVector<f64>> {
    RAND_VECTORS
        .get()
        .expect("rand_vectors not initialized; call init_rand_vectors first")
}

/// Build the feature vector `(λ_1..λ_10, xn_kernel, wt_max_kernel, protection_zeta)`
/// from `atlas_m` (assumed square; its symmetric part is eigendecomposed).
pub fn build_features(atlas_m: &DMatrix<f64>, kt: &KernelTelemetry) -> DVector<f64> {
    let eigen = atlas_m.clone().symmetric_eigen();
    let lambda = eigen.eigenvalues;
    let mut features = Vec::with_capacity(lambda.len().min(10) + 3);
    for &l in lambda.iter().take(10) {
        features.push(l);
    }
    features.push(kt.xn_kernel);
    features.push(kt.wt_max_kernel);
    features.push(kt.protection_zeta);
    DVector::from_vec(features)
}

/// Full driver: consume kernel telemetry, propose, apply feasibility, return the
/// certified perturbation and the proposal that produced it.
pub fn certified_perturbation(
    atlas_m: &DMatrix<f64>,
    hecke_basis: &[DMatrix<f64>],
    kernel_telemetry: &KernelTelemetry,
    epsilon: f64,
    eta: f64,
) -> (DMatrix<f64>, SCNProposal) {
    let dim = atlas_m.nrows();
    init_rand_vectors(dim, 10);
    let features = build_features(atlas_m, kernel_telemetry);
    let proposal = scn_propose(&features, kernel_telemetry);
    let raw_delta = build_perturbation(&proposal, hecke_basis, rand_vectors());
    let delta = mode3_feasibility(&raw_delta, hecke_basis, epsilon, eta);
    (delta, proposal)
}

/// 2×2 array reference of the F₃ map, used for Kani verification (mirrors the
/// existing `mode1_feasibility_map`). Projection is taken onto `span{I}` so the
/// residual `r` is the traceless (diagonal-complement) part.
pub fn mode3_feasibility_2x2(m: [[f64; 2]; 2], epsilon: f64, eta: f64) -> [[f64; 2]; 2] {
    // Hermitianize.
    let herm = [
        [(m[0][0] + m[0][0]) / 2.0, (m[0][1] + m[1][0]) / 2.0],
        [(m[1][0] + m[0][1]) / 2.0, (m[1][1] + m[1][1]) / 2.0],
    ];
    // Project onto span{I}: h = (tr/2) I.
    let s = (herm[0][0] + herm[1][1]) / 2.0;
    let h = [[s, 0.0], [0.0, s]];
    // Residual (traceless) + clip to eta.
    let r = [[herm[0][0] - s, herm[0][1]], [herm[1][0], herm[1][1] - s]];
    let r_norm = (r[0][0] * r[0][0] + r[0][1] * r[0][1] + r[1][0] * r[1][0] + r[1][1] * r[1][1]).sqrt();
    let scale_r = if r_norm > eta { eta / r_norm } else { 1.0 };
    let r_clipped = [[r[0][0] * scale_r, r[0][1] * scale_r], [r[1][0] * scale_r, r[1][1] * scale_r]];
    // x1 = h + r'.
    let x1 = [[h[0][0] + r_clipped[0][0], h[0][1] + r_clipped[0][1]], [h[1][0] + r_clipped[1][0], h[1][1] + r_clipped[1][1]]];
    let x1_norm = (x1[0][0] * x1[0][0] + x1[0][1] * x1[0][1] + x1[1][0] * x1[1][0] + x1[1][1] * x1[1][1]).sqrt();
    let scale_x = if x1_norm > epsilon { epsilon / x1_norm } else { 1.0 };
    [
        [x1[0][0] * scale_x, x1[0][1] * scale_x],
        [x1[1][0] * scale_x, x1[1][1] * scale_x],
    ]
}

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::DMatrix;

    /// Build a cyclic-shift basis of size `n` for the Hecke span.
    fn basis(n: usize) -> Vec<DMatrix<f64>> {
        (0..n)
            .map(|k| {
                let mut m = DMatrix::<f64>::zeros(n, n);
                for i in 0..n {
                    m[(i, (i + k) % n)] = 1.0;
                }
                m
            })
            .collect()
    }

    #[test]
    fn test_gauge_fix_parity_with_lean() {
        let kt = KernelTelemetry {
            xn_kernel: 1.0,
            wt_max_kernel: 0.5,
            protection_zeta: 0.25,
            is_valid_kernel: true,
        };
        let p = gauge_fix(&kt);
        assert!((p.gamma - (-0.25f64).exp()).abs() < 1e-12);
        assert!((p.scale - 1.0 / (1.0 + 0.25 + 1e-12)).abs() < 1e-12);
        assert!(p.is_normalized);
    }

    #[test]
    fn test_mode3_output_norm_bounded_by_epsilon() {
        let raw = DMatrix::<f64>::from_row_slice(
            4,
            4,
            &[
                0.3, 0.1, -0.2, 0.05, 0.1, 0.4, 0.0, 0.1, -0.2, 0.0, 0.5, -0.1, 0.05, 0.1, -0.1, 0.2,
            ],
        );
        let epsilon = 1.0;
        let eta = 0.5;
        let out = mode3_feasibility(&raw, &basis(4), epsilon, eta);
        assert!(
            frobenius_norm(&out) <= epsilon + 1e-9,
            "F3 output norm {} exceeds epsilon {}",
            frobenius_norm(&out),
            epsilon
        );
    }

    #[test]
    fn test_projection_recovers_basis_element() {
        let b = basis(3);
        let target = &b[1] * 2.3;
        let proj = project_onto_hecke_span(&target, &b);
        for i in 0..3 {
            for j in 0..3 {
                assert!(
                    (proj[(i, j)] - target[(i, j)]).abs() < 1e-6,
                    "projection mismatch at ({}, {})",
                    i,
                    j
                );
            }
        }
    }

    #[test]
    fn test_project_residual_is_traceless() {
        let raw = DMatrix::<f64>::from_row_slice(
            3,
            3,
            &[0.1, 0.5, -0.3, 0.2, -0.4, 0.6, 0.7, 0.1, -0.2],
        );
        let b = basis(3);
        let h = project_onto_hecke_span(&raw, &b);
        let r = &raw - &h;
        let inner = (r.transpose() * &h).trace();
        assert!(inner.abs() < 1e-6, "residual not orthogonal to span: {}", inner);
    }

    #[test]
    fn test_certified_perturbation_runs() {
        let atlas = DMatrix::<f64>::from_row_slice(
            4,
            4,
            &[
                2.0, 0.1, 0.0, 0.0, 0.1, 3.0, 0.2, 0.0, 0.0, 0.2, 1.5, 0.1, 0.0, 0.0, 0.1, 2.5,
            ],
        );
        let kt = KernelTelemetry {
            xn_kernel: 0.8,
            wt_max_kernel: 0.4,
            protection_zeta: 0.1,
            is_valid_kernel: true,
        };
        let (delta, proposal) = certified_perturbation(&atlas, &basis(4), &kt, 1.0, 0.5);
        assert_eq!(delta.nrows(), 4);
        assert_eq!(delta.ncols(), 4);
        assert_eq!(proposal.alpha.len(), 10);
        assert_eq!(proposal.commitment_hash.len(), 32);
    }

    #[test]
    fn test_2x2_reference_symmetric_and_bounded() {
        let m = [[0.7, -0.3], [0.2, 0.5]];
        let out = mode3_feasibility_2x2(m, 0.9, 0.3);
        let norm = (out[0][0].powi(2) + out[0][1].powi(2) + out[1][0].powi(2) + out[1][1].powi(2)).sqrt();
        assert!(norm <= 0.9 + 1e-9, "2x2 F3 norm {} exceeds epsilon", norm);
        assert!((out[0][1] - out[1][0]).abs() < 1e-9, "2x2 F3 output not symmetric");
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    /// Kani proof that the 2×2 F₃ reference is symmetric and Frobenius-bounded
    /// by `epsilon`, paralleling the existing `mode1` verification strategy.
    #[kani::proof]
    fn verify_mode3_feasibility_2x2() {
        let a00: f64 = kani::any();
        let a01: f64 = kani::any();
        let a10: f64 = kani::any();
        let a11: f64 = kani::any();

        kani::assume(a00.is_finite() && a01.is_finite() && a10.is_finite() && a11.is_finite());
        kani::assume([a00, a01, a10, a11].iter().all(|&x| x.abs() < 100.0));

        let epsilon: f64 = kani::any();
        kani::assume(epsilon > 0.1 && epsilon < 10.0);
        let eta: f64 = kani::any();
        kani::assume(eta > 0.0 && eta < 1.0);

        let matrix = [[a00, a01], [a10, a11]];
        let mapped = mode3_feasibility_2x2(matrix, epsilon, eta);

        // Output is symmetric (Hermitian in the real case).
        kani::assert(
            (mapped[0][1] - mapped[1][0]).abs() < 1e-9,
            "F3 map must preserve symmetry",
        );

        // Frobenius norm of the mapped matrix is bounded by epsilon.
        let mapped_norm = (mapped[0][0].powi(2)
            + mapped[0][1].powi(2)
            + mapped[1][0].powi(2)
            + mapped[1][1].powi(2))
        .sqrt();
        kani::assert(
            mapped_norm <= epsilon + 1e-6,
            "F3 map must bound Frobenius norm to epsilon",
        );
    }
}
