use nalgebra::{DMatrix, DVector};
use num_complex::Complex64;
use serde::{Deserialize, Serialize};

pub fn commutator(a: &DMatrix<Complex64>, b: &DMatrix<Complex64>) -> DMatrix<Complex64> {
    a * b - b * a
}

pub fn dissipator(l: &DMatrix<Complex64>, rho: &DMatrix<Complex64>) -> DMatrix<Complex64> {
    let l_dag = l.adjoint();
    let term1 = l * rho * &l_dag;
    let term2 = (&l_dag * l * rho + rho * &l_dag * l) * Complex64::new(0.5, 0.0);
    term1 - term2
}

pub fn lindblad_rhs(rho: &DMatrix<Complex64>, h: &DMatrix<Complex64>, ls: &[DMatrix<Complex64>]) -> DMatrix<Complex64> {
    let mut out = commutator(h, rho) * (-Complex64::i());
    for l in ls {
        out += dissipator(l, rho);
    }
    out
}

pub fn euler_step(rho: &DMatrix<Complex64>, h: &DMatrix<Complex64>, ls: &[DMatrix<Complex64>], dt: f64) -> DMatrix<Complex64> {
    let mut rho_next = rho + lindblad_rhs(rho, h, ls) * Complex64::new(dt, 0.0);
    
    // Hermitize
    rho_next = (&rho_next + rho_next.adjoint()) * Complex64::new(0.5, 0.0);
    
    // Trace preservation
    let tr = rho_next.trace();
    if tr.norm() > 1e-12 {
        rho_next /= tr;
    }
    
    rho_next
}

pub fn rk4_step<F>(rho: &DMatrix<Complex64>, t: f64, h_func: F, ls: &[DMatrix<Complex64>], dt: f64) -> DMatrix<Complex64> 
where F: Fn(f64) -> DMatrix<Complex64>
{
    let dt_c = Complex64::new(dt, 0.0);
    let dt_half = dt_c * 0.5;
    let two = Complex64::new(2.0, 0.0);

    let k1 = lindblad_rhs(rho, &h_func(t), ls);
    let k2 = lindblad_rhs(&(rho + &k1 * dt_half), &h_func(t + 0.5 * dt), ls);
    let k3 = lindblad_rhs(&(rho + &k2 * dt_half), &h_func(t + 0.5 * dt), ls);
    let k4 = lindblad_rhs(&(rho + &k3 * dt_c), &h_func(t + dt), ls);

    let mut rho_next = rho + (k1 + k2 * two + k3 * two + k4) * (dt_c / 6.0);

    // Hermitize
    rho_next = (&rho_next + rho_next.adjoint()) * Complex64::new(0.5, 0.0);

    // Trace preservation
    let tr = rho_next.trace();
    if tr.norm() > 1e-12 {
        rho_next /= tr;
    }

    rho_next
}

pub fn get_h_zeta(
    m: &DMatrix<Complex64>,
    t: f64,
    gammas: &[f64],
    amplitudes: Option<&[f64]>,
    alpha: f64,
    phases: Option<&[f64]>,
    j_matrix: Option<&DMatrix<f64>>,
    ladder_ops: Option<(&[DMatrix<Complex64>], &[DMatrix<Complex64>])>,
) -> DMatrix<Complex64> {
    let dim = m.nrows();
    let default_amps = vec![1.0; gammas.len()];
    let default_phs = vec![0.0; gammas.len()];
    let amps = amplitudes.unwrap_or(&default_amps);
    let phs = phases.unwrap_or(&default_phs);
    
    let mut drive = DMatrix::from_element(dim, dim, Complex64::new(0.0, 0.0));
    for ((&a, &g), &ph) in amps.iter().zip(gammas.iter()).zip(phs.iter()) {
        drive += m * Complex64::new(a * (g * t + ph).cos(), 0.0);
    }
    
    let mut h = m * Complex64::new(alpha, 0.0) + drive;
    
    // EchoBraid coupling
    if let (Some(j), Some((a_dag_list, a_list))) = (j_matrix, ladder_ops) {
        let n_primes = a_list.len();
        for i in 0..n_primes {
            for j_idx in (i + 1)..n_primes {
                if j[(i, j_idx)] != 0.0 {
                    let h_int = (&a_dag_list[i] * &a_list[j_idx] + &a_dag_list[j_idx] * &a_list[i]) * Complex64::new(j[(i, j_idx)], 0.0);
                    h += h_int;
                }
            }
        }
    }
    
    h
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZrsdCertificate {
    pub is_admissible: bool,
    pub c_total: f64,
    pub margin: f64,
    pub base_contraction: f64,
    pub resonance_norm: f64,
    pub lambda_m: f64,
}

pub fn evaluate_zrsd_step(
    psi: &DVector<Complex64>,
    g_base: &DMatrix<Complex64>,
    lambda_m: f64,
    r_zeta: &DMatrix<Complex64>,
    epsilon: f64,
) -> (DVector<Complex64>, ZrsdCertificate) {
    // 1. Base Contraction Constant
    // Note: We use spectral norm (L2) approximation or Frobenius for now.
    // For diagonal g_base, it's the max absolute value.
    let l_g = g_base.norm(); // Placeholder for op_norm
    let c_upper = 1.0 - lambda_m * (1.0 - l_g);
    let c_lower = 1.0 - lambda_m * (1.0 + l_g);
    let c_base = c_upper.abs().max(c_lower.abs());
    
    // 2. Resonance Perturbation Norm
    let l_r = r_zeta.norm();
    let delta = epsilon * l_r;
    
    // 3. Total Stability Bound
    let c_total = c_base + lambda_m * delta;
    let margin = 1.0 - c_total;
    let is_admissible = c_total < 1.0;
    
    let cert = ZrsdCertificate {
        is_admissible,
        c_total,
        margin,
        base_contraction: c_base,
        resonance_norm: delta,
        lambda_m,
    };
    
    if !is_admissible {
        return (psi.clone(), cert);
    }
    
    // 4. Perform Update
    // psi_next = (1 - lm) * psi + lm * (G_base * psi + epsilon * R_zeta * psi)
    let term1 = psi * Complex64::new(1.0 - lambda_m, 0.0);
    let term2 = (g_base * psi + r_zeta * psi * Complex64::new(epsilon, 0.0)) * Complex64::new(lambda_m, 0.0);
    let mut psi_next = term1 + term2;
    
    // Re-normalize
    let norm = psi_next.norm();
    if norm > 1e-12 {
        psi_next /= Complex64::new(norm, 0.0);
    }
    
    (psi_next, cert)
}

