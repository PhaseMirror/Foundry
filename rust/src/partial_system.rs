use super::term::MAX_TERMS;

pub const MAX_QUBITS: usize = 4;

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum Axis { X, Y, Z }

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum TwoQubitType { CNOT, CZ, SWAP }

#[derive(Clone, Debug, PartialEq)]
pub enum GateOperation {
    Identity,
    SingleQubitGate { qubit: u8, angle: f64, axis: Axis },
    TwoQubitGate { control: u8, target: u8, gate_type: TwoQubitType },
    RydbergPulse { qubits: [u8; MAX_QUBITS], active: u8, duration: f64, detuning: f64 },
}

impl Default for GateOperation {
    fn default() -> Self {
        GateOperation::Identity
    }
}

impl GateOperation {
    pub fn active_qubits(&self) -> Vec<u8> {
        match self {
            GateOperation::Identity => vec![],
            GateOperation::SingleQubitGate { qubit, .. } => vec![*qubit],
            GateOperation::TwoQubitGate { control, target, .. } => vec![*control, *target],
            GateOperation::RydbergPulse { qubits, active, .. } => {
                qubits[..*active as usize].to_vec()
            }
        }
    }
}

#[derive(Clone, Debug)]
pub struct HardwareSpec {
    pub num_qubits: u8,
    pub qubit_positions: [[f64; 2]; MAX_QUBITS],
    pub rabi_frequency: [f64; MAX_QUBITS],
    pub detuning: [f64; MAX_QUBITS],
    pub blockade_radius: f64,
    pub blockade_interaction: [[f64; MAX_QUBITS]; MAX_QUBITS],
    pub allowed_transitions: [[bool; 2]; MAX_QUBITS],
    pub pulse_length_tolerance: f64,
    pub phase_tolerance: f64,
    pub leakage_rate: f64,
    pub decoherence_rate: f64,
}

impl Default for HardwareSpec {
    fn default() -> Self {
        Self {
            num_qubits: 0,
            qubit_positions: [[0.0; 2]; MAX_QUBITS],
            rabi_frequency: [0.0; MAX_QUBITS],
            detuning: [0.0; MAX_QUBITS],
            blockade_radius: 0.0,
            blockade_interaction: [[0.0; MAX_QUBITS]; MAX_QUBITS],
            allowed_transitions: [[true; 2]; MAX_QUBITS],
            pulse_length_tolerance: 0.1,
            phase_tolerance: 0.1,
            leakage_rate: 0.01,
            decoherence_rate: 100.0,
        }
    }
}

impl HardwareSpec {
    pub fn distance_between(&self, q1: u8, q2: u8) -> f64 {
        let p1 = self.qubit_positions[q1 as usize];
        let p2 = self.qubit_positions[q2 as usize];
        let dx = p1[0] - p2[0];
        let dy = p1[1] - p2[1];
        (dx * dx + dy * dy).sqrt()
    }

    pub fn is_blockaded(&self, q1: u8, q2: u8) -> bool {
        if self.blockade_radius <= 0.0 {
            return false;
        }
        self.distance_between(q1, q2) < self.blockade_radius
    }

    pub fn associator_defect(&self, ops1: &[GateOperation], ops2: &[GateOperation]) -> f64 {
        let mut total = 0.0;
        for op1 in ops1 {
            for op2 in ops2 {
                let q1 = op1.active_qubits();
                let q2 = op2.active_qubits();
                let mut interaction = 0.0;
                for &a in &q1 {
                    for &b in &q2 {
                        let dist = self.distance_between(a, b);
                        if dist > 0.0 {
                            interaction += self.blockade_interaction[a as usize][b as usize] / dist;
                        }
                    }
                }
                total += interaction.abs();
            }
        }
        total
    }
}

#[derive(Clone, Debug)]
pub struct PartialSystem {
    pub vars: u8,
    pub comp_def: [(u8, u8, Option<u8>); MAX_TERMS],
    pub close_def: [(u8, Option<u8>); MAX_TERMS],
    pub gate_terms: [GateOperation; MAX_TERMS],
    pub hardware: HardwareSpec,
}

impl Default for PartialSystem {
    fn default() -> Self {
        const DEFAULT_GATE: GateOperation = GateOperation::Identity;
        Self {
            vars: 0,
            comp_def: [(0, 0, None); MAX_TERMS],
            close_def: [(0, None); MAX_TERMS],
            gate_terms: [DEFAULT_GATE; MAX_TERMS],
            hardware: HardwareSpec::default(),
        }
    }
}

impl PartialSystem {
    pub fn is_composition_lawful(&self, x: u8, y: u8) -> bool {
        let gate_x = &self.gate_terms[x as usize];
        let gate_y = &self.gate_terms[y as usize];

        let qubits_x = gate_x.active_qubits();
        let qubits_y = gate_y.active_qubits();

        if self.hardware.blockade_radius > 0.0 {
            for qx in &qubits_x {
                for qy in &qubits_y {
                    if self.hardware.is_blockaded(*qx, *qy) {
                        return false;
                    }
                }
            }
        }

        for q in qubits_x.iter().chain(qubits_y.iter()) {
            if !self.hardware.allowed_transitions[*q as usize][1] {
                return false;
            }
        }

        let delta = self.hardware.associator_defect(&[gate_x.clone()], &[gate_y.clone()]);
        if delta > self.hardware.pulse_length_tolerance {
            return false;
        }

        true
    }
}
