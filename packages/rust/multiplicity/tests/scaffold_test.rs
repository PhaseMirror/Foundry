use multiplicity_moc::N108Scaffold;
use nalgebra::DVector;

#[test]
fn test_n108_scaffold_stability() {
    let scaffold = N108Scaffold::new(32, 0.82).unwrap();
    let initial_state = DVector::from_element(32, 1.0);
    
    let result = scaffold.execute_n108_cycle(&initial_state).unwrap();
    
    // Contraction check: norm should decrease
    assert!(result.norm() < initial_state.norm());
    println!("Initial Norm: {}, Final Norm: {}", initial_state.norm(), result.norm());
}

#[test]
fn test_n108_stability_budget_enforcement() {
    // Budget >= 1.0 should fail
    let result = N108Scaffold::new(32, 1.0);
    assert!(result.is_err());
}
