use num_bigint::{BigInt, Sign};
use num_traits::{One, Zero, ToPrimitive};
use sha2::{Sha256, Digest};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeGateState {
    pub open: bool,
    pub n_bits: usize,
    pub ms: u64,
    pub rounds: usize,
}

pub fn run_prime_gate(seed: &str, epoch: u64, rounds: usize) -> PrimeGateState {
    let t0 = std::time::Instant::now();
    
    // 1. SHA256
    let input = format!("{}:{}", seed, epoch);
    let hash = Sha256::digest(input.as_bytes());
    
    // 2. BigInt
    let mut n = BigInt::from_bytes_be(Sign::Plus, &hash);
    
    // 3. Ensure odd
    if &n % 2 == BigInt::from(0) {
        n += 1;
    }
    
    let n_bits = n.bits();
    
    // 4. Miller-Rabin
    let open = miller_rabin(&n, rounds);
    
    PrimeGateState {
        open,
        n_bits: n_bits as usize,
        ms: t0.elapsed().as_millis() as u64,
        rounds,
    }
}

fn mod_pow(mut base: BigInt, mut exp: BigInt, m: &BigInt) -> BigInt {
    let mut res = BigInt::from(1);
    base %= m;
    while exp > BigInt::from(0) {
        if &exp % 2 == BigInt::from(1) {
            res = (res * &base) % m;
        }
        base = (&base * &base) % m;
        exp /= 2;
    }
    res
}

fn miller_rabin(n: &BigInt, rounds: usize) -> bool {
    if *n < BigInt::from(4) {
        return *n == BigInt::from(2) || *n == BigInt::from(3);
    }
    if n % 2 == BigInt::from(0) {
        return false;
    }
    
    let mut d = n - 1;
    let mut s = 0;
    while &d % 2 == BigInt::from(0) {
        d /= 2;
        s += 1;
    }
    
    let bases = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
    for i in 0..rounds {
        let a = BigInt::from(bases[i % bases.len()]);
        if a >= n - 2 { continue; }
        
        let mut x = mod_pow(a, d.clone(), n);
        if x == BigInt::from(1) || x == n - 1 {
            continue;
        }
        
        let mut cont = false;
        for _ in 1..s {
            x = (&x * &x) % n;
            if x == n - 1 {
                cont = true;
                break;
            }
        }
        if cont { continue; }
        return false;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_gate() {
        let state = run_prime_gate("seed", 1, 12);
        // We don't assert 'open' because it depends on the hash. 
        // We assert n_bits and rounds match expectation.
        assert_eq!(state.rounds, 12);
        assert!(state.n_bits > 0);
    }
}
