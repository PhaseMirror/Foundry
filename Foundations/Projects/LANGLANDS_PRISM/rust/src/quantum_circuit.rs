use std::f64::consts::PI;
use serde::{Deserialize, Serialize};
use crate::core::{PHI, dirichlet_char_4, dirichlet_euler_factor};
use crate::tensor::PrismTensorState;

/// Quantum Langlands Gate representation.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum QuantumGate {
    Hadamard { qubit: usize },
    Phase { qubit: usize, angle: f64 },
    ControlledPhase { control: usize, target: usize, angle: f64 },
    Swap { q1: usize, q2: usize },
    LanglandsOscillator { qubit: usize, prime: u64, time: u64 },
}

/// Quantum Langlands Circuit.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct QuantumLanglandsCircuit {
    pub num_qubits: usize,
    pub gates: Vec<QuantumGate>,
}

impl QuantumLanglandsCircuit {
    pub fn new(num_qubits: usize) -> Self {
        Self {
            num_qubits,
            gates: Vec::new(),
        }
    }

    /// Synthesize quantum circuit from Prism Tensor State.
    pub fn from_tensor_state(st: &PrismTensorState) -> Self {
        let num_qubits = st.nodes.len();
        let mut qc = Self::new(num_qubits);

        // 1. Hadamard initialization (equal superposition)
        for q in 0..num_qubits {
            qc.gates.push(QuantumGate::Hadamard { qubit: q });
        }

        // 2. Prime phase encoding via Langlands oscillator
        for (q, node) in st.nodes.iter().enumerate() {
            let p = node.prime;
            let chi = dirichlet_char_4(p);
            let l_fac = dirichlet_euler_factor(p, 1.0, chi);
            let angle = (2.0 * PI * (p as f64) * PHI * (st.time as f64 + 1.0) * l_fac) % (2.0 * PI);
            qc.gates.push(QuantumGate::Phase { qubit: q, angle });
            qc.gates.push(QuantumGate::LanglandsOscillator { qubit: q, prime: p, time: st.time });
        }

        // 3. Galois entangling multi-qubit gates
        for i in 0..(num_qubits.saturating_sub(1)) {
            let j = i + 1;
            let angle = (PI / (st.nodes[i].prime as f64)) * st.lambda_m;
            qc.gates.push(QuantumGate::ControlledPhase { control: i, target: j, angle });
        }

        qc
    }

    /// Export circuit as OpenQASM 2.0 string.
    pub fn to_openqasm(&self) -> String {
        let mut qasm = String::new();
        qasm.push_str("OPENQASM 2.0;\ninclude \"qelib1.inc\";\n\n");
        qasm.push_str(&format!("qreg q[{}];\ncreg c[{}];\n\n", self.num_qubits, self.num_qubits));

        for gate in &self.gates {
            match gate {
                QuantumGate::Hadamard { qubit } => {
                    qasm.push_str(&format!("h q[{}];\n", qubit));
                }
                QuantumGate::Phase { qubit, angle } => {
                    qasm.push_str(&format!("rz({:.6}) q[{}];\n", angle, qubit));
                }
                QuantumGate::ControlledPhase { control, target, angle } => {
                    qasm.push_str(&format!("cp({:.6}) q[{}], q[{}];\n", angle, control, target));
                }
                QuantumGate::Swap { q1, q2 } => {
                    qasm.push_str(&format!("swap q[{}], q[{}];\n", q1, q2));
                }
                QuantumGate::LanglandsOscillator { qubit, prime, time } => {
                    let osc_angle = (2.0 * PI * (*prime as f64) * PHI * (*time as f64 + 1.0)).sin();
                    qasm.push_str(&format!("rx({:.6}) q[{}]; // L_phi(p={})\n", osc_angle, qubit, prime));
                }
            }
        }

        qasm.push_str("\nmeasure q -> c;\n");
        qasm
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::LAMBDA_M;

    #[test]
    fn test_quantum_circuit_generation() {
        let primes = [2, 3, 5];
        let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
        let qc = QuantumLanglandsCircuit::from_tensor_state(&st0);

        assert_eq!(qc.num_qubits, 3);
        assert!(!qc.gates.is_empty());

        let qasm = qc.to_openqasm();
        assert!(qasm.contains("OPENQASM 2.0;"));
        assert!(qasm.contains("qreg q[3];"));
        assert!(qasm.contains("measure q -> c;"));
    }
}
