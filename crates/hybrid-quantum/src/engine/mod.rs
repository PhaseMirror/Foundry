use nalgebra::{DMatrix, DVector};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PirtmState {
    pub x: DVector<f64>,
    pub xi: DMatrix<f64>,
    pub lambda: DMatrix<f64>,
    pub g: DVector<f64>,
    pub lambda_m: f64,
}

pub struct PirtmEngine {
    state: PirtmState,
}

impl PirtmEngine {
    pub fn new(dim: usize) -> Self {
        Self {
            state: PirtmState {
                x: DVector::zeros(dim),
                xi: DMatrix::identity(dim, dim),
                lambda: DMatrix::from_element(dim, dim, 0.5),
                g: DVector::zeros(dim),
                lambda_m: 0.1,
            },
        }
    }

    /// Implements X_{t+1} = (1 - lambda_m)X_t + lambda_m * P(Xi_t X_t + Lambda_t T(X_t) + G_t)
    pub fn step(&mut self) {
        let x_t = &self.state.x;
        let xi_t = &self.state.xi;
        let lambda_t = &self.state.lambda;
        let g_t = &self.state.g;
        let lm = self.state.lambda_m;

        // Simplified T(X) = tanh(X) for demonstration
        let t_x = x_t.map(|v| v.tanh());

        let linear_part = xi_t * x_t + lambda_t * t_x + g_t;
        
        // Simplified Projection P = Identity
        let projection = linear_part;

        self.state.x = (1.0 - lm) * x_t + lm * projection;
    }

    pub fn get_x(&self) -> &DVector<f64> {
        &self.state.x
    }
}
