use c_pirtm_rs::math::GroupSort2;
use proptest::prelude::*;
use ndarray::Array1;

proptest! {
    #[test]
    fn test_groupsort2_is_1_lipschitz(v1 in prop::collection::vec(-10.0..10.0, 10), v2 in prop::collection::vec(-10.0..10.0, 10)) {
        let a = Array1::from(v1);
        let b = Array1::from(v2);
        
        let fa = GroupSort2::forward(&a);
        let fb = GroupSort2::forward(&b);
        
        let dist_in = (&a - &b).mapv(|x| x.powi(2)).sum().sqrt();
        let dist_out = (&fa - &fb).mapv(|x| x.powi(2)).sum().sqrt();
        
        // Lipschitz constant should be <= 1
        assert!(dist_out <= dist_in + 1e-9);
    }
}
