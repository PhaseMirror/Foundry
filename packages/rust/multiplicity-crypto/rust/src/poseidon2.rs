//! Poseidon2 sponge permutation over the M61 prime field (`t=9, r=8`).
//!
//! Ported from `pirtm-engine/src/poseidon2.rs` (ADR-0066 §"Cryptographic
//! Bridging"). This is the ZK-compatible commitment backend — the BN254
//! scalar-field substitution is a documented seam (see pirtm-engine docs).
//!
//! Parameters: `p = 2^61 − 1`, width `t = 9`, rate `r = 8`, capacity `1`,
//! `R = 10` rounds, S-box `x ↦ x⁵`.

use crate::commitment::Digest32;
use sha2::{Digest, Sha256};

/// M61: `p = 2^61 − 1`.
pub const M61_PRIME: u64 = (1u64 << 61) - 1;

/// Sponge width `t`.
pub const WIDTH: usize = 9;
/// Sponge rate `r = t − capacity`.
pub const RATE: usize = 8;
/// Capacity (single lane).
pub const CAPACITY: usize = 1;
/// Rounds of the permutation.
pub const ROUNDS: usize = 10;

/// Modular multiplication mod `p = 2^61 − 1` via the Mersenne fold.
#[inline]
#[must_use]
pub const fn mul_mod(a: u64, b: u64) -> u64 {
    let ab = (a as u128) * (b as u128);
    let p = M61_PRIME as u128;
    let mut x = (ab & p) + (ab >> 61);
    while x >= p {
        x -= p;
    }
    x as u64
}

/// S-box: `x ↦ x⁵ mod p`.
#[inline]
#[must_use]
pub fn sbox5(x: u64) -> u64 {
    let x2 = mul_mod(x, x);
    let x4 = mul_mod(x2, x2);
    mul_mod(x4, x)
}

/// Deterministic round constants (`SHA-256("poseidon2-t9r8-round-{i}")` reduced
/// mod `p`), giving a nothing-up-my-sleeve schedule.
#[must_use]
pub fn round_constants() -> [[u64; WIDTH]; ROUNDS] {
    let mut mat = [[0u64; WIDTH]; ROUNDS];
    for (r, row) in mat.iter_mut().enumerate() {
        for (lane, cell) in row.iter_mut().enumerate() {
            let label = format!("poseidon2-t9r8-round-{r}-lane-{lane}");
            let digest = Sha256::digest(label.as_bytes());
            let word = u64::from_be_bytes(digest[0..8].try_into().expect("8-byte window"));
            *cell = word % M61_PRIME;
        }
    }
    mat
}

const CIRCULANT: [u64; WIDTH] = [2, 1, 1, 1, 1, 1, 1, 1, 1];

/// One round: S-box, circulant mix, constant addition.
#[inline]
pub fn round_apply(state: &mut [u64; WIDTH], constants: [u64; WIDTH]) {
    for lane in state.iter_mut() {
        *lane = sbox5(*lane);
    }
    let mut mixed = [0u64; WIDTH];
    for i in 0..WIDTH {
        let mut acc: u64 = 0;
        for j in 0..WIDTH {
            acc = acc.wrapping_add(mul_mod(CIRCULANT[(i + j) % WIDTH], state[j]));
        }
        mixed[i] = acc % M61_PRIME;
    }
    for i in 0..WIDTH {
        mixed[i] = mixed[i].wrapping_add(constants[i]);
        mixed[i] %= M61_PRIME;
    }
    *state = mixed;
}

/// Full permutation over the 9-lane state.
pub fn permute(state: &mut [u64; WIDTH]) {
    let constants = round_constants();
    for entry in constants {
        round_apply(state, entry);
    }
}

/// A deterministic Poseidon2-shaped sponge instance (`t=9, r=8`).
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Poseidon2Sponge {
    state: [u64; WIDTH],
}

impl Poseidon2Sponge {
    #[must_use]
    pub const fn new() -> Self {
        Self { state: [0u64; WIDTH] }
    }

    pub fn absorb(&mut self, bytes: &[u8]) {
        let mut lanes = [0u64; RATE];
        let mut lane = 0usize;
        let mut word: u64 = 0;
        for (i, byte) in bytes.iter().enumerate() {
            word = (word << 8) | u64::from(*byte);
            if (i + 1) % 8 == 0 {
                lanes[lane % RATE] ^= word % M61_PRIME;
                word = 0;
                lane += 1;
                if lane % RATE == 0 {
                    self.permute_with_lanes(&lanes);
                    lanes = [0u64; RATE];
                }
            }
        }
        if word != 0 {
            lanes[lane % RATE] ^= word % M61_PRIME;
            lane += 1;
        }
        if lane % RATE != 0 {
            self.permute_with_lanes(&lanes);
        }
    }

    fn permute_with_lanes(&mut self, lanes: &[u64; RATE]) {
        for (i, lane) in lanes.iter().enumerate() {
            self.state[i] ^= *lane;
        }
        permute(&mut self.state);
    }

    #[must_use]
    pub fn squeeze_bytes32(&mut self) -> [u8; 32] {
        permute(&mut self.state);
        let mut out = [0u8; 32];
        for (i, lane) in self.state[..4].iter().enumerate() {
            out[i * 8..(i + 1) * 8].copy_from_slice(&lane.to_be_bytes());
        }
        out
    }

    /// One-shot seal over a payload (256-bit `crmf_validity_seal`).
    #[must_use]
    pub fn seal(payload: &[u8]) -> [u8; 32] {
        let mut sponge = Self::new();
        sponge.absorb(payload);
        sponge.squeeze_bytes32()
    }
}

/// Compute a Poseidon2 seal over a byte payload.
#[must_use]
pub fn crc32_seal(payload: &[u8]) -> Digest32 {
    Poseidon2Sponge::seal(payload)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn m61_is_actually_prime_input_space() {
        let x = M61_PRIME - 1;
        let one = mul_mod(x, mul_mod(x, x));
        assert_ne!(one, 0);
    }

    #[test]
    fn mul_mod_field_laws() {
        assert_eq!(mul_mod(2, 1), 2);
        assert_eq!(mul_mod(2, 2), 4);
        assert_eq!(mul_mod(M61_PRIME - 1, M61_PRIME - 1), 1);
        assert_eq!(mul_mod(0, 5), 0);
    }

    #[test]
    fn sbox_fixed_points() {
        assert_eq!(sbox5(0), 0);
        assert_eq!(sbox5(1), 1);
    }

    #[test]
    fn seal_is_deterministic() {
        let a = crc32_seal(b"gap-payload-42");
        let b = crc32_seal(b"gap-payload-42");
        assert_eq!(a, b);
    }

    #[test]
    fn seal_is_differentiating() {
        let a = crc32_seal(b"gap-payload-42");
        let b = crc32_seal(b"gap-payload-43");
        assert_ne!(a, b);
    }

    #[test]
    fn seal_reference_vector_stable() {
        let seal = crc32_seal(b"prism-pirtm-interop-0066");
        let hex = hex::encode(seal);
        assert_eq!(
            hex,
            "015ae304023b78cc126c911f53f37b920669d3403be843ac165fc680d7ae86eb"
        );
    }
}
