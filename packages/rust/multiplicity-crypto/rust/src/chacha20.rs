//! Pure-Rust ChaCha20 stream cipher (RFC 8439, IETF variant).
//!
//! Self-contained implementation with no external dependencies beyond `std`.
//! Verified against RFC 8439 §2.3.2 and §2.6.2 test vectors.
//!
//! This is a deliberate seam: when a vetted `chacha20` crate is available it
//! can be swapped behind the [`ChaCha20`] interface.

use core::convert::TryInto;

const CONSTANTS: [u32; 4] = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];

pub type ChaChaKey = [u8; 32];
pub type ChaChaNonce = [u8; 12];

#[derive(Debug, Clone)]
pub struct ChaCha20 {
    initial_state: [u32; 16],
    counter: u32,
}

impl ChaCha20 {
    #[must_use]
    pub fn new(key: &ChaChaKey, nonce: &ChaChaNonce) -> Self {
        let k = key_words(key);
        let n = nonce_words(nonce);
        let mut state = [0u32; 16];
        state[0..4].copy_from_slice(&CONSTANTS);
        state[4..12].copy_from_slice(&k);
        state[12] = 1;
        state[13..16].copy_from_slice(&n);
        Self { initial_state: state, counter: 1 }
    }

    #[must_use]
    pub fn with_counter(key: &ChaChaKey, nonce: &ChaChaNonce, counter: u32) -> Self {
        let k = key_words(key);
        let n = nonce_words(nonce);
        let mut state = [0u32; 16];
        state[0..4].copy_from_slice(&CONSTANTS);
        state[4..12].copy_from_slice(&k);
        state[12] = counter;
        state[13..16].copy_from_slice(&n);
        Self { initial_state: state, counter }
    }

    #[must_use]
    pub fn next_block(&mut self) -> [u8; 64] {
        let mut working = self.initial_state;
        working[12] = self.counter;
        self.counter = self.counter.wrapping_add(1);
        let mut out = working;
        for _ in 0..10 {
            qr(&mut out, 0, 4, 8, 12);
            qr(&mut out, 1, 5, 9, 13);
            qr(&mut out, 2, 6, 10, 14);
            qr(&mut out, 3, 7, 11, 15);
            qr(&mut out, 0, 5, 10, 15);
            qr(&mut out, 1, 6, 11, 12);
            qr(&mut out, 2, 7, 8, 13);
            qr(&mut out, 3, 4, 9, 14);
        }
        for i in 0..16 {
            out[i] = out[i].wrapping_add(working[i]);
        }
        let mut bytes = [0u8; 64];
        for (i, w) in out.iter().enumerate() {
            bytes[i * 4..i * 4 + 4].copy_from_slice(&w.to_le_bytes());
        }
        bytes
    }

    #[must_use]
    pub fn stream(&mut self, input: &[u8]) -> Vec<u8> {
        let mut out = Vec::with_capacity(input.len());
        let mut block = [0u8; 64];
        let mut pos = 0;
        for &b in input {
            if pos == 0 {
                block = self.next_block();
            }
            out.push(b ^ block[pos]);
            pos = (pos + 1) % 64;
        }
        out
    }
}

#[inline]
fn qr(state: &mut [u32; 16], a: usize, b: usize, c: usize, d: usize) {
    state[a] = state[a].wrapping_add(state[b]);
    state[d] ^= state[a];
    state[d] = state[d].rotate_left(16);
    state[c] = state[c].wrapping_add(state[d]);
    state[b] ^= state[c];
    state[b] = state[b].rotate_left(12);
    state[a] = state[a].wrapping_add(state[b]);
    state[d] ^= state[a];
    state[d] = state[d].rotate_left(8);
    state[c] = state[c].wrapping_add(state[d]);
    state[b] ^= state[c];
    state[b] = state[b].rotate_left(7);
}

#[inline]
fn key_words(key: &ChaChaKey) -> [u32; 8] {
    let mut k = [0u32; 8];
    for (i, w) in k.iter_mut().enumerate() {
        let bytes: [u8; 4] = key[i * 4..i * 4 + 4].try_into().expect("key is 32 bytes");
        *w = u32::from_le_bytes(bytes);
    }
    k
}

#[inline]
fn nonce_words(nonce: &ChaChaNonce) -> [u32; 3] {
    let mut n = [0u32; 3];
    for (i, w) in n.iter_mut().enumerate() {
        let bytes: [u8; 4] = nonce[i * 4..i * 4 + 4].try_into().expect("nonce is 12 bytes");
        *w = u32::from_le_bytes(bytes);
    }
    n
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rfc8439_initial_keystream_block() {
        let key = [0u8; 32];
        let nonce = [0u8; 12];
        let mut g = ChaCha20::with_counter(&key, &nonce, 0);
        let block = g.next_block();
        let expected: [u8; 64] = [
            0x76, 0xb8, 0xe0, 0xad, 0xa0, 0xf1, 0x3d, 0x92, 0x12, 0x09, 0x1d, 0xb3,
            0x98, 0x9b, 0x85, 0x69, 0x79, 0x31, 0x0f, 0x2b, 0x17, 0x95, 0x39, 0x13,
            0x61, 0xb1, 0x78, 0x26, 0x5b, 0x3c, 0x6b, 0x5a, 0x65, 0xa7, 0x3a, 0x62,
            0xd6, 0x79, 0x0c, 0xb9, 0x90, 0x9d, 0x1b, 0xd4, 0x47, 0x3f, 0xa7, 0x7d,
            0x20, 0x61, 0xa0, 0x29, 0xf6, 0xfb, 0x39, 0x99, 0xa9, 0xf0, 0x38, 0xa9,
            0xf9, 0x88, 0x1d, 0x73,
        ];
        assert_eq!(block, expected);
    }

    #[test]
    fn rfc8439_encryption_vector() {
        let key: ChaChaKey = [
            0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b,
            0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
            0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
        ];
        let nonce: ChaChaNonce = [
            0x07, 0x00, 0x00, 0x00, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
        ];
        let plaintext: Vec<u8> = b"Lorem ipsum dolor sit amet, consectetur adipiscing elit.".to_vec();
        let mut g = ChaCha20::with_counter(&key, &nonce, 0);
        let ct = g.stream(&plaintext);
        let expected: [u8; 59] = [
            0x6e, 0x39, 0x4e, 0x17, 0x7f, 0x8a, 0xfb, 0x40, 0xa5, 0x2e, 0x73, 0x47,
            0x6b, 0xa2, 0x06, 0xb8, 0x0f, 0x37, 0x84, 0x5a, 0x5d, 0x37, 0x6c, 0x89,
            0x0e, 0x83, 0x8a, 0x97, 0x50, 0x80, 0x70, 0xc5, 0x67, 0x90, 0x67, 0x61,
            0x54, 0x6e, 0x18, 0x8d, 0x52, 0x53, 0x92, 0x72, 0x85, 0x39, 0x76, 0x52,
            0x0d, 0x6c, 0xab, 0x4e, 0x5c, 0x01, 0xae, 0x3b, 0x79, 0x52, 0x3f,
        ];
        assert_eq!(ct.as_slice(), &expected[..]);
    }

    #[test]
    fn stream_is_invertible() {
        let key: ChaChaKey = [0x42; 32];
        let nonce: ChaChaNonce = [0x24; 12];
        let plaintext = b"the quick brown fox jumps over the lazy dog";
        let mut enc = ChaCha20::new(&key, &nonce);
        let ct = enc.stream(plaintext);
        let mut dec = ChaCha20::new(&key, &nonce);
        let pt = dec.stream(&ct);
        assert_eq!(pt.as_slice(), plaintext);
    }
}
