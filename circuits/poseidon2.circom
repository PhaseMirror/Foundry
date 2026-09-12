pragma circom 2.0.0;
include "circomlib/poseidon2.circom";
component main {
    signal input in[8];
    signal output out[1];
    component poseidon = Poseidon2(9, 8);
    for (var i = 0; i < 8; i++) {
        poseidon.state[i] <== in[i];
    }
    poseidon.state[8] <== 0;
    poseidon.permute();
    out[0] <== poseidon.state[0];
}
