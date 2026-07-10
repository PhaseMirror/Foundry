/// Lever 2 — Prime-Gated Indexing (Normative)
/// All structures in Pro-tier MUST carry a valid prime mask.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct PrimeMask(pub u64);

impl PrimeMask {
    pub const EMPTY: Self = Self(0);

    /// Canonical 64-Prime Basis P64
    pub const P64: [u32; 64] = [
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
        59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131,
        137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223,
        227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311,
    ];

    pub fn from_bit(k: u32) -> Self {
        assert!(k < 64);
        Self(1 << k)
    }

    pub fn is_set(&self, k: u32) -> bool {
        assert!(k < 64);
        (self.0 & (1 << k)) != 0
    }

    pub fn and(self, other: Self) -> Self {
        Self(self.0 & other.0)
    }

    pub fn or(self, other: Self) -> Self {
        Self(self.0 | other.0)
    }

    pub fn xor(self, other: Self) -> Self {
        Self(self.0 ^ other.0)
    }

    pub fn count_ones(&self) -> u32 {
        self.0.count_ones()
    }
}

/// Lever 3 — Resonance Encoding Layer (Normative)
/// A resonance word is a 64-bit value with layout:
/// - Bits 0–5: c ∈ {0, …, 95} — R96 resonance class
/// - Bits 6–63: 58-bit payload π
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ResonanceWord(pub u64);

impl ResonanceWord {
    pub const Q29_29_SHIFT: u64 = 1 << 29;

    pub fn pack(c: u8, payload: u64) -> Self {
        assert!(c < 96);
        assert!(payload < (1 << 58));
        Self((payload << 6) | (c as u64))
    }

    pub fn pack_q29_29(c: u8, val: f64) -> Self {
        let payload = (val * (Self::Q29_29_SHIFT as f64)).round() as u64;
        let payload = payload & ((1 << 58) - 1); // Clamp to 58 bits
        Self::pack(c, payload)
    }

    pub fn unpack(&self) -> (u8, u64) {
        let c = (self.0 & 0x3F) as u8;
        let payload = self.0 >> 6;
        (c, payload)
    }
    
    pub fn unpack_q29_29(&self) -> (u8, f64) {
        let (c, payload) = self.unpack();
        // Handle negative numbers if signed, but let's assume unsigned or two's complement in 58 bits
        let mut val = payload;
        if (val & (1 << 57)) != 0 { // if sign bit of 58-bit integer is set
            val |= !((1 << 58) - 1); // sign extend to 64 bits
        }
        let fval = (val as i64) as f64 / (Self::Q29_29_SHIFT as f64);
        (c, fval)
    }

    pub fn class(&self) -> u8 {
        (self.0 & 0x3F) as u8
    }

    pub fn payload(&self) -> u64 {
        self.0 >> 6
    }
}
