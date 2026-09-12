#[cfg(test)]
mod stress_tests {
    use crate::constitutional::{
        ArticleII, Articles, ConstitutionalParameters, DriftFloor, Enforcement,
    };
    use crate::InvariantRegistry;
    use crate::Thresholds;
    use std::collections::HashMap;

    fn get_mock_params() -> ConstitutionalParameters {
        let mut precision_forms = HashMap::new();
        precision_forms.insert("FACT".to_string(), 0.085);
        ConstitutionalParameters {
            schema_version: "0.1.0".to_string(),
            constitution_ref: "test".to_string(),
            ratified: "2026-05-25".to_string(),
            supersedes: None,
            articles: Articles {
                ii: ArticleII {
                    drift_floor: DriftFloor {
                        delta_c: 0.17,
                        classification: "ANCHOR".to_string(),
                        provenance_adr: "test".to_string(),
                        precision_forms,
                        override_policy: "PROHIBITED".to_string(),
                    },
                },
            },
            enforcement: Enforcement {
                on_breach: "COLLAPSE".to_string(),
                error_codes: HashMap::new(),
                audit_frequency_ms: None,
            },
        }
    }

    #[test]
    fn test_thresholds_from_constitutional() {
        let params = get_mock_params();
        let thresholds = Thresholds::from_constitutional(&params);
        assert_eq!(thresholds.tau_r, 0.17);
        assert!(thresholds.validate().is_ok());
    }

    #[test]
    fn test_thresholds_default() {
        let thresholds = Thresholds::default();
        assert!(thresholds.validate().is_ok());
    }

    #[test]
    fn test_drift_pressure_enforcement() {
        let params = get_mock_params();
        let thresholds = Thresholds::from_constitutional(&params);
        let authority = "CUSTODIAN_CA_FED";
        let form = "ADVISORY";

        for i in 1..17 {
            let drift = i as f64 * 0.01;
            let result =
                InvariantRegistry::audit_drift_with_thresholds(&thresholds, authority, form, drift);
            assert!(result.is_ok(), "Drift {} should be stable", drift);
        }

        let breach_drift = 0.18;
        let result = InvariantRegistry::audit_drift_with_thresholds(
            &thresholds,
            authority,
            form,
            breach_drift,
        );
        assert_eq!(result.unwrap_err(), "TOPOLOGICAL_DRIFT_EXCEEDED");
    }

    #[test]
    fn test_fact_form_precision_pressure() {
        let params = get_mock_params();
        let thresholds = Thresholds::from_constitutional(&params);
        let authority = "CUSTODIAN_CA_FED";
        let form = "FACT";

        let stable_drift = 0.08;
        assert!(InvariantRegistry::audit_drift_with_thresholds(
            &thresholds,
            authority,
            form,
            stable_drift
        )
        .is_ok());

        let precision_breach = 0.09;
        assert_eq!(
            InvariantRegistry::audit_drift_with_thresholds(
                &thresholds,
                authority,
                form,
                precision_breach
            )
            .unwrap_err(),
            "FACT_PRECISION_VIOLATION"
        );
    }
}
