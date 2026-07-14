// examples/spectral_bridge.rs
use materia_commons::hamiltonian::build_hamiltonians;
use materia_commons::spectral_bridge::{trace_delta_h, formal_correlation};
use nalgebra::DMatrix;
use std::fs;

const KAPPA: f64 = 0.1;
const GAMMA: f64 = 0.5;
const SIGMA: f64 = 2.0;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🔬 Spectral Bridge (Rust + Kani)");
    println!("---------------------------------");

    let (h1, h2) = build_hamiltonians(KAPPA, GAMMA, SIGMA);

    // Compute trace identity
    let trace = trace_delta_h(&h1, &h2);
    println!("Trace of H₂ - H₁ = {:.12}", trace);

    // Diagonalize both (using nalgebra's eigensolver)
    let eig1 = h1.symmetric_eigen();
    let eig2 = h2.symmetric_eigen();
    let evals1 = eig1.eigenvalues;
    let evals2 = eig2.eigenvalues;
    let delta_e: Vec<f64> = evals2.iter().zip(evals1.iter()).map(|(a, b)| a - b).collect();

    let rho = formal_correlation(&delta_e, KAPPA, GAMMA, SIGMA);
    println!("Pearson correlation ρ (formal) = {:.6}", rho);

    // Optional: load Python results and compare
    if let Ok(content) = fs::read_to_string("zsd_results.txt") {
        // Parse as CSV or JSON; for simplicity we just print a message
        println!("Python results file found – you can compare manually.");
    }

    println!("✅ Spectral bridge computation complete.");
    Ok(())
}
