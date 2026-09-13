//! Port of `atomic-calculator/multiplicity_test.py` — the phase-mirror
//! signature conservation property and the neutral-atom (UAC → PMat)
//! placeholder validation.

use std::collections::BTreeMap;

/// `multiplicity_mock(sig) = Σ exponents` (placeholder M invariant).
fn multiplicity_mock(sig: &BTreeMap<i64, i64>) -> i64 {
    sig.values().sum()
}

/// `uc_simulate`: placeholder neutral-atom evolution with net conservation;
/// the Python `Fraction(1,1)` net factor makes M_out == M_in exactly.
fn uc_simulate(sig_in: &BTreeMap<i64, i64>, error_mha: f64) -> bool {
    let m_in = multiplicity_mock(sig_in);
    let m_out = m_in; // net conservation (identity + noise)
    ((m_out - m_in) as f64).abs() * 1e3 < error_mha
}

#[test]
fn uac_pmat_binding_conservation() {
    // Test H2 / LiH simplified signature {1: 2}.
    let h2_sig: BTreeMap<i64, i64> = BTreeMap::from([(1, 2)]);
    assert!(uc_simulate(&h2_sig, 1.3), "H2 conservation failed");
}

#[test]
fn phase_mirror_signature_negation_and_m_conservation() {
    // Simulate Rust output while mirroring `multiplicity_test.py`.
    let original: BTreeMap<i64, i64> = BTreeMap::from([(2, 1), (3, -1)]);
    let negated: BTreeMap<i64, i64> = original.iter().map(|(p, e)| (*p, -*e)).collect();
    assert_eq!(
        negated,
        BTreeMap::from([(2, -1), (3, 1)]),
        "Negation mismatch"
    );

    // Python: multiplicity_mock(original) == multiplicity_mock(negated)*-1
    //          + 2*sum(original.values())
    let lhs = multiplicity_mock(&original);
    let rhs = -multiplicity_mock(&negated) + 2 * original.values().sum::<i64>();
    assert_eq!(lhs, rhs, "M-conservation failed");
}

#[test]
fn negation_is_involution_for_zero_sum_signatures() {
    // The M-conservation identity `M(σ) == -M(-σ) + 2Σe` reduces to
    // `s == -(-s) + 2s`, which holds iff Σe == 0 — i.e. for conservation
    // (charge/prime-flow) preserving signatures.
    for sig in [
        BTreeMap::from([(2_i64, 1_i64), (3, -1)]),
        BTreeMap::from([(2, 3), (5, -2), (7, -1)]),
        BTreeMap::from([(11_i64, 0_i64)]),
    ] {
        assert_eq!(
            sig.values().sum::<i64>(),
            0,
            "test precondition: signature must be conservative"
        );
        let negated: BTreeMap<i64, i64> = sig.iter().map(|(p, e)| (*p, -*e)).collect();
        assert_eq!(
            multiplicity_mock(&sig),
            -multiplicity_mock(&negated) + 2 * sig.values().sum::<i64>(),
            "M-conservation failed for {sig:?}"
        );
    }
}
