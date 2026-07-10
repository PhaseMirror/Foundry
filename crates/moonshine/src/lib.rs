pub mod prime_word;
pub mod fixed_point;
pub mod hecke;

pub use prime_word::*;
pub use fixed_point::*;
pub use hecke::*;

#[cfg(test)]
mod tests {
    use super::*;
    use num_rational::Ratio;
    use num_bigint::BigInt;
    use std::collections::HashMap;

    #[test]
    fn test_prime_word_n() {
        let w = PrimeWord::new(vec![1, 1], vec![2, 3]);
        assert_eq!(w.n(), BigInt::from(6));
    }

    #[test]
    fn test_fixed_point_iteration() {
        let field = RationalPrimeField;
        let mut t0 = HashMap::new();
        let w = PrimeWord::new(vec![1, 0], vec![2, 3]);
        t0.insert(w.clone(), Ratio::from(BigInt::from(0)));

        let contractive_map = |t: &PrimeState| {
            let mut res = t.clone();
            let entry = res.entry(w.clone()).or_insert_with(|| Ratio::from(BigInt::from(0)));
            // T_{n+1} = 0.5 * T_n + 1
            *entry = (entry.clone() * Ratio::new(BigInt::from(1), BigInt::from(2))) + Ratio::from(BigInt::from(1));
            res
        };

        let result = fixed_point_iteration(contractive_map, t0, &field, 1e-10, 100);
        assert!(result.converged);
        // Fixed point should be close to 2
        let val = result.value.get(&w).unwrap();
        let f_val = val.numer().to_string().parse::<f64>().unwrap() / val.denom().to_string().parse::<f64>().unwrap();
        assert!((f_val - 2.0).abs() < 1e-10);
    }

    #[test]
    fn test_hecke_commutation() {
        let n = 100;
        let t2 = hecke_prime_matrix(2, n);
        let t3 = hecke_prime_matrix(3, n);
        // Note: Commutation might still fail at the boundary due to truncation.
        // We'll check if they commute on the subspace where n < N/6.
        let comm = &t2 * &t3 - &t3 * &t2;
        for i in 0..n/6 {
            for j in 0..n {
                assert_eq!(comm[(i, j)], 0, "Commutation failed at ({}, {})", i, j);
            }
        }
    }
}
