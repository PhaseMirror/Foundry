//! # Word Love Contract Assertions (ADR-0031 §4)
//!
//! Runtime assertion framework verifying Word Love contracts in execution engines.

use crate::word_love::{factorize, GematriaScheme, string_gematria, digital_root, SemanticToken, Encoding, Trajectory};

/// Contract check: Verify that standard gematria for Ahavah and Echad equals 13.
pub fn assert_ahavah_echad_standard() -> bool {
    let ahavah_val = string_gematria(GematriaScheme::Standard, "אהבה");
    let echad_val = string_gematria(GematriaScheme::Standard, "אחד");
    ahavah_val == 13 && echad_val == 13
}

/// Contract check: Verify prime factorization invariants for 13 and 4.
pub fn assert_factorization_invariants() -> bool {
    let f13 = factorize(13);
    let f4 = factorize(4);
    f13.omega() == 1 && f13.omega_total() == 1 && f13.val_at(13) == 1 &&
    f4.omega() == 1 && f4.omega_total() == 2 && f4.val_at(2) == 2
}

/// Contract check: Verify orthogonality invariants.
pub fn assert_orthogonality_invariants() -> bool {
    let ahavah = SemanticToken::new("ahavah", "Love", "אהבה", "ahavah", "Love");
    let echad = SemanticToken::new("echad", "One", "אחד", "echad", "Oneness");

    let enc_std = Encoding::new(ahavah.clone(), GematriaScheme::Standard).unwrap();
    let enc_red = Encoding::new(ahavah.clone(), GematriaScheme::Reduced).unwrap();
    let enc_ech = Encoding::new(echad, GematriaScheme::Standard).unwrap();

    let t_std = Trajectory::of_encoding(enc_std);
    let t_red = Trajectory::of_encoding(enc_red);
    let t_ech = Trajectory::of_encoding(enc_ech);

    // Semantic identity != mathematical invariant identity
    (t_std.encoding.token == t_red.encoding.token) &&
    (t_std.invariant != t_red.invariant) &&
    // Mathematical invariant identity != semantic identity
    (t_std.invariant == t_ech.invariant) &&
    (t_std.encoding.token != t_ech.encoding.token)
}

/// Contract check: Verify ADR-022 retraction of digital root normalization.
pub fn assert_digital_root_retraction() -> bool {
    let f13 = factorize(13);
    let f22 = factorize(22);
    let dr13 = digital_root(13);
    let dr22 = digital_root(22);
    // Under digital root they collide (dr=4), but their prime spectra are strictly distinct
    (dr13 == 4 && dr22 == 4) && (f13 != f22)
}

/// Zero-Knowledge Circuit Errors for Monotonic Sequence Constraints, Origin Anchoring, and Primality.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParmCircuitError {
    UnsortedSequence { index: usize, left: u64, right: u64 },
    GrandProductMismatch { computed: u64, expected: u64 },
    CompositeFactorRejected { index: usize, value: u64 },
    UnitElementRejected { index: usize },
    RangeCheckExceeded { index: usize, value: u64, bound: u64 },
    EmptySequence,
}

/// Computable primality check: verifies $n \ge 2$ and no divisors up to $\sqrt{n}$.
pub fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }
    let mut d = 3u64;
    while d * d <= n {
        if n % d == 0 {
            return false;
        }
        d += 2;
    }
    true
}

/// Verify that every element in the prime list is a genuine prime ($p_i \ge 2$, $p_i \in \mathbb{P}$).
/// Strictly rejects composite integers (e.g. 12, 9, 54) and unit padding (1).
pub fn verify_primality_and_unit_exclusion(primes: &[u64]) -> Result<(), ParmCircuitError> {
    for (i, &p) in primes.iter().enumerate() {
        if p == 1 {
            return Err(ParmCircuitError::UnitElementRejected { index: i });
        }
        if !is_prime(p) {
            return Err(ParmCircuitError::CompositeFactorRejected { index: i, value: p });
        }
    }
    Ok(())
}

/// Verify that a prime sequence strictly satisfies the zero-knowledge circuit constraint
/// $p_i \ge p_{i+1}$ (monotone descending total order).
pub fn verify_circuit_monotonic_descending(primes: &[u64]) -> Result<(), ParmCircuitError> {
    if primes.is_empty() {
        return Ok(());
    }
    for i in 0..primes.len().saturating_sub(1) {
        if primes[i] < primes[i + 1] {
            return Err(ParmCircuitError::UnsortedSequence {
                index: i,
                left: primes[i],
                right: primes[i + 1],
            });
        }
    }
    Ok(())
}

/// Compute the grand product $\prod p_i$ of a list of primes.
pub fn compute_list_product(primes: &[u64]) -> u64 {
    primes.iter().fold(1u64, |acc, &p| acc * p)
}

/// Compute the running product wire trace $\pi_0, \pi_1, \dots, \pi_{k-1}$ for the arithmetic circuit.
pub fn compute_running_products(primes: &[u64]) -> Vec<u64> {
    let mut trace = Vec::new();
    let mut cur = 1u64;
    for &p in primes {
        cur *= p;
        trace.push(cur);
    }
    trace
}

/// Verify the full triad of circuit constraints:
/// 1. Monotonic descending order ($p_i \ge p_{i+1}$).
/// 2. In-circuit primality and unit exclusion ($p_i \in \mathbb{P} \wedge p_i \ge 2$).
/// 3. Grand product equivalence ($\prod p_i = E_{\text{raw}}$).
pub fn verify_anchored_circuit_constraints(primes: &[u64], expected_encoding: u64) -> Result<(), ParmCircuitError> {
    verify_circuit_monotonic_descending(primes)?;
    verify_primality_and_unit_exclusion(primes)?;
    let prod = compute_list_product(primes);
    if prod != expected_encoding {
        return Err(ParmCircuitError::GrandProductMismatch {
            computed: prod,
            expected: expected_encoding,
        });
    }
    Ok(())
}

/// Compute the non-negative difference slack variables $\Delta_i = p_i - p_{i+1}$
/// for $O(1)$ range-check table lookups in the SNARK circuit.
pub fn compute_circuit_differences(primes: &[u64]) -> Result<Vec<u64>, ParmCircuitError> {
    verify_circuit_monotonic_descending(primes)?;
    let mut diffs = Vec::new();
    for i in 0..primes.len().saturating_sub(1) {
        diffs.push(primes[i] - primes[i + 1]);
    }
    Ok(diffs)
}

/// Circuit Sealing Function: evaluates PARM sealed state inside the constrained circuit.
/// Strictly asserts $p_i \ge p_{i+1}$, $p_i \in \mathbb{P}$, and $\prod p_i = E_{\text{raw}}$.
pub fn compute_anchored_sealed_state(primes: &[u64], expected_encoding: u64) -> Result<u64, ParmCircuitError> {
    verify_anchored_circuit_constraints(primes, expected_encoding)?;
    Ok(crate::word_love::parm_sealed_state(primes))
}

/// Contract check: Verify ZK circuit monotonicity constraints and unsorted permutation rejection.
pub fn assert_circuit_monotonicity_constraint() -> bool {
    let canonical_108 = [3u64, 3, 3, 2, 2];
    let unsorted_1 = [2u64, 2, 3, 3, 3];
    let unsorted_2 = [3u64, 2, 3, 2, 3];

    let canonical_ok = verify_circuit_monotonic_descending(&canonical_108).is_ok();
    let unsorted_1_rejected = verify_circuit_monotonic_descending(&unsorted_1).is_err();
    let unsorted_2_rejected = verify_circuit_monotonic_descending(&unsorted_2).is_err();

    let diffs = compute_circuit_differences(&canonical_108).unwrap();
    let diffs_ok = diffs == vec![0, 0, 1, 0];

    let root_108 = compute_anchored_sealed_state(&canonical_108, 108).unwrap();

    canonical_ok && unsorted_1_rejected && unsorted_2_rejected && diffs_ok && (root_108 == 960)
}

/// Contract check: Verify Grand Product Equivalence and rejection of decoupled/forged primes.
pub fn assert_grand_product_equivalence_constraint() -> bool {
    let ahavah_primes = [13u64];
    let ahavah_val = 13u64;

    let forged_primes = [7u64, 5]; // Monotonic (7 >= 5), but 7 * 5 = 35 != 13

    let authentic_ok = verify_anchored_circuit_constraints(&ahavah_primes, ahavah_val).is_ok();
    let forged_rejected = verify_anchored_circuit_constraints(&forged_primes, ahavah_val).is_err();

    let trace_108 = compute_running_products(&[3, 3, 3, 2, 2]);
    let trace_ok = trace_108 == vec![3, 9, 27, 54, 108];

    authentic_ok && forged_rejected && trace_ok
}

/// Contract check: Verify in-circuit primality table lookup and unit exclusion constraints (WL-PRIME-011).
pub fn assert_primality_and_unit_exclusion_constraint() -> bool {
    let composite_12_9 = [12u64, 9]; // 12 * 9 = 108, 12 >= 9, but 12 and 9 composite
    let composite_54_2 = [54u64, 2]; // 54 * 2 = 108, 54 >= 2, but 54 composite
    let unit_108_1 = [108u64, 1];    // 108 * 1 = 108, 108 >= 1, but 1 is unit
    let unit_cycle = [3u64, 3, 3, 2, 2, 1]; // Unit padded

    let comp1_rejected = verify_anchored_circuit_constraints(&composite_12_9, 108).is_err();
    let comp2_rejected = verify_anchored_circuit_constraints(&composite_54_2, 108).is_err();
    let unit1_rejected = verify_anchored_circuit_constraints(&unit_108_1, 108).is_err();
    let unit2_rejected = verify_anchored_circuit_constraints(&unit_cycle, 108).is_err();

    let canonical_108 = [3u64, 3, 3, 2, 2];
    let canonical_ok = verify_anchored_circuit_constraints(&canonical_108, 108).is_ok();

    comp1_rejected && comp2_rejected && unit1_rejected && unit2_rejected && canonical_ok
}

/// Non-deterministic Pratt Primality Certificate for Large Primes ($p > 2^{16}$).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrattCertificate {
    pub p: u64,
    pub g: u64,
    pub factors: Vec<(u64, u32)>,
}

/// Fast modular exponentiation $base^{exp} \pmod m$ using square-and-multiply.
pub fn mod_pow(base: u64, mut exp: u64, modulus: u64) -> u64 {
    if modulus == 0 || modulus == 1 {
        return 0;
    }
    let mut acc = 1u128;
    let mut b = (base % modulus) as u128;
    let m = modulus as u128;
    while exp > 0 {
        if exp % 2 == 1 {
            acc = (acc * b) % m;
        }
        b = (b * b) % m;
        exp /= 2;
    }
    acc as u64
}

/// Verify a Pratt Certificate inside the circuit verification environment.
pub fn verify_pratt_certificate(cert: &PrattCertificate) -> bool {
    let p = cert.p;
    let g = cert.g;
    if p <= 2 || g <= 1 || g >= p {
        return false;
    }
    let mut prod = 1u64;
    for &(q, e) in &cert.factors {
        for _ in 0..e {
            prod = match prod.checked_mul(q) {
                Some(v) => v,
                None => return false,
            };
        }
    }
    if prod != p - 1 {
        return false;
    }
    // Fermat check: g^(p-1) == 1 (mod p)
    if mod_pow(g, p - 1, p) != 1 {
        return false;
    }
    // Lucas checks: g^((p-1)/q) != 1 (mod p)
    for &(q, _) in &cert.factors {
        if q == 0 || !is_prime(q) || mod_pow(g, (p - 1) / q, p) == 1 {
            return false;
        }
    }
    true
}

/// Hybrid Primality Verifier:
/// - $n \le 65536$: $O(1)$ static table lookup.
/// - $n > 65536$: $O(\log n)$ Pratt Certificate verification.
pub fn is_hybrid_prime(n: u64, cert: Option<&PrattCertificate>) -> bool {
    if n <= 65536 {
        is_prime(n)
    } else {
        match cert {
            Some(c) => c.p == n && verify_pratt_certificate(c),
            None => false,
        }
    }
}

/// Contract check: Verify large-prime Pratt certificate verification (WL-LARGEPRIME-012).
pub fn assert_large_prime_pratt_verification() -> bool {
    let cert65537 = PrattCertificate {
        p: 65537,
        g: 3,
        factors: vec![(2, 16)],
    };
    let cert131071 = PrattCertificate {
        p: 131071,
        g: 3,
        factors: vec![(2, 1), (3, 1), (5, 1), (17, 1), (257, 1)],
    };

    let p65537_ok = is_hybrid_prime(65537, Some(&cert65537));
    let p131071_ok = is_hybrid_prime(131071, Some(&cert131071));
    let comp65535_rejected = !is_hybrid_prime(65535, None);

    p65537_ok && p131071_ok && comp65535_rejected
}

/// Quantized exponential attenuation factor over fixed-point scale N = 1024.
pub fn care_decay(sep: u64) -> u64 {
    match sep {
        0 => 1024,
        1 => 376,
        2 => 138,
        3 => 50,
        4 => 18,
        5 => 6,
        6 => 2,
        _ => 0,
    }
}

/// Compute certified prime-weighted coupling $\gamma_{pn} \in [0, 1024]$.
/// Strictly collapses to 0 if either orbital fails the hybrid primality oracle.
pub fn compute_gamma_certified(
    p: u64,
    n: u64,
    trust: u64,
    cert_p: Option<&PrattCertificate>,
    cert_n: Option<&PrattCertificate>,
) -> u64 {
    if !is_hybrid_prime(p, cert_p) || !is_hybrid_prime(n, cert_n) {
        return 0;
    }
    let min_val = p.min(n);
    let max_val = p.max(n);
    if max_val == 0 {
        return 0;
    }
    let sep = p.abs_diff(n);
    let att = care_decay(sep);
    (min_val * att * trust) / (max_val * 1024)
}

/// Compute certified socio-atomic multiplicity $M_{pn} \in [1024, 3072]$ ($[1, 3]$).
pub fn compute_certified_multiplicity(gamma: u64, trust: u64) -> u64 {
    // M = 1024 + 2 * gamma * trust / 1024
    1024 + (2 * gamma * trust) / 1024
}

/// Sedona Spine Kernel Bridge Record (WL-SPINE-013).
pub struct SedonaSpineKernel;

impl SedonaSpineKernel {
    pub fn verify_token_trajectory(encoding: u64, primes: &[u64]) -> Result<u64, ParmCircuitError> {
        compute_anchored_sealed_state(primes, encoding)
    }

    pub fn evaluate_care_bond(
        patient_prime: u64,
        nurse_prime: u64,
        trust: u64,
        cert_p: Option<&PrattCertificate>,
        cert_n: Option<&PrattCertificate>,
    ) -> (u64, u64) {
        let gamma = compute_gamma_certified(patient_prime, nurse_prime, trust, cert_p, cert_n);
        let multiplicity = compute_certified_multiplicity(gamma, trust);
        (gamma, multiplicity)
    }
}

/// Contract check: Verify Sedona Spine Rust Kernel Binding (WL-SPINE-013).
pub fn assert_sedona_spine_binding() -> bool {
    let cert65537 = PrattCertificate {
        p: 65537,
        g: 3,
        factors: vec![(2, 16)],
    };

    // Valid prime orbitals (13, 13) at full trust (1024)
    let (gamma_13, m_13) = SedonaSpineKernel::evaluate_care_bond(13, 13, 1024, None, None);
    let bond_13_ok = (gamma_13 == 1024) && (m_13 == 3072); // M = 3.0

    // Inadmissible composite orbital (12) collapses gamma to 0, M to 1.0 (1024)
    let (gamma_comp, m_comp) = SedonaSpineKernel::evaluate_care_bond(12, 13, 1024, None, None);
    let bond_comp_ok = (gamma_comp == 0) && (m_comp == 1024);

    // Large-prime certified orbital 65537
    let (gamma_large, m_large) = SedonaSpineKernel::evaluate_care_bond(65537, 65537, 1024, Some(&cert65537), Some(&cert65537));
    let bond_large_ok = (gamma_large == 1024) && (m_large == 3072);

    bond_13_ok && bond_comp_ok && bond_large_ok
}
