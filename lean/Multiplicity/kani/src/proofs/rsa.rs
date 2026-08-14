use multiplicity_rsa::*;

#[kani::proof]
#[kani::unwind(32)] // enough for u32 bit shifts
pub fn verify_rsa_break() {
    let p: u32 = kani::any();
    let q: u32 = kani::any();
    
    // Constrain primes for small values to prevent overflow in N and PHI
    kani::assume(p > 1 && p < 100);
    kani::assume(q > 1 && q < 100);
    kani::assume(p != q);

    let n = p * q;
    let phi = (p - 1) * (q - 1);
    
    let e: u32 = kani::any();
    kani::assume(e > 1 && e < phi);
    
    // Check if e and phi are coprime
    let (g, _, _) = extended_gcd(e as i32, phi as i32);
    kani::assume(g == 1);

    let m: u32 = kani::any();
    kani::assume(m < n); // message must be strictly less than n

    // Execute break algorithm
    let sk = break_rsa(p, q, e).expect("should yield valid private key since e, phi coprime");
    
    let pk = RsaPublicKey { n, e };
    let c = encrypt(&pk, m);
    let dec_m = decrypt(&sk, c);

    // Kani assert that decryption of encryption matches original message
    kani::assert(dec_m == m, "Factoring to RSA decryption failed");
}
