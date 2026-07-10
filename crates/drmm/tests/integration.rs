use drmm_rs::{DRMMOptimizer, OptimizerConfig};
use ndarray::ArrayD;

#[test]
fn test_optimizer_step() {
    let config = OptimizerConfig::default();
    let mut optimizer = DRMMOptimizer::new(config);
    
    let mut param = ArrayD::from_elem(vec![10], 1.0);
    let grad = ArrayD::from_elem(vec![10], 0.1);
    
    let initial_val = param[0];
    optimizer.step(0, &mut param.view_mut(), &grad.view());
    
    // Parameter should have changed
    assert_ne!(param[0], initial_val);
}
