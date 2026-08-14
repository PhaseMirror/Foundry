use blake3::Hasher;
use serde::{Deserialize, Serialize};

/// Classical Signature Quotient Descriptor (C-SQD).
/// This structure captures the classical parameters required to compute the experimental
/// prime set and witness for the open quantum system CPTP channel.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CSQD {
    pub experiment_id: String,
    pub deformation_g: f64,
    pub num_primes: usize,
    pub signature_payload: Vec<u8>,
}

/// The output of the CSQD Adapter.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CSQDResult {
    /// The ordered prime list emitted for the experimental run.
    pub primes: Vec<u64>,
    /// Optional collision-resistant witness for the run (Blake3 hash of primes and signature).
    pub witness: Option<String>,
}

/// A thin pure-classical C-SQD -> prime-set adapter.
pub struct CSQDAdapter;

impl CSQDAdapter {
    /// Helper to generate the first N primes.
    fn generate_primes(n: usize) -> Vec<u64> {
        let mut primes = Vec::with_capacity(n);
        let mut current = 2;
        while primes.len() < n {
            if Self::is_prime(current) {
                primes.push(current);
            }
            current += 1;
        }
        primes
    }

    fn is_prime(num: u64) -> bool {
        if num < 2 {
            return false;
        }
        if num == 2 || num == 3 {
            return true;
        }
        if num % 2 == 0 || num % 3 == 0 {
            return false;
        }
        let mut i = 5;
        while i * i <= num {
            if num % i == 0 || num % (i + 2) == 0 {
                return false;
            }
            i += 6;
        }
        true
    }

    /// Process a C-SQD and emit the ordered prime list and optional witness.
    pub fn process(csqd: &CSQD, emit_witness: bool) -> CSQDResult {
        // Generate the ordered list of primes
        let primes = Self::generate_primes(csqd.num_primes);
        
        let witness = if emit_witness {
            let mut hasher = Hasher::new();
            hasher.update(csqd.experiment_id.as_bytes());
            hasher.update(&csqd.deformation_g.to_le_bytes());
            for p in &primes {
                hasher.update(&p.to_le_bytes());
            }
            hasher.update(&csqd.signature_payload);
            Some(hasher.finalize().to_hex().to_string())
        } else {
            None
        };

        CSQDResult { primes, witness }
    }
}
