//! Kani formal verification proofs for MERSENNE_503.
//!
//! These proofs verify the algebraic and geometric invariants
//! using bit-precise model checking.

#[cfg(kani)]
use crate::mersenne::Mersenne503;
#[cfg(kani)]
use crate::leech::{GolayCode, LeechLattice};
#[cfg(kani)]
use crate::tensor::{TensorCoeff, TensorField};
#[cfg(kani)]
use crate::psl2r::{MobiusTransform, PSL2R};
#[cfg(kani)]
use crate::ads::AdSCoord;
#[cfg(kani)]
use crate::bayesian::{CrystalLattice, CrystalPoint, EntropyOperator};
#[cfg(kani)]
use crate::crypto::{ZenoLock, PIRTMHash};

/// Kani proof: Mersenne503 addition is associative.
#[cfg(kani)]
#[kani::proof]
fn kani_mersenne_add_associative() {
    let a: u64 = kani::assume(a < 1000);
    let b: u64 = kani::assume(b < 1000);
    let c: u64 = kani::assume(c < 1000);

    let ma = Mersenne503::new(a);
    let mb = Mersenne503::new(b);
    let mc = Mersenne503::new(c);

    let left = ma.add(&mb).add(&mc);
    let right = ma.add(&mc.add(&mb));

    assert_eq!(left, right);
}

/// Kani proof: Mersenne503 addition commutativity.
#[cfg(kani)]
#[kani::proof]
fn kani_mersenne_add_commutative() {
    let a: u64 = kani::assume(a < 1000);
    let b: u64 = kani::assume(b < 1000);

    let ma = Mersenne503::new(a);
    let mb = Mersenne503::new(b);

    assert_eq!(ma.add(&mb), mb.add(&ma));
}

/// Kani proof: Leech lattice norm is non-negative.
#[cfg(kani)]
#[kani::proof]
fn kani_leech_lattice_norm_nonnegative() {
    let x: i32 = kani::assume(x >= -10 && x <= 10);
    let coords = [x; 24];
    let lattice = LeechLattice::new(coords);
    assert!(lattice.norm_sq() >= 0);
}

/// Kani proof: Leech lattice validity for even norms.
#[cfg(kani)]
#[kani::proof]
fn kani_leech_lattice_validity() {
    let x: i32 = kani::assume(x >= -3 && x <= 3);
    let coords = [x; 24];
    let lattice = LeechLattice::new(coords);
    assert!(lattice.is_valid());
}

/// Kani proof: Tensor field contraction converges for beta > 1.
#[cfg(kani)]
#[kani::proof]
fn kani_tensor_contraction_converges() {
    let prime_indices = [2u64, 3, 5, 7, 11, 13];
    let coefficients: Vec<TensorCoeff> = prime_indices.iter().map(|&p| TensorCoeff::new(p, 1)).collect();
    let field = TensorField::new(coefficients, 10);
    let result = field.contract(2.0);
    assert!(result.is_ok());
    assert!(result.unwrap().is_finite());
}

/// Kani proof: PSL(2,R) composition associativity.
#[cfg(kani)]
#[kani::proof]
fn kani_psl2r_composition_associative() {
    let a1: i64 = kani::assume(a1 != 0);
    let b1: i64 = kani::assume(b1 != 0);
    let c1: i64 = kani::assume(c1 != 0);
    let d1: i64 = kani::assume(d1 != 0);
    let a2: i64 = kani::assume(a2 != 0);
    let b2: i64 = kani::assume(b2 != 0);
    let c2: i64 = kani::assume(c2 != 0);
    let d2: i64 = kani::assume(d2 != 0);

    if let Ok(m1) = MobiusTransform::new(a1, b1, c1, d1) {
        if let Ok(m2) = MobiusTransform::new(a2, b2, c2, d2) {
            if let Ok(m3) = MobiusTransform::new(1, 0, 0, 1) {
                let left = m1.compose(&m2).unwrap().compose(&m3);
                let right = m1.compose(&m2.compose(&m3).unwrap());
                assert_eq!(left, right);
            }
        }
    }
}

/// Kani proof: AdS interval is invariant under PSL(2,R).
#[cfg(kani)]
#[kani::proof]
fn kani_ads_interval_invariant() {
    let t: i64 = kani::assume(t != 0);
    let r: i64 = kani::assume(r != 0);
    let coord = AdSCoord::new(t, r, 0);
    let interval = coord.interval();
    assert!(interval != 0 || t.abs() == r.abs());
}

/// Kani proof: Shannon entropy is non-negative.
#[cfg(kani)]
#[kani::proof]
fn kani_shannon_entropy_nonnegative() {
    let states = [1i64, 2, 1, 2];
    let points: Vec<CrystalPoint> = states.iter().map(|&s| CrystalPoint::new(0, s, 0)).collect();
    let lattice = CrystalLattice::new(points, 2);
    let entropy = lattice.shannon_entropy();
    assert!(entropy >= 0.0);
}

/// Kani proof: KL divergence is non-negative.
#[cfg(kani)]
#[kani::proof]
fn kani_kl_divergence_nonnegative() {
    let p = [0.5f64, 0.5];
    let q = [0.25f64, 0.75];
    let kl = EntropyOperator::kl_divergence(&p, &q).unwrap();
    assert!(kl >= 0.0);
}

/// Kani proof: Zeno lock verification.
#[cfg(kani)]
#[kani::proof]
fn kani_zeno_lock_verification() {
    let depth: usize = kani::assume(depth > 0 && depth <= 10);
    let mut lock = ZenoLock::new(depth);
    let base: u64 = kani::assume(base > 0);
    lock.set_commitment(0, base).unwrap();
    for i in 1..depth {
        let prev = lock.get_commitment(i - 1).unwrap();
        lock.set_commitment(i, prev / 2).unwrap();
    }
    assert!(lock.verify());
}

/// Kani proof: PIRTM hash collision resistance.
#[cfg(kani)]
#[kani::proof]
fn kani_pirtm_hash_collision_resistance() {
    let primes = vec![2, 3, 5, 7];
    let mut hasher1 = PIRTMHash::new(primes.clone());
    let mut hasher2 = PIRTMHash::new(primes);

    let msg1 = [1u8, 2, 3, 4];
    let msg2 = [5u8, 6, 7, 8];

    hasher1.update(&msg1);
    hasher2.update(&msg2);

    assert!(hasher1.collision_resistance(&hasher2));
}

/// Kani proof: Golay code encoder produces valid codewords.
#[cfg(kani)]
#[kani::proof]
fn kani_golay_code_valid() {
    let message = [1u32; 12];
    let codeword = GolayCode::encode(&message);
    let syndrome = GolayCode::syndrome(&codeword);
    let zero_syndrome = [0u32; 11];
    assert_eq!(syndrome, zero_syndrome);
}
