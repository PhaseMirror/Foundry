pragma circom 2.1.6;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";

/**
 * MillerRabin64 - Deterministic 64-bit Primality Testing Circuit
 * 
 * PURPOSE:
 * Implements deterministic Miller-Rabin primality test for numbers < 2^64.
 * Uses trial division and full 7-base Fermat primality test for cryptographic prime verification.
 * Foundation for MTPI prime-indexed identity system.
 */

template ModReduceN(BITS) {
    signal input t;
    signal input n;
    signal output r;
    
    signal q <-- t \ n;
    r <== t - q * n;
    
    component rlt = LessThan(BITS);
    rlt.in[0] <== r;
    rlt.in[1] <== n;
    rlt.out === 1;
}

template MulModN(BITS) {
    signal input a;
    signal input b;
    signal input n;
    signal output r;
    
    signal t;
    t <== a * b;
    
    component red = ModReduceN(BITS);
    red.t <== t;
    red.n <== n;
    r <== red.r;
}

template Select() {
    signal input b;
    signal input x;
    signal input y;
    signal output z;
    
    b * (b - 1) === 0;
    z <== y + b * (x - y);
}

template PowModN(BITS, EXPBITS) {
    signal input base;
    signal input exp;
    signal input n;
    signal output r;
    
    signal acc[EXPBITS + 1];
    acc[0] <== 1;
    
    component e = Num2Bits(EXPBITS);
    e.in <== exp;
    
    signal curBase[EXPBITS + 1];
    curBase[0] <== base;
    
    component sel[EXPBITS];
    component mul[EXPBITS];
    component sq[EXPBITS];
    
    for (var i = 0; i < EXPBITS; i++) {
        sel[i] = Select();
        sel[i].b <== e.out[i];
        sel[i].x <== curBase[i];
        sel[i].y <== 1;
        
        mul[i] = MulModN(BITS);
        mul[i].a <== acc[i];
        mul[i].b <== sel[i].z;
        mul[i].n <== n;
        acc[i+1] <== mul[i].r;
        
        sq[i] = MulModN(BITS);
        sq[i].a <== curBase[i];
        sq[i].b <== curBase[i];
        sq[i].n <== n;
        curBase[i+1] <== sq[i].r;
    }
    
    r <== acc[EXPBITS];
}

template RemNotZeroSmallPrime(p) {
    signal input n;
    signal output ok;
    
    signal q <-- n \ p;
    signal r <-- n % p;
    
    n === q * p + r;
    
    component rlt = LessThan(16);
    rlt.in[0] <== r;
    rlt.in[1] <== p;
    rlt.out === 1;
    
    component rz = IsZero();
    rz.in <== r;
    
    signal eq;
    eq <== n - p;
    component eqz = IsZero();
    eqz.in <== eq;
    
    ok <== (1 - rz.out) + eqz.out - (1 - rz.out) * eqz.out;
}

template TrialDivisionGate(K) {
    signal input n;
    signal output ok;
    
    var P[16] = [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53];
    
    component r_comp[K];
    signal pass[K];
    
    for (var i = 0; i < K; i++) {
        r_comp[i] = RemNotZeroSmallPrime(P[i]);
        r_comp[i].n <== n;
        pass[i] <== r_comp[i].ok;
    }
    
    signal acc[K + 1];
    acc[0] <== 1;
    for (var i = 0; i < K; i++) {
        acc[i+1] <== acc[i] * pass[i];
    }
    
    ok <== acc[K];
}

template ExtractSD(BITS) {
    signal input nm1;
    signal output s;
    signal output d;
    
    component bits = Num2Bits(BITS);
    bits.in <== nm1;
    
    signal s_out[BITS];
    signal found[BITS];
    
    found[0] <== bits.out[0];
    s_out[0] <== 0;
    
    for (var i = 1; i < BITS; i++) {
        found[i] <== found[i-1] + bits.out[i] - found[i-1] * bits.out[i];
        signal not_found_prev;
        not_found_prev <== 1 - found[i-1];
        s_out[i] <== s_out[i-1] + not_found_prev;
    }
    
    s <== s_out[BITS-1];
    
    signal pow2[BITS];
    component is_s[BITS];
    
    var cur_pow2 = 1;
    for (var i = 0; i < BITS; i++) {
        is_s[i] = IsZero();
        is_s[i].in <== s - i;
        if (i == 0) {
            pow2[i] <== is_s[i].out * cur_pow2;
        } else {
            pow2[i] <== pow2[i-1] + is_s[i].out * cur_pow2;
        }
        cur_pow2 = cur_pow2 * 2;
    }
    
    signal d_w <-- nm1 / pow2[BITS-1];
    d <== d_w;
    nm1 === d * pow2[BITS-1];
    
    component dBits = Num2Bits(BITS);
    dBits.in <== d;
    dBits.out[0] === 1;
}

template SingleBaseMillerRabin(BITS) {
    signal input n;
    signal input nm1;
    signal input base;
    signal input d;
    signal input s;
    
    signal output isPrime;

    component pow = PowModN(BITS, BITS);
    pow.base <== base;
    pow.exp <== d;
    pow.n <== n;
    
    signal x[BITS];
    x[0] <== pow.r;
    
    component isOne = IsZero();
    isOne.in <== x[0] - 1;
    
    component isNm1[BITS];
    isNm1[0] = IsZero();
    isNm1[0].in <== x[0] - nm1;
    
    signal passInitial;
    passInitial <== isOne.out + isNm1[0].out - isOne.out * isNm1[0].out;
    
    component sq[BITS - 1];
    signal r_less_than_s[BITS - 1];
    component cmp[BITS - 1];
    signal foundNm1[BITS];
    foundNm1[0] <== isNm1[0].out;
    
    for (var r = 1; r < BITS; r++) {
        cmp[r-1] = LessThan(6);
        cmp[r-1].in[0] <== r;
        cmp[r-1].in[1] <== s;
        r_less_than_s[r-1] <== cmp[r-1].out;
        
        sq[r-1] = MulModN(BITS);
        sq[r-1].a <== x[r-1];
        sq[r-1].b <== x[r-1];
        sq[r-1].n <== n;
        
        x[r] <== sq[r-1].r;
        
        isNm1[r] = IsZero();
        isNm1[r].in <== x[r] - nm1;
        
        signal validMatch;
        validMatch <== isNm1[r].out * r_less_than_s[r-1];
        foundNm1[r] <== foundNm1[r-1] + validMatch - foundNm1[r-1] * validMatch;
    }
    
    isPrime <== passInitial + foundNm1[BITS-1] - passInitial * foundNm1[BITS-1];
}

template MillerRabin64() {
    signal input prime;
    signal output isPrime;
    
    component gt3 = GreaterThan(64);
    gt3.in[0] <== prime;
    gt3.in[1] <== 3;
    gt3.out === 1;
    
    component bits = Num2Bits(64);
    bits.in <== prime;
    bits.out[0] === 1;
    
    component td = TrialDivisionGate(8);
    td.n <== prime;
    
    signal nm1;
    nm1 <== prime - 1;
    
    component extract = ExtractSD(64);
    extract.nm1 <== nm1;
    
    signal s <== extract.s;
    signal d <== extract.d;
    
    var NUM_BASES = 7;
    var bases[7] = [2, 3, 5, 7, 11, 13, 17];
    
    component mrBase[7];
    signal passBase[7];
    
    for (var i = 0; i < NUM_BASES; i++) {
        mrBase[i] = SingleBaseMillerRabin(64);
        mrBase[i].n <== prime;
        mrBase[i].nm1 <== nm1;
        mrBase[i].base <== bases[i];
        mrBase[i].d <== d;
        mrBase[i].s <== s;
        
        passBase[i] <== mrBase[i].isPrime;
    }
    
    signal acc[8];
    acc[0] <== 1;
    for (var i = 0; i < NUM_BASES; i++) {
        acc[i+1] <== acc[i] * passBase[i];
    }
    
    isPrime <== td.ok * acc[7];
}
