//! Topological Quantum Phase Estimation (QPE)
//!
//! Provides a framework for synthesizing QPE directly over the
//! combinatorial manifold. QPE is the foundation for Shor's Algorithm
//! and period finding.

use tqc_compiler::LogicGate;

/// A QPE algorithmic solver mapped to the topological space.
pub struct QpeSolver {
    /// The number of counting qubits (precision of the phase estimation).
    pub counting_qubits: usize,
    /// The number of state qubits (eigenvector of the unitary).
    pub state_qubits: usize,
}

impl QpeSolver {
    /// Initializes the QPE solver.
    #[must_use]
    pub fn new(counting_qubits: usize, state_qubits: usize) -> Self {
        Self {
            counting_qubits,
            state_qubits,
        }
    }

    /// Builds the QPE circuit for a given Unitary operator (represented as a series of controlled phase shifts).
    pub fn build_circuit(&self) -> Vec<LogicGate> {
        let mut circuit = Vec::new();

        // 1. Initialization: Hadamard on all counting qubits
        for i in 0..self.counting_qubits {
            circuit.push(LogicGate::Hadamard(i));
        }

        // Initialize state qubits to an eigenstate (for demonstration, just |1>)
        circuit.push(LogicGate::PauliX(self.counting_qubits));

        // 2. Controlled Unitaries
        // For a generic QPE demonstration, we apply a controlled phase shift
        // U = Rz(theta). Applying U^(2^j) means rotating by theta * 2^j.
        let theta = std::f64::consts::PI / 4.0; // The phase we want to estimate

        for j in 0..self.counting_qubits {
            let power = 1 << j;
            let phase_shift = theta * (power as f64);

            // Controlled Phase Shift: CRz(phase_shift)
            // Decomposition:
            // Rz(phase/2) on target
            // CNot control -> target
            // Rz(-phase/2) on target
            // CNot control -> target
            // Rz(phase/2) on control
            let control = j;
            let target = self.counting_qubits; // The state qubit

            circuit.push(LogicGate::Rz(target, phase_shift / 2.0));
            circuit.push(LogicGate::CNot(control, target));
            circuit.push(LogicGate::Rz(target, -phase_shift / 2.0));
            circuit.push(LogicGate::CNot(control, target));
            circuit.push(LogicGate::Rz(control, phase_shift / 2.0));
        }

        // 3. Inverse QFT on the counting qubits
        // For simplicity, we just use the QftSolver to generate the circuit
        // and invert it. (Since QFT is unitary, the inverse is the reversed sequence
        // with inverted phases. Since we only have standard QFT, we can just compile
        // QFT and apply it. In topological space, we can easily reverse the braid word,
        // but here we generate the Inverse QFT logically.)

        // Logical Inverse QFT (Swap reversed, then controlled phases reversed)
        for i in 0..(self.counting_qubits / 2) {
            let swap_j = self.counting_qubits - 1 - i;
            circuit.push(LogicGate::CNot(i, swap_j));
            circuit.push(LogicGate::CNot(swap_j, i));
            circuit.push(LogicGate::CNot(i, swap_j));
        }

        for i in (0..self.counting_qubits).rev() {
            for j in (0..i).rev() {
                let m = (i - j + 1) as f64;
                let phase = -std::f64::consts::PI / 2.0_f64.powf(m - 1.0);

                // CRz
                circuit.push(LogicGate::Rz(i, phase / 2.0));
                circuit.push(LogicGate::CNot(j, i));
                circuit.push(LogicGate::Rz(i, -phase / 2.0));
                circuit.push(LogicGate::CNot(j, i));
                circuit.push(LogicGate::Rz(j, phase / 2.0));
            }
            circuit.push(LogicGate::Hadamard(i));
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
    fn test_qpe_circuit_generation() {
        let solver = QpeSolver::new(3, 1);
        let circuit = solver.build_circuit();

        assert!(!circuit.is_empty());

        let p = UseCaseParams::new(4, 3, 8);
        let compiler = Compiler::new(&p);

        let braid_word = compiler.compile(&circuit).unwrap();
        assert!(
            !braid_word.sequence.is_empty(),
            "QPE should compile into a topological braid word"
        );
    }
}
