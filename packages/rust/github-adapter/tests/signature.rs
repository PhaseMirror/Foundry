//! Port of `verify_signature` from `app/main.py`.

use github_adapter::signature::{signature_digest, verify_signature};

/// Reference vector: `hmac.new(b"secret", b"hello world", sha256).hexdigest()`
/// (verified against `openssl dgst -sha256 -hmac secret`).
const REFERENCE_DIGEST: &str = "734cc62f32841568f45715aeb9f4d7891324e6d948e4c6c60c0621cdac48623a";

const SECRET: &[u8] = b"secret";
const PAYLOAD: &[u8] = b"hello world";

#[test]
fn digest_matches_openssl_reference() {
    assert_eq!(signature_digest(SECRET, PAYLOAD), REFERENCE_DIGEST);
}

#[test]
fn valid_signature_verifies() {
    let header = format!("sha256={REFERENCE_DIGEST}");
    assert!(verify_signature(SECRET, PAYLOAD, &header));
}

#[test]
fn tampered_payload_fails() {
    let header = format!("sha256={REFERENCE_DIGEST}");
    assert!(!verify_signature(SECRET, b"hello world!", &header));
}

#[test]
fn wrong_secret_fails() {
    let header = format!("sha256={REFERENCE_DIGEST}");
    assert!(!verify_signature(b"other", PAYLOAD, &header));
}

#[test]
fn empty_header_short_circuits() {
    assert!(!verify_signature(SECRET, PAYLOAD, ""));
}

#[test]
fn missing_sha256_prefix_fails() {
    // compare_digest over "sha256=..." vs bare hex is False even though the
    // digest bytes would match.
    assert!(!verify_signature(SECRET, PAYLOAD, REFERENCE_DIGEST));
}
