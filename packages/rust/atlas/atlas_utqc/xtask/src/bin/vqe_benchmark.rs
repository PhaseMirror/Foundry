#![allow(clippy::unwrap_used)]
#![allow(missing_docs)]

use tqc_algorithms::{Ansatz, VqeSolver};
use tqc_atlas::canonical;
use tqc_model::Model;

fn main() {
    let model = Model::load().unwrap();
    let p = canonical(&model).unwrap();

    println!("=======================================================");
    println!(" Holospaces Finite-Closure Variational Quantum Eigensolver");
    println!("=======================================================");
    println!("End-to-end Classical to Topological optimization loop.");
    println!("Synthesizing parameterized classical gates (Ry, Rz) via");
    println!("exact evaluation over the finite closure.");
    println!();

    let ansatz = Ansatz {
        num_qubits: 4,
        layers: 2,
    };

    let num_params = ansatz.num_qubits * ansatz.layers * 2;
    let initial_thetas = vec![0.5; num_params];

    let solver = VqeSolver::new(&p);

    println!("Starting VQE Optimization...");
    println!(
        "Ansatz: {} qubits, {} layers, {} parameters",
        ansatz.num_qubits, ansatz.layers, num_params
    );
    // 4. Initial evaluation
    let initial_energy = solver.evaluate_energy(&ansatz, &initial_thetas).unwrap();
    println!("Initial State Energy: {:.4}", initial_energy);

    // 5. Optimization
    println!("Running VQE pseudo-gradient optimization over topological braid words...");
    let (optimized_thetas, final_energy) = solver.optimize(&ansatz, &initial_thetas, 10).unwrap();

    println!();
    println!("Optimization Complete!");
    println!("Final Energy: {:.4}", final_energy);
    println!("Energy Reduction: {:.4}", initial_energy - final_energy);
    println!("Optimized Parameters: {:?}", optimized_thetas);
}
