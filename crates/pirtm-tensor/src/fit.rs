use ndarray::Array1;
use crate::multiplicity_cell::MultiplicityCell;

/// The Contractive Fit Operator for MA-VQE.
/// 
/// Replaces heuristic numerical gradients with the SAPGC (Scale-Adaptive 
/// Prime-Graded Feedback Controller) pipeline. It uses the exact, bounded 
/// outputs of the MultiplicityCell to compute a contractive update step.
pub struct ContractiveFit<C: MultiplicityCell> {
    cell: C,
    base_alpha: f64,     // Baseline contraction rate (must be < 1.0)
    defect_penalty: f64, // Scales the suppression when arta_defect > 0
}

pub trait TelemetryObserver {
    fn record_step(&mut self, iteration: usize, defect: f64, coherent: f64, state_norm: f64);
}

impl<C: MultiplicityCell> ContractiveFit<C> {
    /// Instantiate a new Contractive Fit operator.
    ///
    /// # Panics
    /// Panics if `base_alpha` is outside the (0, 1) interval, violating
    /// the strict contraction requirement of the global loop.
    pub fn new(cell: C, base_alpha: f64, defect_penalty: f64) -> Self {
        assert!(
            base_alpha > 0.0 && base_alpha < 1.0,
            "L0 Violation: base_alpha must be strictly in (0, 1) for guaranteed contraction."
        );
        ContractiveFit {
            cell,
            base_alpha,
            defect_penalty,
        }
    }

    /// Performs a single optimization step on the prime-indexed state.
    pub fn step(&self, state: &Array1<f64>) -> (Array1<f64>, f64, f64) {
        let (coherent, defect) = self.cell.forward(state);
        let effective_alpha = self.base_alpha / (1.0 + self.defect_penalty * defect);

        let mut next_state = state.clone();
        next_state.mapv_inplace(|x: f64| {
            let target = (x * coherent).tanh();
            (1.0 - effective_alpha) * x + effective_alpha * target
        });

        (next_state, coherent, defect)
    }

    /// Executes the full MA-VQE convergence loop.
    /// Returns the terminal state and a boolean indicating if it reached the target tolerance.
    pub fn optimize(
        &self, 
        initial_state: Array1<f64>, 
        max_iter: usize, 
        defect_tol: f64,
        mut observer: Option<&mut dyn TelemetryObserver>
    ) -> (Array1<f64>, bool) {
        let mut current_state = initial_state;
        
        for i in 0..max_iter {
            let (next_state, coherent, defect) = self.step(&current_state);
            current_state = next_state;

            if let Some(ref mut obs) = observer {
                let norm = current_state.dot(&current_state).sqrt();
                obs.record_step(i, defect, coherent, norm);
            }

            // L1 Guardrail: Halt if the Arta defect falls below the calibration tolerance
            if defect <= defect_tol {
                return (current_state, true);
            }
        }
        
        (current_state, false)
    }
    
    /// Expose the underlying cell's dimension for pipeline verification
    pub fn dim(&self) -> usize {
        self.cell.dim()
    }
}
