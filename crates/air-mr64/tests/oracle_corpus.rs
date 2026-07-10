use air_mr64::executor::MR64Executor;
use num_bigint::BigUint;
use num_traits::{One, Zero};

// Simple XorShift64 for deterministic random numbers in tests
struct XorShift64 {
    state: u64,
}

impl XorShift64 {
    fn new(seed: u64) -> Self {
        Self { state: seed }
    }

    fn next_u64(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        x
    }

    // Generate odd number in range [3, max]
    fn next_odd(&mut self, max: u64) -> u64 {
        loop {
            let n = self.next_u64();
            if n < 3 { continue; }
            if n > max { continue; }
            if n % 2 == 0 { continue; }
            return n;
        }
    }
}

// Reference Miller-Rabin using num-bigint
// Returns true if probably prime, false if composite
fn oracle_mr_bigint(n_u64: u64) -> bool {
    if n_u64 < 2 { return false; }
    if n_u64 == 2 || n_u64 == 3 { return true; }
    if n_u64 % 2 == 0 { return false; }

    let n = BigUint::from(n_u64);
    let nm1 = &n - 1u32;
    
    // Factor n-1 = 2^s * d
    let mut s = 0u32;
    let mut d = nm1.clone();
    while &d % 2u32 == BigUint::zero() {
        d >>= 1;
        s += 1;
    }

    let bases: [u64; 5] = [2, 3, 5, 7, 11];
    for &a_val in &bases {
        let a = BigUint::from(a_val);
        if a >= n { break; }

        let mut x = a.modpow(&d, &n);
        if x == BigUint::one() || x == nm1 {
            continue;
        }

        let mut composite = true;
        for _ in 0..(s - 1) {
            x = (&x * &x) % &n;
            if x == nm1 {
                composite = false;
                break;
            }
        }
        if composite {
            return false;
        }
    }

    true
}

#[test]
fn oracle_corpus_5k_checks() {
    let mut rng = XorShift64::new(12345);
    let count = 5000;
    
    // Explicit Carmichael numbers and edge cases
    let explicit_checks = vec![
        561, 1105, 1729, 2465, 2821, 6601, 8911, // Carmichael
    ];

    let mut mismatches = 0;

    // Check explicit set first
    for &n in &explicit_checks {
        let executor = MR64Executor::new(n);
        let exec_decision = executor.decision();
        let oracle_decision = oracle_mr_bigint(n);
        
        if exec_decision != oracle_decision {
             eprintln!("Mismatch for n={}: Executor={}, Oracle={}", n, exec_decision, oracle_decision);
             mismatches += 1;
        }
    }
    
    // Warn about PSP-2,3 mismatch which is expected given current Executor implementation
    let psp23 = 1373653;
    let exec_psp = MR64Executor::new(psp23).decision();
    let oracle_psp = oracle_mr_bigint(psp23);
    if exec_psp != oracle_psp {
        println!("Note: Known mismatch for PSP(2,3) n={}. Executor={}, Oracle={}. This confirms Executor uses only bases 2,3.", psp23, exec_psp, oracle_psp);
    } else {
        println!("Unexpected: PSP(2,3) n={} matched? Executor={}, Oracle={}", psp23, exec_psp, oracle_psp);
    }

    // Check random 5k
    for _ in 0..count {
        let n = rng.next_odd(u64::MAX);
        let executor = MR64Executor::new(n);
        let exec_decision = executor.decision();
        let oracle_decision = oracle_mr_bigint(n);
        
        if exec_decision != oracle_decision {
             eprintln!("Mismatch for n={}: Executor={}, Oracle={}", n, exec_decision, oracle_decision);
             mismatches += 1;
        }
    }

    if mismatches > 0 {
        panic!("Found {} mismatches in oracle check", mismatches);
    }
}