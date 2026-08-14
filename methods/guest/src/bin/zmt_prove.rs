use risc0_zkvm::guest::env;

fn main() {
    // Read inputs (prime/zero tables) from the host
    let primes: Vec<f64> = env::read();
    let zeros: Vec<f64> = env::read();
    let n = primes.len();
    let m = zeros.len();

    // Dense kernel HS-norm squared computation
    let factor = (2.0 / std::f64::consts::PI).sqrt();
    let mut hs_norm_sq: f64 = 0.0;

    for &p in &primes {
        let log_p = p.ln();
        for &gamma in &zeros {
            let fejer = {
                let x = std::f64::consts::PI * gamma;
                if x.abs() < 1e-12 { 1.0 } else { (x.sin() / x).powi(2) }
            };
            let k_real = factor * fejer * (gamma * log_p).cos() / (1.0 + gamma * gamma);
            let k_imag = factor * fejer * (gamma * log_p).sin() / (1.0 + gamma * gamma);
            hs_norm_sq += k_real * k_real + k_imag * k_imag;
        }
    }

    // Scale by 1e18 and convert to u64 (safe because norm is < 1e-9)
    let scaled = (hs_norm_sq * 1e18) as u64;
    let bytes = scaled.to_be_bytes();
    env::commit_slice(&bytes); // commits exactly 8 bytes
}
