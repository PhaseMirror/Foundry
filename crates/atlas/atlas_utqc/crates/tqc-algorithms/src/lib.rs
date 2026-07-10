//! Topological Variational Quantum Eigensolver (VQE)
//!
//! Provides an end-to-end framework for hybrid classical-topological optimization.
//! Synthesizes parameterized classical quantum ansatz circuits into Atlas-native
//! Braid Words, executes them on the Holospaces emulator, and minimizes the energy.

pub mod grover;
pub mod qft;
pub mod qpe;
pub mod shor;

use tqc_compiler::{BraidGen, Compiler, LogicGate};
use tqc_core::generators::{Generators, Permutation};
use tqc_core::UseCaseParams;

/// A parameterized quantum circuit (Hardware Efficient Ansatz)
pub struct Ansatz {
    /// The number of virtual qubits.
    pub num_qubits: usize,
    /// The number of repeating layers in the hardware efficient ansatz.
    pub layers: usize,
}

impl Ansatz {
    /// Generates the circuit given a set of parameters (theta).
    ///
    /// # Errors
    /// Returns an error if the number of parameters provided does not match the
    /// expected parameter count for the ansatz structure (2 * qubits * layers).
    pub fn build_circuit(&self, thetas: &[f64]) -> Result<Vec<LogicGate>, String> {
        let expected_params = 2 * self.num_qubits * self.layers;
        if thetas.len() != expected_params {
            return Err(format!(
                "Ansatz expected {} parameters, but received {}",
                expected_params,
                thetas.len()
            ));
        }

        let mut circuit = Vec::new();
        let mut param_idx = 0;

        for _ in 0..self.layers {
            for q in 0..self.num_qubits {
                circuit.push(LogicGate::Ry(q, thetas[param_idx]));
                param_idx += 1;
                circuit.push(LogicGate::Rz(q, thetas[param_idx]));
                param_idx += 1;
            }
            // Entangling layer
            for q in 0..(self.num_qubits.saturating_sub(1)) {
                circuit.push(LogicGate::CNot(q, q + 1));
            }
        }
        Ok(circuit)
    }
}

/// Executes a VQE loop over the Atlas.
pub struct VqeSolver<'a> {
    params: &'a UseCaseParams,
    generators: Generators,
}

impl<'a> VqeSolver<'a> {
    /// Initializes the solver for a given Atlas topology.
    pub fn new(params: &'a UseCaseParams) -> Self {
        Self {
            params,
            generators: Generators::new(params),
        }
    }

    /// Evaluates the objective function (energy) for a set of parameters.
    ///
    /// # Errors
    /// Returns an error if the ansatz cannot be compiled or parameters are mismatched.
    pub fn evaluate_energy(&self, ansatz: &Ansatz, thetas: &[f64]) -> Result<f64, String> {
        // 1. Classical parameterized generation
        let circuit = ansatz.build_circuit(thetas)?;

        // 2. Classical-to-Topological Compilation
        let compiler = Compiler::new(self.params);
        let word = compiler.compile(&circuit)?;

        // 3. Topological Execution
        let mut perm = Permutation::identity(self.params.class_count());
        for gen in word.sequence {
            let p = match gen {
                BraidGen::Sigma => &self.generators.sigma,
                BraidGen::Tau => &self.generators.tau,
                BraidGen::Mu => &self.generators.mu,
            };
            perm = perm.then(p);
        }

        // Base ground state
        let n = self.params.class_count() as usize;
        let m = self.params.modality as i64;
        let base: Vec<i64> = (0..n as i64).map(|i| i % m - (m / 2)).collect();

        // 4. State collapse and measurement
        let state = perm.permute_amplitudes(&base);

        // Synthetic Hamiltonian expectation: sum of squares weighted by class index
        let energy: f64 = state
            .iter()
            .enumerate()
            .map(|(i, &v)| (i as f64) * (v as f64).powi(2))
            .sum();

        Ok(energy)
    }

    /// Runs a gradient-free parameter shift optimization.
    ///
    /// # Errors
    /// Returns an error if evaluation fails during the loop.
    pub fn optimize(
        &self,
        ansatz: &Ansatz,
        initial_thetas: &[f64],
        iterations: usize,
    ) -> Result<(Vec<f64>, f64), String> {
        let mut thetas = initial_thetas.to_vec();
        let mut best_energy = f64::MAX;
        let step = 0.1;

        for _ in 0..iterations {
            let mut current_energy = self.evaluate_energy(ansatz, &thetas)?;
            if current_energy < best_energy {
                best_energy = current_energy;
            }

            // Pseudo-gradient descent
            for i in 0..thetas.len() {
                let old = thetas[i];
                thetas[i] = old + step;
                let e_plus = self.evaluate_energy(ansatz, &thetas)?;

                thetas[i] = old - step;
                let e_minus = self.evaluate_energy(ansatz, &thetas)?;

                if e_plus < current_energy && e_plus < e_minus {
                    thetas[i] = old + step;
                    current_energy = e_plus;
                } else if e_minus < current_energy {
                    thetas[i] = old - step;
                    current_energy = e_minus;
                } else {
                    thetas[i] = old;
                }
            }
        }
        Ok((thetas, best_energy))
    }
}
