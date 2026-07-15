pragma circom 2.1.6;

template Poseidon2Sponge() {
    signal input in[205];
    signal output out;
}

template Poseidon2() {
    signal input in[6];
    signal output out;
}

template WitnessCommitmentBinding() {
    signal input witness_fields[205];
    signal input xn_kernel;
    signal input retention_rate;
    signal input max_wac_product;
    signal input retry_nonce;
    signal input zeta_shadow;

    signal output h_commitment;
    signal output cas_commitment;

    component poseidon_h = Poseidon2Sponge();
    component poseidon_gamma = Poseidon2();

    for (var i = 0; i < 205; i++) {
        poseidon_h.in[i] <== witness_fields[i];
    }
    h_commitment <== poseidon_h.out;

    poseidon_gamma.in[0] <== h_commitment;
    poseidon_gamma.in[1] <== xn_kernel;
    poseidon_gamma.in[2] <== retention_rate;
    poseidon_gamma.in[3] <== max_wac_product;
    poseidon_gamma.in[4] <== retry_nonce;
    poseidon_gamma.in[5] <== zeta_shadow;

    cas_commitment <== poseidon_gamma.out;
}

component main = WitnessCommitmentBinding();
