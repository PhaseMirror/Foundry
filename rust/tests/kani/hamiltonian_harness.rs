// Kani Harness: Associator Defect Within Tolerance
// Verifies that for declared-lawful sequences, the associator defect remains within tolerance.

#[cfg(test)]
mod tests {
    use super::*;
    use kani::*;

    #[kani::proof]
    fn verify_associator_within_tolerance() {
        let mut hw = HardwareSpec::default();
        hw.num_qubits = 2;
        hw.rabi_frequency = [10.0, 10.0, 0.0, 0.0];
        hw.detuning = [0.0, 0.0, 0.0, 0.0];
        hw.blockade_radius = 5.0;
        hw.pulse_length_tolerance = 0.01;

        let mut sys = PartialSystem::default();
        sys.vars = 4;
        sys.hardware = hw;

        // Define gates
        let h_gate = GateOperation::SingleQubitGate { qubit: 0, angle: PI/2.0, axis: Axis::X };
        let cnot_gate = GateOperation::TwoQubitGate { control: 0, target: 1, gate_type: TwoQubitType::CNOT };

        sys.gate_terms[0] = h_gate;
        sys.gate_terms[1] = cnot_gate;

        // The composition (0,1) should be lawful if associator defect < tolerance
        assert!(sys.is_composition_lawful(0, 1));
    }
}
