use regex::Regex;
use std::sync::LazyLock;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ProofAnchorError {
    #[error("pi_native must be 0x-prefixed 64 hex characters")]
    InvalidFormat,
}

static PI_NATIVE_RE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"^0x[a-f0-9]{64}$").unwrap()
});

pub fn validate_pi_native(pi_native: &str) -> bool {
    PI_NATIVE_RE.is_match(&pi_native.to_lowercase())
}

pub fn normalize_pi_native(pi_native: &str) -> Result<String, ProofAnchorError> {
    if !validate_pi_native(pi_native) {
        return Err(ProofAnchorError::InvalidFormat);
    }
    Ok(pi_native.to_lowercase())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_pi_native() {
        assert!(validate_pi_native("0x0000000000000000000000000000000000000000000000000000000000000000"));
        assert!(!validate_pi_native("0x123"));
        assert!(!validate_pi_native("not-hex"));
    }
}
