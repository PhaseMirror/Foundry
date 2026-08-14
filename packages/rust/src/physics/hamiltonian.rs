use nalgebra::DMatrix;
use std::f64::consts::PI;

// ---------- Hardware Parameters ----------
#[derive(Clone, Debug)]
pub struct HardwareSpec {
    pub num_qubits: u8,
    pub qubit_positions: [[f64; 2]; 32],          // (x, y) in microns
    pub rabi_frequency: [f64; 32],                // Ω_i (MHz)
    pub detuning: [f64; 32],                      // Δ_i (MHz)
    pub blockade_radius: f64,                     // R_b (microns)
    pub blockade_interaction: [[f64; 32]; 32],    // V_ij (MHz)
    pub allowed_transitions: [[bool; 32]; 32],    // Can we drive |1⟩↔|r⟩?
    pub pulse_length_tolerance: f64,              // ± δt (ns)
    pub phase_tolerance: f64,                     // ± δφ (rad)
    pub leakage_rate: f64,
    pub decoherence_rate: f64,
}

impl Default for HardwareSpec {
    fn default() -> Self {
        Self {
            num_qubits: 0,
            qubit_positions: [[0.0; 2]; 32],
            rabi_frequency: [0.0; 32],
            detuning: [0.0; 32],
            blockade_radius: 5.0,
            blockade_interaction: [[0.0; 32]; 32],
            allowed_transitions: [[false; 32]; 32],
            pulse_length_tolerance: 1.0,
            phase_tolerance: 0.01,
            leakage_rate: 0.001,
            decoherence_rate: 0.1,
        }
    }
}

// ---------- Gate Operations ----------
#[derive(Clone, Debug, PartialEq)]
pub enum Axis {
    X,
    Y,
    Z,
}

#[derive(Clone, Debug, PartialEq)]
pub enum TwoQubitType {
    CNOT,
    CZ,
    SWAP,
}

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

// ---------- Hamiltonian Construction ----------
impl HardwareSpec {
    /// Build the full Hamiltonian for a sequence of gate operations.
    pub fn hamiltonian(&self, sequence: &[GateOperation]) -> DMatrix<f64> {
        let n = self.num_qubits as usize;
        let dim = 1 << n;
        let mut h = DMatrix::zeros(dim, dim);

        for gate in sequence {
            let h_gate = self.gate_hamiltonian(gate);
            h += h_gate;
        }

        // Add static Rydberg blockade interaction
        for i in 0..n {
            for j in (i+1)..n {
                if self.blockade_interaction[i][j] != 0.0 {
                    let v_ij = self.blockade_interaction[i][j];
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

    /// Compute the Hamiltonian for a single gate operation.
    fn gate_hamiltonian(&self, gate: &GateOperation) -> DMatrix<f64> {
        match gate {
            GateOperation::Identity => DMatrix::zeros(1 << self.num_qubits, 1 << self.num_qubits),
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
                        (PI / 4.0) * ((DMatrix::identity(1 << self.num_qubits, 1 << self.num_qubits) - z_c) * x_t)
                    }
                    TwoQubitType::CZ => {
                        let z_c = self.pauli_z(c);
                        let z_t = self.pauli_z(t);
                        (PI / 4.0) * (DMatrix::identity(1 << self.num_qubits, 1 << self.num_qubits) - z_c) * (DMatrix::identity(1 << self.num_qubits, 1 << self.num_qubits) - z_t)
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
            GateOperation::RydbergPulse { qubits, detuning, .. } => {
                let mut h = DMatrix::zeros(1 << self.num_qubits, 1 << self.num_qubits);
                for q in qubits {
                    let q = *q as usize;
                    let omega = self.rabi_frequency[q];
                    let delta = *detuning + self.detuning[q];
                    let sigma_x = self.pauli_x(q);
                    let sigma_z = self.pauli_z(q);
                    h += (omega / 2.0) * sigma_x + (delta / 2.0) * sigma_z;
                }
                h
            }
        }
    }

    // Pauli matrix generators (Kronecker products)
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

// ---------- Associator Defect ----------
impl HardwareSpec {
    /// Compute the associator defect Δ = || H_{(x∘y)∘z} - H_{x∘(y∘z)} ||_F
    pub fn associator_defect(&self, seq1: &[GateOperation], seq2: &[GateOperation]) -> f64 {
        let h1 = self.hamiltonian(seq1);
        let h2 = self.hamiltonian(seq2);
        (h1 - h2).norm() // Frobenius norm
    }
}
