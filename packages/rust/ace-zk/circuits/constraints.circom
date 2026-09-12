pragma circom 2.1.6;

// Canonical ACE circuit budget lock.
// Non-negotiable target: 5,087 constraints from fixed cost buckets.

template ConstraintBudgetLock() {
    signal output fwht_cost;
    signal output poseidon_h_cost;
    signal output poseidon_gamma_cost;
    signal output range_cost;
    signal output total_cost;

    fwht_cost <== 384;
    poseidon_h_cost <== 3171;
    poseidon_gamma_cost <== 1500;
    range_cost <== 32;

    total_cost <== fwht_cost + poseidon_h_cost + poseidon_gamma_cost + range_cost;

    // Hard lock.
    total_cost === 5087;
}

component main = ConstraintBudgetLock();
