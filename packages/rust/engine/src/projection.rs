use nalgebra::{DMatrix, DVector};

pub fn project_parameters_soft(
    xi: &DMatrix<f64>,
    lam: &DMatrix<f64>,
    op_norm_t: f64,
    target: f64,
) -> (DMatrix<f64>, DMatrix<f64>) {
    let n_xi = xi.clone().svd(false, false).singular_values[0];
    let n_lam = lam.clone().svd(false, false).singular_values[0];
    let budget = n_xi + n_lam * op_norm_t;

    if budget <= target || budget == 0.0 {
        return (xi.clone(), lam.clone());
    }

    let scale = target / budget;
    (xi * scale, lam * scale)
}

pub fn project_parameters_weighted_l1(
    values: &DVector<f64>,
    weights: &DVector<f64>,
    budget: f64,
    tol: f64,
) -> (DVector<f64>, f64) {
    assert_eq!(values.len(), weights.len());
    if budget < 0.0 {
        panic!("budget must be non-negative");
    }

    let abs_values = values.map(|x| x.abs());
    let weighted_norm: f64 = weights.component_mul(&abs_values).sum();

    if weighted_norm <= budget + tol {
        return (values.clone(), 0.0);
    }

    // Filter weights > 0
    let mut participants: Vec<(f64, f64)> = Vec::new();
    for i in 0..weights.len() {
        if weights[i] > 0.0 {
            participants.push((abs_values[i], weights[i]));
        }
    }

    if participants.is_empty() {
        return (values.clone(), 0.0);
    }

    // Sort by ratio abs_val / weight
    participants.sort_by(|a, b| (b.0 / b.1).partial_cmp(&(a.0 / a.1)).unwrap());

    let mut prefix_w_abs = 0.0;
    let mut prefix_w_sq = 0.0;
    let mut tau = 0.0;

    for (abs_val, w) in &participants {
        prefix_w_abs += w * abs_val;
        prefix_w_sq += w * w;
        tau = (prefix_w_abs - budget) / prefix_w_sq;

        if tau <= abs_val / w + tol {
            // Check if it's above the next ratio if any
            // For simplicity, we can just break here and refine
            break;
        }
    }

    tau = tau.max(0.0);

    // Binary search refinement
    let mut lo = 0.0;
    let mut hi = participants[0].0 / participants[0].1;
    for _ in 0..50 {
        let mid = 0.5 * (lo + hi);
        let mut current_norm = 0.0;
        for (abs_val, w) in &participants {
            current_norm += w * (abs_val - mid * w).max(0.0);
        }
        if (current_norm - budget).abs() < tol {
            tau = mid;
            break;
        }
        if current_norm > budget {
            lo = mid;
        } else {
            hi = mid;
            tau = mid;
        }
    }

    let mut result = values.clone();
    for i in 0..weights.len() {
        if weights[i] > 0.0 {
            let abs_val = values[i].abs();
            let projected = (abs_val - tau * weights[i]).max(0.0);
            result[i] = values[i].signum() * projected;
        }
    }

    (result, tau)
}
