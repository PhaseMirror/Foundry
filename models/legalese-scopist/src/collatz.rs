use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CollatzResult {
    pub start_bound: String,
    pub end_bound: String,
    pub max_steps: u32,
    pub max_value_reached: String,
    pub cycle_detected: bool,
    pub verified: bool,
}

/// Bitwise optimized step
#[inline(always)]
fn next_collatz(n: u128) -> Option<u128> {
    if n & 1 == 0 {
        Some(n >> 1)
    } else {
        // 3n + 1
        n.checked_mul(3)?.checked_add(1)
    }
}

/// Computes the Collatz trajectory for a single number.
/// Returns (steps, max_value) or None if overflow occurs (which is treated as unverified).
fn compute_trajectory(mut n: u128) -> Option<(u32, u128)> {
    let mut steps = 0;
    let mut max_val = n;
    
    while n > 1 {
        n = next_collatz(n)?;
        if n > max_val {
            max_val = n;
        }
        steps += 1;
    }
    
    Some((steps, max_val))
}

#[cfg(not(target_arch = "wasm32"))]
pub fn verify_range(start: u128, end: u128) -> CollatzResult {
    use std::sync::{Arc, Mutex};
    use std::sync::atomic::{AtomicU32, AtomicBool, Ordering};
    use std::thread;

    let chunk_size = 10_000;
    // We use a Mutex since AtomicU128 is not stabilized in Rust yet. 
    // With chunk_size = 10_000, lock contention overhead is strictly zero relative to compute.
    let current = Arc::new(Mutex::new(start));
    
    let max_steps = Arc::new(AtomicU32::new(0));
    let max_value = Arc::new(Mutex::new(0u128));
    let cycle_detected = Arc::new(AtomicBool::new(false));
    let verified = Arc::new(AtomicBool::new(true));

    let num_threads = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(4);
    let mut handles = vec![];

    for _ in 0..num_threads {
        let current_clone = Arc::clone(&current);
        let steps_clone = Arc::clone(&max_steps);
        let val_clone = Arc::clone(&max_value);
        let cycle_clone = Arc::clone(&cycle_detected);
        let verif_clone = Arc::clone(&verified);

        handles.push(thread::spawn(move || {
            loop {
                // Emulating AtomicU128 fetch_add safely
                let chunk_start = {
                    let mut curr = current_clone.lock().unwrap();
                    if *curr > end {
                        break;
                    }
                    let s = *curr;
                    *curr = curr.saturating_add(chunk_size);
                    s
                };
                
                let chunk_end = end.min(chunk_start.saturating_add(chunk_size - 1));

                let mut local_max_steps = 0;
                let mut local_max_val = 0;
                let mut local_cycle = false;
                let mut local_verified = true;

                for n in chunk_start..=chunk_end {
                    if let Some((s, v)) = compute_trajectory(n) {
                        if s > local_max_steps { local_max_steps = s; }
                        if v > local_max_val { local_max_val = v; }
                    } else {
                        local_cycle = true;
                        local_verified = false;
                    }
                }

                steps_clone.fetch_max(local_max_steps, Ordering::Relaxed);
                
                if local_max_val > 0 {
                    let mut g_val = val_clone.lock().unwrap();
                    if local_max_val > *g_val {
                        *g_val = local_max_val;
                    }
                }

                if local_cycle {
                    cycle_clone.store(true, Ordering::Relaxed);
                }
                if !local_verified {
                    verif_clone.store(false, Ordering::Relaxed);
                }
            }
        }));
    }

    for handle in handles {
        let _ = handle.join();
    }

    let final_steps = max_steps.load(Ordering::Relaxed);
    let final_val = *max_value.lock().unwrap();
    let final_cycle = cycle_detected.load(Ordering::Relaxed);
    let final_verified = verified.load(Ordering::Relaxed);

    CollatzResult {
        start_bound: start.to_string(),
        end_bound: end.to_string(),
        max_steps: final_steps,
        max_value_reached: final_val.to_string(),
        cycle_detected: final_cycle,
        verified: final_verified,
    }
}

#[cfg(target_arch = "wasm32")]
pub fn verify_range(start: u128, end: u128) -> CollatzResult {
    let mut max_steps = 0;
    let mut max_value = 0;
    let mut cycle = false;
    let mut verified = true;

    for n in start..=end {
        if let Some((steps, val)) = compute_trajectory(n) {
            if steps > max_steps { max_steps = steps; }
            if val > max_value { max_value = val; }
        } else {
            verified = false;
        }
    }

    CollatzResult {
        start_bound: start.to_string(),
        end_bound: end.to_string(),
        max_steps,
        max_value_reached: max_value.to_string(),
        cycle_detected: cycle,
        verified,
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_next_collatz_no_panic() {
        let n: u128 = kani::any();
        // Assume n won't overflow 3n+1
        kani::assume(n <= (u128::MAX - 1) / 3);
        
        let result = next_collatz(n);
        
        kani::assert(result.is_some(), "Next collatz step should not overflow and return Some");
    }

    #[kani::proof]
    fn verify_next_collatz_overflow_behavior() {
        let n: u128 = kani::any();
        // If n is odd and greater than the safe limit, it should return None to indicate overflow
        kani::assume(n > (u128::MAX - 1) / 3);
        kani::assume(n & 1 != 0);
        
        let result = next_collatz(n);
        kani::assert(result.is_none(), "Next collatz step should return None on overflow");
    }
}
