#[cfg(kani)]
mod kani_verify {
    use lorenz_attractor_rust::*;

    #[kani::proof]
    fn verify_origin_velocity_is_zero() {
        let sigma: f64 = kani::any();
        let rho: f64 = kani::any();
        let beta: f64 = kani::any();
        kani::assume(sigma.is_finite());
        kani::assume(rho.is_finite());
        kani::assume(beta.is_finite());

        let params = LorenzParams::new(sigma, rho, beta);
        let v0 = classical_velocity(&LorenzPoint::origin(), &params);

        assert!(v0.x == 0.0);
        assert!(v0.y == 0.0);
        assert!(v0.z == 0.0);
    }

    #[kani::proof]
    fn verify_jacobian_trace_exactness() {
        let sigma: f64 = kani::any();
        let rho: f64 = kani::any();
        let beta: f64 = kani::any();
        kani::assume(sigma >= 0.0 && sigma <= 100.0);
        kani::assume(rho >= 0.0 && rho <= 100.0);
        kani::assume(beta >= 0.0 && beta <= 100.0);

        let params = LorenzParams::new(sigma, rho, beta);
        let p = LorenzPoint::new(1.0, 2.0, 3.0);
        let j = Jacobian3D::evaluate(&p, &params);

        let tr_eval = j.trace();
        let tr_theo = Jacobian3D::theoretical_trace(&params);

        assert!((tr_eval - tr_theo).abs() < 1e-10);
    }

    #[kani::proof]
    fn verify_clamping_bounds() {
        let x: f64 = kani::any();
        let y: f64 = kani::any();
        let z: f64 = kani::any();
        let bound: f64 = 100.0;

        kani::assume(x.is_finite());
        kani::assume(y.is_finite());
        kani::assume(z.is_finite());

        let p = LorenzPoint::new(x, y, z).clamp(bound);

        assert!(p.x >= -bound && p.x <= bound);
        assert!(p.y >= -bound && p.y <= bound);
        assert!(p.z >= -bound && p.z <= bound);
    }

    #[kani::proof]
    fn verify_prime_params_positivity() {
        let p1: u64 = kani::any();
        let p2: u64 = kani::any();
        let p3: u64 = kani::any();

        kani::assume(p1 >= 2 && p1 <= 1000);
        kani::assume(p2 >= 2 && p2 <= 1000);
        kani::assume(p3 >= 2 && p3 <= 1000);

        let prime_params = PrimeLorenzParams::new(p1, p2, p3);
        let params = prime_params.to_lorenz_params(0.0);

        assert!(params.sigma > 0.0);
        assert!(params.rho > 0.0);
        assert!(params.beta > 0.0);
        assert!(Jacobian3D::theoretical_trace(&params) < 0.0);
    }
}
