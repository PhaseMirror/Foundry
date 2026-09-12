use nalgebra::DMatrix;

pub fn hecke_prime_matrix(p: usize, n: usize) -> DMatrix<i64> {
    let mut mat = DMatrix::zeros(n, n);
    for i in 0..n {
        if p * i < n {
            mat[(i, p * i)] += 1;
        }
        if i % p == 0 {
            mat[(i, i / p)] += p as i64;
        }
    }
    mat
}

pub fn verify_commutation(tm: &DMatrix<i64>, tn: &DMatrix<i64>) -> bool {
    tm * tn == tn * tm
}

pub fn verify_multiplicativity(tm: &DMatrix<i64>, tn: &DMatrix<i64>, tmn: &DMatrix<i64>) -> bool {
    tm * tn == *tmn
}
