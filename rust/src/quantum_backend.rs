use super::partial_system::{GateOperation, HardwareSpec};

#[derive(Clone, Debug)]
pub struct HamiltonianCoefficients {
    pub rabi: f64,
    pub detuning: f64,
    pub phase: f64,
}

pub fn single_qubit_hamiltonian(gate: &GateOperation, hw: &HardwareSpec) -> HamiltonianCoefficients {
    match gate {
        GateOperation::SingleQubitGate { qubit, angle, axis } => {
            let q = *qubit as usize;
            HamiltonianCoefficients {
                rabi: hw.rabi_frequency[q] * angle.cos(),
                detuning: hw.detuning[q],
                phase: match axis {
                    super::partial_system::Axis::X => 0.0,
                    super::partial_system::Axis::Y => std::f64::consts::FRAC_PI_2,
                    super::partial_system::Axis::Z => std::f64::consts::PI,
                },
            }
        }
        GateOperation::RydbergPulse { qubits, active, duration: _, detuning } => {
            let avg_rabi: f64 = qubits[..*active as usize]
                .iter()
                .map(|&q| hw.rabi_frequency[q as usize])
                .sum::<f64>()
                / (*active as f64);
            HamiltonianCoefficients {
                rabi: avg_rabi,
                detuning: *detuning,
                phase: 0.0,
            }
        }
        _ => HamiltonianCoefficients { rabi: 0.0, detuning: 0.0, phase: 0.0 },
    }
}

pub fn fidelity_bound(gate: &GateOperation, hw: &HardwareSpec) -> f64 {
    let coeffs = single_qubit_hamiltonian(gate, hw);
    let rabi_bound = coeffs.rabi.abs();
    let detuning_bound = coeffs.detuning.abs();
    let leakage = hw.leakage_rate;
    let dephasing = 1.0 - (-hw.decoherence_rate * 0.001).exp();

    1.0 - leakage - dephasing - (rabi_bound * 0.001) - (detuning_bound * 0.0001)
}

pub fn rydberg_interaction_strength(
    hw: &HardwareSpec,
    q1: u8,
    q2: u8,
) -> f64 {
    let dist = hw.distance_between(q1, q2);
    if dist <= 0.0 {
        return f64::INFINITY;
    }
    hw.blockade_interaction[q1 as usize][q2 as usize] / dist.powi(6)
}
