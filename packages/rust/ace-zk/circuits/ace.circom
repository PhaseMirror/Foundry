pragma circom 2.1.6;

// Pulling the true Multiplicity Crypto Poseidon2 implementation
include "./poseidon2.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template ACE_Governance_Gate() {
    // --- Public Inputs (Anchored to the Smart Contract) ---
    signal input kani_proof_hash;
    signal input max_drift;

    // --- Private Inputs (Raw Execution Telemetry) ---
    signal input current_drift;
    signal input total_energy_t0;
    signal input total_energy_t;
    signal input shuffle_seed;
    signal input theta_base_commitment;
    signal input tau_min;
    signal input epoch_timestamp;

    // --- Output (The CRMF Validity Seal) ---
    signal output crmf_validity_seal;

    // 1. Contractivity Enforcement: current_drift <= max_drift
    // We use a 252-bit comparator for BN254 scalar field safety
    component drift_check = LessEqThan(252);
    drift_check.in[0] <== current_drift;
    drift_check.in[1] <== max_drift;
    drift_check.out === 1; // SIG_GOV_KILL if 0

    // 2. Kani-Backed Energy Conservation
    // As proven in Lean 4: sys.totalEnergy t = sys.totalEnergy 0
    total_energy_t === total_energy_t0;

    // 3. The True Poseidon2(t=9, r=8) Canonical Sponge Anchor
    // Compressing the verified state into a single SNARK-friendly field element
    component sponge = Poseidon2_Sponge_9();
    sponge.in[0] <== kani_proof_hash;
    sponge.in[1] <== current_drift;
    sponge.in[2] <== max_drift;
    sponge.in[3] <== total_energy_t;
    sponge.in[4] <== shuffle_seed;
    sponge.in[5] <== theta_base_commitment;
    sponge.in[6] <== tau_min;
    sponge.in[7] <== epoch_timestamp;

    crmf_validity_seal <== sponge.out;
}

// The Kani proof and the drift limit are public to the verifier; 
// the internal tensor telemetry is zero-knowledge.
component main {public [kani_proof_hash, max_drift]} = ACE_Governance_Gate();

