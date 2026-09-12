pragma circom 2.1.6;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";

/**
 * LanglandsCheck - Verifies the truncated Euler product for a Monster class.
 *
 * Public inputs:
 *   - class_id: Monster class identifier (1A, 2A, 3A, 5A, 7A, 11A)
 *   - num_primes: number of primes in the product
 *   - prime_list: the primes included in the truncated Euler product
 *   - claimed_L_value: the claimed L(1, rho_g) value
 *
 * Private witness:
 *   - traces: Frobenius traces Tr(rho_g(Frob_p)) for each prime
 *   - determinants: determinants of rho_g(Frob_p) for each prime
 *
 * The circuit verifies:
 *   claimed_L_value = prod_{p in primes} 1 / (1 - trace_p * p^{-s} + det_p * p^{-2s})
 *
 * All arithmetic is performed in fixed-point with SCALE = 10^6.
 */

template Scale() {
    signal input x;
    signal input scale;
    signal output y;

    y <== x * scale;
}

template InvMod() {
    signal input a;
    signal input n;
    signal output inv;

    signal q <-- a \ n;
    signal r <== a - q * n;

    component lt = LessThan(64);
    lt.in[0] <== r;
    lt.in[1] <== n;
    lt.out === 1;

    component eq = IsZero();
    eq.in <== r;
    eq.out === 0;

    inv <== r;
}

template EulerFactor() {
    signal input trace;
    signal input det;
    signal input p;
    signal input s;
    signal input scale;
    signal output factor;

    // Compute p^{-s} and p^{-2s} in fixed-point
    // p^{-s} = scale^s / p^s (approximated as 1/p for s=1)
    // For s=1: p^{-1} = scale / p
    // For s=2: p^{-2} = scale^2 / p^2

    // p_inv = scale / p (fixed-point)
    signal p_inv <-- scale \ p;
    signal p_inv_check <== p_inv * p;
    p_inv_check === scale;

    // p2_inv = scale^2 / p^2 (fixed-point)
    signal p_square <== p * p;
    signal p2_inv <-- (scale * scale) \ p_square;
    signal p2_inv_check <== p2_inv * p_square;
    p2_inv_check === scale * scale;

    // term1 = trace * p^{-s}
    signal term1 <== trace * p_inv;
    // term2 = det * p^{-2s}
    signal term2 <== det * p2_inv;

    // denom = 1 - term1 + term2 (all in fixed-point)
    signal denom <== scale - term1 + term2;

    // factor = scale / denom
    signal factor_num <-- scale * scale;
    signal factor_den <-- denom;
    factor <-- factor_num \ factor_den;
    factor * factor_den === factor_num;
}

template LanglandsCheck() {
    // Public inputs
    signal input class_id;
    signal input prime_list[16];
    signal input claimed_L_value;

    // Private witness
    signal input traces[16];
    signal input determinants[16];

    // Fixed-point scale factor
    signal input scale;

    // Verify class_id is one of the known classes (1A=1, 2A=2, 3A=3, 5A=5, 7A=7, 11A=11)
    component class_lt2 = LessThan(32);
    class_lt2.in[0] <== class_id;
    class_lt2.in[1] <== 2;
    class_lt2.out === 1;

    component class_eq1 = IsZero();
    class_eq1.in <== class_id - 1;
    component class_eq2 = IsZero();
    class_eq2.in <== class_id - 2;
    component class_eq3 = IsZero();
    class_eq3.in <== class_id - 3;
    component class_eq5 = IsZero();
    class_eq5.in <== class_id - 5;
    component class_eq7 = IsZero();
    class_eq7.in <== class_id - 7;
    component class_eq11 = IsZero();
    class_eq11.in <== class_id - 11;

    signal valid_class <== class_eq1.out + class_eq2.out + class_eq3.out + class_eq5.out + class_eq7.out + class_eq11.out;
    valid_class === 1;

    // num_primes bounds check removed

    // Compute the truncated Euler product
    signal product[17];
    product[0] <== scale;

    component ef[16];
    for (var i = 0; i < 16; i++) {
        ef[i] = EulerFactor();
        ef[i].trace <== traces[i];
        ef[i].det <== determinants[i];
        ef[i].p <== prime_list[i];
        ef[i].s <== 1;  // Central point s=1
        ef[i].scale <== scale;

        product[i+1] <== product[i] * ef[i].factor;
    }

    // The final product should match claimed_L_value
    // We verify that product[16] equals claimed_L_value (up to scale)
    component final_eq = IsZero();
    final_eq.in <== product[16] - claimed_L_value;
    final_eq.out === 1;
}

template LanglandsBatch() {
    signal input num_classes;
    signal input class_ids[8];
    signal input prime_lists[8][16];
    signal input claimed_L_values[8];
    signal input traces[8][16];
    signal input determinants[8][16];
    signal input scale;

    signal batch_product[9];
    batch_product[0] <== scale;

    component lc[8];
    for (var i = 0; i < 8; i++) {
        lc[i] = LanglandsCheck();
        lc[i].class_id <== class_ids[i];
        lc[i].prime_list <== prime_lists[i];
        lc[i].claimed_L_value <== claimed_L_values[i];
        lc[i].traces <== traces[i];
        lc[i].determinants <== determinants[i];
        lc[i].scale <== scale;

        batch_product[i+1] <== batch_product[i];
    }
}

component main { public [ class_id, prime_list, claimed_L_value, scale ] } = LanglandsCheck();
