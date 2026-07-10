use apex_hologram::{HologramCircuit, PhiAddress, RecursiveProof, AtlasEmbeddingProof};
use apex_goldilocks_core::boundary_lattice::LatticeElement;
use goldilocks::GoldilocksField;

#[test]
fn test_hologram_phi_resolution() {
    let mut circuit = HologramCircuit::new(12288);
    let element = LatticeElement::new(10, 20);
    let addr = PhiAddress::from_lattice(element);
    
    circuit.cells[addr.0 as usize] = GoldilocksField::new(1337);
    
    let resolved = circuit.resolve(addr).unwrap();
    assert_eq!(resolved, GoldilocksField::new(1337));
}

#[test]
fn test_recursive_proof_chain() {
    let initial_hash = [1u8; 32];
    let proof_0 = RecursiveProof::new_initial(initial_hash);
    
    let next_hash = [2u8; 32];
    let proof_1 = proof_0.recurse(next_hash);
    
    assert_eq!(proof_1.layer, 1);
    assert_eq!(proof_1.root_hash, next_hash);
    assert_eq!(proof_1.prev_proof.unwrap().root_hash, initial_hash);
}

#[test]
fn test_aep_structure() {
    let initial_hash = [0xAA; 32];
    let proof = RecursiveProof::new_initial(initial_hash);
    let aep = AtlasEmbeddingProof {
        proof,
        domain_tag: 0x99,
    };
    
    assert_eq!(aep.domain_tag, 0x99);
}
