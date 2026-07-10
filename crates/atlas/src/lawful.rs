use serde::{Deserialize, Serialize};

pub const VERSION: &str = "1.0";
pub const ANCHOR_HASH: &str = "8167719f6b1d7b9ca6f0d463e9c8da4de84a5a1b5b9a5c15df684860b1d5b6e3";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelExecution {
    pub p: u64,
    pub lambda_p: f64,
    pub l_p: f64,
    pub c_p: f64,
}

pub fn run_108_cycle() -> (Vec<ChannelExecution>, f64) {
    let primes = vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31];
    let kappa = 0.9;
    let sigma = 0.5;
    let mut trace = Vec::new();
    let mut max_c = 0.0;

    for &p in &primes {
        let a_p_norm = 108.0 / (p as f64).sqrt();
        let l_p = a_p_norm * 1.05;
        let lambda_p = kappa * (p as f64).powf(-sigma) / a_p_norm;
        let c_p = lambda_p * l_p;
        if c_p > max_c { max_c = c_p; }
        trace.push(ChannelExecution { p, lambda_p, l_p, c_p });
    }
    (trace, max_c)
}

pub fn compute_entropy(psis: &[f64]) -> f64 {
    let mut total_norm_sq = 0.0;
    for &psi in psis {
        total_norm_sq += psi * psi;
    }
    
    let mut s_pi = 0.0;
    for &psi in psis {
        let p = (psi * psi) / total_norm_sq;
        if p > 0.0 {
            s_pi -= p * p.ln();
        }
    }
    s_pi
}

pub fn reproduce_tier_energies() -> (f64, f64, f64) {
    let w = [1.0, 0.8, 0.6, 0.4, 0.2];
    let mut x = [0.0f64; 108];
    for t in 0..108 {
        if t % 27 == 0 { x[t] = w[0]; }
        else if t % 9 == 0 { x[t] = w[1]; }
        else if t % 3 == 0 { x[t] = w[2]; }
        else if t % 4 == 0 { x[t] = w[3]; }
        else if t % 2 == 0 { x[t] = w[4]; }
    }

    let r1 = (0..108).step_by(27).map(|i| x[i] * x[i]).sum::<f64>();
    let r2 = (0..108).step_by(9).map(|i| x[i] * x[i]).sum::<f64>() - r1;
    let r3 = (0..108).step_by(3).map(|i| x[i] * x[i]).sum::<f64>() - (r1 + r2);
    (r1, r2, r3)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn verify_fixed_point() {
        let (trace, max_c) = run_108_cycle();
        println!("Prime | Lambda_p | L_p | c_p");
        for e in &trace {
            println!("{:5} | {:.6} | {:.6} | {:.6}", e.p, e.lambda_p, e.l_p, e.c_p);
        }
        println!("MAX c_p: {:.10}", max_c);
        assert!(max_c < 1.0 - 1e-6);

        let psi_t0 = vec![0.4, 0.3, 0.2, 0.1];
        let s0 = compute_entropy(&psi_t0);
        let psi_t1: Vec<f64> = psi_t0.iter().map(|&x| x * (1.0 + 1e-12)).collect();
        let s1 = compute_entropy(&psi_t1);
        let delta_s = (s1 - s0).abs();
        println!("S_pi Delta: {:.10e}", delta_s);
        assert!(delta_s < 1e-8);

        let (r1, r2, r3) = reproduce_tier_energies();
        println!("R1: {:.2}, R2: {:.2}, R3: {:.2}", r1, r2, r3);
        assert!((r1 - 4.0).abs() < 0.01);
        assert!((r2 - 5.12).abs() < 0.01);
        assert!((r3 - 8.64).abs() < 0.01);
    }
}
