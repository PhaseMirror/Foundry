pub mod prime_encoding;

pub use prime_encoding::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prime_encoding() {
        let state = State(vec![1, 0, 2]); // 2^1 * 5^2 = 50
        assert_eq!(prime_support(&state), vec!["A", "C"]);
        assert_eq!(prime_signature(&state), "2·5^2");
        assert!((prime_product(&state) - 50.0).abs() < 1e-10);
        assert_eq!(l1_norm(&state), 3);
        assert_eq!(normalized_profile(&state), vec![1.0/3.0, 0.0, 2.0/3.0]);
    }
}
