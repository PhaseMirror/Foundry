use nalgebra::{DMatrix, DVector};
use std::f64::consts::PI;

// ---------- Hardware Parameters (already in your code) ----------
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
            num_qubits: 0,
            qubit_positions: [[0.0; 2]; 32],
            rabi_frequency: [0.0; 32],
            detuning: [0.0; 32],
            blockade_radius: 0.0,
            blockade_interaction: [[0.0; 32]; 32],
            allowed_transitions: [[true; 32]; 32],
            pulse_length_tolerance: 0.1,
            phase_tolerance: 0.1,
            leakage_rate: 0.01,
            decoherence_rate: 100.0,
        }
    }
}

// ---------- Gate Operations (already in your code) ----------
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

impl Default for GateOperation {
    fn default() -> Self {
        GateOperation::Identity
    }
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

#[derive(Clone, Debug)]
pub struct PartialSystem {
    pub vars: u8,
    pub comp_def: [(u8, u8, Option<u8>); 32],
    pub close_def: [(u8, Option<u8>); 32],
    pub gate_terms: [GateOperation; 32],
    pub hardware: HardwareSpec,
}

impl Default for PartialSystem {
    fn default() -> Self {
        const DEFAULT_GATE: GateOperation = GateOperation::Identity;
        Self {
            vars: 0,
            comp_def: [(0, 0, None); 32],
            close_def: [(0, None); 32],
            gate_terms: [DEFAULT_GATE; 32],
            hardware: HardwareSpec::default(),
        }
    }
}

// ---------- Hamiltonian Evaluator ----------
impl HardwareSpec {
    pub fn hamiltonian(&self, sequence: &[GateOperation]) -> DMatrix<f64> {
        let n = self.num_qubits as usize;
        let dim = 1 << n;
        let mut h = DMatrix::zeros(dim, dim);

        for gate in sequence {
            let h_gate = self.gate_hamiltonian(gate);
            h += h_gate;
        }

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
                        let i = DMatrix::identity(1 << self.num_qubits, 1 << self.num_qubits);
                        (PI / 4.0) * (i - z_c) * x_t
                    }
                    TwoQubitType::CZ => {
                        let z_c = self.pauli_z(c);
                        let z_t = self.pauli_z(t);
                        let i = DMatrix::identity(1 << self.num_qubits, 1 << self.num_qubits);
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

    pub fn matrix_exponential(&self, H: &DMatrix<f64>, tau: f64) -> DMatrix<f64> {
        let dim = 1 << self.num_qubits;
        let mut U = DMatrix::identity(dim, dim);
        let mut term = DMatrix::identity(dim, dim);
        let max_terms = 10; // Bounded Taylor expansion for Kani BMC
        
        for k in 1..=max_terms {
            // factor = (-i tau) / k, but since we are using f64 (real),
            // this is a simplified real-exponential analog for BMC verification structure.
            // (Real physics uses complex unitaries, handled here as a simplified real-space projection for Kani)
            let factor = -tau / (k as f64);
            term = &term * H * factor;
            U += &term;
        }
        U
    }

    pub fn evaluate_sequence(&self, seq: &[GateOperation]) -> DMatrix<f64> {
        let dim = 1 << self.num_qubits;
        let mut U = DMatrix::identity(dim, dim);
        for gate in seq {
            let h_gate = self.hamiltonian(&[gate.clone()]);
            let u_gate = self.matrix_exponential(&h_gate, self.pulse_length_tolerance);
            U = u_gate * U;
        }
        U
    }

    pub fn associator_defect(&self, seq1: &[GateOperation], seq2: &[GateOperation]) -> f64 {
        let u1 = self.evaluate_sequence(seq1);
        let u2 = self.evaluate_sequence(seq2);
        (u1 - u2).norm()
    }
}

// ---------- Lawfulness Check ----------
impl PartialSystem {
    pub fn is_composition_lawful(&self, x: u8, y: u8) -> bool {
        let gate_x = self.gate_terms[x as usize].clone();
        let gate_y = self.gate_terms[y as usize].clone();

        if self.hardware.blockade_radius > 0.0 {
            let qubits_x = gate_x.qubits();
            let qubits_y = gate_y.qubits();
            for qx in qubits_x.iter() {
                for qy in qubits_y.iter() {
                    let dist = self.distance_between(*qx, *qy);
                    if dist < self.hardware.blockade_radius {
                        return false;
                    }
                }
            }
        }

        let delta = self.hardware.associator_defect(&[gate_x.clone(), gate_y.clone()], &[gate_y, gate_x]);
        if delta > self.hardware.pulse_length_tolerance {
            return false;
        }

        true
    }

    pub fn distance_between(&self, q1: u8, q2: u8) -> f64 {
        let (x1, y1) = (self.hardware.qubit_positions[q1 as usize][0],
                        self.hardware.qubit_positions[q1 as usize][1]);
        let (x2, y2) = (self.hardware.qubit_positions[q2 as usize][0],
                        self.hardware.qubit_positions[q2 as usize][1]);
        ((x1 - x2).powi(2) + (y1 - y2).powi(2)).sqrt()
    }
}

#[cfg(kani)]
mod kani_harnesses {
    use super::*;

    #[kani::proof]
    fn verify_associator_within_tolerance() {
        let mut hw = HardwareSpec::default();
        hw.num_qubits = 2;
        hw.rabi_frequency = [10.0, 10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        hw.detuning = [0.0; 32];
        hw.blockade_radius = 5.0;
        hw.pulse_length_tolerance = 0.01;

        let mut sys = PartialSystem::default();
        sys.vars = 3;
        sys.hardware = hw;

        let gate0 = GateOperation::RydbergPulse { qubits: vec![0], duration: 1.0, detuning: 0.0 };
        let gate1 = GateOperation::RydbergPulse { qubits: vec![1], duration: 1.0, detuning: 0.0 };
        sys.gate_terms[0] = gate0.clone();
        sys.gate_terms[1] = gate1.clone();

        assert!(sys.is_composition_lawful(0, 1));

        let delta = sys.hardware.associator_defect(&[gate0.clone(), gate1.clone()], &[gate1, gate0]);
        assert!(delta <= sys.hardware.pulse_length_tolerance);
    }
}
