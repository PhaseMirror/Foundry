use crate::types::PrimeMask;
use crate::types::{PETCEntry, PETCReport, StepInfo};
use num_prime::nt_funcs::is_prime;
use std::time::{SystemTime, UNIX_EPOCH};

const P_64: &[u64] = &[
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
    101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193,
    197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307,
    311,
];

pub struct PETCLedger<T> {
    pub max_gap: u64,
    pub min_length: usize,
    entries: Vec<PETCEntry<T>>,
}

impl<T> PETCLedger<T> {
    pub fn new(max_gap: u64, min_length: usize) -> Self {
        Self {
            max_gap,
            min_length,
            entries: Vec::new(),
        }
    }

    pub fn append(
        &mut self,
        prime: u64,
        event: Option<T>,
        mut info: Option<StepInfo>,
    ) -> Result<&PETCEntry<T>, String> {
        if !is_prime(&prime, None).probably() {
            return Err(format!("non-prime index: {}", prime));
        }

        // Check if it's in P_64 and set the prime mask in info if so.
        if let Some(ref mut step_info) = info {
            if let Some(pos) = P_64.iter().position(|&p| p == prime) {
                step_info.prime_mask = Some(PrimeMask(1 << pos));
            }
        }

        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs_f64();

        let entry = PETCEntry {
            prime,
            event,
            info,
            timestamp: Some(timestamp),
        };
        self.entries.push(entry);
        Ok(self.entries.last().unwrap())
    }

    pub fn entries(&self) -> &[PETCEntry<T>] {
        &self.entries
    }

    pub fn coverage(&self, lo: u64, hi: u64) -> f64 {
        if hi < lo {
            return 0.0;
        }

        let mut denominator = 0;
        for val in lo..=hi {
            if is_prime(&val, None).probably() {
                denominator += 1;
            }
        }

        if denominator == 0 {
            return 0.0;
        }

        let mut present_count = 0;
        let mut seen = std::collections::HashSet::new();
        for entry in &self.entries {
            if entry.prime >= lo && entry.prime <= hi {
                if seen.insert(entry.prime) {
                    present_count += 1;
                }
            }
        }

        present_count as f64 / denominator as f64
    }

    pub fn validate(&self) -> PETCReport {
        let primes: Vec<u64> = self.entries.iter().map(|e| e.prime).collect();
        let chain_length = primes.len();

        if chain_length == 0 {
            return PETCReport {
                satisfied: false,
                chain_length: 0,
                coverage: 0.0,
                gap_violations: Vec::new(),
                monotonic: true,
                violations: Vec::new(),
                primes_checked: Vec::new(),
            };
        }

        let violations: Vec<u64> = primes
            .iter()
            .enumerate()
            .filter(|(_, p)| !is_prime(*p, None).probably())
            .map(|(i, _)| i as u64)
            .collect();

        let monotonic = primes.windows(2).all(|w| w[0] < w[1]);

        let gap_violations: Vec<(u64, u64)> = primes
            .windows(2)
            .filter(|w| w[1] - w[0] > self.max_gap)
            .map(|w| (w[0], w[1]))
            .collect();

        let coverage = if monotonic {
            self.coverage(primes[0], *primes.last().unwrap())
        } else {
            0.0
        };

        let satisfied = violations.is_empty()
            && monotonic
            && gap_violations.is_empty()
            && chain_length >= self.min_length;

        PETCReport {
            satisfied,
            chain_length,
            coverage,
            gap_violations,
            monotonic,
            violations,
            primes_checked: primes,
        }
    }
}

pub fn infinite_prime_check(primes: &[u64], min_density: f64) -> serde_json::Value {
    let mut primes_list: Vec<u64> = primes
        .iter()
        .cloned()
        .filter(|&p| is_prime(&p, None).probably())
        .collect();
    primes_list.sort();
    primes_list.dedup();

    if primes_list.is_empty() {
        return serde_json::json!({"ok": false, "reason": "no primes"});
    }

    let largest = *primes_list.last().unwrap();
    let density = primes_list.len() as f64 / largest.max(1) as f64;
    let gaps: Vec<u64> = primes_list.windows(2).map(|w| w[1] - w[0]).collect();
    let largest_gap = gaps.iter().max().cloned().unwrap_or(0);

    serde_json::json!({
        "ok": density >= min_density,
        "density": density,
        "largest_gap": largest_gap,
        "count": primes_list.len(),
        "support": primes_list,
    })
}
