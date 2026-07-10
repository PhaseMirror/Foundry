/// Input validation guards for MR64 executor
///
/// These guards enforce the scope and limits of the current implementation
/// to prevent silent failures, capacity overflows, and undefined behavior.

/// Guard for n input validation
///
/// # Constraints
///
/// - n must be odd (Miller-Rabin only applies to odd composites/primes)
/// - n must be >= 3 (2 is handled separately, n=1 is trivial)
/// - n must be < 2^63 to avoid capacity overflow in trace field conversions
///
/// # Panics
///
/// Panics if n violates any constraint
///
/// # Examples
///
/// ```
/// use air_mr64::guards::guard_n;
///
/// guard_n(17); // OK - small odd prime
/// guard_n(561); // OK - Carmichael number
/// // guard_n(2); // PANIC - even
/// // guard_n(u64::MAX); // PANIC - too large
/// ```
use crate::support::support_window;

pub fn guard_n(n: u64) {
    let window = support_window();
    assert!(n >= 3, "n must be >= 3 (n=2 is even, n=1 is trivial)");
    assert!(
        n % 2 == 1,
        "n must be odd (Miller-Rabin requires odd input)"
    );

    assert!(
        n <= window.max_n,
        "n={} exceeds maximum supported value {} from support_window.json. Refuse input to avoid undefined trace growth.",
        n,
        window.max_n
    );
}

pub fn guard_trace_rows(rows: usize) {
    let window = support_window();
    assert!(
        rows <= window.max_trace_rows,
        "Trace rows {} exceed support window limit {}. Rejecting input.",
        rows,
        window.max_trace_rows
    );
}

/// Guard for trace size validation
///
/// # Constraints
///
/// - Serialized trace size must not exceed max_trace_size_bytes from support window
/// - This prevents unbounded memory growth and ensures honest benchmarking
///
/// # Panics
///
/// Panics if serialized trace size exceeds limit
pub fn guard_trace_size(trace_json: &str) {
    let window = support_window();
    let size_bytes = trace_json.as_bytes().len();
    
    assert!(
        size_bytes <= window.max_trace_size_bytes,
        "Trace size {} bytes exceeds support window limit {} bytes. Rejecting input.",
        size_bytes,
        window.max_trace_size_bytes
    );
}

/// Guard for proof size validation
///
/// # Constraints
///
/// - Binary proof blob must not exceed max_proof_size_bytes from support window
/// - Ensures on-chain calldata stays within reasonable bounds
///
/// # Panics
///
/// Panics if proof size exceeds limit
pub fn guard_proof_size(proof_bytes: &[u8]) {
    let window = support_window();
    let size_bytes = proof_bytes.len();
    
    assert!(
        size_bytes <= window.max_proof_size_bytes,
        "Proof size {} bytes exceeds support window limit {} bytes. Rejecting proof.",
        size_bytes,
        window.max_proof_size_bytes
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn guard_accepts_small_primes() {
        guard_n(3);
        guard_n(17);
        guard_n(97);
        guard_n(65537);
    }

    #[test]
    fn guard_accepts_carmichael() {
        guard_n(561);
        guard_n(1105);
        guard_n(1729);
    }

    #[test]
    fn guard_accepts_large_64bit_primes() {
        guard_n(4294967291); // 2^32 - 5
        guard_n((1u64 << 63) - 25); // 2^63 - 25
    }

    #[test]
    #[should_panic(expected = "n must be >= 3")]
    fn guard_rejects_n_equals_1() {
        guard_n(1);
    }

    #[test]
    #[should_panic(expected = "n must be >= 3")]
    fn guard_rejects_n_equals_2() {
        guard_n(2);
    }

    #[test]
    #[should_panic(expected = "n must be odd")]
    fn guard_rejects_even() {
        guard_n(100);
    }

    #[test]
    #[should_panic(expected = "exceeds maximum supported value")]
    fn guard_rejects_too_large() {
        guard_n(u64::MAX);
    }

    #[test]
    #[should_panic(expected = "exceeds maximum supported value")]
    fn guard_rejects_above_2_63() {
        guard_n((1u64 << 63) + 1);
    }

    #[test]
    fn guard_trace_rows_within_window() {
        guard_trace_rows(1024);
    }

    #[test]
    #[should_panic(expected = "Trace rows")]
    fn guard_trace_rows_rejects_large() {
        guard_trace_rows(support_window().max_trace_rows + 1);
    }

    #[test]
    fn guard_trace_size_accepts_small() {
        let small_json = r#"{"rows":[],"column_order":[]}"#;
        guard_trace_size(small_json);
    }

    #[test]
    #[should_panic(expected = "Trace size")]
    fn guard_trace_size_rejects_large() {
        // Create a very large string that exceeds the limit
        let large_size = support_window().max_trace_size_bytes + 1;
        let large_json = "x".repeat(large_size);
        guard_trace_size(&large_json);
    }

    #[test]
    fn guard_proof_size_accepts_small() {
        let small_proof = vec![0u8; 1024];
        guard_proof_size(&small_proof);
    }

    #[test]
    #[should_panic(expected = "Proof size")]
    fn guard_proof_size_rejects_large() {
        let large_size = support_window().max_proof_size_bytes + 1;
        let large_proof = vec![0u8; large_size];
        guard_proof_size(&large_proof);
    }
}
