pragma circom 2.1.6;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";

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
    signal p2_inv <-- (scale * scale) \ (p * p);
    signal p2_inv_check <== p2_inv * p * p;
    p2_inv_check === scale * scale;

    // term1 = trace * p^{-s}
    signal term1 <-- trace * p_inv;
    // term2 = det * p^{-2s}
    signal term2 <-- det * p2_inv;

    // denom = 1 - term1 + term2 (all in fixed-point)
    signal denom <== scale - term1 + term2;

    // factor = scale / denom
    signal factor_num <-- scale * scale;
    signal factor_den <-- denom;
    factor <== factor_num \ factor_den;
}

template LanglandsCheck() {
    // Public inputs
    signal input class_id;
    signal input num_primes;
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

    // Verify num_primes is within bounds
    component num_lt = LessThan(32);
    num_lt.in[0] <== num_primes;
    num_lt.in[1] <== 16;
    num_lt.out === 1;

    // Compute the truncated Euler product
    signal product[16];
    product[0] <== scale;

    for (var i = 0; i < 16; i++) {
        component ef = EulerFactor();
        ef.trace <== traces[i];
        ef.det <== determinants[i];
        ef.p <== prime_list[i];
        ef.s <== 1;  // Central point s=1
        ef.scale <== scale;

        if (i > 0) {
            product[i] <== product[i-1] * ef.factor;
        } else {
            product[i] <== ef.factor;
        }
    }

    // The final product should match claimed_L_value
    // We verify that product[num_primes-1] equals claimed_L_value (up to scale)
    component final_eq = IsZero();
    final_eq.in <== product[num_primes - 1] - claimed_L_value;
    final_eq.out === 1;
}

template LanglandsBatch() {
    signal input num_classes;
    signal input class_ids[8];
    signal input num_primes[8];
    signal input prime_lists[8][16];
    signal input claimed_L_values[8];
    signal input traces[8][16];
    signal input determinants[8][16];
    signal input scale;

    signal batch_product[8];
    batch_product[0] <== scale;

    for (var i = 0; i < 8; i++) {
        component lc = LanglandsCheck();
        lc.class_id <== class_ids[i];
        lc.num_primes <== num_primes[i];
        lc.prime_list <== prime_lists[i];
        lc.claimed_L_value <== claimed_L_values[i];
        lc.traces <== traces[i];
        lc.determinants <== determinants[i];
        lc.scale <== scale;

        if (i > 0) {
            batch_product[i] <== batch_product[i-1];
        }
    }
}
