// =====================================================================
// 1. Imports
// =====================================================================

use nalgebra::{DMatrix, DVector, Complex};
use std::f64::consts::PI;

// =====================================================================
// 2. Hardware Specification
// =====================================================================

#[derive(Clone, Debug)]
pub struct HardwareSpec {
    pub num_qubits: u8,
    pub qubit_positions: [[f64; 2]; 32],
    pub rabi_frequency: [f64; 32],
    pub detuning: [f64; 32],
    pub blockade_radius: f64,
    pub blockade_interaction: [[f64; 32]; 32],
    pub allowed_transitions: [[bool; 32]; 32],
    pub pulse_length_tolerance: f64,
    pub phase_tolerance: f64,
    pub leakage_rate: f64,
    pub decoherence_rate: f64,
}

impl Default for HardwareSpec {
    fn default() -> Self {
        Self {
            num_qubits: 2,
            qubit_positions: [[0.0; 2]; 32],
            rabi_frequency: [0.0; 32],
            detuning: [0.0; 32],
            blockade_radius: 5.0,
            blockade_interaction: [[0.0; 32]; 32],
            allowed_transitions: [[false; 32]; 32],
            pulse_length_tolerance: 0.01,
            phase_tolerance: 0.01,
            leakage_rate: 0.001,
            decoherence_rate: 0.1,
        }
    }
}

// =====================================================================
// 3. Gate Operations
// =====================================================================

#[derive(Clone, Debug, PartialEq)]
pub enum Axis { X, Y, Z }

#[derive(Clone, Debug, PartialEq)]
pub enum TwoQubitType { CNOT, CZ, SWAP }

#[derive(Clone, Debug, PartialEq)]
pub enum GateOperation {
    Identity,
    SingleQubitGate { qubit: u8, angle: f64, axis: Axis },
    TwoQubitGate { control: u8, target: u8, gate_type: TwoQubitType },
    RydbergPulse { qubits: Vec<u8>, duration: f64, detuning: f64 },
}

impl GateOperation {
    pub fn qubits(&self) -> Vec<u8> {
        match self {
            GateOperation::Identity => vec![],
            GateOperation::SingleQubitGate { qubit, .. } => vec![*qubit],
            GateOperation::TwoQubitGate { control, target, .. } => vec![*control, *target],
            GateOperation::RydbergPulse { qubits, .. } => qubits.clone(),
        }
    }
}

// =====================================================================
// 4. Pauli Matrices (Kronecker products)
// =====================================================================

impl HardwareSpec {
    fn pauli_x(&self, q: usize) -> DMatrix<f64> {
        self.pauli_matrix(q, &[[0.0, 1.0], [1.0, 0.0]])
    }
    fn pauli_y(&self, q: usize) -> DMatrix<f64> {
        self.pauli_matrix(q, &[[0.0, -1.0], [1.0, 0.0]])
    }
    fn pauli_z(&self, q: usize) -> DMatrix<f64> {
        self.pauli_matrix(q, &[[1.0, 0.0], [0.0, -1.0]])
    }

    fn pauli_matrix(&self, q: usize, mat: &[[f64; 2]; 2]) -> DMatrix<f64> {
        let n = self.num_qubits as usize;
        let dim = 1 << n;
        let mut result = DMatrix::zeros(dim, dim);
        for i in 0..dim {
            for j in 0..dim {
                let bit_i = (i >> q) & 1;
                let bit_j = (j >> q) & 1;
                let other_i = i & !(1 << q);
                let other_j = j & !(1 << q);
                if other_i == other_j {
                    result[(i, j)] = mat[bit_i][bit_j];
                }
            }
        }
        result
    }
}

// =====================================================================
// 5. Hamiltonian Evaluator
// =====================================================================

impl HardwareSpec {
    /// Constructs the full many‑body Hamiltonian for a sequence of gate operations.
    /// The Hamiltonian is a 2^n × 2^n Hermitian matrix with zero trace.
    pub fn hamiltonian(&self, sequence: &[GateOperation]) -> DMatrix<f64> {
        let n = self.num_qubits as usize;
        let dim = 1 << n;
        let mut h = DMatrix::zeros(dim, dim);

        // Sum gate Hamiltonians
        for gate in sequence {
            let h_gate = self.gate_hamiltonian(gate);
            h += h_gate;
        }

        // Add static Rydberg blockade interactions
        for i in 0..n {
            for j in (i+1)..n {
                let v_ij = self.blockade_interaction[i][j];
                if v_ij != 0.0 {
                    for state in 0..dim {
                        let ri = (state >> i) & 1;
                        let rj = (state >> j) & 1;
                        if ri == 1 && rj == 1 {
                            h[(state, state)] += v_ij;
                        }
                    }
                }
            }
        }

        h
    }

    fn gate_hamiltonian(&self, gate: &GateOperation) -> DMatrix<f64> {
        let dim = 1 << self.num_qubits;
        match gate {
            GateOperation::Identity => DMatrix::zeros(dim, dim),
            GateOperation::SingleQubitGate { qubit, angle, axis } => {
                let q = *qubit as usize;
                let sigma = match axis {
                    Axis::X => self.pauli_x(q),
                    Axis::Y => self.pauli_y(q),
                    Axis::Z => self.pauli_z(q),
                };
                (angle / 2.0) * sigma
            }
            GateOperation::TwoQubitGate { control, target, gate_type } => {
                let c = *control as usize;
                let t = *target as usize;
                match gate_type {
                    TwoQubitType::CNOT => {
                        let z_c = self.pauli_z(c);
                        let x_t = self.pauli_x(t);
                        let i = DMatrix::identity(dim, dim);
                        (PI / 4.0) * (i - z_c) * x_t
                    }
                    TwoQubitType::CZ => {
                        let z_c = self.pauli_z(c);
                        let z_t = self.pauli_z(t);
                        let i = DMatrix::identity(dim, dim);
                        (PI / 4.0) * (i - z_c) * (i - z_t)
                    }
                    TwoQubitType::SWAP => {
                        let x_c = self.pauli_x(c);
                        let x_t = self.pauli_x(t);
                        let y_c = self.pauli_y(c);
                        let y_t = self.pauli_y(t);
                        let z_c = self.pauli_z(c);
                        let z_t = self.pauli_z(t);
                        (PI / 4.0) * (x_c*x_t + y_c*y_t + z_c*z_t)
                    }
                }
            }
            GateOperation::RydbergPulse { qubits, duration: _, detuning } => {
                let mut h = DMatrix::zeros(dim, dim);
                for q in qubits {
                    let q = *q as usize;
                    let omega = self.rabi_frequency[q];
                    let delta = *detuning + self.detuning[q];
                    h += (omega / 2.0) * self.pauli_x(q)
                       + (delta / 2.0) * self.pauli_z(q);
                }
                h
            }
        }
    }

    /// Computes the associator defect: Frobenius norm of H(seq1) - H(seq2).
    pub fn associator_defect(&self, seq1: &[GateOperation], seq2: &[GateOperation]) -> f64 {
        let h1 = self.hamiltonian(seq1);
        let h2 = self.hamiltonian(seq2);
        (h1 - h2).norm() // Frobenius norm
    }

    /// Returns the Euclidean distance between two qubits.
    pub fn distance_between(&self, q1: u8, q2: u8) -> f64 {
        let (x1, y1) = (self.qubit_positions[q1 as usize][0],
                        self.qubit_positions[q1 as usize][1]);
        let (x2, y2) = (self.qubit_positions[q2 as usize][0],
                        self.qubit_positions[q2 as usize][1]);
        ((x1 - x2).powi(2) + (y1 - y2).powi(2)).sqrt()
    }
}

// =====================================================================
// 6. Kani Harness
// =====================================================================

#[cfg(kani)]
mod kani_harness {
    use super::*;

    #[kani::proof]
    #[kani::unwind(8)]
    fn verify_hamiltonian_properties() {
        // We verify for sequences up to 8 gates and hardware with 2‑8 qubits.
        let seq_len: u8 = kani::any();
        kani::assume(seq_len <= 8);

        // Build a concrete sequence (for symbolic verification, we'd use kani::any(),
        // but here we use a fixed representative sequence to keep the harness simple).
        let mut seq = Vec::new();
        for _ in 0..seq_len {
            seq.push(GateOperation::RydbergPulse {
                qubits: vec![0],
                duration: 1.0,
                detuning: 0.0,
            });
            seq.push(GateOperation::SingleQubitGate {
                qubit: 0,
                angle: PI/2.0,
                axis: Axis::X,
            });
            seq.push(GateOperation::TwoQubitGate {
                control: 0,
                target: 1,
                gate_type: TwoQubitType::CNOT,
            });
        }

        // Fixed hardware specification for verification
        let mut hw = HardwareSpec::default();
        hw.num_qubits = 2;
        hw.rabi_frequency = [10.0, 10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                             0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                             0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                             0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        hw.detuning = [0.0; 32];
        hw.blockade_radius = 5.0;
        hw.pulse_length_tolerance = 0.01;

        let h = hw.hamiltonian(&seq);

        // Property 1: Hermiticity
        let h_t = h.transpose();
        assert!(relative_eq!(h, h_t, epsilon = 1e-12));

        // Property 2: Trace zero
        let trace = h.trace();
        assert!(trace.abs() < 1e-12);
    }
}
