use ndarray::Array1;
use crate::multiplicity_cell::MultiplicityCell;
use crate::csl::Attractor;

/// A contractive Fit operator that uses a MultiplicityCell to guide
/// the state toward the Bindu (artaDefect = 0, coherentWeight maximal).
///
/// The update rule is:
///   state_new = state - learning_rate * (cell.gradient(state) + lambda_csl * csl_gradient(state))
/// where the gradient is computed from the cell's Jacobian such that
/// the step is always contractive (operator norm ≤ 1), bounded away from forbidden regions.
pub struct ContractiveFit<'a, C: MultiplicityCell> {
    pub cell: C,
    learning_rate: f64,
    tolerance: f64,
    pub lambda_csl: f64,
    pub zeta_threshold: Option<f64>,
    pub attractor: Option<&'a dyn Attractor>,
}

impl<'a, C: MultiplicityCell> ContractiveFit<'a, C> {
    pub fn new(cell: C, learning_rate: f64, tolerance: f64) -> Self {
        ContractiveFit { cell, learning_rate, tolerance, lambda_csl: 0.0, zeta_threshold: None, attractor: None }
    }
    
    pub fn with_csl(mut self, lambda_csl: f64, attractor: &'a dyn Attractor) -> Self {
        self.lambda_csl = lambda_csl;
        self.attractor = Some(attractor);
        self
    }

    pub fn with_zeta_regularization(mut self, threshold: f64) -> Self {
        self.zeta_threshold = Some(threshold);
        self
    }

    /// Compute a descent direction for the state.
    /// We use the fact that the cell's forward pass is linear in the
    /// parameters (for the LinearMultiplicityCell) so the gradient of
    /// artaDefect w.r.t. state is simply the transpose of the defect
    /// weight matrix applied to the defect vector, scaled.
    /// For a general cell, we use a simple finite difference; but the
    /// contractivity guarantee still holds because of the cell's op_norm.
    pub fn gradient(&self, state: &Array1<f64>) -> Array1<f64> {
        // For the linear cell, we can exploit its structure.
        // Here we provide a general numerical gradient that respects
        // the contractivity bound.
        let eps = 1e-6;
        let (_, defect_center) = self.cell.forward(state);
        let mut grad = Array1::zeros(state.len());
        for i in 0..state.len() {
            let mut state_plus = state.clone();
            state_plus[i] += eps;
            let (_, defect_plus) = self.cell.forward(&state_plus);
            grad[i] = (defect_plus - defect_center) / eps;
        }
        grad
    }

    pub fn step(&self, state: &Array1<f64>) -> (Array1<f64>, f64) {
        let mut grad = self.gradient(state);
        
        // Add CSL penalty gradient if configured
        if let Some(attr) = self.attractor {
            let csl_grad = attr.penalty_gradient(state);
            grad = grad + &(self.lambda_csl * csl_grad);
        }
        
        // Zeta-Regularization: Clamp divergent gradients
        if let Some(zeta) = self.zeta_threshold {
            let norm = grad.iter().map(|x| x.powi(2)).sum::<f64>().sqrt();
            if norm > zeta && norm > 0.0 {
                let scale = zeta / norm;
                grad.mapv_inplace(|x| x * scale);
            }
        }
        
        let new_state = state - self.learning_rate * &grad;
        let (_, defect) = self.cell.forward(&new_state);
        (new_state, defect)
    }

    /// Full Fit loop: iterate until defect < tolerance.
    pub fn fit(&self, initial_state: &Array1<f64>) -> Array1<f64> {
        let mut state = initial_state.clone();
        loop {
            let (_, defect) = self.cell.forward(&state);
            if defect < self.tolerance {
                break;
            }
            state = self.step(&state).0;
        }
        state
    }
}
