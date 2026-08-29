use west_east::csc::{ConsciousSymbol, SymbolRegistry};

#[test]
fn test_symbol_coherence_norm() {
    let sym = ConsciousSymbol::new("yin_yang", 5, vec![(1, 1.0, 0.0), (2, 0.5, 0.0)], (1.0, 0.0), 1.0);
    let coh_sq = sym.compute_coherence_norm_sq();
    let log_5 = 5.0f64.ln();
    let expected = (1.0 * 1.0) / log_5 + (2.0 * 0.25) / log_5;
    assert!((coh_sq - expected).abs() < 1e-6);
}

#[test]
fn test_composite_driver_budget_clamping() {
    let mut registry = SymbolRegistry::new(0.5);
    let sym = ConsciousSymbol::new("large", 3, vec![(1, 10.0, 0.0)], (2.0, 0.0), 1.0);
    registry.register(sym);

    let driver = registry.evaluate_composite_driver(1.0);
    assert!((driver.norm() - 0.5).abs() < 1e-6, "Driver must be clamped to max_budget");
}
