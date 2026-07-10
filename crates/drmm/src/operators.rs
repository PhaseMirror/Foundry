use ndarray::{Array2, ArrayViewMut2};

/// Recursive Operator Ξ(t): Encodes feedback dynamics and entropy modulation.
pub struct Xi;

impl Xi {
    pub fn init(dim: usize) -> Array2<f64> {
        Array2::eye(dim)
    }

    pub fn evolve(x: &mut ArrayViewMut2<f64>, t: f64, alpha: f64) {
        let gradient = x.mapv(|val| -(val.abs().ln_1p()));
        for (a, b) in x.iter_mut().zip(gradient.iter()) {
            *a += alpha * t * b;
        }
    }
}

/// Universal Multiplicity Constant Λm(t): Time-varying modulator of systemic flow.
pub struct LambdaM;

impl LambdaM {
    pub fn field(t: f64) -> f64 {
        (-1.0 / (1.0 + t.powi(2))).exp()
    }

    pub fn evolve(x: &mut ArrayViewMut2<f64>, t: f64) {
        let factor = Self::field(t);
        for val in x.iter_mut() {
            *val *= factor;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_operators() {
        let mut x = Xi::init(3);
        Xi::evolve(&mut x.view_mut(), 1.0, 0.1);
        LambdaM::evolve(&mut x.view_mut(), 1.0);
        
        assert_eq!(x.dim(), (3, 3));
    }
}
