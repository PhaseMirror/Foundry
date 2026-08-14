pragma circom 2.1.6;

// Phase 2 topology lock for Poseidon2 sponge parameters.
// This file currently focuses on parameter locking, while hash internals
// will be integrated with production Poseidon2 gates in Phase 3.

template Poseidon2TopologyLock() {
    signal input t;
    signal input r;
    signal output ok;

    // Constrain t == 9 and r == 8 for ACE canonical topology.
    signal t_match;
    signal r_match;
    t_match <== t - 9;
    r_match <== r - 8;

    // Both must be zero.
    t_match === 0;
    r_match === 0;

    ok <== 1;
}

// No main component in include file.
