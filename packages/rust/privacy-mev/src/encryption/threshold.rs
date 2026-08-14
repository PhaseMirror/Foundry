use base64::{Engine as _, engine::general_purpose::STANDARD};
use crate::utils::shamir::{self, Share};
use crate::utils::keccak::{viem_to_hex_str, viem_keccak256, viem_from_hex_str};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq, Eq)]
pub struct EncryptedPayload {
    pub ciphertext: String,
    pub commitment: String,
    pub signature: String,
    pub timelock: Option<u64>,
}

#[derive(serde::Deserialize, serde::Serialize)]
struct ShareJson {
    x: String,
    y: String,
}

#[derive(serde::Deserialize, serde::Serialize)]
struct HybridWrapper {
    data: String,
    shares: String,
}

pub struct ThresholdEncryption;

impl ThresholdEncryption {
    pub fn encrypt(payload: &str, threshold: usize) -> Result<EncryptedPayload, anyhow::Error> {
        encrypt(payload, threshold)
    }

    pub fn decrypt(encrypted: &EncryptedPayload, shares: &[String]) -> Result<String, anyhow::Error> {
        decrypt(encrypted, shares)
    }

    pub fn generate_key_shares(n: usize, k: usize) -> Result<Vec<String>, anyhow::Error> {
        generate_key_shares(n, k)
    }
}

/// Encrypts a payload. If the payload length in hex is > 32 (rough threshold),
/// it uses hybrid encryption. Otherwise, it uses direct SSS.
pub fn encrypt(payload: &str, threshold: usize) -> Result<EncryptedPayload, anyhow::Error> {
    let hex_repr = viem_to_hex_str(payload);
    
    // Equivalent to hex.length > 32 in JS (excluding '0x' prefix)
    let clean_hex = hex_repr.strip_prefix("0x").unwrap_or(&hex_repr);
    if clean_hex.len() > 32 {
        return encrypt_hybrid(payload, threshold);
    }

    let secret = u128::from_str_radix(clean_hex, 16)?;
    let n = threshold * 2;
    let shares = shamir::split(secret, n, threshold)?;

    let share_jsons: Vec<ShareJson> = shares
        .into_iter()
        .map(|s| ShareJson {
            x: s.x.to_string(),
            y: s.y.to_string(),
        })
        .collect();

    let ciphertext = serde_json::to_string(&share_jsons)?;
    let commitment = viem_keccak256(&hex_repr);

    // Mock timelock (approx 1 second from now, using dummy Unix timestamp)
    let dummy_now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0);

    Ok(EncryptedPayload {
        ciphertext,
        commitment,
        signature: "0xmock_signature".to_string(),
        timelock: Some(dummy_now + 1000),
    })
}

fn encrypt_hybrid(payload: &str, threshold: usize) -> Result<EncryptedPayload, anyhow::Error> {
    // Ephemeral key (weak random/timestamp for prototype parity)
    let dummy_now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0);
    
    let key = dummy_now as u128;
    
    // Encrypt payload with key: mock XOR / format
    let b64_payload = STANDARD.encode(payload.as_bytes());
    let encrypted_data = format!("aes_mock:{}:{}", key, b64_payload);

    let n = threshold * 2;
    let key_shares = shamir::split(key, n, threshold)?;

    let share_jsons: Vec<ShareJson> = key_shares
        .into_iter()
        .map(|s| ShareJson {
            x: s.x.to_string(),
            y: s.y.to_string(),
        })
        .collect();

    let serialized_key_shares = serde_json::to_string(&share_jsons)?;

    let wrapper = HybridWrapper {
        data: encrypted_data,
        shares: serialized_key_shares,
    };

    let ciphertext = serde_json::to_string(&wrapper)?;
    let commitment = viem_keccak256(&viem_to_hex_str(payload));

    Ok(EncryptedPayload {
        ciphertext,
        commitment,
        signature: "0xmock_hybrid_sig".to_string(),
        timelock: None,
    })
}

/// Decrypts an encrypted payload using the provided key shares.
pub fn decrypt(encrypted: &EncryptedPayload, shares: &[String]) -> Result<String, anyhow::Error> {
    // Try parsing as HybridWrapper first
    if let Ok(wrapper) = serde_json::from_str::<HybridWrapper>(&encrypted.ciphertext) {
        if wrapper.data.starts_with("aes_mock:") {
            return decrypt_hybrid(&wrapper.data, shares);
        }
    }

    // Fall back to direct Shamir Secret Sharing
    let share_objs = parse_shares(shares)?;
    let recovered_secret = shamir::combine(&share_objs)?;

    // Convert recovered bigint back to hex string
    let hex_val = format!("{:x}", recovered_secret);
    // Pad to ensure even length for hex decoding
    let padded_hex = if hex_val.len() % 2 != 0 {
        format!("0{}", hex_val)
    } else {
        hex_val
    };

    viem_from_hex_str(&format!("0x{}", padded_hex))
}

fn decrypt_hybrid(encrypted_data: &str, shares: &[String]) -> Result<String, anyhow::Error> {
    let parts: Vec<&str> = encrypted_data.split(':').collect();
    if parts.len() < 3 || parts[0] != "aes_mock" {
        return Err(anyhow::anyhow!("Unknown encryption format"));
    }

    let expected_key_str = parts[1];
    let share_objs = parse_shares(shares)?;
    let recovered_key = shamir::combine(&share_objs)?;

    if recovered_key.to_string() != expected_key_str {
        return Err(anyhow::anyhow!("Decryption failed: Invalid key shares"));
    }

    let decoded_bytes = STANDARD.decode(parts[2])?;
    let decrypted = String::from_utf8(decoded_bytes)?;
    Ok(decrypted)
}

fn parse_shares(shares: &[String]) -> Result<Vec<Share>, anyhow::Error> {
    shares
        .iter()
        .map(|s| {
            let parsed: ShareJson = serde_json::from_str(s)?;
            let x = parsed.x.parse::<u128>()?;
            let y = parsed.y.parse::<u128>()?;
            Ok(Share { x, y })
        })
        .collect()
}

pub fn generate_key_shares(n: usize, k: usize) -> Result<Vec<String>, anyhow::Error> {
    let mut shares = Vec::with_capacity(n);
    for i in 0..n {
        shares.push(format!("pub_share_{}_{}", i, k));
    }
    Ok(shares)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_threshold_encryption_direct() {
        let payload = "hello"; // fits in 32 hex chars
        let encrypted = encrypt(payload, 3).unwrap();
        
        // Extract shares from ciphertext for testing
        let share_jsons: Vec<ShareJson> = serde_json::from_str(&encrypted.ciphertext).unwrap();
        let shares_str: Vec<String> = share_jsons
            .iter()
            .map(|s| serde_json::to_string(s).unwrap())
            .collect();

        // Needs at least 3 shares
        let decrypted = decrypt(&encrypted, &shares_str[0..3]).unwrap();
        assert_eq!(decrypted, payload);
    }

    #[test]
    fn test_threshold_encryption_hybrid() {
        // Longer payload to force hybrid mode
        let payload = "this is a very long payload that definitely does not fit in 16 bytes/32 hex characters limit";
        let encrypted = encrypt(payload, 2).unwrap();

        // Extract shares
        let wrapper: HybridWrapper = serde_json::from_str(&encrypted.ciphertext).unwrap();
        let share_jsons: Vec<ShareJson> = serde_json::from_str(&wrapper.shares).unwrap();
        let shares_str: Vec<String> = share_jsons
            .iter()
            .map(|s| serde_json::to_string(s).unwrap())
            .collect();

        let decrypted = decrypt(&encrypted, &shares_str[0..2]).unwrap();
        assert_eq!(decrypted, payload);
    }
}
