use universal_logic::fts::FreeTypeSignature;

#[test]
fn test_fts_composition_and_conservation() {
    let sig_a = FreeTypeSignature::from_atom("logic.classical", 2);
    let sig_b = FreeTypeSignature::from_atom("logic.fuzzy", 1);
    let sig_c = FreeTypeSignature::from_atom("logic.classical", -2);

    let combined = sig_a.add(&sig_c);
    assert!(combined.weights.is_empty(), "Opposite atoms must cancel to empty signature");

    let sig_total = sig_a.add(&sig_b);
    assert!(FreeTypeSignature::verify_conservation(&sig_a, &sig_b, &sig_total));
    assert!(!FreeTypeSignature::verify_conservation(&sig_a, &sig_b, &sig_a));
}
