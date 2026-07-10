use crate::math::projection::project_parameters_soft;
use crate::math::types::{Status, StepInfo};
use nalgebra::{DMatrix, DVector};
use crate::math::types::{PrimeMask, ResonanceWord};

pub type Operator = fn(&DVector<f64>) -> DVector<f64>;
pub type Projector = fn(&DVector<f64>) -> DVector<f64>;

fn operator_norm(m: &DMatrix<f64>) -> f64 {
    if m.is_empty() {
        return 0.0;
    }
    m.clone().svd(false, false).singular_values[0]
}

pub fn step(
    x_t: &DVector<f64>,
    xi_t: &DMatrix<f64>,
    lam_t: &DMatrix<f64>,
    t_op: Operator,
    g_t: &DVector<f64>,
    p_op: Projector,
    epsilon: f64,
    op_norm_t: f64,
    t: usize,
) -> (DVector<f64>, StepInfo) {
    let mut n_xi = operator_norm(xi_t);
    let mut n_lam = operator_norm(lam_t);
    let mut q_t = n_xi + n_lam * op_norm_t;
    let target = 1.0 - epsilon;
    let mut projected = false;

    let (final_xi, final_lam) = if q_t > target {
        projected = true;
        let (xi_p, lam_p) = project_parameters_soft(xi_t, lam_t, op_norm_t, target);
        n_xi = operator_norm(&xi_p);
        n_lam = operator_norm(&lam_p);
        q_t = n_xi + n_lam * op_norm_t;
        (xi_p, lam_p)
    } else {
        (xi_t.clone(), lam_t.clone())
    };

    let candidate = &final_xi * x_t + &final_lam * t_op(x_t) + g_t;
    let x_next = p_op(&candidate);
    let residual = (x_next.clone() - x_t).norm();

    // Generate resonance word and prime mask
    let resonance_word = if t < 64 {
        Some(ResonanceWord::pack((t % 96) as u8, (residual.to_bits() >> 7) & ((1 << 57) - 1)))
    } else {
        None
    };

    let prime_mask = if t < 64 {
        Some(PrimeMask(1 << t))
    } else {
        None
    };

    let info = StepInfo {
        step: t,
        q: q_t,
        epsilon,
        n_xi,
        n_lam,
        projected,
        residual,
        note: None,
        resonance_word,
        prime_mask,
    };

    (x_next, info)
}

pub fn run(
    x0: &DVector<f64>,
    xi_seq: &[DMatrix<f64>],
    lam_seq: &[DMatrix<f64>],
    g_seq: &[DVector<f64>],
    t_op: Operator,
    p_op: Projector,
    epsilon: f64,
    op_norm_t: f64,
    tol: f64,
    max_steps: Option<usize>,
) -> (DVector<f64>, Vec<DVector<f64>>, Vec<StepInfo>, Status) {
    let mut x = x0.clone();
    let mut history = vec![x.clone()];
    let mut infos = Vec::new();
    let mut converged = false;
    let mut safe = true;
    let target = 1.0 - epsilon;

    let mut t_max = xi_seq.len().min(lam_seq.len()).min(g_seq.len());
    if let Some(ms) = max_steps {
        t_max = t_max.min(ms);
    }

    for t in 0..t_max {
        let (x_next, info) = step(
            &x,
            &xi_seq[t],
            &lam_seq[t],
            t_op,
            &g_seq[t],
            p_op,
            epsilon,
            op_norm_t,
            t,
        );
        safe = safe && info.q <= target + 1e-12;
        let res = info.residual;
        infos.push(info);
        history.push(x_next.clone());
        x = x_next;

        if res < tol {
            converged = true;
            break;
        }
    }

    let residual = if let Some(last) = infos.last() {
        last.residual
    } else {
        f64::INFINITY
    };

    let status = Status {
        converged,
        safe,
        steps: infos.len(),
        residual,
        epsilon,
        note: None,
    };

    (x, history, infos, status)
}

pub fn fixed_point_estimate(
    history: &[DVector<f64>],
    window: usize,
) -> (DVector<f64>, f64) {
    if history.is_empty() {
        panic!("history cannot be empty");
    }

    let win = window.max(1).min(history.len());
    let tail = &history[history.len() - win..];

    let dim = tail[0].len();
    let mut estimate = DVector::zeros(dim);
    for v in tail {
        estimate += v;
    }
    estimate /= win as f64;

    let mut tail_bound: f64 = 0.0;
    for v in tail {
        let dev = (v - &estimate).norm();
        tail_bound = tail_bound.max(dev);
    }

    (estimate, tail_bound)
}
