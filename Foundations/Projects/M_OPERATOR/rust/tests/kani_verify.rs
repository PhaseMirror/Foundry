#[cfg(kani)]
mod kani_verify {
    use m_operator_rust::*;

    #[kani::proof]
    fn verify_nonlinear_regularization_bounded() {
        let w: f64 = kani::any();
        kani::assume(w.is_finite());
        let alpha = 0.5;
        let r = nonlinear_regularization(w, alpha);

        assert!(r >= 0.0);
        assert!(r <= alpha);
    }

    #[kani::proof]
    fn verify_vector_clamping() {
        let x: f64 = kani::any();
        let y: f64 = kani::any();
        let z: f64 = kani::any();
        let bound: f64 = 50.0;

        kani::assume(x.is_finite());
        kani::assume(y.is_finite());
        kani::assume(z.is_finite());

        let v = MVector3::new(x, y, z).clamp(bound);

        assert!(v.x >= -bound && v.x <= bound);
        assert!(v.y >= -bound && v.y <= bound);
        assert!(v.z >= -bound && v.z <= bound);
    }

    #[kani::proof]
    fn verify_bayesian_update_bounded() {
        let joint: f64 = kani::any();
        let evidence: f64 = kani::any();

        kani::assume(joint >= 0.0 && joint <= 1.0);
        kani::assume(evidence >= 0.0 && evidence <= 1.0);

        let p = quantum_bayesian_update(joint, evidence);

        assert!(p >= 0.0 && p <= 1.0);
    }
}
