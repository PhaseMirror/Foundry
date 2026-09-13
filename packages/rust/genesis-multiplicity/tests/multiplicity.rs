//! Port of `genesis-ode/tests/unit/test_multiplicity.py`.

use genesis_multiplicity::{
    MultiplicityDecoder, MultiplicityEncoder, PrimeBandAllocator, SurfaceState,
};

fn allocator() -> PrimeBandAllocator {
    PrimeBandAllocator::new(None)
}

fn encoder() -> MultiplicityEncoder {
    MultiplicityEncoder::new(allocator())
}

fn decoder() -> MultiplicityDecoder {
    MultiplicityDecoder::new(allocator())
}

fn approx(a: f64, b: f64) -> bool {
    (a - b).abs() < 1e-9
}

fn sample_state() -> SurfaceState {
    // Mirror of `test_encoding_decoding_roundtrip`.
    SurfaceState {
        substrate: String::from("metallurgical"),
        coherence: 0.8,
        stability_threshold: 1.0,
        effective_stress: 0.5,
        frequency: 1.0,
        logical_state: Some(String::from("ON")),
        ..Default::default()
    }
}

#[test]
fn encoding_decoding_roundtrip() {
    let enc = encoder();
    let dec = decoder();

    let encoding = enc.encode(&sample_state());

    assert_eq!(encoding.prime_signature, vec![2, 3, 7, 13]);
    assert_eq!(encoding.exponent_vector[&2], 4); // 0.8 * 5
    assert_eq!(encoding.exponent_vector[&3], 5); // 0.5 * 10
    assert_eq!(encoding.exponent_vector[&7], 1); // "ON"

    let recon = dec.decode(&encoding);

    // Reconstructed coherence should be mid-bin (4+0.5)/5 = 0.9.
    assert!(approx(recon.coherence, 0.9));
    assert!(approx(recon.stress, 0.55)); // (5+0.5)/10
    assert_eq!(recon.logical_state, "ON");
    assert!(!recon.threshold_exceeded); // 0.5 > 0.5 is False
}

#[test]
fn threshold_encoding() {
    let enc = encoder();
    let dec = decoder();

    let mut state = sample_state();
    state.substrate = String::from("Semi");
    state.coherence = 0.9;
    state.effective_stress = 0.6;
    state.switching_threshold = Some(0.5);

    let encoding = enc.encode(&state);
    assert_eq!(encoding.exponent_vector[&5], 1); // 0.6 > 0.5

    let recon = dec.decode(&encoding);
    assert!(recon.threshold_exceeded);
}

#[test]
fn reconstruction_score_is_high_for_close_values() {
    let enc = encoder();
    let dec = decoder();

    let mut state = sample_state();
    state.coherence = 0.82;
    state.effective_stress = 0.51;

    let encoding = enc.encode(&state);
    let score = dec.compute_reconstruction_score(&state, &encoding);

    assert!((0.0..=1.0).contains(&score), "score in [0,1], got {score}");
    assert!(score > 0.8, "score {score} should be high for close values");
}

#[test]
fn sparsity_index_counts_active_primes() {
    let enc = encoder();

    let mut state = sample_state();
    state.coherence = 0.0; // zero exponent
    state.effective_stress = 0.0;
    state.logical_state = Some(String::from("OFF")); // l_exp = 2, still active
    state.frequency = 0.0;

    let encoding = enc.encode(&state);
    // Exponents: c=0, s=0, l=2, f=0; only prime 7 keeps a positive exponent.
    assert_eq!(encoding.prime_signature.len(), 1);
    assert!(approx(encoding.sparsity_index, 0.1)); // 1 / 10 available primes
}

#[test]
fn module_quarantine_does_not_mutate_source_state() {
    let enc = encoder();

    let mut state = sample_state();
    state.logical_state = None; // pydantic default "ON" applies on construction
    let original_coherence = state.coherence;

    let attached = enc.attach(&state);

    // Verifies that encoding does NOT mutate the scalar value of the state
    // itself, only the metadata field.
    assert_eq!(attached.coherence, original_coherence);
    assert!(attached.multiplicity.is_some());
    assert_eq!(
        attached.multiplicity.as_ref().unwrap().exponent_vector[&2],
        4
    );
}

#[test]
fn locality_delta_is_bounded_under_single_exponent_perturbation() {
    use std::collections::HashMap;
    let enc = encoder();
    let dec = decoder();

    let state = sample_state();
    let encoding = enc.encode(&state);

    let delta = dec.validate_locality(&encoding, &HashMap::from([(3, 1)]));
    // Single coherence/-prime exponent moves reconstructed stress by 0.1;
    // no categorical mismatch is possible here, so delta ~ 0.1.
    assert!(delta > 0.0 && delta < 0.2, "delta {delta} out of bounds");
}
