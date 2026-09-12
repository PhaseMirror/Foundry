use knot_in_time_core::constitutional::{
    ArticleII, Articles, ConstitutionalParameters, DriftFloor, Enforcement,
};
use knot_in_time_core::{InvariantRegistry, KnotHamiltonian, Thresholds};
use std::collections::HashMap;

fn main() {
    let mut precision_forms = HashMap::new();
    precision_forms.insert("FACT".to_string(), 0.085);
    let params = ConstitutionalParameters {
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
    };

    let knot = KnotHamiltonian::new("3_1".to_string());
    println!("Coherence protection: {}", knot.get_coherence_protection());

    // Legacy API: uses constitutional params directly
    let drift = 0.10;
    match InvariantRegistry::audit_drift(&params, "CUSTODIAN_ITAR", "FACT", drift) {
        Ok(margin) => println!("Legacy audit pass. Margin: {:.4}", margin),
        Err(e) => println!("Legacy audit failed: {}", e),
    }

    // New API: bridge constitutional params to Thresholds
    let thresholds = Thresholds::from_constitutional(&params);
    println!(
        "Thresholds: tau_r={}, l_eff_max={}, contractivity_margin={}",
        thresholds.tau_r, thresholds.l_eff_max, thresholds.contractivity_margin
    );
    match thresholds.validate() {
        Ok(_) => println!("Thresholds validated"),
        Err(e) => println!("Threshold validation failed: {}", e),
    }

    // New API: validate drift against Thresholds
    match InvariantRegistry::audit_drift_with_thresholds(
        &thresholds,
        "CUSTODIAN_ITAR",
        "FACT",
        drift,
    ) {
        Ok(margin) => println!("Threshold-based audit pass. Margin: {:.4}", margin),
        Err(e) => println!("Threshold-based audit failed: {}", e),
    }
}
