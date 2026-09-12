pub fn prime_set(k: usize) -> [u32; 8] {
    let primes = [2, 3, 5, 7, 11, 13, 17, 19];
    let mut result = [0u32; 8];
    let count = k.min(8);
    for i in 0..count {
        result[i] = primes[i];
    }
    result
}

pub fn prime_first(k: usize) -> u32 {
    let primes = prime_set(k);
    if primes[0] == 0 && k == 0 {
        0
    } else {
        primes[0]
    }
}

pub fn multiplicity_op<const K: usize>(occupation: [u32; K]) -> u32 {
    if K == 0 {
        0
    } else {
        prime_first(K + 1).saturating_mul(occupation[0])
    }
}

pub fn zeta_hamiltonian(alpha: u32, m_op: u32) -> u32 {
    alpha * m_op
}

pub fn lambda_op(kappa: u32) -> u32 {
    kappa
}

pub fn pi_lambda_m(rho: u32, m_star: u32) -> u32 {
    rho.min(m_star)
}

pub fn lambda_stabilizer(_kappa: u32, _rho: u32, _m_star: u32) -> u32 {
    0
}

pub fn small_gain_check(q_t: u32, eta_t: u32, epsilon: u32) -> bool {
    q_t.saturating_add(eta_t) < epsilon.saturating_sub(1)
}
