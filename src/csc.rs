use crate::types::{CSCBudget, CSCMargin, StepInfo};
use std::collections::HashMap;

pub fn solve_budget(
    op_norm_t: f64,
    epsilon: f64,
    alpha: f64,
) -> Result<CSCBudget, String> {
    if op_norm_t <= 0.0 {
        return Err("op_norm_t must be positive".to_string());
    }
    if !(0.0..1.0).contains(&epsilon) {
        return Err("epsilon must be in [0, 1)".to_string());
    }
    if !(0.0..=1.0).contains(&alpha) {
        return Err("alpha must be in [0, 1]".to_string());
    }

    let q_star = 1.0 - epsilon;
    let xi_norm_max = alpha * q_star;
    let lam_norm_max = ((1.0 - alpha) * q_star) / op_norm_t;
    Ok(CSCBudget {
        xi_norm_max,
        lam_norm_max,
        q_star,
        epsilon,
        op_norm_t,
        alpha,
    })
}

pub fn compute_margin(
    xi_norm: f64,
    lam_norm: f64,
    op_norm_t: f64,
    epsilon: f64,
) -> CSCMargin {
    let q_target = 1.0 - epsilon;
    let q_actual = xi_norm + lam_norm * op_norm_t;
    let margin = q_target - q_actual;

    let t_headroom = if lam_norm > 0.0 {
        (1.0 - epsilon - xi_norm) / lam_norm
    } else {
        f64::INFINITY
    };

    let epsilon_headroom = margin.max(0.0);
    CSCMargin {
        margin,
        q_actual,
        q_target,
        t_headroom,
        epsilon_headroom,
        safe: margin >= 0.0,
    }
}

pub fn multi_step_margin(infos: &[StepInfo]) -> Result<CSCMargin, String> {
    if infos.is_empty() {
        return Err("infos must not be empty".to_string());
    }

    let worst = infos.iter()
        .min_by(|a, b| {
            let margin_a = (1.0 - a.epsilon) - a.q;
            let margin_b = (1.0 - b.epsilon) - b.q;
            margin_a.partial_cmp(&margin_b).unwrap()
        })
        .unwrap();

    let q_target = 1.0 - worst.epsilon;
    let q_actual = worst.q;
    let margin = q_target - q_actual;

    let t_headroom = if worst.n_lam > 0.0 {
        (q_target - worst.n_xi) / worst.n_lam
    } else {
        f64::INFINITY
    };

    Ok(CSCMargin {
        margin,
        q_actual,
        q_target,
        t_headroom,
        epsilon_headroom: margin.max(0.0),
        safe: margin >= 0.0,
    })
}

pub fn sensitivity(
    xi_norm: f64,
    lam_norm: f64,
    epsilon: f64,
) -> HashMap<String, f64> {
    let q_target = 1.0 - epsilon;
    let t_max = if lam_norm > 0.0 {
        (q_target - xi_norm) / lam_norm
    } else {
        f64::INFINITY
    };

    let epsilon_min = (xi_norm + lam_norm - 1.0).max(0.0);
    let epsilon_headroom = if xi_norm == 0.0 && lam_norm == 0.0 {
        f64::INFINITY
    } else {
        (epsilon - epsilon_min).max(0.0)
    };

    let mut res = HashMap::new();
    res.insert("T_max".to_string(), t_max);
    res.insert("epsilon_min".to_string(), epsilon_min);
    res.insert("epsilon_headroom".to_string(), epsilon_headroom);
    res
}
