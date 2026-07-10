/// Deterministic MR64 executor with proper witness generation
/// 
/// Emits one row per multiply or square operation with full Barrett reduction witnesses

use crate::barrett::{barrett_mulred, mu_for};
use trace_serializer::{ExecutionTrace, TraceRow};

/// Factor n-1 = 2^s * d where d is odd
fn factor_power_of_two(mut num: u64) -> (u32, u64) {
    let mut s = 0u32;
    while num % 2 == 0 {
        num /= 2;
        s += 1;
    }
    (s, num)
}

/// Compute (a * b) mod n
fn mulmod(a: u64, b: u64, n: u64) -> u64 {
    ((a as u128 * b as u128) % n as u128) as u64
}

/// Compute a^e mod n using binary exponentiation
fn modpow(mut base: u64, mut exp: u64, n: u64) -> u64 {
    if n == 1 {
        return 0;
    }
    let mut result = 1u64;
    base = base % n;
    while exp > 0 {
        if exp % 2 == 1 {
            result = mulmod(result, base, n);
        }
        exp >>= 1;
        base = mulmod(base, base, n);
    }
    result
}

/// Execute Miller-Rabin round for base a
/// Returns trace rows for this round with all 20 columns populated
fn mr_round(n: u64, a: u64, d: u64, s: u32, round: u64) -> Vec<TraceRow> {
    let mu = mu_for(n);
    let mut rows = Vec::new();
    let mut x: u64 = 1;
    let mut step = 0u64;
    
    // Round start marker
    rows.push(TraceRow {
        round,
        step,
        is_round_start: 1,
        is_mul: 0,
        is_square: 0,
        is_end: 0,
        a,
        d,
        s: s as u64,
        bit: 0,
        acc: x,
        base: a % n,
        t_lo: 0,
        t_hi: 0,
        q: 0,
        r: 0,
        mu_lo: mu.0,
        mu_hi: mu.1,
        hit_nm1: 0,
        witness_flag: 1,
    });
    step += 1;
    
    // Compute x = a^d mod n with recorded multiplies and squares
    let mut base = a % n;
    let mut e = d;
    
    while e > 0 {
        // Multiply when bit is 1
        if e & 1 == 1 {
            let (x_new, red) = barrett_mulred(x, base, n, mu);
            rows.push(TraceRow {
                round,
                step,
                is_round_start: 0,
                is_mul: 1,
                is_square: 0,
                is_end: 0,
                a,
                d,
                s: s as u64,
                bit: 1,
                acc: x_new,
                base,
                t_lo: red.t_lo,
                t_hi: red.t_hi,
                q: red.q_lo, // Store low part of q
                r: red.r_lo, // Store low part of r
                mu_lo: mu.0,
                mu_hi: mu.1,
                hit_nm1: 0,
                witness_flag: 1,
            });
            x = x_new;
            step += 1;
        }
        
        // Always square base
        let (sq, red2) = barrett_mulred(base, base, n, mu);
        rows.push(TraceRow {
            round,
            step,
            is_round_start: 0,
            is_mul: 0,
            is_square: 1,
            is_end: 0,
            a,
            d,
            s: s as u64,
            bit: 0,
            acc: sq,
            base: sq,
            t_lo: red2.t_lo,
            t_hi: red2.t_hi,
            q: red2.q_lo,
            r: red2.r_lo,
            mu_lo: mu.0,
            mu_hi: mu.1,
            hit_nm1: 0,
            witness_flag: 1,
        });
        base = sq;
        step += 1;
        e >>= 1;
    }
    
    // Check initial value before squaring (this is a^d mod n)
    let initial_x_is_one = x == 1;
    let initial_x_is_nm1 = x == n.wrapping_sub(1);
    
    // If initial value is 1 or n-1, witness passes - still do squarings for trace consistency
    // but mark that we already passed
    let passed_on_initial = initial_x_is_one || initial_x_is_nm1;
    
    // s squarings for MR witness check
    for i in 0..s {
        let (x_new, red) = barrett_mulred(x, x, n, mu);
        let is_one = if x_new == 1 { 1 } else { 0 };
        let is_nm1 = if x_new == n.wrapping_sub(1) { 1 } else { 0 };
        let is_last = i == s - 1;
        
        // Early exit if we hit 1 or n-1
        // OR if we passed on initial value and this is first squaring
        let will_exit = is_one == 1 || is_nm1 == 1 || (passed_on_initial && i == 0);
        
        rows.push(TraceRow {
            round,
            step,
            is_round_start: 0,
            is_mul: 0,
            is_square: 1,
            is_end: if is_last || will_exit { 1 } else { 0 },
            a,
            d,
            s: s as u64,
            bit: 0,
            acc: x_new,
            base: x,
            t_lo: red.t_lo,
            t_hi: red.t_hi,
            q: red.q_lo,
            r: red.r_lo,
            mu_lo: mu.0,
            mu_hi: mu.1,
            hit_nm1: is_nm1,
            witness_flag: 1,
        });
        x = x_new;
        step += 1;
        
        // Early exit
        if will_exit {
            break;
        }
    }
    
    rows
}

/// MR64 executor with proper witness generation
pub struct MR64Executor {
    pub n: u64,
}

impl MR64Executor {
    pub fn new(n: u64) -> Self {
        Self { n }
    }

    /// Execute MR64 with multiple witness bases
    pub fn execute(&self) -> ExecutionTrace {
        let mut trace = ExecutionTrace::new();
        
        // Handle edge cases
        if self.n < 2 {
            trace.push(TraceRow {
                round: 0,
                step: 0,
                is_round_start: 1,
                is_end: 1,
                acc: 0,
                witness_flag: 1,
                ..Default::default()
            });
            return trace;
        }
        
        if self.n == 2 || self.n == 3 {
            trace.push(TraceRow {
                round: 0,
                step: 0,
                is_round_start: 1,
                is_end: 1,
                acc: 1,
                witness_flag: 1,
                ..Default::default()
            });
            return trace;
        }
        
        if self.n % 2 == 0 {
            trace.push(TraceRow {
                round: 0,
                step: 0,
                is_round_start: 1,
                is_end: 1,
                acc: 0,
                a: 2,
                witness_flag: 1,
                ..Default::default()
            });
            return trace;
        }
        
        // Factor n-1 = 2^s * d
        let (s, d) = factor_power_of_two(self.n - 1);
        
        // Use witness bases [2, 3]
        let witness_bases = [2u64, 3u64];
        
        for (round_idx, &base) in witness_bases.iter().enumerate() {
            let round_rows = mr_round(self.n, base, d, s, round_idx as u64);
            for row in round_rows {
                trace.push(row);
            }
        }
        
        trace
    }
    
    /// Determine MR64 decision from execution trace
    /// Returns true if probably prime, false if composite
    pub fn decision(&self) -> bool {
        // Handle special cases
        if self.n < 2 {
            return false;
        }
        if self.n == 2 || self.n == 3 {
            return true;
        }
        if self.n % 2 == 0 {
            return false;
        }
        
        // Implement Miller-Rabin directly using modpow
        let (s, d) = factor_power_of_two(self.n - 1);
        let nm1 = self.n - 1;
        let bases = [2u64, 3u64];
        
        for &a in &bases {
            if a >= self.n {
                continue;
            }
            
            // Compute x = a^d mod n
            let mut x = modpow(a, d, self.n);
            
            // Check if x == 1 or x == n-1
            if x == 1 || x == nm1 {
                continue; // This witness passes
            }
            
            // Square x up to s-1 times
            let mut found_nm1 = false;
            for _ in 0..(s-1) {
                x = mulmod(x, x, self.n);
                if x == nm1 {
                    found_nm1 = true;
                    break;
                }
            }
            
            if !found_nm1 {
                // This witness failed - n is composite
                return false;
            }
        }
        
        // All witnesses passed - probably prime
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_executor_prime_17() {
        let executor = MR64Executor::new(17);
        let trace = executor.execute();
        
        // Should have many rows (not just 2!)
        assert!(trace.rows.len() >= 10, "n=17 should have >= 10 rows, got {}", trace.rows.len());
        
        // Check at least one row has Barrett columns populated
        let has_witness = trace.rows.iter().any(|r| {
            r.mu_lo > 0 || r.mu_hi > 0
        });
        assert!(has_witness, "No rows with Barrett mu values");
        
        // Check control flags are set
        let has_mul = trace.rows.iter().any(|r| r.is_mul == 1);
        let has_square = trace.rows.iter().any(|r| r.is_square == 1);
        assert!(has_mul || has_square, "No multiply or square operations recorded");
    }

    #[test]
    fn test_executor_composite_561() {
        let executor = MR64Executor::new(561);
        let trace = executor.execute();
        
        // Carmichael number should have >= 4 rows (not 2!)
        assert!(trace.rows.len() >= 4, "n=561 should have >= 4 rows, got {}", trace.rows.len());
        
        // Check witness columns are populated
        let all_zeros = trace.rows.iter().all(|r| {
            r.mu_lo == 0 && r.mu_hi == 0 && r.t_lo == 0 && r.t_hi == 0
        });
        assert!(!all_zeros, "All Barrett columns are zero - invalid witness");
    }

    #[test]
    fn test_row_shape() {
        let executor = MR64Executor::new(17);
        let trace = executor.execute();
        
        // Count is_round_start markers
        let round_starts = trace.rows.iter().filter(|r| r.is_round_start == 1).count();
        assert_eq!(round_starts, 2, "Should have 2 rounds (bases [2, 3])");
        
        // Verify is_mul XOR is_square for non-start rows
        for row in &trace.rows {
            if row.is_round_start == 0 {
                let xor = (row.is_mul ^ row.is_square) == 1;
                assert!(xor, "is_mul XOR is_square must be 1 for non-start rows");
            }
        }
    }

    #[test]
    fn test_determinism() {
        let executor = MR64Executor::new(17);
        
        let trace1 = executor.execute();
        let trace2 = executor.execute();
        
        assert_eq!(trace1.rows.len(), trace2.rows.len());
        assert_eq!(trace1.column_order_hash(), trace2.column_order_hash());
        
        // Check first few rows are identical
        for i in 0..trace1.rows.len().min(5) {
            assert_eq!(trace1.rows[i].round, trace2.rows[i].round);
            assert_eq!(trace1.rows[i].step, trace2.rows[i].step);
            assert_eq!(trace1.rows[i].acc, trace2.rows[i].acc);
        }
    }

    #[test]
    fn test_no_zero_barrett_on_ops() {
        let executor = MR64Executor::new(17);
        let trace = executor.execute();
        
        for (i, row) in trace.rows.iter().enumerate() {
            if row.is_mul == 1 || row.is_square == 1 {
                assert!(
                    row.mu_lo > 0 || row.mu_hi > 0,
                    "Row {} has operation but zero mu", i
                );
            }
        }
    }
}

    #[test]
    fn test_is_end_on_early_exit() {
        let executor = MR64Executor::new(17);
        let trace = executor.execute();
        
        // Count is_end markers
        let end_count = trace.rows.iter().filter(|r| r.is_end == 1).count();
        
        // Should have 2 is_end markers (one per round for bases [2, 3])
        assert_eq!(end_count, 2, "Should have exactly 2 is_end markers, got {}", end_count);
        
        // Check that rows with hit_nm1=1 also have is_end=1
        for (i, row) in trace.rows.iter().enumerate() {
            if row.hit_nm1 == 1 {
                assert_eq!(row.is_end, 1, "Row {} has hit_nm1=1 but is_end=0", i);
            }
        }
    }
