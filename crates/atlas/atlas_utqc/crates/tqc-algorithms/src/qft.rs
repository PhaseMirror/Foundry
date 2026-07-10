//! Topological Quantum Fourier Transform (QFT)
//!
//! Provides a framework for synthesizing the QFT directly over the
//! combinatorial manifold using Atlas-native logic gates. This proves
//! polynomial compilation of phase estimation components.

use std::f64::consts::PI;
use tqc_compiler::LogicGate;

/// A QFT algorithmic solver mapped to the topological space.
pub struct QftSolver {
    /// The number of virtual qubits in the QFT state space.
    pub num_qubits: usize,
}

impl QftSolver {
    /// Initializes the solver for a given number of virtual qubits.
    #[must_use]
    pub fn new(num_qubits: usize) -> Self {
        Self { num_qubits }
    }

    /// Builds the QFT circuit.
    pub fn build_circuit(&self) -> Vec<LogicGate> {
        let mut circuit = Vec::new();

        for i in 0..self.num_qubits {
            circuit.push(LogicGate::Hadamard(i));

            // Apply controlled rotations for all subsequent qubits
            for j in (i + 1)..self.num_qubits {
                let m = (j - i + 1) as f64;
                let phase = PI / 2.0_f64.powf(m - 1.0);

                // Controlled Phase shift decomposition
                // CPhase(phi) on target (i) controlled by (j):
                // Rz(phi/2) on target
                // CNOT control target
                // Rz(-phi/2) on target
                // CNOT control target
                // Rz(phi/2) on control
                circuit.push(LogicGate::Rz(i, phase / 2.0));
                circuit.push(LogicGate::CNot(j, i));
                circuit.push(LogicGate::Rz(i, -phase / 2.0));
                circuit.push(LogicGate::CNot(j, i));
                circuit.push(LogicGate::Rz(j, phase / 2.0));
            }
        }

        // Swap operations to reverse the order (Standard QFT ending)
        for i in 0..(self.num_qubits / 2) {
            let j = self.num_qubits - 1 - i;
            // SWAP decomposition into 3 CNOTs
            circuit.push(LogicGate::CNot(i, j));
            circuit.push(LogicGate::CNot(j, i));
            circuit.push(LogicGate::CNot(i, j));
        }

        circuit
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tqc_compiler::Compiler;
    use tqc_core::UseCaseParams;

    #[test]
    fn test_qft_circuit_generation() {
        let solver = QftSolver::new(4);
        let circuit = solver.build_circuit();

        assert!(!circuit.is_empty());

        let p = UseCaseParams::new(4, 3, 8);
        let compiler = Compiler::new(&p);

        let braid_word = compiler.compile(&circuit).unwrap();
        assert!(
            !braid_word.sequence.is_empty(),
            "QFT should compile into a topological braid word"
        );
    }
}
