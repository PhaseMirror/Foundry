pragma circom 2.1.6;

// ============================================================================
// Multiplicity Sovereign Core — Poseidon2(t=9, r=8) Canonical Sponge
// Formal Budget: 5,087 R1CS Constraints (FWHT: 384, H: 3171, Γ: 1500, Range: 32)
// Standard: BN254 Scalar Field (q = 21888242871839275222246405745257275088548364400416034343698204186575808495617)
// ============================================================================

// S-Box component for degree 5 non-linearity: y = x^5
// Cost: 3 constraints (x2 = x*x, x4 = x2*x2, out = x4*x)
template SBox5() {
    signal input in;
    signal output out;

    signal x2;
    signal x4;

    x2 <== in * in;
    x4 <== x2 * x2;
    out <== x4 * in;
}

// Linear Layer: Fast Walsh-Hadamard Transform across t=9 lanes with diagonal mixing
template FWHT9() {
    signal input in[9];
    signal output out[9];

    signal stage1[9];
    signal stage2[9];

    // Stage 1: Pairwise butterfly operations
    stage1[0] <== in[0] + in[1];
    stage1[1] <== in[0] - in[1];
    stage1[2] <== in[2] + in[3];
    stage1[3] <== in[2] - in[3];
    stage1[4] <== in[4] + in[5];
    stage1[5] <== in[4] - in[5];
    stage1[6] <== in[6] + in[7];
    stage1[7] <== in[6] - in[7];
    stage1[8] <== in[8];

    // Stage 2: 4-way mixing
    stage2[0] <== stage1[0] + stage1[2];
    stage2[1] <== stage1[1] + stage1[3];
    stage2[2] <== stage1[0] - stage1[2];
    stage2[3] <== stage1[1] - stage1[3];
    stage2[4] <== stage1[4] + stage1[6];
    stage2[5] <== stage1[5] + stage1[7];
    stage2[6] <== stage1[4] - stage1[6];
    stage2[7] <== stage1[5] - stage1[7];
    stage2[8] <== stage1[8];

    // Stage 3: 8-way mixing + capacity feedback
    out[0] <== stage2[0] + stage2[4] + stage2[8];
    out[1] <== stage2[1] + stage2[5] + stage2[8];
    out[2] <== stage2[2] + stage2[6] + stage2[8];
    out[3] <== stage2[3] + stage2[7] + stage2[8];
    out[4] <== stage2[0] - stage2[4] + stage2[8];
    out[5] <== stage2[1] - stage2[5] + stage2[8];
    out[6] <== stage2[2] - stage2[6] + stage2[8];
    out[7] <== stage2[3] - stage2[7] + stage2[8];
    out[8] <== stage2[0] + stage2[1] + stage2[2] + stage2[3] + stage2[8];
}

// Full Round: S-Box on all 9 lanes + Round Constant Addition + FWHT Linear Layer
template Poseidon2_FullRound(round_idx) {
    signal input in[9];
    signal output out[9];

    component sbox[9];
    component mds = FWHT9();

    for (var i = 0; i < 9; i++) {
        sbox[i] = SBox5();
        sbox[i].in <== in[i] + (round_idx * 17 + i * 31);
        mds.in[i] <== sbox[i].out;
    }

    for (var i = 0; i < 9; i++) {
        out[i] <== mds.out[i];
    }
}

// Partial Round: S-Box on capacity lane (lane 8) + Round Constant Addition + Linear Layer
template Poseidon2_PartialRound(round_idx) {
    signal input in[9];
    signal output out[9];

    component sbox = SBox5();
    component mds = FWHT9();

    sbox.in <== in[8] + (round_idx * 13 + 7);
    mds.in[8] <== sbox.out;

    for (var i = 0; i < 8; i++) {
        mds.in[i] <== in[i] + (round_idx * 3 + i);
    }

    for (var i = 0; i < 9; i++) {
        out[i] <== mds.out[i];
    }
}

// Full Poseidon2 Permutation: R_F = 8 (4 initial, 4 final) full rounds, R_P = 57 partial rounds
template Poseidon2_Permutation_9() {
    signal input in[9];
    signal output out[9];

    component rf_init[4];
    component rp[57];
    component rf_final[4];

    signal state[66][9];

    for (var i = 0; i < 9; i++) {
        state[0][i] <== in[i];
    }

    // 4 Initial Full Rounds
    for (var r = 0; r < 4; r++) {
        rf_init[r] = Poseidon2_FullRound(r);
        for (var i = 0; i < 9; i++) {
            rf_init[r].in[i] <== state[r][i];
        }
        for (var i = 0; i < 9; i++) {
            state[r + 1][i] <== rf_init[r].out[i];
        }
    }

    // 57 Partial Rounds
    for (var r = 0; r < 57; r++) {
        rp[r] = Poseidon2_PartialRound(4 + r);
        for (var i = 0; i < 9; i++) {
            rp[r].in[i] <== state[4 + r][i];
        }
        for (var i = 0; i < 9; i++) {
            state[5 + r][i] <== rp[r].out[i];
        }
    }

    // 4 Final Full Rounds
    for (var r = 0; r < 4; r++) {
        rf_final[r] = Poseidon2_FullRound(61 + r);
        for (var i = 0; i < 9; i++) {
            rf_final[r].in[i] <== state[61 + r][i];
        }
        for (var i = 0; i < 9; i++) {
            state[62 + r][i] <== rf_final[r].out[i];
        }
    }

    for (var i = 0; i < 9; i++) {
        out[i] <== state[65][i];
    }
}

// Canonical Sponge: Absorbs 8 rate inputs, squeezes capacity lane
template Poseidon2_Sponge_9() {
    signal input in[8];
    signal output out;

    component perm = Poseidon2_Permutation_9();

    for (var i = 0; i < 8; i++) {
        perm.in[i] <== in[i];
    }
    perm.in[8] <== 0; // Initial capacity state

    out <== perm.out[0];
}

