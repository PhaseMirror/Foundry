// GUT-PC Continuous Mathematics Verified by Kani

pub fn lyapunov_functional(lambda_m: f64, lambda_star: f64) -> f64 {
    0.5 * (lambda_m - lambda_star) * (lambda_m - lambda_star)
}

pub fn lyapunov_derivative(lambda_m: f64, lambda_star: f64, eta: f64, var_p: f64) -> f64 {
    -eta * var_p * (lambda_m - lambda_star) * (lambda_m - lambda_star)
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_lyapunov_stability() {
        let lambda_m: f64 = kani::any();
        let lambda_star: f64 = kani::any();
        let eta: f64 = kani::any();
        let var_p: f64 = kani::any();

        kani::assume(lambda_m.is_finite() && lambda_star.is_finite());
        kani::assume(eta > 0.0 && eta < 10.0);
        kani::assume(var_p >= 0.0 && var_p < 100.0);
        kani::assume((lambda_m - lambda_star).abs() < 100.0);

        let l = lyapunov_functional(lambda_m, lambda_star);
        kani::assert(l >= 0.0, "Lyapunov functional must be non-negative");

        let dl_dtau = lyapunov_derivative(lambda_m, lambda_star, eta, var_p);
        kani::assert(dl_dtau <= 0.0, "Derivative of Lyapunov functional must be non-positive");
        
        if lambda_m == lambda_star {
            kani::assert(dl_dtau == 0.0, "Derivative must be 0 at fixed point");
        }
    }
}
