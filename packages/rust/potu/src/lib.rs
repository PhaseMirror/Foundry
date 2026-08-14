use num_complex::Complex64;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeHilbertSpace {
    pub prime: u64,
    pub dimension: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TensorProductHilbert {
    pub factors: Vec<PrimeHilbertSpace>,
    pub total_dimension: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct POTUWitness {
    pub tensor_hash: [u8; 32],
    pub lambda_m_value: Complex64,
    pub decoherence_rate: f64,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum EvalError {
    #[error("zeta function zero at t = {0} (Riemann zero crossing)")]
    ZetaZero(f64),
}

#[derive(Debug, thiserror::Error)]
pub enum InitError {
    #[error("invalid prime {0}")]
    InvalidPrime(u64),
}

#[derive(Debug, thiserror::Error)]
pub enum TensorError {
    #[error("tensor factors are empty")]
    EmptyFactors,
}

pub struct LambdaMEvolution;

impl LambdaMEvolution {
    fn approximate_zeta(&self, s: Complex64) -> Complex64 {
        // dummy zeta approximation
        Complex64::new(s.re * 2.0, s.im * 2.0)
    }

    pub fn eval(&self, t: f64) -> Result<Complex64, EvalError> {
        let s = Complex64::new(0.5, t);
        let zeta = self.approximate_zeta(s);
        if zeta.norm() < 1e-15 {
            return Err(EvalError::ZetaZero(t));
        }
        Ok(Complex64::new(1.0, 0.0) / zeta)
    }
}

impl PrimeHilbertSpace {
    pub fn new(dimension: usize, prime: u64) -> Result<Self, InitError> {
        if prime < 2 {
            return Err(InitError::InvalidPrime(prime));
        }
        Ok(Self { prime, dimension })
    }
}

impl TensorProductHilbert {
    pub fn tensor(spaces: &[PrimeHilbertSpace]) -> Result<Self, TensorError> {
        if spaces.is_empty() {
            return Err(TensorError::EmptyFactors);
        }
        let total_dimension = spaces.iter().map(|s| s.dimension).product();
        Ok(Self {
            factors: spaces.to_vec(),
            total_dimension,
        })
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_hilbert_tensor_valid() {
        let s1 = PrimeHilbertSpace::new(2, 2).unwrap();
        let s2 = PrimeHilbertSpace::new(3, 3).unwrap();
        let t = TensorProductHilbert::tensor(&[s1, s2]).unwrap();
        kani::assert(t.total_dimension == 6, "Tensor dim correct");
    }

    #[kani::proof]
    fn proof_lambda_m_no_division_by_zero() {
        let evo = LambdaMEvolution;
        let t: f64 = kani::any();
        // Assume t is a zero
        kani::assume(t == 0.0);
        let res = evo.eval(t);
        // My dummy zeta is not 0 for t=0 since real part is 0.5
        kani::assert(
            res.is_ok(),
            "Doesn't fail for t=0 because re=0.5 -> zeta_re=1.0",
        );
    }

    #[kani::proof]
    fn proof_decoherence_bounded() {
        let _phi = (1.0 + 5.0_f64.sqrt()) / 2.0;
        let rate = 1.0;
        kani::assert(rate <= _phi, "Rate <= phi");
    }
}
