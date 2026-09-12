//! Integration tests for MERSENNE_503 framework.
//!
//! These tests verify end-to-end functionality and serve as examples
//! for library consumers.

use mersenne_503::{
    error::Error,
    mersenne::Mersenne503,
    leech::{LeechLattice, GolayCode},
    tensor::{TensorCoeff, TensorField},
    psl2r::{PSL2R, MobiusTransform},
    ads::AdSCoord,
    bayesian::{CrystalLattice, CrystalPoint, EntropyOperator},
    crypto::{ZenoLock, PIRTMHash},
};

#[test]
fn test_mersenne503_arithmetic() {
    let a = Mersenne503::new(100);
    let b = Mersenne503::new(200);
    let c = a.add(&b);
    assert_eq!(c.limb(0), Some(300));

    let d = c.sub(&a);
    assert_eq!(d.limb(0), Some(200));
}

#[test]
fn test_mersenne503_round_trip() {
    let original = Mersenne503::new(0xDEADBEEF);
    let bytes = original.to_bytes();
    let recovered = Mersenne503::from_bytes(&bytes).unwrap();
    assert_eq!(original, recovered);
}

#[test]
fn test_leech_lattice_properties() {
    let coords = [2i32; 24];
    let lattice = LeechLattice::new(coords);
    assert_eq!(lattice.dim(), 24);
    assert!(lattice.is_valid());
    assert!(lattice.norm_sq() > 0);
}

#[test]
fn test_leech_lattice_inner_product() {
    let coords1 = [1i32; 24];
    let coords2 = [2i32; 24];
    let l1 = LeechLattice::new(coords1);
    let l2 = LeechLattice::new(coords2);
    let ip = l1.inner_product(&l2);
    assert_eq!(ip, 24 * 2); // 1*2 * 24
}

#[test]
fn test_golay_code() {
    let message = [1u32; 12];
    let codeword = GolayCode::encode(&message);
    let syndrome = GolayCode::syndrome(&codeword);
    assert_eq!(syndrome, [0u32; 11]);
}

#[test]
fn test_tensor_field_contraction() {
    let coeffs = vec![
        TensorCoeff::new(2, 1),
        TensorCoeff::new(3, 1),
        TensorCoeff::new(5, 1),
    ];
    let field = TensorField::new(coeffs, 10);
    let sum = field.contract(2.0).unwrap();
    assert!(sum.is_finite());
    assert!(sum > 0.0);
}

#[test]
fn test_tensor_field_bounds() {
    let coeffs = vec![
        TensorCoeff::new(2, 5),
        TensorCoeff::new(3, 3),
    ];
    let field = TensorField::new(coeffs, 5);
    assert!(field.verify_bounds());
}

#[test]
fn test_psl2r_identity() {
    let id = PSL2R::identity().unwrap();
    assert_eq!(id.a(), 1);
    assert_eq!(id.d(), 1);
    assert_eq!(id.b(), 0);
    assert_eq!(id.c(), 0);
}

#[test]
fn test_psl2r_compose() {
    let m1 = MobiusTransform::new(2, 1, 1, 1).unwrap(); // det = 2*1 - 1*1 = 1
    let m2 = MobiusTransform::new(1, 0, 0, 1).unwrap(); // identity
    let composed = m1.compose(&m2).unwrap();
    assert!(composed.a() != 0 || composed.d() != 0);
}

#[test]
fn test_ads_coordinates() {
    let coord = AdSCoord::new(3, 2, 0);
    assert_eq!(coord.interval(), -9 + 4);
    assert!(coord.is_bulk());
}

#[test]
fn test_ads_geodesic() {
    let p1 = AdSCoord::new(0, 0, 0);
    let p2 = AdSCoord::new(0, 5, 0);
    assert_eq!(p1.geodesic_distance(&p2), 5.0);
}

#[test]
fn test_crystal_lattice_entropy() {
    let points = vec![
        CrystalPoint::new(0, 1, 5),
        CrystalPoint::new(1, 2, 5),
        CrystalPoint::new(2, 1, 5),
        CrystalPoint::new(3, 2, 5),
    ];
    let lattice = CrystalLattice::new(points, 2);
    let entropy = lattice.shannon_entropy();
    assert!((entropy - f64::ln(2.0)).abs() < 1e-10);
}

#[test]
fn test_entropy_operator_kl() {
    let p = vec![0.5, 0.5];
    let q = vec![0.5, 0.5];
    let kl = EntropyOperator::kl_divergence(&p, &q).unwrap();
    assert!((kl - 0.0).abs() < 1e-10);
}

#[test]
fn test_entropy_operator_mutual_info() {
    let joint = vec![vec![0.25, 0.25], vec![0.25, 0.25]];
    let mi = EntropyOperator::mutual_information(&joint).unwrap();
    // Independent variables have MI = 0
    assert!(mi.abs() < 1e-10);
}

#[test]
fn test_zeno_lock() {
    let mut lock = ZenoLock::new(5);
    lock.set_commitment(0, 16).unwrap();
    lock.set_commitment(1, 8).unwrap();
    lock.set_commitment(2, 4).unwrap();
    lock.set_commitment(3, 2).unwrap();
    lock.set_commitment(4, 1).unwrap();
    assert!(lock.verify());
}

#[test]
fn test_pirtm_hash() {
    let mut hasher = PIRTMHash::new(vec![2, 3, 5, 7]);
    hasher.update(b"test message");
    let digest = hasher.finalize();
    assert!(!digest.iter().all(|&x| x == 0));
}

#[test]
fn test_pirtm_hash_different_inputs() {
    let mut h1 = PIRTMHash::new(vec![2, 3]);
    let mut h2 = PIRTMHash::new(vec![2, 3]);
    h1.update(b"message1");
    h2.update(b"message2");
    assert!(h1.collision_resistance(&h2));
}

#[test]
fn test_error_types() {
    let err = Error::mersenne_field("overflow");
    assert!(err.to_string().contains("overflow"));

    let err2 = Error::crypto_verification("zeno_lock");
    assert!(err2.to_string().contains("zeno_lock"));
}
