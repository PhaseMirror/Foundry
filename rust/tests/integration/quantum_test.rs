#[cfg(test)]
mod tests {
    use prime_rust::quantum_backend::{fidelity_bound, rydberg_interaction_strength};
    use prime_rust::partial_system::{HardwareSpec, GateOperation, Axis, MAX_QUBITS};
    use prime_rust::associator::{associator_defect, binary_residual};

    #[test]
    fn test_fidelity_bound_identity() {
        let hw = HardwareSpec::default();
        let gate = GateOperation::Identity;
        let fidelity = fidelity_bound(&gate, &hw);
        assert!(fidelity > 0.0);
        assert!(fidelity <= 1.0);
    }

    #[test]
    fn test_fidelity_bound_single_qubit() {
        let mut hw = HardwareSpec::default();
        hw.leakage_rate = 0.01;
        hw.decoherence_rate = 100.0;

        let gate = GateOperation::SingleQubitGate {
            qubit: 0,
            angle: std::f64::consts::PI,
            axis: Axis::X,
        };
        let fidelity = fidelity_bound(&gate, &hw);
        assert!(fidelity > 0.0);
        assert!(fidelity <= 1.0);
    }

    #[test]
    fn test_rydberg_interaction_far() {
        let mut hw = HardwareSpec::default();
        hw.qubit_positions[0] = [0.0, 0.0];
        hw.qubit_positions[1] = [100.0, 0.0];
        hw.blockade_interaction[0][1] = 1.0;

        let strength = rydberg_interaction_strength(&hw, 0, 1);
        assert!(strength < 0.001);
    }

    #[test]
    fn test_rydberg_interaction_close() {
        let mut hw = HardwareSpec::default();
        hw.qubit_positions[0] = [0.0, 0.0];
        hw.qubit_positions[1] = [1.0, 0.0];
        hw.blockade_interaction[0][1] = 1.0;

        let strength = rydberg_interaction_strength(&hw, 0, 1);
        assert!(strength > 0.0);
    }

    #[test]
    fn test_associator_defect_non_negative() {
        let hw = HardwareSpec::default();
        let x = GateOperation::SingleQubitGate { qubit: 0, angle: 1.0, axis: Axis::X };
        let y = GateOperation::SingleQubitGate { qubit: 1, angle: 1.0, axis: Axis::Y };
        let z = GateOperation::SingleQubitGate { qubit: 0, angle: 0.5, axis: Axis::Z };

        let delta = associator_defect::<8>(&x, &y, &z, &hw);
        assert!(delta >= 0.0);
    }

    #[test]
    fn test_binary_residual_non_negative() {
        let hw = HardwareSpec::default();
        let x = GateOperation::SingleQubitGate { qubit: 0, angle: 1.0, axis: Axis::X };
        let y = GateOperation::SingleQubitGate { qubit: 1, angle: 1.0, axis: Axis::Y };

        let residual = binary_residual(&x, &y, &hw);
        assert!(residual >= 0.0);
    }
}
