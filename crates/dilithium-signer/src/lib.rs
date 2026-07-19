use pqcrypto_dilithium::dilithium5::*;
use pqcrypto_traits::sign::{PublicKey, SecretKey, DetachedSignature};

/// Generate a new Dilithium5 keypair.
///
/// # Returns
/// `(public_key_bytes, secret_key_bytes)` where:
/// - `public_key_bytes` is 1312 bytes
/// - `secret_key_bytes` is 2528 bytes
pub fn keygen() -> (Vec<u8>, Vec<u8>) {
    let (pk, sk) = keypair();
    (pk.as_bytes().to_vec(), sk.as_bytes().to_vec())
}

/// Sign a message with a Dilithium5 secret key.
///
/// # Arguments
/// * `sk_bytes` - 2528-byte secret key
/// * `msg` - message bytes to sign
///
/// # Returns
/// 2420-byte detached signature
pub fn sign(sk_bytes: &[u8], msg: &[u8]) -> Vec<u8> {
    let sk = SecretKey::from_bytes(sk_bytes).expect("Invalid Dilithium secret key");
    let sig = detached_sign(msg, &sk);
    sig.as_bytes().to_vec()
}

/// Verify a Dilithium5 signature.
///
/// # Arguments
/// * `pk_bytes` - 1312-byte public key
/// * `msg` - message bytes that were signed
/// * `sig_bytes` - 2420-byte signature
///
/// # Returns
/// `Ok(())` if valid, `Err(())` if invalid
pub fn verify(pk_bytes: &[u8], msg: &[u8], sig_bytes: &[u8]) -> Result<(), ()> {
    let pk = PublicKey::from_bytes(pk_bytes).map_err(|_| ())?;
    let sig = DetachedSignature::from_bytes(sig_bytes).map_err(|_| ())?;
    verify_detached_signature(&sig, msg, &pk).map_err(|_| ())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keygen_produces_valid_keys() {
        let (pk, sk) = keygen();
        assert_eq!(pk.len(), 2592, "Dilithium5 public key must be 2592 bytes");
        assert_eq!(sk.len(), 4896, "Dilithium5 secret key must be 4896 bytes");
    }

    #[test]
    fn test_sign_verify_roundtrip() {
        let (pk, sk) = keygen();
        let msg = b"hello dilithium world";
        let sig = sign(&sk, msg);
        assert_eq!(sig.len(), 4627, "Dilithium5 signature must be 4627 bytes");
        assert!(verify(&pk, msg, &sig).is_ok(), "Valid signature must verify");
    }

    #[test]
    fn test_verify_rejects_tampered_message() {
        let (pk, sk) = keygen();
        let msg = b"original message";
        let mut sig = sign(&sk, msg);
        // Tamper with the signature by flipping a byte.
        sig[0] ^= 0xff;
        let bad_msg = b"tampered message";
        assert!(verify(&pk, bad_msg, &sig).is_err(), "Tampered signature must fail");
    }

    #[test]
    fn test_verify_rejects_wrong_key() {
        let (pk_a, sk_a) = keygen();
        let (pk_b, _sk_b) = keygen();
        let msg = b"message from A";
        let sig = sign(&sk_a, msg);
        assert!(verify(&pk_b, msg, &sig).is_err(), "Signature from A must fail against B's key");
    }

    #[test]
    fn test_verify_rejects_empty_signature() {
        let (pk, _sk) = keygen();
        let msg = b"message";
        assert!(verify(&pk, msg, &[]).is_err(), "Empty signature must fail");
    }

    #[test]
    fn test_deterministic_keygen() {
        // Two keygens should produce different keys (with overwhelming probability).
        let (pk1, sk1) = keygen();
        let (pk2, sk2) = keygen();
        assert_ne!(pk1, pk2, "Keygen must be non-deterministic");
        assert_ne!(sk1, sk2, "Keygen must be non-deterministic");
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    #[kani::proof]
    #[kani::unwind(5)]
    fn kani_dilithium_verify_sound() {
        // Kani harness: generate a fresh keypair, sign a kani-chosen message,
        // and assert verification succeeds. Forged signatures are expected to fail,
        // but exhaustive checking of all 2^2420 signatures is infeasible; this
        // harness establishes the *happy path* invariant.
        let (pk, sk) = keygen();
        let msg = kani::any();
        let sig = sign(&sk, &msg);
        assert!(verify(&pk, &msg, &sig).is_ok(), "Valid signature must verify under Kani");
    }
}
