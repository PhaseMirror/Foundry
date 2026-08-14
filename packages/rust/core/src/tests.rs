#[cfg(test)]
mod tests {
    use crate::types::{AtomicPrime, SquarefreeComposite, PirtmModulus};
    use crate::mlir_emitter::{MlirEmitter, UNRESOLVED_COUPLING};
    use crate::spectral::SpectralGovernor;
    use nalgebra::DMatrix;

    #[test]
    fn test_merge_coprimality() {
        let p = 7919;
        let q = 7907;
        let emitter = MlirEmitter::new(PirtmModulus::Atomic(AtomicPrime::new(p).unwrap()), 0.05);
        
        let res = emitter.emit_merge(p, q);
        assert!(res.is_ok());
        assert!(res.as_ref().unwrap().contains("pirtm.merge"));

        let res_fail = emitter.emit_merge(p, p);
        assert!(res_fail.is_err());
    }

    #[test]
    fn test_is_squarefree() {
        assert!(SquarefreeComposite::new(15).is_ok());
        assert!(SquarefreeComposite::new(30).is_ok());
        assert!(SquarefreeComposite::new(4).is_err());
        assert!(SquarefreeComposite::new(12).is_err());
        assert!(SquarefreeComposite::new(7919 * 7907).is_ok());
    }

    #[test]
    fn test_mlir_golden_snapshots() {
        let p = AtomicPrime::new(7919).unwrap();
        let emitter = MlirEmitter::new(PirtmModulus::Atomic(p), 0.05);

        let sg = emitter.emit_session_graph(p.value(), UNRESOLVED_COUPLING, None).unwrap_or_default();
        let expected_sg = "  pirtm.session_graph { prime_index = 7919 : i64, gain_matrix = #pirtm.unresolved_coupling, spectral_radius = 1.0000 : f64, stability_margin = 0.0000 : f64 }";
        assert_eq!(sg, expected_sg);

        let merge = emitter.emit_merge(7919, 7907).unwrap();
        let expected_merge = "    %merged = \"pirtm.merge\"(%lhs, %rhs) : (!pirtm.tensor<mod=7919>, !pirtm.tensor<mod=7907>) -> !pirtm.ctensor<mod=62615533>";
        assert_eq!(merge, expected_merge);
    }

    #[test]
    fn test_spectral_small_gain_verifier() {
        let gov = SpectralGovernor::new(2);
        
        let stable_psi = DMatrix::from_row_slice(2, 2, &[
            0.0, 0.5,
            0.5, 0.0
        ]);
        assert!(gov.verify_spectral_small_gain(&stable_psi).is_ok());

        let unstable_psi = DMatrix::from_row_slice(2, 2, &[
            0.0, 1.1,
            1.1, 0.0
        ]);
        assert!(gov.verify_spectral_small_gain(&unstable_psi).is_err());

        assert!(gov.verify_mlir_session_graph(UNRESOLVED_COUPLING).is_err());
    }
}

#[cfg(test)]
mod spectral_tests {
    use crate::spectral::SpectralGovernor;
    use nalgebra::{DMatrix, DVector};

    fn identity_op(_x: &DVector<f64>) -> DVector<f64> {
        _x.clone()
    }

    fn contractive_op(_x: &DVector<f64>) -> DVector<f64> {
        let a = DMatrix::from_row_slice(2, 2, &[0.0, 0.5, 0.5, 0.0]);
        a * _x
    }

    #[test]
    fn spectral_governor_passes_contractivity() {
        let mut gov = SpectralGovernor::new(2);
        let report = gov.analyze(contractive_op);
        assert!(report.contraction_feasible);
        assert!(report.recommended_epsilon > 0.0);
    }

    #[test]
    fn spectral_governor_fails_contractivity() {
        let mut gov = SpectralGovernor::new(2);
        let report = gov.analyze(identity_op);
        assert!(!report.contraction_feasible);
        assert_eq!(report.recommended_epsilon, gov.max_epsilon);
    }

    #[test]
    fn spectral_governor_govern_interface() {
        let mut gov = SpectralGovernor::new(2);
        let (epsilon, op_norm, report) = gov.govern(contractive_op);
        assert!(report.contraction_feasible);
        assert!(epsilon > 0.0);
        assert!(op_norm > 0.0);
    }

    #[test]
    fn test_gershgorin_disks() {
        let matrix = vec![
            vec![0.5, 0.1],
            vec![0.1, 0.5],
        ];
        let cert = SpectralGovernor::gershgorin_disks(&matrix);
        assert!(cert.is_stable);
        assert!(cert.max_radius > 0.0);
    }

    #[test]
    fn test_evaluate_stability_tiered() {
        let stable_matrix = vec![
            vec![0.3, 0.1],
            vec![0.1, 0.3],
        ];
        let result = SpectralGovernor::evaluate_stability(&stable_matrix, 4);
        assert!(result.is_ok());
        
        let boundary_matrix = vec![
            vec![0.98, 0.01],
            vec![0.01, 0.98],
        ];
        assert!(SpectralGovernor::evaluate_stability(&boundary_matrix, 4).is_err());
    }
}