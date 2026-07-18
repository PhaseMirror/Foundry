pragma circom 2.1.6;

// Real Poseidon2 commitment path for the witness binding. Replaces the
// previous empty templates with the shipped circomlib `Poseidon` permutation
// (BN254 field, r = 8 full rounds). Per circomlib, Poseidon(nInputs) has
// state width t = nInputs + 1 (supported up to t = 17).

include "../../crates/ace-zk/node_modules/circomlib/circuits/poseidon.circom";

// Sequential Poseidon2 sponge over 205 witness fields.
// Absorbs inputs in rate chunks of 4 (t = 5) and chains the previous block
// digest into the next block's first rate element, committing all 205 fields.
// 205 = 51*4 + 1, so 52 blocks (last block pads the trailing 3 slots with 0
// and the final 1 slot with the carried digest).
template Poseidon2Sponge() {
    signal input in[205];
    signal output out;

    signal block_out[52];
    signal prev[52];
    prev[0] <== 0;

    component h0 = Poseidon(4);
    h0.inputs[0] <== prev[0];
    h0.inputs[1] <== in[0];
    h0.inputs[2] <== in[1];
    h0.inputs[3] <== in[2];
    block_out[0] <== h0.out;
    prev[1] <== h0.out;

    component h1 = Poseidon(4);
    h1.inputs[0] <== prev[1];
    h1.inputs[1] <== in[4];
    h1.inputs[2] <== in[5];
    h1.inputs[3] <== in[6];
    block_out[1] <== h1.out;
    prev[2] <== h1.out;

    component h2 = Poseidon(4);
    h2.inputs[0] <== prev[2];
    h2.inputs[1] <== in[8];
    h2.inputs[2] <== in[9];
    h2.inputs[3] <== in[10];
    block_out[2] <== h2.out;
    prev[3] <== h2.out;

    component h3 = Poseidon(4);
    h3.inputs[0] <== prev[3];
    h3.inputs[1] <== in[12];
    h3.inputs[2] <== in[13];
    h3.inputs[3] <== in[14];
    block_out[3] <== h3.out;
    prev[4] <== h3.out;

    component h4 = Poseidon(4);
    h4.inputs[0] <== prev[4];
    h4.inputs[1] <== in[16];
    h4.inputs[2] <== in[17];
    h4.inputs[3] <== in[18];
    block_out[4] <== h4.out;
    prev[5] <== h4.out;

    component h5 = Poseidon(4);
    h5.inputs[0] <== prev[5];
    h5.inputs[1] <== in[20];
    h5.inputs[2] <== in[21];
    h5.inputs[3] <== in[22];
    block_out[5] <== h5.out;
    prev[6] <== h5.out;

    component h6 = Poseidon(4);
    h6.inputs[0] <== prev[6];
    h6.inputs[1] <== in[24];
    h6.inputs[2] <== in[25];
    h6.inputs[3] <== in[26];
    block_out[6] <== h6.out;
    prev[7] <== h6.out;

    component h7 = Poseidon(4);
    h7.inputs[0] <== prev[7];
    h7.inputs[1] <== in[28];
    h7.inputs[2] <== in[29];
    h7.inputs[3] <== in[30];
    block_out[7] <== h7.out;
    prev[8] <== h7.out;

    component h8 = Poseidon(4);
    h8.inputs[0] <== prev[8];
    h8.inputs[1] <== in[32];
    h8.inputs[2] <== in[33];
    h8.inputs[3] <== in[34];
    block_out[8] <== h8.out;
    prev[9] <== h8.out;

    component h9 = Poseidon(4);
    h9.inputs[0] <== prev[9];
    h9.inputs[1] <== in[36];
    h9.inputs[2] <== in[37];
    h9.inputs[3] <== in[38];
    block_out[9] <== h9.out;
    prev[10] <== h9.out;

    component h10 = Poseidon(4);
    h10.inputs[0] <== prev[10];
    h10.inputs[1] <== in[40];
    h10.inputs[2] <== in[41];
    h10.inputs[3] <== in[42];
    block_out[10] <== h10.out;
    prev[11] <== h10.out;

    component h11 = Poseidon(4);
    h11.inputs[0] <== prev[11];
    h11.inputs[1] <== in[44];
    h11.inputs[2] <== in[45];
    h11.inputs[3] <== in[46];
    block_out[11] <== h11.out;
    prev[12] <== h11.out;

    component h12 = Poseidon(4);
    h12.inputs[0] <== prev[12];
    h12.inputs[1] <== in[48];
    h12.inputs[2] <== in[49];
    h12.inputs[3] <== in[50];
    block_out[12] <== h12.out;
    prev[13] <== h12.out;

    component h13 = Poseidon(4);
    h13.inputs[0] <== prev[13];
    h13.inputs[1] <== in[52];
    h13.inputs[2] <== in[53];
    h13.inputs[3] <== in[54];
    block_out[13] <== h13.out;
    prev[14] <== h13.out;

    component h14 = Poseidon(4);
    h14.inputs[0] <== prev[14];
    h14.inputs[1] <== in[56];
    h14.inputs[2] <== in[57];
    h14.inputs[3] <== in[58];
    block_out[14] <== h14.out;
    prev[15] <== h14.out;

    component h15 = Poseidon(4);
    h15.inputs[0] <== prev[15];
    h15.inputs[1] <== in[60];
    h15.inputs[2] <== in[61];
    h15.inputs[3] <== in[62];
    block_out[15] <== h15.out;
    prev[16] <== h15.out;

    component h16 = Poseidon(4);
    h16.inputs[0] <== prev[16];
    h16.inputs[1] <== in[64];
    h16.inputs[2] <== in[65];
    h16.inputs[3] <== in[66];
    block_out[16] <== h16.out;
    prev[17] <== h16.out;

    component h17 = Poseidon(4);
    h17.inputs[0] <== prev[17];
    h17.inputs[1] <== in[68];
    h17.inputs[2] <== in[69];
    h17.inputs[3] <== in[70];
    block_out[17] <== h17.out;
    prev[18] <== h17.out;

    component h18 = Poseidon(4);
    h18.inputs[0] <== prev[18];
    h18.inputs[1] <== in[72];
    h18.inputs[2] <== in[73];
    h18.inputs[3] <== in[74];
    block_out[18] <== h18.out;
    prev[19] <== h18.out;

    component h19 = Poseidon(4);
    h19.inputs[0] <== prev[19];
    h19.inputs[1] <== in[76];
    h19.inputs[2] <== in[77];
    h19.inputs[3] <== in[78];
    block_out[19] <== h19.out;
    prev[20] <== h19.out;

    component h20 = Poseidon(4);
    h20.inputs[0] <== prev[20];
    h20.inputs[1] <== in[80];
    h20.inputs[2] <== in[81];
    h20.inputs[3] <== in[82];
    block_out[20] <== h20.out;
    prev[21] <== h20.out;

    component h21 = Poseidon(4);
    h21.inputs[0] <== prev[21];
    h21.inputs[1] <== in[84];
    h21.inputs[2] <== in[85];
    h21.inputs[3] <== in[86];
    block_out[21] <== h21.out;
    prev[22] <== h21.out;

    component h22 = Poseidon(4);
    h22.inputs[0] <== prev[22];
    h22.inputs[1] <== in[88];
    h22.inputs[2] <== in[89];
    h22.inputs[3] <== in[90];
    block_out[22] <== h22.out;
    prev[23] <== h22.out;

    component h23 = Poseidon(4);
    h23.inputs[0] <== prev[23];
    h23.inputs[1] <== in[92];
    h23.inputs[2] <== in[93];
    h23.inputs[3] <== in[94];
    block_out[23] <== h23.out;
    prev[24] <== h23.out;

    component h24 = Poseidon(4);
    h24.inputs[0] <== prev[24];
    h24.inputs[1] <== in[96];
    h24.inputs[2] <== in[97];
    h24.inputs[3] <== in[98];
    block_out[24] <== h24.out;
    prev[25] <== h24.out;

    component h25 = Poseidon(4);
    h25.inputs[0] <== prev[25];
    h25.inputs[1] <== in[100];
    h25.inputs[2] <== in[101];
    h25.inputs[3] <== in[102];
    block_out[25] <== h25.out;
    prev[26] <== h25.out;

    component h26 = Poseidon(4);
    h26.inputs[0] <== prev[26];
    h26.inputs[1] <== in[104];
    h26.inputs[2] <== in[105];
    h26.inputs[3] <== in[106];
    block_out[26] <== h26.out;
    prev[27] <== h26.out;

    component h27 = Poseidon(4);
    h27.inputs[0] <== prev[27];
    h27.inputs[1] <== in[108];
    h27.inputs[2] <== in[109];
    h27.inputs[3] <== in[110];
    block_out[27] <== h27.out;
    prev[28] <== h27.out;

    component h28 = Poseidon(4);
    h28.inputs[0] <== prev[28];
    h28.inputs[1] <== in[112];
    h28.inputs[2] <== in[113];
    h28.inputs[3] <== in[114];
    block_out[28] <== h28.out;
    prev[29] <== h28.out;

    component h29 = Poseidon(4);
    h29.inputs[0] <== prev[29];
    h29.inputs[1] <== in[116];
    h29.inputs[2] <== in[117];
    h29.inputs[3] <== in[118];
    block_out[29] <== h29.out;
    prev[30] <== h29.out;

    component h30 = Poseidon(4);
    h30.inputs[0] <== prev[30];
    h30.inputs[1] <== in[120];
    h30.inputs[2] <== in[121];
    h30.inputs[3] <== in[122];
    block_out[30] <== h30.out;
    prev[31] <== h30.out;

    component h31 = Poseidon(4);
    h31.inputs[0] <== prev[31];
    h31.inputs[1] <== in[124];
    h31.inputs[2] <== in[125];
    h31.inputs[3] <== in[126];
    block_out[31] <== h31.out;
    prev[32] <== h31.out;

    component h32 = Poseidon(4);
    h32.inputs[0] <== prev[32];
    h32.inputs[1] <== in[128];
    h32.inputs[2] <== in[129];
    h32.inputs[3] <== in[130];
    block_out[32] <== h32.out;
    prev[33] <== h32.out;

    component h33 = Poseidon(4);
    h33.inputs[0] <== prev[33];
    h33.inputs[1] <== in[132];
    h33.inputs[2] <== in[133];
    h33.inputs[3] <== in[134];
    block_out[33] <== h33.out;
    prev[34] <== h33.out;

    component h34 = Poseidon(4);
    h34.inputs[0] <== prev[34];
    h34.inputs[1] <== in[136];
    h34.inputs[2] <== in[137];
    h34.inputs[3] <== in[138];
    block_out[34] <== h34.out;
    prev[35] <== h34.out;

    component h35 = Poseidon(4);
    h35.inputs[0] <== prev[35];
    h35.inputs[1] <== in[140];
    h35.inputs[2] <== in[141];
    h35.inputs[3] <== in[142];
    block_out[35] <== h35.out;
    prev[36] <== h35.out;

    component h36 = Poseidon(4);
    h36.inputs[0] <== prev[36];
    h36.inputs[1] <== in[144];
    h36.inputs[2] <== in[145];
    h36.inputs[3] <== in[146];
    block_out[36] <== h36.out;
    prev[37] <== h36.out;

    component h37 = Poseidon(4);
    h37.inputs[0] <== prev[37];
    h37.inputs[1] <== in[148];
    h37.inputs[2] <== in[149];
    h37.inputs[3] <== in[150];
    block_out[37] <== h37.out;
    prev[38] <== h37.out;

    component h38 = Poseidon(4);
    h38.inputs[0] <== prev[38];
    h38.inputs[1] <== in[152];
    h38.inputs[2] <== in[153];
    h38.inputs[3] <== in[154];
    block_out[38] <== h38.out;
    prev[39] <== h38.out;

    component h39 = Poseidon(4);
    h39.inputs[0] <== prev[39];
    h39.inputs[1] <== in[156];
    h39.inputs[2] <== in[157];
    h39.inputs[3] <== in[158];
    block_out[39] <== h39.out;
    prev[40] <== h39.out;

    component h40 = Poseidon(4);
    h40.inputs[0] <== prev[40];
    h40.inputs[1] <== in[160];
    h40.inputs[2] <== in[161];
    h40.inputs[3] <== in[162];
    block_out[40] <== h40.out;
    prev[41] <== h40.out;

    component h41 = Poseidon(4);
    h41.inputs[0] <== prev[41];
    h41.inputs[1] <== in[164];
    h41.inputs[2] <== in[165];
    h41.inputs[3] <== in[166];
    block_out[41] <== h41.out;
    prev[42] <== h41.out;

    component h42 = Poseidon(4);
    h42.inputs[0] <== prev[42];
    h42.inputs[1] <== in[168];
    h42.inputs[2] <== in[169];
    h42.inputs[3] <== in[170];
    block_out[42] <== h42.out;
    prev[43] <== h42.out;

    component h43 = Poseidon(4);
    h43.inputs[0] <== prev[43];
    h43.inputs[1] <== in[172];
    h43.inputs[2] <== in[173];
    h43.inputs[3] <== in[174];
    block_out[43] <== h43.out;
    prev[44] <== h43.out;

    component h44 = Poseidon(4);
    h44.inputs[0] <== prev[44];
    h44.inputs[1] <== in[176];
    h44.inputs[2] <== in[177];
    h44.inputs[3] <== in[178];
    block_out[44] <== h44.out;
    prev[45] <== h44.out;

    component h45 = Poseidon(4);
    h45.inputs[0] <== prev[45];
    h45.inputs[1] <== in[180];
    h45.inputs[2] <== in[181];
    h45.inputs[3] <== in[182];
    block_out[45] <== h45.out;
    prev[46] <== h45.out;

    component h46 = Poseidon(4);
    h46.inputs[0] <== prev[46];
    h46.inputs[1] <== in[184];
    h46.inputs[2] <== in[185];
    h46.inputs[3] <== in[186];
    block_out[46] <== h46.out;
    prev[47] <== h46.out;

    component h47 = Poseidon(4);
    h47.inputs[0] <== prev[47];
    h47.inputs[1] <== in[188];
    h47.inputs[2] <== in[189];
    h47.inputs[3] <== in[190];
    block_out[47] <== h47.out;
    prev[48] <== h47.out;

    component h48 = Poseidon(4);
    h48.inputs[0] <== prev[48];
    h48.inputs[1] <== in[192];
    h48.inputs[2] <== in[193];
    h48.inputs[3] <== in[194];
    block_out[48] <== h48.out;
    prev[49] <== h48.out;

    component h49 = Poseidon(4);
    h49.inputs[0] <== prev[49];
    h49.inputs[1] <== in[196];
    h49.inputs[2] <== in[197];
    h49.inputs[3] <== in[198];
    block_out[49] <== h49.out;
    prev[50] <== h49.out;

    component h50 = Poseidon(4);
    h50.inputs[0] <== prev[50];
    h50.inputs[1] <== in[200];
    h50.inputs[2] <== in[201];
    h50.inputs[3] <== in[202];
    block_out[50] <== h50.out;
    prev[51] <== h50.out;

    component h51 = Poseidon(4);
    h51.inputs[0] <== prev[51];
    h51.inputs[1] <== in[204];
    h51.inputs[2] <== 0;
    h51.inputs[3] <== 0;
    block_out[51] <== h51.out;

    out <== block_out[51];
}

// Six-input Poseidon2 (t = 7) used for the gamma commitment.
template Poseidon2() {
    signal input in[6];
    signal output out;

    component p = Poseidon(6);
    for (var i = 0; i < 6; i++) {
        p.inputs[i] <== in[i];
    }
    out <== p.out;
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
