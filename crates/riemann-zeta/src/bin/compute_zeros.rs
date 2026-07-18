use riemann_zeta::{RiemannZeta, RiemannConfig, ZeroVerifier};
use rug::Complex;
use std::time::Instant;

fn main() {
    let config = RiemannConfig {
        precision_bits: 1024,
        max_iterations: 10000,
        zero_verification_threshold: 1e-12,
    };

    println!("Riemann Zeta Zero Verification (ADR-055 / ADR-001)");
    println!("Precision: {} bits", config.precision_bits);
    println!("Threshold: {}", config.zero_verification_threshold);
    println!();

    let zeta = RiemannZeta::new(config.clone()).unwrap();
    let verifier = ZeroVerifier::new(config.clone());

    // Verify first 10 non-trivial zeros
    let known_zeros = [
        14.1347251417347,
        21.0220396387716,
        25.0108575801457,
        30.4248761258595,
        32.9350615877392,
        37.5861781588257,
        40.9187190121475,
        43.3270732809149,
        48.0051508811672,
        49.7738324776723,
    ];

    println!("Verifying known non-trivial zeros...");
    println!("{:<20} {:<20} {:<20} {:<10}", "Imag(t)", "Real Lower", "Real Upper", "Verified");
    println!("{}", "-".repeat(70));

    for (i, &t) in known_zeros.iter().enumerate() {
        let start = Instant::now();
        let s = Complex::with_val(config.precision_bits, 0.5, t);
        let result = verifier.verify(&s).unwrap();
        let elapsed = start.elapsed();

        println!(
            "{:<20.15} {:<20.15} {:<20.15} {:<10} {:?}",
            t, result.real_part_lower, result.real_part_upper,
            if result.is_zero { "YES" } else { "NO" },
            elapsed
        );
    }

    println!();
    println!("Computing ζ(2) = π²/6 for sanity check...");
    let s2 = Complex::with_val(256, 2.0, 0.0);
    let interval = zeta.evaluate(&s2).unwrap();
    let pi_sq_over_6 = Float::with_val(256, std::f64::consts::PI.powi(2) / 6.0);
    println!(
        "ζ(2) ∈ [{}, {}], contains π²/6 ≈ {}: {}",
        interval.low,
        interval.high,
        pi_sq_over_6,
        interval.contains(&pi_sq_over_6)
    );
}
