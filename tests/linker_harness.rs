// Linker harness: integration tests for PrimeMonomialMatrix (PMat).
// PMat is the computational bridge between free compact-closed syntax
// and scalar multiplicity invariants.

#[cfg(test)]
mod tests {
    use multiplicity::{Signature, PrimeMonomialMatrix, multiplicity};
    use num_rational::BigRational;
    use num_traits::One;

    fn make_sig(map: &[(u64, i64)]) -> Signature {
        let mut sig = Signature::new();
        for &(p, e) in map {
            sig.insert(p, e);
        }
        sig
    }

    #[test]
    fn pmat_construction_and_dimensions() {
        let src = vec![make_sig(&[]), make_sig(&[(2, 1)])];
        let tgt = vec![make_sig(&[(3, 1)]), make_sig(&[])];
        let pmat = PrimeMonomialMatrix::new(src, tgt);
        assert_eq!(pmat.rows, 2);
        assert_eq!(pmat.cols, 2);
        assert!(pmat.entries.is_empty());
    }

    #[test]
    fn pmat_insert_valid_entry() {
        // src = [empty], tgt = [2^1]
        // Grading: tgt[0] - src[0] = 2^1
        let src = vec![make_sig(&[])];
        let tgt = vec![make_sig(&[(2, 1)])];
        let mut pmat = PrimeMonomialMatrix::new(src, tgt);
        let result = pmat.insert(0, 0, 1, make_sig(&[(2, 1)]));
        assert!(result.is_ok());
        assert_eq!(pmat.entries.len(), 1);
    }

    #[test]
    fn pmat_insert_rejects_grading_violation() {
        // src = [empty], tgt = [2^1], but we try to insert 3^1 (wrong grading)
        let src = vec![make_sig(&[])];
        let tgt = vec![make_sig(&[(2, 1)])];
        let mut pmat = PrimeMonomialMatrix::new(src, tgt);
        let result = pmat.insert(0, 0, 1, make_sig(&[(3, 1)]));
        assert!(result.is_err());
    }

    #[test]
    fn pmat_insert_rejects_invalid_sign() {
        let src = vec![make_sig(&[])];
        let tgt = vec![make_sig(&[(2, 1)])];
        let mut pmat = PrimeMonomialMatrix::new(src, tgt);
        let result = pmat.insert(0, 0, 2, make_sig(&[(2, 1)]));
        assert!(result.is_err());
    }

    #[test]
    fn pmat_insert_rejects_out_of_bounds() {
        let src = vec![make_sig(&[])];
        let tgt = vec![make_sig(&[(2, 1)])];
        let mut pmat = PrimeMonomialMatrix::new(src, tgt);
        let result = pmat.insert(5, 0, 1, make_sig(&[(2, 1)]));
        assert!(result.is_err());
    }

    #[test]
    fn pmat_validate_valid_matrix() {
        let src = vec![make_sig(&[]), make_sig(&[(2, 1)])];
        let tgt = vec![make_sig(&[(3, 1)]), make_sig(&[])];
        let mut pmat = PrimeMonomialMatrix::new(src.clone(), tgt.clone());
        // Entry (0,0): grading = tgt[0] - src[0] = 3^1
        pmat.insert(0, 0, 1, make_sig(&[(3, 1)])).unwrap();
        // Entry (1,1): grading = tgt[1] - src[1] = -(2^1)
        pmat.insert(1, 1, 1, make_sig(&[(2, -1)])).unwrap();
        assert!(pmat.validate().is_ok());
    }

    #[test]
    fn pmat_compose_compatible_dimensions() {
        // f: A -> B, g: B -> C
        let src_f = vec![make_sig(&[])];
        let tgt_f = vec![make_sig(&[(2, 1)])];
        let mut f = PrimeMonomialMatrix::new(src_f, tgt_f);
        f.insert(0, 0, 1, make_sig(&[(2, 1)])).unwrap();

        let src_g = vec![make_sig(&[(2, 1)])];
        let tgt_g = vec![make_sig(&[(2, 1), (3, 1)])];
        let mut g = PrimeMonomialMatrix::new(src_g, tgt_g);
        g.insert(0, 0, 1, make_sig(&[(3, 1)])).unwrap();

        let composed = f.compose(&g);
        assert!(composed.is_ok());
        let h = composed.unwrap();
        assert_eq!(h.rows, 1);
        assert_eq!(h.cols, 1);
        // Composition: src[0] -> tgt_f[0] -> tgt_g[0]
        // Entry should be sign=1, monomial = 2^1 * 3^1
        let entry = h.entries.get(&(0, 0)).unwrap();
        assert_eq!(entry.sign, 1);
        assert_eq!(entry.monomial, make_sig(&[(2, 1), (3, 1)]));
    }

    #[test]
    fn pmat_compose_rejects_incompatible() {
        let src = vec![make_sig(&[])];
        let tgt = vec![make_sig(&[(2, 1)])];
        let f = PrimeMonomialMatrix::new(src, tgt);

        let src2 = vec![make_sig(&[]), make_sig(&[(3, 1)])]; // rows=2, but f.cols=1
        let tgt2 = vec![make_sig(&[])];
        let g = PrimeMonomialMatrix::new(src2, tgt2);

        assert!(f.compose(&g).is_err());
    }

    #[test]
    fn pmat_to_rational_matrix() {
        let src = vec![make_sig(&[])];
        let tgt = vec![make_sig(&[(2, 1)])];
        let mut pmat = PrimeMonomialMatrix::new(src, tgt);
        pmat.insert(0, 0, 1, make_sig(&[(2, 1)])).unwrap();

        let dense = pmat.to_rational_matrix();
        assert_eq!(dense.len(), 1);
        assert_eq!(dense[0].len(), 1);
        // Entry (0,0) = +1 * multiplicity(2^1) = 2
        assert_eq!(dense[0][0], BigRational::new(num_bigint::BigInt::from(2), num_bigint::BigInt::one()));
    }
}
