use west_east::pilot_p11::PilotP11Suite;

#[test]
fn test_pilot_p11_mask_and_symbols() {
    let mask = PilotP11Suite::get_prime_mask();
    assert_eq!(mask.len(), 11);
    assert_eq!(mask, vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]);

    let registry = PilotP11Suite::create_pilot_registry();
    assert_eq!(registry.symbols.len(), 8);

    for sym in registry.symbols.values() {
        assert!(sym.compute_coherence_norm_sq() > 0.0);
    }
}
