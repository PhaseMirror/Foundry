// examples/resolvent_scan.rs
use multiplicity_common::hamiltonian::{build_hamiltonians, N_STATES};
use multiplicity_common::spectral_resolvent::{resolvent_trace, first_order_trace};
use nalgebra::DMatrix;

const KAPPA: f64 = 0.1;
const GAMMA: f64 = 0.5;
const SIGMA: f64 = 2.0;

fn main() {
    println!("Resolvent Trace Scan (Kani-verified logic)");
    println!("==========================================");
    let (_, h2) = build_hamiltonians(KAPPA, GAMMA, SIGMA);

    // Sample z values
    let z_values = [0.5, 1.0, 1.5, 2.0, 3.0, 5.0, 10.0];
    println!("z\tFull Trace\t1st-order\tDiff");
    for &z in &z_values {
        let full = resolvent_trace(z, &h2);
        let first = first_order_trace(z);
        let diff = (full - first).abs();
        println!("{:.2}\t{:.8}\t{:.8}\t{:.2e}", z, full, first, diff);
    }
    println!("\nNote: The 1st-order expansion is only valid for z near the spectral range.");
}
