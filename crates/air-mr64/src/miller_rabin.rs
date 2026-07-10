/// Miller-Rabin primality test implementation for 64-bit numbers
///
/// Executes the MR64 algorithm to generate an execution trace
use goldilocks::GoldilocksField;

use crate::bigint::{BigInt, Modulus};

const SMALL_PRIMES: &[u64] = &[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31];
const WITNESS_BASES: &[u64] = &[2, 3, 5, 7, 11, 13, 17];

#[derive(Debug, Clone)]
pub struct MR64Result {
    pub is_prime: bool,
    pub trace_steps: Vec<TraceStep>,
}

#[derive(Debug, Clone)]
pub struct TraceStep {
    pub n: u64,
    pub a: u64,
    pub b: u64,
    pub result: u64,
    pub operation: Operation,
}

#[derive(Debug, Clone, Copy)]
pub enum Operation {
    TrialDivision,
    Factorization,
    ModularExp,
    WitnessCheck,
    FinalResult,
}

/// Execute Miller-Rabin primality test on n
pub fn miller_rabin_64(n: u64) -> MR64Result {
    let mut trace_steps = Vec::new();

    // Step 1: Handle small cases - but still generate trace steps!
    if n < 2 {
        trace_steps.push(TraceStep {
            n,
            a: 0,
            b: 0,
            result: 0,
            operation: Operation::FinalResult,
        });
        return MR64Result {
            is_prime: false,
            trace_steps,
        };
    }

    if n == 2 || n == 3 {
        trace_steps.push(TraceStep {
            n,
            a: 1,
            b: 1,
            result: 1,
            operation: Operation::FinalResult,
        });
        return MR64Result {
            is_prime: true,
            trace_steps,
        };
    }

    if n % 2 == 0 {
        trace_steps.push(TraceStep {
            n,
            a: 2,
            b: n / 2,
            result: 0,
            operation: Operation::TrialDivision,
        });
        return MR64Result {
            is_prime: false,
            trace_steps,
        };
    }

    // Step 2: Trial division by small primes - record all tests
    for &p in SMALL_PRIMES {
        if p > n {
            break;
        }

        let remainder = n % p;

        trace_steps.push(TraceStep {
            n,
            a: p,
            b: remainder,
            result: if remainder == 0 { 0 } else { 1 },
            operation: Operation::TrialDivision,
        });

        if n == p {
            trace_steps.push(TraceStep {
                n,
                a: 1,
                b: 1,
                result: 1,
                operation: Operation::FinalResult,
            });
            return MR64Result {
                is_prime: true,
                trace_steps,
            };
        }

        if remainder == 0 {
            return MR64Result {
                is_prime: false,
                trace_steps,
            };
        }
    }

    // Step 3: Factor n-1 = 2^s * d
    let (s, d) = factor_power_of_two(n - 1);
    let modulus = Modulus::new(BigInt::from_u64(n));

    trace_steps.push(TraceStep {
        n,
        a: s,
        b: d,
        result: n - 1,
        operation: Operation::Factorization,
    });

    // Step 4: Test witness bases
    for &base in WITNESS_BASES {
        if !witness_test(n, s, d, base, &modulus, &mut trace_steps) {
            // Composite
            return MR64Result {
                is_prime: false,
                trace_steps,
            };
        }
    }

    // Passed all witness tests - probably prime
    trace_steps.push(TraceStep {
        n,
        a: 1,
        b: 1,
        result: 1,
        operation: Operation::FinalResult,
    });

    MR64Result {
        is_prime: true,
        trace_steps,
    }
}

/// Factor out powers of 2: returns (s, d) where n = 2^s * d
fn factor_power_of_two(mut n: u64) -> (u64, u64) {
    let mut s = 0;
    while n % 2 == 0 {
        s += 1;
        n /= 2;
    }
    (s, n)
}

/// Miller-Rabin witness test
/// Returns true if base is a witness for n being prime
fn witness_test(
    n: u64,
    s: u64,
    d: u64,
    base: u64,
    modulus: &Modulus,
    trace: &mut Vec<TraceStep>,
) -> bool {
    // Compute x = base^d mod n
    let mut x = mod_exp(n, base, d, modulus, trace);

    if x == 1 || x == n - 1 {
        return true; // Inconclusive, try next witness
    }

    // Square x repeatedly s-1 times
    for _ in 0..s - 1 {
        x = mod_mul(n, x, x, modulus, trace);

        if x == n - 1 {
            return true; // Inconclusive
        }

        if x == 1 {
            return false; // Composite
        }
    }

    false // Composite
}

/// Modular exponentiation: base^exp mod n using square-and-multiply
fn mod_exp(n: u64, base: u64, mut exp: u64, modulus: &Modulus, trace: &mut Vec<TraceStep>) -> u64 {
    let mut result = 1u64;
    let mut base_power = base % n;

    while exp > 0 {
        if exp & 1 == 1 {
            result = mod_mul(n, result, base_power, modulus, trace);
        }

        base_power = mod_mul(n, base_power, base_power, modulus, trace);
        exp >>= 1;
    }

    result
}

/// Modular multiplication: (a * b) mod n using 128-bit intermediate
fn mod_mul(n: u64, a: u64, b: u64, modulus: &Modulus, trace: &mut Vec<TraceStep>) -> u64 {
    let a_big = BigInt::from_u64(a);
    let b_big = BigInt::from_u64(b);
    let result_big = modulus.mul_red(&a_big, &b_big);
    let result = result_big.to_u64().expect("MR64 result should fit in u64");

    trace.push(TraceStep {
        n,
        a,
        b,
        result,
        operation: Operation::ModularExp,
    });

    result
}

/// Convert MR64 trace to Goldilocks field trace for AIR
pub fn trace_to_field(result: &MR64Result, trace_len: usize) -> Vec<Vec<GoldilocksField>> {
    let num_cols = 10; // n, a, b, t, q, r, acc, exp_bit, s_hit, flags
    let mut trace = vec![vec![GoldilocksField::ZERO; trace_len]; num_cols];

    // Fill trace with execution steps
    for (i, step) in result.trace_steps.iter().enumerate() {
        if i >= trace_len {
            break;
        }

        trace[0][i] = GoldilocksField::new(step.n); // n (constant)
        trace[1][i] = GoldilocksField::new(step.a); // a
        trace[2][i] = GoldilocksField::new(step.b); // b
        trace[6][i] = GoldilocksField::new(step.result); // acc (result)
        trace[8][i] = GoldilocksField::ONE; // s_hit (selector - step is active)

        // Set flags based on operation
        trace[9][i] = match step.operation {
            Operation::FinalResult if result.is_prime => GoldilocksField::ONE,
            Operation::FinalResult => GoldilocksField::ZERO,
            _ => GoldilocksField::ZERO,
        };
    }

    // Pad remaining rows with inactive selectors
    let constant_n = if !result.trace_steps.is_empty() {
        result.trace_steps[0].n
    } else {
        0 // Default if no trace steps
    };

    for i in result.trace_steps.len()..trace_len {
        trace[0][i] = GoldilocksField::new(constant_n); // Keep n constant
        trace[8][i] = GoldilocksField::ZERO; // s_hit = 0 (inactive)
    }

    trace
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_known_primes() {
        let primes = vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47];

        for &p in &primes {
            let result = miller_rabin_64(p);
            assert!(result.is_prime, "Failed for prime {}", p);
        }
    }

    #[test]
    fn test_known_composites() {
        let composites = vec![4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25];

        for &c in &composites {
            let result = miller_rabin_64(c);
            assert!(!result.is_prime, "Failed for composite {}", c);
        }
    }

    #[test]
    fn test_large_prime() {
        // Mersenne prime: 2^31 - 1 = 2147483647
        let result = miller_rabin_64(2147483647);
        assert!(result.is_prime);
    }

    #[test]
    fn test_pseudoprime() {
        // Carmichael number: 561 = 3 × 11 × 17
        let result = miller_rabin_64(561);
        assert!(!result.is_prime);
    }
}
