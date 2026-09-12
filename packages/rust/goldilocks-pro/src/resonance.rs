// Canonical ResonanceWord is defined in the `goldilocks` crate.
// Re-exported here for backward compatibility.
pub use goldilocks::ResonanceWord;

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
