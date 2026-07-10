// Integration tests aligning Rust implementation with Lean formalism
// These tests mirror the theorems proved in the Lean files under formal/src/PIRTM.
// They ensure the Rust `Signature` operations satisfy the same algebraic laws.

#[cfg(test)]
mod integration {
    // Import public items from the `multiplicity` crate
    use multiplicity::{Signature, multiplicity};
    use num_rational::BigRational;
    use num_traits::One;

    #[test]
    fn test_unit_law() {
        // Lean theorem: multiplicity_unit → multiplicity sigUnit = 1
        let sig = Signature::new(); // sigUnit corresponds to empty signature
        assert_eq!(multiplicity(&sig), num_rational::BigRational::one());
    }

    #[test]
    fn test_product_law() {
        // Lean theorem: multiplicity_add → multiplicity (addSig s1 s2) = multiplicity s1 * multiplicity s2
        let mut s1 = Signature::new();
        s1.insert(2, 3); // 2^3
        let mut s2 = Signature::new();
        s2.insert(3, 2); // 3^2
        let prod = s1.mul(&s2);
        let lhs = multiplicity(&prod);
        let rhs = multiplicity(&s1) * multiplicity(&s2);
        assert_eq!(lhs, rhs);
    }

    #[test]
    fn test_associativity() {
        // Lean theorem: sig_add_assoc → addSig (addSig s1 s2) s3 = addSig s1 (addSig s2 s3)
        let mut s1 = Signature::new();
        s1.insert(2, 1);
        let mut s2 = Signature::new();
        s2.insert(3, 1);
        let mut s3 = Signature::new();
        s3.insert(5, 1);
        let left = s1.mul(&s2).mul(&s3);
        let right = s1.mul(&s2.mul(&s3));
        assert_eq!(left, right);
    }

    #[test]
    fn test_identity() {
        // Lean theorem: sig_unit_id → addSig s sigUnit = s
        let mut s = Signature::new();
        s.insert(7, 4);
        let with_unit = s.mul(&Signature::new()); // multiplication with empty signature
        assert_eq!(with_unit, s);
    }

    #[test]
    fn test_inverse_law() {
        // Lean theorem: multiplicity_inv → multiplicity (invSig s) = 1 / multiplicity s
        let mut s = Signature::new();
        s.insert(2, 3);
        s.insert(3, -2);
        let inv = s.inv();
        let lhs = multiplicity(&inv);
        let rhs = BigRational::one() / multiplicity(&s);
        assert_eq!(lhs, rhs);
    }

    #[test]
    fn test_exponent_addition_via_mul() {
        // Ensure that mul corresponds to pointwise addition of exponents
        let mut a = Signature::new();
        a.insert(2, 1);
        a.insert(5, 2);
        let mut b = Signature::new();
        b.insert(2, 3);
        b.insert(7, 1);
        let prod = a.mul(&b);
        // Expected map: 2 -> 4, 5 -> 2, 7 -> 1
        let mut expected = Signature::new();
        expected.insert(2, 4);
        expected.insert(5, 2);
        expected.insert(7, 1);
        assert_eq!(prod, expected);
    }

}
