const ROUND_CONSTANTS: [u64; 24] = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000,
    0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
    0x000000008000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
];

const ROTATION_OFFSETS: [u32; 25] = [
    0,  1, 62, 28, 27,
   36, 44,  6, 55, 20,
    3, 10, 43, 25, 39,
   41, 45, 15, 21,  8,
   18,  2, 61, 56, 14,
];

fn keccak_f1600(state: &mut [u64; 25]) {
    for &rc in ROUND_CONSTANTS.iter() {
        // Theta step
        let mut c = [0u64; 5];
        for x in 0..5 {
            c[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        }
        let mut d = [0u64; 5];
        for x in 0..5 {
            let prev = c[(x + 4) % 5];
            let next = c[(x + 1) % 5];
            d[x] = prev ^ next.rotate_left(1);
        }
        for x in 0..5 {
            for y in 0..5 {
                state[x + y * 5] ^= d[x];
            }
        }

        // Rho and Pi steps
        let mut temp_state = [0u64; 25];
        for x in 0..5 {
            for y in 0..5 {
                let idx = x + y * 5;
                let new_x = y;
                let new_y = (2 * x + 3 * y) % 5;
                let new_idx = new_x + new_y * 5;
                temp_state[new_idx] = state[idx].rotate_left(ROTATION_OFFSETS[idx]);
            }
        }

        // Chi step
        for y in 0..5 {
            for x in 0..5 {
                let idx = x + y * 5;
                let idx_next = ((x + 1) % 5) + y * 5;
                let idx_next2 = ((x + 2) % 5) + y * 5;
                state[idx] = temp_state[idx] ^ ((!temp_state[idx_next]) & temp_state[idx_next2]);
            }
        }

        // Iota step
        state[0] ^= rc;
    }
}

pub fn keccak256(data: &[u8]) -> [u8; 32] {
    let mut state = [0u64; 25];
    let mut offset = 0;
    let rate_bytes = 136;

    // Process complete blocks
    while offset + rate_bytes <= data.len() {
        let block = &data[offset..offset + rate_bytes];
        for i in 0..17 {
            let mut word = 0u64;
            for j in 0..8 {
                word |= (block[i * 8 + j] as u64) << (j * 8);
            }
            state[i] ^= word;
        }
        keccak_f1600(&mut state);
        offset += rate_bytes;
    }

    // Process remaining bytes and apply padding
    let mut block = vec![0u8; rate_bytes];
    let remaining = data.len() - offset;
    block[..remaining].copy_from_slice(&data[offset..]);

    // Padding byte 0x01 for Keccak-256 (not SHA3)
    block[remaining] = 0x01;
    // Padding byte 0x80 at the end of block
    block[rate_bytes - 1] |= 0x80;

    // Process the final block
    for i in 0..17 {
        let mut word = 0u64;
        for j in 0..8 {
            word |= (block[i * 8 + j] as u64) << (j * 8);
        }
        state[i] ^= word;
    }
    keccak_f1600(&mut state);

    // Extract 32-byte digest
    let mut digest = [0u8; 32];
    for i in 0..4 {
        let word = state[i];
        for j in 0..8 {
            digest[i * 8 + j] = (word >> (j * 8)) as u8;
        }
    }
    digest
}

/// Converts a UTF-8 string to a "0x" prefixed hex string representing its bytes.
pub fn viem_to_hex_str(val: &str) -> String {
    format!("0x{}", hex::encode(val.as_bytes()))
}

/// Converts a bigint (u128) to a minimum-length big-endian "0x" prefixed hex string.
pub fn viem_to_hex_bigint(val: u128) -> String {
    if val == 0 {
        return "0x00".to_string();
    }
    let bytes = val.to_be_bytes();
    if let Some(first_non_zero) = bytes.iter().position(|&b| b != 0) {
        format!("0x{}", hex::encode(&bytes[first_non_zero..]))
    } else {
        "0x00".to_string()
    }
}

/// Computes the Keccak-256 hash of the decoded bytes of a "0x" prefixed hex string,
/// and returns the result as a "0x" prefixed 32-byte hex string.
pub fn viem_keccak256(hex_str: &str) -> String {
    let clean_hex = hex_str.strip_prefix("0x").unwrap_or(hex_str);
    let bytes = hex::decode(clean_hex).unwrap_or_else(|_| vec![]);
    let hash_bytes = keccak256(&bytes);
    format!("0x{}", hex::encode(hash_bytes))
}

/// Decodes a "0x" prefixed hex string back to a UTF-8 string.
pub fn viem_from_hex_str(hex_str: &str) -> Result<String, anyhow::Error> {
    let clean_hex = hex_str.strip_prefix("0x").unwrap_or(hex_str);
    let bytes = hex::decode(clean_hex)?;
    String::from_utf8(bytes).map_err(|e| anyhow::anyhow!(e))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keccak256_empty() {
        let hash = keccak256(&[]);
        assert_eq!(
            hex::encode(hash),
            "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
        );
    }

    #[test]
    fn test_keccak256_zero_byte() {
        let hash = keccak256(&[0]);
        assert_eq!(
            hex::encode(hash),
            "bc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a"
        );
    }

    #[test]
    fn test_viem_helpers() {
        let hex_str = viem_to_hex_str("hello");
        assert_eq!(hex_str, "0x68656c6c6f");
        
        let back = viem_from_hex_str(&hex_str).unwrap();
        assert_eq!(back, "hello");

        let hash = viem_keccak256(&hex_str);
        assert_eq!(
            hash,
            "0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8" // keccak256("hello")
        );

        assert_eq!(viem_to_hex_bigint(0), "0x00");
        assert_eq!(viem_to_hex_bigint(1), "0x01");
        assert_eq!(viem_to_hex_bigint(256), "0x0100");
    }
}
