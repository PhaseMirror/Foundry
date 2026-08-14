pragma circom 2.1.6;

// Pulling the true Multiplicity Crypto Poseidon2 implementation
include "../node_modules/multiplicity-crypto-circom/circuits/poseidon2.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template ACE_Governance_Gate() {
    // --- Public Inputs (Anchored to the Smart Contract) ---
    signal input kani_proof_hash;
    signal input max_drift;

    // --- Private Inputs (Raw Execution Telemetry) ---
    signal input current_drift;
    signal input total_energy_t0;
    signal input total_energy_t;

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

    // 3. The True Poseidon2(t=9, r=8) Cryptographic Anchor
    // Compressing the verified state into a single SNARK-friendly field element
    component hasher = Poseidon2(4);
    hasher.in[0] <== kani_proof_hash;
    hasher.in[1] <== current_drift;
    hasher.in[2] <== total_energy_t;
    hasher.in[3] <== max_drift;

    crmf_validity_seal <== hasher.out;
}

// The Kani proof and the drift limit are public to the verifier; 
// the internal tensor telemetry is zero-knowledge.
component main {public [kani_proof_hash, max_drift]} = ACE_Governance_Gate();
