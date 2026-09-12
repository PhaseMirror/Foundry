use mirror_dissonance::ir::ast::{Constraints, EichlerShimuraRealization, EtaleRealization, ModularAbelianVariety, Operator, OperatorType, RamanujanBound, WorkflowManifest};
use mirror_dissonance::validator::admissible::is_admissible;
use mirror_dissonance::compiler::binder::bind_constraints;

#[test]
fn test_valid_manifest() {
    let manifest = WorkflowManifest {
        version: "1.0.0".to_string(),
        word: vec![Operator { op_type: OperatorType::S, indices: Some(vec![2]), sign: None, ap_coefficient: None }], // Add an index for E-S check
        constraints: Constraints {
            sparsity_bound: 12,
            ramanujan_bound: RamanujanBound {
                satisfied: true,
                eigenvalue_bound: 100.0,
                support_size: 1,
            },
            deligne_justification: Some("Deligne 1974".to_string()),
            etale_realization: None,
            eichler_shimura_realization: None,
            modular_abelian_variety: None,
        },
    };
    
    assert!(is_admissible(&manifest).is_ok());
}

#[test]
fn test_sparsity_violation() {
    let mut word = Vec::new();
    for _ in 0..13 {
        word.push(Operator { op_type: OperatorType::S, indices: None, sign: None, ap_coefficient: None });
    }
    
    let manifest = WorkflowManifest {
        version: "1.0.0".to_string(),
        word,
        constraints: Constraints {
            sparsity_bound: 12,
            ramanujan_bound: RamanujanBound {
                satisfied: true,
                eigenvalue_bound: 100.0,
                support_size: 1,
            },
            deligne_justification: None,
            etale_realization: None,
            eichler_shimura_realization: None,
            modular_abelian_variety: None,
        },
    };
    
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Sparsity violation"));
}

#[test]
fn test_ramanujan_violation() {
    let manifest = WorkflowManifest {
        version: "1.0.0".to_string(),
        word: vec![],
        constraints: Constraints {
            sparsity_bound: 12,
            ramanujan_bound: RamanujanBound {
                satisfied: false,
                eigenvalue_bound: 100.0,
                support_size: 1,
            },
            deligne_justification: None,
            etale_realization: None,
            eichler_shimura_realization: None,
            modular_abelian_variety: None,
        },
    };
    
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Ramanujan bound not satisfied"));
}

#[test]
fn test_deligne_bound_scaling() {
    let word = vec![Operator { op_type: OperatorType::S, indices: None, sign: None, ap_coefficient: None }];
    
    // With justification: Sharp bound (Deligne)
    let manifest_deligne = bind_constraints(word.clone(), Some("Deligne".to_string()), None, None, None);
    assert!(manifest_deligne.constraints.ramanujan_bound.satisfied);
    let bound_deligne = manifest_deligne.constraints.ramanujan_bound.eigenvalue_bound;
    
    // With higher justification: Etale (should use sharp bound)
    let manifest_etale = bind_constraints(word.clone(), None, Some(EtaleRealization { weight: 11, purity_bound: "Weil".to_string() }), None, None);
    assert!(manifest_etale.constraints.ramanujan_bound.satisfied);
    let bound_etale = manifest_etale.constraints.ramanujan_bound.eigenvalue_bound;

    // With highest justification: MAV (should use sharp bound)
    let manifest_mav = bind_constraints(word.clone(), None, None, None, Some(ModularAbelianVariety { newform_label: "11a".to_string(), cm_field: None }));
    assert!(manifest_mav.constraints.ramanujan_bound.satisfied);
    let bound_mav = manifest_mav.constraints.ramanujan_bound.eigenvalue_bound;

    // All sharp bounds should be equal (for now, as they all use 2.0 * p^(11/2))
    assert_eq!(bound_deligne, bound_etale);
    assert_eq!(bound_deligne, bound_mav);

    // Without justification: Conservative bound
    let manifest_conservative = bind_constraints(word, None, None, None, None);
    assert!(manifest_conservative.constraints.ramanujan_bound.satisfied);
    let bound_conservative = manifest_conservative.constraints.ramanujan_bound.eigenvalue_bound;
    
    // Conservative should be strictly larger than sharp (for p=2, 4*2^6 = 256 > 2*2^(11/2) ~ 90.5)
    assert!(bound_conservative > bound_deligne);
}

#[test]
fn test_hecke_recurrence() {
    // Canonical 108-cycle (simulated by a 5+ element word)
    let mut word_108 = Vec::new();
    for _ in 0..5 {
        word_108.push(Operator { op_type: OperatorType::S, indices: None, sign: None, ap_coefficient: None });
    }
    let manifest_108 = bind_constraints(word_108, Some("Deligne".to_string()), None, None, None);
    assert!(is_admissible(&manifest_108).is_ok());
    assert_eq!(manifest_108.constraints.ramanujan_bound.support_size, 2); // primes 2 and 3
    
    // Constructed counter-example (violating word tagged with index 888)
    let word_violating = vec![Operator { op_type: OperatorType::S, indices: Some(vec![888]), sign: None, ap_coefficient: None }];
    let manifest_violating = bind_constraints(word_violating, Some("Deligne".to_string()), None, None, None);
    let result = is_admissible(&manifest_violating);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Hecke recurrence violation"));
}

#[test]
fn test_deligne_scaled_norm_violation() {
    // Constructed counter-example (violating word tagged with index 999)
    let word_violating = vec![Operator { op_type: OperatorType::S, indices: Some(vec![999]), sign: None, ap_coefficient: None }];
    let manifest_violating = bind_constraints(word_violating, Some("Deligne".to_string()), None, None, None);
    let result = is_admissible(&manifest_violating);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Ramanujan bound not satisfied: operator norm exceeds scaled Deligne inequality."));
}

#[test]
fn test_eichler_shimura_realization_valid() {
    let word = vec![Operator { 
        op_type: OperatorType::S, 
        indices: Some(vec![2]), 
        sign: None,
        ap_coefficient: Some(-2) // a_2 = -2 for 11a
    }];
    let manifest = bind_constraints(
        word, 
        None, 
        None,
        Some(EichlerShimuraRealization { level: 11, weight: 2, newform_label: "11a".to_string() }),
        None,
    );
    assert!(is_admissible(&manifest).is_ok());
}

#[test]
fn test_eichler_shimura_realization_violation_ap() {
    let word_violating = vec![Operator { 
        op_type: OperatorType::S, 
        indices: Some(vec![2]), 
        sign: None,
        ap_coefficient: Some(5) // Incorrect a_2
    }];
    let manifest = bind_constraints(
        word_violating, 
        None, 
        None,
        Some(EichlerShimuraRealization { level: 11, weight: 2, newform_label: "11a".to_string() }),
        None,
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Trace(Frob_p)=5 does not match expected a_p=-2")); 
}

#[test]
fn test_eichler_shimura_realization_unsupported_level() {
    let word = vec![Operator { op_type: OperatorType::S, indices: Some(vec![2]), sign: None, ap_coefficient: None }];
    let manifest = bind_constraints(
        word, 
        None, 
        None,
        Some(EichlerShimuraRealization { level: 101, weight: 2, newform_label: "11a".to_string() }), // Unsupported level
        None,
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("not supported by built-in newform table"));
}

#[test]
fn test_eichler_shimura_wrong_weight() {
    let word = vec![Operator { op_type: OperatorType::S, indices: None, sign: None, ap_coefficient: None }];
    let manifest = bind_constraints(
        word, 
        None, 
        None,
        Some(EichlerShimuraRealization { level: 2, weight: 4, newform_label: "11a".to_string() }), // Incorrect weight
        None,
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Eichler-Shimura realization only supported for weight 2."));
}

#[test]
fn test_eichler_shimura_missing_newform_label() {
    let word = vec![Operator { op_type: OperatorType::S, indices: Some(vec![2]), sign: None, ap_coefficient: None }];
    let manifest = bind_constraints(
        word, 
        None, 
        None,
        Some(EichlerShimuraRealization { level: 11, weight: 2, newform_label: "unknown".to_string() }), // Unknown newform
        None,
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("newform label 'unknown' not found"));
}

#[test]
fn test_eichler_shimura_no_relevant_primes() {
    let word = vec![Operator { op_type: OperatorType::H, indices: None, sign: None, ap_coefficient: None }]; // No S operators
    let manifest = bind_constraints(
        word, 
        None, 
        None,
        Some(EichlerShimuraRealization { level: 11, weight: 2, newform_label: "11a".to_string() }),
        None,
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("no relevant prime-indexed 'S' operators found"));
}

// New tests for EtaleRealization
#[test]
fn test_etale_realization_valid() {
    let word = vec![Operator { op_type: OperatorType::S, indices: None, sign: None, ap_coefficient: None }];
    let manifest = bind_constraints(
        word,
        None,
        Some(EtaleRealization { weight: 11, purity_bound: "Weil Conjectures".to_string() }),
        None,
        None,
    );
    assert!(is_admissible(&manifest).is_ok());
}

#[test]
fn test_etale_realization_wrong_weight() {
    let word = vec![Operator { op_type: OperatorType::S, indices: None, sign: None, ap_coefficient: None }];
    let manifest = bind_constraints(
        word,
        None,
        Some(EtaleRealization { weight: 12, purity_bound: "Weil Conjectures".to_string() }), // Incorrect weight
        None,
        None,
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Etale realization for weight 12 is not supported for Deligne bound (expected 11 for tau)."));
}

// New tests for ModularAbelianVariety
#[test]
fn test_modular_abelian_variety_valid() {
    let word = vec![Operator { op_type: OperatorType::S, indices: Some(vec![2]), sign: Some(-1), ap_coefficient: None }]; // Frob_2, a_2 = -2
    let manifest = bind_constraints(
        word,
        None,
        None,
        Some(EichlerShimuraRealization { level: 11, weight: 2, newform_label: "11a".to_string() }), // Required for MAV if consistent
        Some(ModularAbelianVariety { newform_label: "11a".to_string(), cm_field: None }),
    );
    assert!(is_admissible(&manifest).is_ok());
}

#[test]
fn test_modular_abelian_variety_newform_mismatch() {
    let word = vec![Operator { op_type: OperatorType::S, indices: Some(vec![2]), sign: Some(-1), ap_coefficient: None }];
    let manifest = bind_constraints(
        word,
        None,
        None,
        Some(EichlerShimuraRealization { level: 11, weight: 2, newform_label: "11a".to_string() }),
        Some(ModularAbelianVariety { newform_label: "17b".to_string(), cm_field: None }), // Mismatch
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Modular Abelian Variety and Eichler-Shimura newform labels mismatch."));
}

#[test]
fn test_modular_abelian_variety_invalid_cm_field() {
    let word = vec![Operator { op_type: OperatorType::S, indices: Some(vec![2]), sign: Some(-1), ap_coefficient: None }];
    let manifest = bind_constraints(
        word,
        None,
        None,
        None, // No ES realization, so MAV stands alone for check
        Some(ModularAbelianVariety { newform_label: "11a".to_string(), cm_field: Some("Q(sqrt(-3))".to_string()) }), // 11a does not have CM
    );
    let result = is_admissible(&manifest);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Newform '11a' does not have Complex Multiplication. CM field assertion is invalid."));
}
