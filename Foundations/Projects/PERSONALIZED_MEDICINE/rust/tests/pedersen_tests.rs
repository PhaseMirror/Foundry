use personalized_medicine::bn254::Bn254;
use personalized_medicine::pedersen::PedersenEngine;
use num_bigint::BigUint;

#[test]
fn test_h_new_computation_and_subgroup() {
    let h_new = PedersenEngine::compute_h_new();
    assert!(Bn254::is_on_curve(&h_new), "H_new must be on curve");
    assert!(Bn254::is_in_subgroup(&h_new), "H_new must be in subgroup");
}

#[test]
fn test_pedersen_commitment_and_opening() {
    let h_new = PedersenEngine::compute_h_new();
    let preimage = "n=(1,0,0)|y_digest=conc:10|ctx=pm-v3-audit";
    let (v, _sha) = PedersenEngine::derive_v_scalar(preimage);
    let r: BigUint = "987654321098765432109876543210".parse().unwrap();

    let c = PedersenEngine::commit(&v, &r, &h_new);
    assert!(Bn254::is_on_curve(&c));
    assert!(PedersenEngine::verify_opening(&c, &v, &r, &h_new));

    // Wrong opening should fail
    let wrong_v = &v + 1u32;
    assert!(!PedersenEngine::verify_opening(&c, &wrong_v, &r, &h_new));
}
