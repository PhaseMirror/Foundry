use personalized_medicine::bn254::{Bn254, G1Point};

#[test]
fn test_generator_on_curve() {
    let g = Bn254::generator_g();
    assert!(Bn254::is_on_curve(&g), "Generator G must be on BN254 G1");
}

#[test]
fn test_subgroup_order() {
    let g = Bn254::generator_g();
    let q = Bn254::q();
    let scaled = Bn254::scalar_mul(&g, &q);
    assert_eq!(scaled, G1Point::Infinity, "[q]G must equal Infinity");
}

#[test]
fn test_point_addition_and_doubling() {
    let g = Bn254::generator_g();
    let two_g = Bn254::scalar_mul(&g, &2u32.into());
    let g_plus_g = Bn254::add(&g, &g);
    assert_eq!(two_g, g_plus_g, "2*G must equal G + G");
}
