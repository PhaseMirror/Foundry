use shpa::topological::{FractalTree, TopologicalEngine};

#[test]
fn test_topological_leaf_signature() {
    let leaf = FractalTree::Leaf {
        operator_hash: [0x42; 32],
    };
    let sig = TopologicalEngine::compute_signature(&leaf);
    assert_ne!(sig, [0u8; 32]);
}

#[test]
fn test_topological_permutation_sensitivity() {
    let op = [0xAA; 32];
    let c1 = FractalTree::Leaf {
        operator_hash: [0x11; 32],
    };
    let c2 = FractalTree::Leaf {
        operator_hash: [0x22; 32],
    };

    let tree1 = FractalTree::Node {
        operator_hash: op,
        children: vec![c1.clone(), c2.clone()],
    };
    let tree2 = FractalTree::Node {
        operator_hash: op,
        children: vec![c2.clone(), c1.clone()],
    };

    let sig1 = TopologicalEngine::compute_signature(&tree1);
    let sig2 = TopologicalEngine::compute_signature(&tree2);
    assert_ne!(sig1, sig2, "Swapping children must produce different topological signatures");
}
