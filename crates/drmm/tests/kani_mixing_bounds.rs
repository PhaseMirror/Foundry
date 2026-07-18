use ndarray::{Array1, ArrayViewMutD};
use drmm_rs::{DRMMOptimizer, OptimizerConfig};
use num_complex::Complex;

#[cfg(kani)]
#[kani::proof]
#[kani::unwind(3)]
fn verify_state_dependent_mixing() {
    // We constrain the input gradient size to 2 for SAT solver tractability.
    let g0_int: i8 = kani::any();
    let g1_int: i8 = kani::any();
    let g0 = (g0_int as f64) / 10.0;
    let g1 = (g1_int as f64) / 10.0;
    
    kani::assume(g0 >= -5.0 && g0 <= 5.0);
    kani::assume(g1 >= -5.0 && g1 <= 5.0);
    
    let grad = Array1::from_vec(vec![g0, g1]);
    let initial_grad_norm = (g0.powi(2) + g1.powi(2)).sqrt();
    
    let config = OptimizerConfig {
        lr: 0.1,
        alpha: 1.0,
        ema_beta: 0.99,
        momentum: 0.9,
        eps: 1e-8,
        lambda_min: 0.01,
        lambda_max: 10.0,
        weight_decay: 0.0,
        num_bins: 2,
    };
    
    let mut optimizer = DRMMOptimizer::new(config);
    
    // Create a dummy parameter vector
    let mut param = Array1::from_vec(vec![0.0, 0.0]);
    let mut param_view = param.view_mut().into_dyn();
    let grad_view = grad.view().into_dyn();
    
    // Execute a step of the optimizer with dynamic state-dependent rank-1 mixing
    optimizer.step(0, &mut param_view, &grad_view);
    
    // After step, the param contains the negative delta (since param started at 0)
    // delta = -param / lr. So param = -lr * delta. => delta = -param / lr
    // We want to check that the newly mapped spectral gradient (delta) is bounded.
    let delta0 = -param[0] / 0.1;
    let delta1 = -param[1] / 0.1;
    let new_grad_norm = (delta0.powi(2) + delta1.powi(2)).sqrt();
    
    // Safety property: The state-dependent mixed gradient strictly avoids unbounded inflation.
    // It should either contract (be smaller than max bound) or stay within a reasonable inflation envelope.
    // Given lambda_max = 10.0, the absolute maximum theoretical stretch is 10.0.
    assert!(new_grad_norm <= initial_grad_norm * 10.0 + 1e-6);
}
