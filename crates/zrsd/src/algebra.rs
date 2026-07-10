use nalgebra::{DMatrix, DVector};
use num_complex::Complex64;

pub fn get_binary_basis(num_primes: usize) -> Vec<Vec<u8>> {
    let dim = 1 << num_primes;
    let mut basis = Vec::with_capacity(dim);
    for i in 0..dim {
        let mut occ = Vec::with_capacity(num_primes);
        for j in (0..num_primes).rev() {
            occ.push(((i >> j) & 1) as u8);
        }
        basis.push(occ);
    }
    basis
}

pub fn get_creation_annihilation(num_primes: usize, basis: &Vec<Vec<u8>>) -> (Vec<DMatrix<Complex64>>, Vec<DMatrix<Complex64>>) {
    let dim = basis.len();
    let mut a_dag_list = Vec::with_capacity(num_primes);
    let mut a_list = Vec::with_capacity(num_primes);
    
    for i in 0..num_primes {
        let mut a_dag = DMatrix::from_element(dim, dim, Complex64::new(0.0, 0.0));
        let mut a = DMatrix::from_element(dim, dim, Complex64::new(0.0, 0.0));
        for (j, occ) in basis.iter().enumerate() {
            // Note: occ is [p0, p1, ..., p_n-1]
            // We want to flip the i-th prime's occupation if it's 0
            if occ[i] == 0 {
                let mut target_occ = occ.clone();
                target_occ[i] = 1;
                // Find index of target_occ in basis
                if let Some(target_idx) = basis.iter().position(|x| x == &target_occ) {
                    a_dag[(target_idx, j)] = Complex64::new(1.0, 0.0);
                    a[(j, target_idx)] = Complex64::new(1.0, 0.0);
                }
            }
        }
        a_dag_list.push(a_dag);
        a_list.push(a);
    }
    
    (a_dag_list, a_list)
}

pub fn multiplicity_operator(primes: &[u64], basis: &Vec<Vec<u8>>) -> DMatrix<Complex64> {
    let dim = basis.len();
    let mut m_vals = DVector::from_element(dim, Complex64::new(0.0, 0.0));
    for (i, occ) in basis.iter().enumerate() {
        let mut val = 0.0;
        for (j, &k) in occ.iter().enumerate() {
            val += (primes[j] as f64).ln() * k as f64;
        }
        m_vals[i] = Complex64::new(val, 0.0);
    }
    DMatrix::from_diagonal(&m_vals)
}
