use universal_logic::algebras::heyting::HeytingElement;
use universal_logic::algebras::quantum::QuantumEffect;
use universal_logic::fusion::{FusionAlgebra, LogicFusionEngine};

#[test]
fn test_cross_logic_embeddings() {
    assert_eq!(LogicFusionEngine::embed_classical(true), 1.0);
    assert_eq!(LogicFusionEngine::embed_classical(false), 0.0);

    let h = HeytingElement(65);
    assert!((LogicFusionEngine::embed_heyting(h) - 0.65).abs() < 1e-6);

    let q = QuantumEffect::new(0.8, 0.0, 0.6);
    assert!((LogicFusionEngine::embed_quantum_effect(&q) - 0.70).abs() < 1e-6);
}

#[test]
fn test_fusion_operator() {
    let x = 0.6;
    let y = 0.7;
    assert!((LogicFusionEngine::fuse(x, y, FusionAlgebra::MV) - 1.0).abs() < 1e-6);
    assert!((LogicFusionEngine::fuse(x, y, FusionAlgebra::Godel) - 0.7).abs() < 1e-6);
}
