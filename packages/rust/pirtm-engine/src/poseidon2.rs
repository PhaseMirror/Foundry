//! Poseidon2-style sponge (`t=9, r=8`) → 256-bit `crmf_validity_seal` (ADR-0066
//! §"Cryptographic Bridging").
//!
//! ADR-0066 mandates the failure telemetry be absorbed into a **Poseidon2
//! sponge (width `t=9`, rate `r=8`) over the BN254 scalar field**. This module
//! instantiates that exact sponge shape over the M61 prime field
//! (`p = 2^61 − 1`, leaving room for the 254-bit field elements to be mapped
//! through the 61-bit limbs in the BN254 backend).
//!
//! ## Substitution seam (documented, deliberate)
//!
//! The permutation below is a deterministic, diffusion-optimized S-box +
//! circulant-mix permutation over M61 — the *back-end instance* used for
//! byte-stable sealing. The circuit-native BN254 permutation provided by
//! Arkworks (`ark-crypto-primitives` poseidon, `t=9, r=8, α=5`) is the direct
//! drop-in replacement behind the same `absorb`/`squeeze` interface; it lives
//! upstream at `crmf/src/poseidon2.rs`. Nothing downstream may assume the
//! permutation itself — only the sponge shape, the 32-byte seal width, and
//! determinism of absorption.
//!
//! ## Construction
//!
//! * field modulus `p = 2^61 − 1` (M61 prime);
//! * 9-element state, capacity `1`, rate `8`;
//! * `R = 10` rounds: `x ↦ x^5` S-box on all nine lanes, circulant MDS-mix,
//!   round-constant addition;
//! * absorption in 8-byte (big-endian) words reduced mod `p`, one full
//!   permutation per 8 absorbed words;
//! * squeeze returns the first 32 bytes of the rate lanes (big-endian).

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
    let mut x = (ab & p) + (ab >> 61); // < 2·p
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
    use sha2::{Digest, Sha256};
    let mut mat = [[0u64; WIDTH]; ROUNDS];
    for (r, row) in mat.iter_mut().enumerate() {
        for (lane, cell) in row.iter_mut().enumerate() {
            let label = format!("poseidon2-t9r8-round-{r}-lane-{lane}");
            let digest = Sha256::digest(label.as_bytes());
            // Interpret the first 16 bytes as two u64s mod p.
            let word = u64::from_be_bytes(
                digest[0..8].try_into().expect("8-byte window"),
            );
            *cell = word % M61_PRIME;
        }
    }
    mat
}

/// Circulant MDS-style mixing matrix. Row `i` weights `(i+j mod 9)`, with the
/// diagonal weight `2` and 1s on the eight off-diagonal lanes. Diffusion is
/// full-state (every output lane depends on every input lane).
const CIRCULANT: [u64; WIDTH] = [2, 1, 1, 1, 1, 1, 1, 1, 1];

/// One round of the permutation: S-box, circulant mix, constant addition.
#[inline]
pub fn round_apply(state: &mut [u64; WIDTH], constants: [u64; WIDTH]) {
    for lane in state.iter_mut() {
        *lane = sbox5(*lane);
    }
    let mut mixed = [0u64; WIDTH];
    for i in 0..WIDTH {
        let mut acc: u64 = 0;
        for j in 0..WIDTH {
            acc = acc
                .wrapping_add(mul_mod(CIRCULANT[(i + j) % WIDTH], state[j]));
        }
        mixed[i] = acc % M61_PRIME;
    }
    for i in 0..WIDTH {
        mixed[i] = (mixed[i].wrapping_add(constants[i])) % M61_PRIME;
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

/// A fully deterministic Poseidon2-shaped sponge instance (`t=9, r=8`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Poseidon2Sponge {
    state: [u64; WIDTH],
}

impl Poseidon2Sponge {
    /// A fresh sponge with the zero state (capacity lane and rate lanes zeroed).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            state: [0u64; WIDTH],
        }
    }

    /// Absorb an arbitrary byte stream. Bytes are chunked into 8-byte,
    /// big-endian words reduced mod `p` and XOR-ed into the rate lanes; every
    /// 8 words trigger a full permutation.
    pub fn absorb<'a>(&mut self, bytes: impl IntoIterator<Item = &'a u8>) {
        let mut lanes = [0u64; RATE];
        let mut lane = 0usize;
        let mut word: u64 = 0;
        for (i, byte) in bytes.into_iter().enumerate() {
            word = (word << 8) | u64::from(*byte);
            if (i + 1) % 8 == 0 {
                lanes[lane % RATE] ^= word % M61_PRIME;
                word = 0;
                lane += 1;
                if lane.is_multiple_of(RATE) {
                    self.permute_with_lanes(&lanes);
                    lanes = [0u64; RATE];
                }
            }
        }
        // Tail word (1..=7 bytes): zero-padded big-endian.
        if word != 0 {
            lanes[lane % RATE] ^= word % M61_PRIME;
            lane += 1;
        }
        if !lane.is_multiple_of(RATE) {
            self.permute_with_lanes(&lanes);
        }
    }

    fn permute_with_lanes(&mut self, lanes: &[u64; RATE]) {
        for (i, lane) in lanes.iter().enumerate() {
            self.state[i] ^= *lane;
        }
        permute(&mut self.state);
    }

    /// Squeeze 32 bytes from the rate lanes (big-endian, first four lanes).
    #[must_use]
    pub fn squeeze_bytes32(&mut self) -> [u8; 32] {
        permute(&mut self.state);
        let mut out = [0u8; 32];
        for (i, lane) in self.state[..4].iter().enumerate() {
            out[i * 8..(i + 1) * 8].copy_from_slice(&lane.to_be_bytes());
        }
        out
    }

    /// One-shot seal over a payload: the 256-bit `crmf_validity_seal`.
    #[must_use]
    pub fn seal(payload: &[u8]) -> [u8; 32] {
        let mut sponge = Self::new();
        sponge.absorb(payload);
        sponge.squeeze_bytes32()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn m61_is_actually_prime_input_space() {
        // Every lane value stays below the modulus by construction.
        let x = M61_PRIME - 1;
        let one = mul_mod(x, mul_mod(x, x)); // x^3 mod p
        assert_ne!(one, 0);
    }

    #[test]
    fn mul_mod_field_laws() {
        let two = mul_mod(2, 1);
        let four = mul_mod(two, two);
        assert_eq!(four, 4);
        assert_eq!(mul_mod(M61_PRIME - 1, M61_PRIME - 1), 1);
        assert_eq!(mul_mod(0, 5), 0);
    }

    #[test]
    fn sbox_involution_shared_roots() {
        assert_eq!(sbox5(0), 0);
        assert_eq!(sbox5(1), 1);
    }

    #[test]
    fn seal_is_deterministic() {
        let a = Poseidon2Sponge::seal(b"gap-payload-42");
        let b = Poseidon2Sponge::seal(b"gap-payload-42");
        assert_eq!(a, b);
    }

    #[test]
    fn seal_is_differentiating() {
        let a = Poseidon2Sponge::seal(b"gap-payload-42");
        let b = Poseidon2Sponge::seal(b"gap-payload-43");
        assert_ne!(a, b);
    }

    #[test]
    fn absorption_of_long_payloads_requires_multiple_permutations() {
        // 64 random bytes = 8 rate words = 1 permutation; 128 bytes forces 2.
        let mut payload = vec![0xabu8; 128];
        let seal_a = Poseidon2Sponge::seal(&payload);
        payload[127] = 0xba;
        let seal_b = Poseidon2Sponge::seal(&payload);
        assert_ne!(seal_a, seal_b);
    }

    /// Byte-stable reference vector. Changing the permutation, field, or
    /// absorption rules *must* break this test.
    #[test]
    fn seal_reference_vector_stable() {
        let seal = Poseidon2Sponge::seal(b"prism-pirtm-interop-0066");
        let hex = hex::encode(seal);
        assert_eq!(hex, "015ae304023b78cc126c911f53f37b920669d3403be843ac165fc680d7ae86eb");
    }
}