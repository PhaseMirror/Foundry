use crate::types::WeightSchedule;
use nalgebra::DMatrix;

pub enum WeightProfile {
    Uniform,
    LogDecay,
    Harmonic,
    Custom(fn(usize, u64) -> f64),
}

fn resolve_alphas(primes: &[u64], profile: WeightProfile) -> Vec<f64> {
    let count = primes.len();
    if count == 0 {
        return Vec::new();
    }

    match profile {
        WeightProfile::Uniform => vec![0.5; count],
        WeightProfile::Harmonic => (1..=count)
            .map(|i| (1.0 / i as f64).min(1.0).max(0.0))
            .collect(),
        WeightProfile::LogDecay => {
            let raw: Vec<f64> = primes
                .iter()
                .map(|&p| 1.0 / (p as f64).max(2.0).ln().max(1e-12))
                .collect();
            let min = raw.iter().fold(f64::INFINITY, |a, &b| a.min(b));
            let max = raw.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
            if max - min < 1e-12 {
                vec![0.5; count]
            } else {
                raw.iter()
                    .map(|&r| ((r - min) / (max - min)).min(1.0).max(0.0))
                    .collect()
            }
        }
        WeightProfile::Custom(f) => primes
            .iter()
            .enumerate()
            .map(|(i, &p)| f(i + 1, p).min(1.0).max(0.0))
            .collect(),
    }
}

pub fn synthesize_weights(
    primes: &[u64],
    dim: usize,
    op_norm_t: f64,
    q_star: f64,
    profile: WeightProfile,
    epsilon: f64,
    basis: Option<&DMatrix<f64>>,
) -> Result<WeightSchedule, String> {
    if dim == 0 {
        return Err("dim must be positive".to_string());
    }
    if op_norm_t <= 0.0 {
        return Err("op_norm_t must be positive".to_string());
    }

    let q_target = q_star.min(1.0 - epsilon).max(0.0);
    let alphas = resolve_alphas(primes, profile);
    let q_targets = vec![q_target; primes.len()];

    let base = match basis {
        Some(b) => {
            if b.nrows() != dim || b.ncols() != dim {
                return Err("basis must have shape (dim, dim)".to_string());
            }
            b.clone()
        }
        None => DMatrix::identity(dim, dim),
    };

    let denom = 1.0 + op_norm_t;
    let mut xi_seq = Vec::new();
    let mut lam_seq = Vec::new();

    for alpha in alphas {
        let xi_scale = (alpha * q_target) / denom;
        let lam_scale = ((1.0 - alpha) * q_target) / (denom * op_norm_t);
        xi_seq.push(&base * xi_scale);
        lam_seq.push(&base * lam_scale);
    }

    Ok(WeightSchedule {
        xi_seq,
        lam_seq,
        q_targets,
        primes_used: primes.to_vec(),
    })
}

pub fn validate_schedule(schedule: &WeightSchedule, op_norm_t: f64, tol: f64) -> (bool, f64) {
    let mut max_q: f64 = 0.0;
    let mut valid = true;

    for i in 0..schedule.xi_seq.len() {
        let xi = &schedule.xi_seq[i];
        let lam = &schedule.lam_seq[i];
        let target = schedule.q_targets[i];

        let n_xi = xi.clone().svd(false, false).singular_values[0];
        let n_lam = lam.clone().svd(false, false).singular_values[0];
        let q_value = n_xi + n_lam * op_norm_t;

        max_q = max_q.max(q_value);
        if q_value > target + tol {
            valid = false;
        }
    }
    (valid, max_q)
}
