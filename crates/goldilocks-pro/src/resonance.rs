use crate::GoldilocksField;

/// Lever 3 — Resonance Encoding Layer (Normative)
/// A resonance word is a 64-bit value with layout:
/// - Bits 0–5: c ∈ {0, …, 95} — R96 resonance class
use serde::{Serialize, Deserialize};

/// ResonanceWord encodes:
/// - Bits 0-5: class
/// - Bits 6-63: payload
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, Serialize, Deserialize)]
pub struct ResonanceWord(pub u64);

impl ResonanceWord {
    pub const Q29_29_SHIFT: u64 = 1 << 29;

    #[inline]
    pub fn pack(c: u8, payload: u64) -> Self {
        assert!(c < 96, "Resonance class c must be < 96");
        assert!(payload < (1 << 58), "Payload π must be < 2^58");
        Self((payload << 6) | (c as u64))
    }

    /// Pack a floating point value into a Q29.29 fixed-point payload.
    #[inline]
    pub fn pack_q29_29(c: u8, val: f64) -> Self {
        let payload = (val * (Self::Q29_29_SHIFT as f64)).round() as i64;
        // Clamp to 58-bit signed range
        let payload = payload.clamp(-(1 << 57), (1 << 57) - 1);
        let u_payload = (payload as u64) & ((1 << 58) - 1);
        Self::pack(c, u_payload)
    }

    #[inline]
    pub fn unpack(&self) -> (u8, u64) {
        let c = (self.0 & 0x3F) as u8;
        let payload = self.0 >> 6;
        (c, payload)
    }

    /// Unpack a Q29.29 fixed-point payload into a floating point value.
    #[inline]
    pub fn unpack_q29_29(&self) -> (u8, f64) {
        let (c, payload) = self.unpack();
        // Sign extend 58-bit to 64-bit
        let mut val = payload;
        if (val & (1 << 57)) != 0 {
            val |= !((1 << 58) - 1);
        }
        let fval = (val as i64) as f64 / (Self::Q29_29_SHIFT as f64);
        (c, fval)
    }

    #[inline]
    pub fn class(&self) -> u8 {
        (self.0 & 0x3F) as u8
    }

    #[inline]
    pub fn payload(&self) -> u64 {
        self.0 >> 6
    }

    /// Interpret the resonance word directly as a field element in Goldilocks.
    pub fn to_field(&self) -> GoldilocksField {
        GoldilocksField::new(self.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resonance_packing() {
        let rw = ResonanceWord::pack(42, 123456789);
        let (c, p) = rw.unpack();
        assert_eq!(c, 42);
        assert_eq!(p, 123456789);
    }

    #[test]
    fn test_q29_29_precision() {
        let c = 5;
        let val = 3.1415926535;
        let rw = ResonanceWord::pack_q29_29(c, val);
        let (unpacked_c, unpacked_val) = rw.unpack_q29_29();
        assert_eq!(unpacked_c, c);
        assert!((unpacked_val - val).abs() < 1e-8);
        
        let neg_val = -1.2345;
        let rw_neg = ResonanceWord::pack_q29_29(c, neg_val);
        let (_, unpacked_neg) = rw_neg.unpack_q29_29();
        assert!((unpacked_neg - neg_val).abs() < 1e-8);
    }
}
