#[cfg(test)]
mod authority_tests {
    use crate::authority::{ratify_velocity, JurisdictionalGuard};
    use crate::constitutional::{
        ArticleII, Articles, ConstitutionalParameters, DriftFloor, Enforcement,
    };
    use std::collections::HashMap;

    // Helper to provide context if needed, though ratify_velocity doesn't currently use params.
    // Included for future-proofing as the runtime becomes fully constitutional-aware.
    fn get_mock_params() -> ConstitutionalParameters {
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
                        precision_forms: HashMap::new(),
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
    fn test_ratify_velocity_quebec() {
        assert_eq!(
            ratify_velocity("EXECUTE", "CUSTODIAN_QC", Some("CA-QC")),
            "EXECUTE"
        );
        assert_eq!(ratify_velocity("STOP", "POLICY_QC", Some("CA-QC")), "PAUSE");
        assert_eq!(
            ratify_velocity("PROCEED", "ADVISORY", Some("CA-QC")),
            "PAUSE"
        );
    }

    #[test]
    fn test_jurisdictional_guard_accepts_mapped_authority() {
        assert!(JurisdictionalGuard::verify("CUSTODIAN_CA_FED"));
    }

    #[test]
    fn test_ratify_interaction_preserves_custodian_velocity() {
        assert_eq!(
            ratify_velocity("ESCALATE", "CUSTODIAN_CA_DEFENCE", None),
            "ESCALATE"
        );
    }
}
