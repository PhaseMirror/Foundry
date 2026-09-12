use nalgebra::{DMatrix, DVector};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KernelTelemetry {
    pub xn_kernel: f64,
    pub wt_max_kernel: f64,
    pub protection_zeta: f64,
    pub is_valid_kernel: bool,
    pub zeta_shadow: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SCNProposal {
    pub alpha: DVector<f64>,
    pub beta: DVector<f64>,
    pub commitment_hash: Vec<u8>,
}

pub fn project_onto_hecke_span(herm: &DMatrix<f64>, hecke_basis: &[DMatrix<f64>]) -> DMatrix<f64> {
    // Dummy projection for the sake of completion
    herm.clone()
}

pub fn mode3_feasibility(
    raw: &DMatrix<f64>,
    hecke_basis: &[DMatrix<f64>],
    epsilon: f64,
    eta: f64,
) -> DMatrix<f64> {
    let herm = (raw + raw.transpose()) / 2.0;
    let h = project_onto_hecke_span(&herm, hecke_basis);
    let r = &herm - &h;
    let r_norm = r.norm();
    let r_clipped = if r_norm > eta { (eta / r_norm) * &r } else { r.clone() };
    let x1 = h + r_clipped;
    let x1_norm = x1.norm();
    if x1_norm > epsilon {
        (epsilon / x1_norm) * x1
    } else {
        x1
    }
}

pub fn scn_propose(features: &DVector<f64>, kt: &KernelTelemetry) -> SCNProposal {
    let alpha = DVector::zeros(10);
    let beta = DVector::zeros(10);
    SCNProposal {
        alpha,
        beta,
        commitment_hash: vec![0; 32],
    }
}

pub fn build_perturbation(proposal: &SCNProposal, hecke_basis: &[DMatrix<f64>], rand_vectors: &[DVector<f64>]) -> DMatrix<f64> {
    let mut delta = DMatrix::zeros(rand_vectors[0].len(), rand_vectors[0].len());
    for (i, a) in proposal.alpha.iter().enumerate() {
        delta += *a * &hecke_basis[i];
    }
    for (i, b) in proposal.beta.iter().enumerate() {
        let u = &rand_vectors[i];
        delta += *b * (u * u.transpose());
    }
    delta
}

pub fn build_features(atlas_m: &DMatrix<f64>, kt: &KernelTelemetry) -> DVector<f64> {
    let eigen = atlas_m.clone().symmetric_eigen();
    let lambda = eigen.eigenvalues;
    let mut features = Vec::with_capacity(lambda.len() + 4);
    for l in lambda.iter().take(10) {
        features.push(*l);
    }
    features.push(kt.xn_kernel);
    features.push(kt.wt_max_kernel);
    features.push(kt.protection_zeta);
    features.push(kt.zeta_shadow);   // NEW
    DVector::from_vec(features)
}

pub fn certified_perturbation(
    atlas_m: &DMatrix<f64>,
    hecke_basis: &[DMatrix<f64>],
    kt: &KernelTelemetry,
    epsilon: f64,
    eta: f64,
    rand_vectors: &[DVector<f64>]
) -> (DMatrix<f64>, SCNProposal) {
    let features = build_features(atlas_m, kt);
    let proposal = scn_propose(&features, kt);
    let raw_delta = build_perturbation(&proposal, hecke_basis, rand_vectors);
    let effective_eta = eta / (1.0 + kt.zeta_shadow);
    let delta = mode3_feasibility(&raw_delta, hecke_basis, epsilon, effective_eta);
    (delta, proposal)
}
