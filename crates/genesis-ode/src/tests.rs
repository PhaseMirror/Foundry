#[cfg(test)]
mod tests {
    use crate::{ScalarCore, SurfaceState};

    #[test]
    fn test_equivalence() {
        let core = ScalarCore::new(0.1, 0.05, 0.1, 0.05, 0.0, 0.01, 0.1).unwrap();
        let state = SurfaceState {
            substrate: "test".to_string(),
            coherence: 0.5,
            stability_threshold: 1.0,
            effective_stress: 0.1,
            grounding: 0.1,
            alignment: 0.1,
            impedance: 1.0,
            kinematic_drag: 0.0,
            timestamp: 0.0,
        };
        
        let next_state = core.step(state, 0.1, 0.2, 0.0);
        
        // Expected values based on python logic
        // dc_dt = (0.1 * (1.0 - 0.5)) + (0.05 * 0.1) - (0.1 * 0.1) + (0.05 * 0.1) - 0.01
        // dc_dt = 0.05 + 0.005 - 0.01 + 0.005 - 0.01 = 0.04
        // new_coherence = 0.5 + 0.04 * 0.1 = 0.504
        
        assert!((next_state.coherence - 0.504).abs() < 1e-6);
    }
}
