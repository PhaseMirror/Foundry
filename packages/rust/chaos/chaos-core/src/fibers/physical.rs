use nalgebra::DMatrix;

pub struct PhysicalFiber {
    pub laplacian: DMatrix<f64>,
    pub lambda_param: f64,
    pub kappa_target: f64,
}

impl PhysicalFiber {
    pub fn new(lambda_param: f64, kappa_target: f64) -> Self {
        let laplacian = DMatrix::from_row_slice(3, 3, &[
             2.0/3.0, -1.0/3.0, -1.0/3.0,
            -1.0/3.0,  2.0/3.0, -1.0/3.0,
            -1.0/3.0, -1.0/3.0,  2.0/3.0,
        ]);
        Self {
            laplacian,
            lambda_param,
            kappa_target,
        }
    }

    pub fn calculate_k_viol(&self, x: &[f64]) -> f64 {
        let weights = vec![1.0, 1.0, 1.0];
        let dot: f64 = weights.iter().zip(x.iter()).map(|(w, xi)| w * xi).sum();
        (dot - self.kappa_target).abs()
    }

    pub fn calculate(&self, x: &nalgebra::DVector<f64>) -> f64 {
        let quad_form = x.dot(&( &self.laplacian * x ));
        let penalty = self.lambda_param * self.calculate_k_viol(x.as_slice());
        -quad_form - penalty
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use nalgebra::DVector;

    #[test]
    fn test_physical_fiber() {
        let fiber = PhysicalFiber::new(1.0, 0.0);
        let x = DVector::from_vec(vec![1.0, 1.0, 1.0]);
        let res = fiber.calculate(&x);
        // Laplacian on constant vector [1,1,1] is 0
        // k_viol on [1,1,1] with target 0 is 3
        // quad_form = 0
        // penalty = 1.0 * 3.0 = 3
        // Result = -0 - 3 = -3
        assert!((res + 3.0).abs() < 1e-9);
    }
}
