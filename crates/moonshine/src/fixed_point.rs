use num_rational::Ratio;
use num_bigint::BigInt;
use crate::prime_word::PrimeState;

pub trait NumericField<T> {
    fn norm(&self, x: &T) -> f64;
    fn diff(&self, a: &T, b: &T) -> T;
}

pub struct RationalPrimeField;

impl NumericField<PrimeState> for RationalPrimeField {
    fn norm(&self, x: &PrimeState) -> f64 {
        let mut sum = 0.0;
        for coeff in x.values() {
            let numer = coeff.numer().to_string().parse::<f64>().unwrap_or(0.0);
            let denom = coeff.denom().to_string().parse::<f64>().unwrap_or(1.0);
            let f_val = numer / denom;
            sum += f_val * f_val;
        }
        sum.sqrt()
    }

    fn diff(&self, a: &PrimeState, b: &PrimeState) -> PrimeState {
        let mut res = a.clone();
        for (w, coeff) in b {
            let entry = res.entry(w.clone()).or_insert_with(|| Ratio::from(BigInt::from(0)));
            *entry -= coeff;
        }
        res
    }
}

pub struct FixedPointResult<T> {
    pub value: T,
    pub residual: f64,
    pub n_iter: usize,
    pub converged: bool,
}

pub fn fixed_point_iteration<T, F, M>(
    contractive_map: M,
    t0: T,
    field: &F,
    tol: f64,
    max_iter: usize,
) -> FixedPointResult<T>
where
    T: Clone,
    F: NumericField<T>,
    M: Fn(&T) -> T,
{
    let mut t = t0.clone();
    let mut residual = f64::INFINITY;
    let mut converged = false;

    for i in 1..=max_iter {
        let t_new = contractive_map(&t);
        let d = field.diff(&t_new, &t);
        residual = field.norm(&d);
        t = t_new;
        if residual < tol {
            converged = true;
            return FixedPointResult { value: t, residual, n_iter: i, converged };
        }
    }

    FixedPointResult { value: t, residual, n_iter: max_iter, converged }
}
