
use proptest::prelude::*;
use pirtm_tensor::multiplicity_cell::{LinearMultiplicityCell, MultiplicityCell};
use pirtm_tensor::contractive_fit::ContractiveFit;
use ndarray::arr1;

proptest! {
    #[test]
    fn contractive_fit_never_increases_defect(
        w0 in -1.0..1.0f64,
        w1 in -1.0..1.0f64,
        w2 in -1.0..1.0f64,
        d00 in -0.5..0.5f64,
        d11 in -0.5..0.5f64,
        d22 in -0.5..0.5f64,
        s0 in -10.0..10.0f64,
        s1 in -10.0..10.0f64,
        s2 in -10.0..10.0f64,
    ) {
        // Ensure Frobenius norm ≤ 1
        let frob_sq = w0*w0 + w1*w1 + w2*w2 + d00*d00 + d11*d11 + d22*d22;
        if frob_sq > 1.0 { return Ok(()); } // skip invalid combos

        let cell = LinearMultiplicityCell::new(
            arr1(&[w0, w1, w2]),
            ndarray::Array2::from_diag(&arr1(&[d00, d11, d22]))
        );
        let fit = ContractiveFit::new(cell, 0.1, 1e-6);
        let state = arr1(&[s0, s1, s2]);
        let (new_state, new_defect) = fit.step(&state);
        let (_, old_defect) = fit.cell.forward(&state);

        // The defect should not increase (within floating tolerance)
        prop_assert!(new_defect <= old_defect + 1e-9,
            "Defect increased from {} to {}", old_defect, new_defect);
    }
}
