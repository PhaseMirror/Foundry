use universal_logic::algebras::classical::ClassicalLogic;
use universal_logic::algebras::fuzzy::FuzzyLogic;
use universal_logic::algebras::heyting::{HeytingElement, HeytingLogic};
use universal_logic::algebras::modal::KripkeFrame;
use universal_logic::algebras::quantum::QuantumEffect;

#[test]
fn test_classical_and_fuzzy_laws() {
    assert_eq!(ClassicalLogic::not(true), false);
    assert_eq!(ClassicalLogic::implies(true, false), false);

    // Fuzzy MV
    assert!((FuzzyLogic::mv_and(0.7, 0.5) - 0.2).abs() < 1e-6);
    assert!((FuzzyLogic::mv_or(0.7, 0.5) - 1.0).abs() < 1e-6);

    // Fuzzy Gödel
    assert_eq!(FuzzyLogic::godel_and(0.8, 0.3), 0.3);
    assert_eq!(FuzzyLogic::godel_or(0.8, 0.3), 0.8);
}

#[test]
fn test_heyting_and_modal_logic() {
    let a = HeytingElement(40);
    let b = HeytingElement(70);
    assert_eq!(HeytingLogic::implies(a, b), HeytingLogic::TOP);
    assert_eq!(HeytingLogic::implies(b, a), a);

    let mut frame = KripkeFrame::new(2);
    frame.set_accessible(0, 1);
    assert!(frame.box_op(0, &[true, true]));
    assert!(!frame.box_op(0, &[true, false]));
}

#[test]
fn test_quantum_effect_algebra() {
    let e = QuantumEffect::new(0.8, 0.1, 0.8).project_effect();
    let not_e = e.not().project_effect();
    assert!((not_e.a - 0.2).abs() < 1e-6);

    let f = QuantumEffect::identity();
    let mean = e.kubo_ando_geometric_mean(&f).project_effect();
    assert!(mean.a >= 0.0 && mean.a <= 1.0);
    assert!(mean.c >= 0.0 && mean.c <= 1.0);
}
