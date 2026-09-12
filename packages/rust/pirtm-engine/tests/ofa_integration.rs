use pirtm_engine::ofa::{EndomorphismRule, OFANumeral};

#[test]
fn test_ofa_numeral_iteration_parity() {
    let initial_value = 0_u64;
    let steps = 5_u64;
    let fusion_hash = String::from("0xdeadbeef_ofa_lattice");

    let numeral = OFANumeral::new(initial_value, fusion_hash.clone());
    let evolved = numeral.iterate(steps);

    assert_eq!(evolved.get_value(), 5);
    println!("Successfully validated OFA-ii iteration invariant: 0 + 5 -> {}", evolved.get_value());
}

#[test]
fn test_endomorphism_contractive_boundary() {
    // Rule with maximal norm bound c = 0.4 (c < 1 constraint)
    let rule = EndomorphismRule::new(String::from("op_zeta_scale"), 1, 0.4);
    
    let sample_norm = 1.5;
    assert!(
        rule.validate_transition(sample_norm),
        "Contractivity boundary check failed: norm expansion detected!"
    );

    let violating_norm = 3.0;
    assert!(
        !rule.validate_transition(violating_norm),
        "Failed to catch expanding transition vector under contractive rule."
    );
}
