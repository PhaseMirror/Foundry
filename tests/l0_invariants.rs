// L0 Invariants: core algebraic properties of the Signature type.
// These verify the foundational laws that the Lean formalization depends on.

#[cfg(test)]
mod tests {
    use multiplicity::{Signature, multiplicity};
    use num_rational::BigRational;
    use num_bigint::BigInt;
    use num_traits::One;

    fn rat(n: i64) -> BigRational {
        BigRational::new(BigInt::from(n), BigInt::one())
    }

    #[test]
    fn signature_map_only_stores_nonzero_exponents() {
        let mut sig = Signature::new();
        sig.insert(2, 0);
        assert!(sig.map.is_empty(), "Zero exponent should be removed");

        sig.insert(2, 3);
        assert_eq!(sig.map.len(), 1);
        assert_eq!(sig.map[&2], 3);

        sig.insert(2, 0);
        assert!(sig.map.is_empty(), "Resetting to zero should remove entry");
    }

    #[test]
    fn multiplicity_of_empty_is_one() {
        let sig = Signature::new();
        assert_eq!(multiplicity(&sig), BigRational::one());
    }

    #[test]
    fn multiplicity_of_single_prime_power() {
        let mut sig = Signature::new();
        sig.insert(2, 3); // 2^3 = 8
        assert_eq!(multiplicity(&sig), rat(8));

        let mut sig = Signature::new();
        sig.insert(7, 2); // 7^2 = 49
        assert_eq!(multiplicity(&sig), rat(49));
    }

    #[test]
    fn multiplicity_negative_exponent_yields_reciprocal() {
        let mut sig = Signature::new();
        sig.insert(3, -1); // 3^-1 = 1/3
        let m = multiplicity(&sig);
        assert_eq!(m, BigRational::new(num_bigint::BigInt::from(1), num_bigint::BigInt::from(3)));
    }

    #[test]
    fn mul_is_commutative() {
        let mut a = Signature::new();
        a.insert(2, 1);
        a.insert(3, 2);
        let mut b = Signature::new();
        b.insert(5, 3);
        b.insert(2, -1);

        let ab = a.mul(&b);
        let ba = b.mul(&a);
        assert_eq!(ab, ba, "Signature multiplication must be commutative");
    }

    #[test]
    fn mul_is_associative() {
        let mut a = Signature::new();
        a.insert(2, 1);
        let mut b = Signature::new();
        b.insert(3, 1);
        let mut c = Signature::new();
        c.insert(5, 1);

        let ab_c = a.mul(&b).mul(&c);
        let a_bc = a.mul(&b.mul(&c));
        assert_eq!(ab_c, a_bc, "Signature multiplication must be associative");
    }

    #[test]
    fn empty_signature_is_identity() {
        let mut sig = Signature::new();
        sig.insert(11, 4);
        let unit = Signature::new();

        assert_eq!(sig.mul(&unit), sig, "Right identity");
        assert_eq!(unit.mul(&sig), sig, "Left identity");
    }

    #[test]
    fn inv_negates_exponents() {
        let mut sig = Signature::new();
        sig.insert(2, 3);
        sig.insert(5, -2);
        let inv = sig.inv();

        assert_eq!(inv.map[&2], -3);
        assert_eq!(inv.map[&5], 2);
    }

    #[test]
    fn mul_with_inv_yields_unit() {
        let mut sig = Signature::new();
        sig.insert(2, 5);
        sig.insert(7, -3);
        let inv = sig.inv();
        let product = sig.mul(&inv);

        assert!(product.map.is_empty(), "sig * sig^-1 should be empty (unit)");
        assert_eq!(multiplicity(&product), BigRational::one());
    }

    #[test]
    fn multiplicity_of_compound_signature() {
        // 2^3 * 3^2 * 5^-1 = 8 * 9 / 5 = 72/5
        let mut sig = Signature::new();
        sig.insert(2, 3);
        sig.insert(3, 2);
        sig.insert(5, -1);
        let m = multiplicity(&sig);
        assert_eq!(m, BigRational::new(
            num_bigint::BigInt::from(72),
            num_bigint::BigInt::from(5),
        ));
    }
}
