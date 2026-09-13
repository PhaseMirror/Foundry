//! Port of `verify_signature` from `app/main.py`.
//!
//! `verify_signature(payload_body, signature_header)` uses
//! `hmac.new(secret, payload, hashlib.sha256).hexdigest()` and compares
//! against `"sha256={digest}"` via `hmac.compare_digest`.

use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

/// `hmac.new(secret, payload, sha256).hexdigest()` — lowercase hex.
pub fn signature_digest(secret: &[u8], payload: &[u8]) -> String {
    let mut mac = HmacSha256::new_from_slice(secret).expect("HMAC accepts keys of any length");
    mac.update(payload);
    hex::encode(mac.finalize().into_bytes())
}

/// `expected = f"sha256={digest}"; return hmac.compare_digest(expected, header)`.
///
/// An empty/absent header is rejected up front (matches the Python guard).
/// The final comparison is constant-time over equal-length byte strings.
pub fn verify_signature(secret: &[u8], payload: &[u8], header: &str) -> bool {
    if header.is_empty() {
        return false;
    }
    let expected = format!("sha256={}", signature_digest(secret, payload));
    constant_time_eq(expected.as_bytes(), header.as_bytes())
}

/// Constant-time equality over byte slices (length mismatch short-circuits,
/// exactly as `hmac.compare_digest` does for str bytes).
fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}
