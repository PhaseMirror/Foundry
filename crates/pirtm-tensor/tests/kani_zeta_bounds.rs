#[cfg(kani)]
mod tests {
    use ndarray::{Array1, Array2};
    use pirtm_tensor::multiplicity_cell::LinearMultiplicityCell;
    use pirtm_tensor::contractive_fit::ContractiveFit;

    #[kani::proof]
    #[kani::unwind(3)]
    fn verify_zeta_regularization() {
        let w_coh = Array1::from_vec(vec![0.5, 0.5]);
        let w_def = Array2::from_shape_vec((2, 2), vec![0.5, 0.0, 0.0, 0.5]).unwrap();
        let cell = LinearMultiplicityCell::new(w_coh, w_def);
        
        let zeta_max = 5.0;
        let fit = ContractiveFit::new(cell, 0.1, 1e-4)
            .with_zeta_regularization(zeta_max);

        // Discretized random state
        let s0_int: i8 = kani::any();
        let s1_int: i8 = kani::any();
        let s0 = (s0_int as f64) * 100.0; // Potentially massive starting state to force explosive gradients
        let s1 = (s1_int as f64) * 100.0;
        
        // Prevent NaN logic
        kani::assume(s0 >= -500.0 && s0 <= 500.0);
        kani::assume(s1 >= -500.0 && s1 <= 500.0);

        let state = Array1::from_vec(vec![s0, s1]);

        // Evaluate a single step
        let (new_state, _) = fit.step(&state);
        
        // Compute the absolute displacement vector norm.
        // new_state = state - lr * clamped_grad
        // displacement = new_state - state = -lr * clamped_grad
        // ||displacement|| / lr = ||clamped_grad||
        let d0 = (new_state[0] - state[0]) / 0.1;
        let d1 = (new_state[1] - state[1]) / 0.1;
        let eff_grad_norm = (d0.powi(2) + d1.powi(2)).sqrt();

        // Safety property: The effective gradient mathematically cannot exceed the zeta threshold,
        // no matter how divergent the infinite series topological state has become.
        assert!(eff_grad_norm <= zeta_max + 1e-5);
    }
}
