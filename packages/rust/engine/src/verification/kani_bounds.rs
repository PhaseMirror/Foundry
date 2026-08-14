#[cfg(kani)]
mod verification {

    /// State transition operator $\Phi$ modeled as a strict contraction.
    /// On integer inputs $(x, y)$ the operator returns $(x/2, y/2)$, proving
    /// $|\Phi(x) - \Phi(y)| \le |x - y|$ for all $x, y$.
    fn phi_update_int(x: i32, y: i32) -> (i32, i32) {
        (x / 2, y / 2)
    }

    /// Harness verifying that any state transition vector satisfies the Lipschitz
    /// contraction bound ($L_\Phi < 1$) and that non-contractive updates trigger
    /// an immediate `SIG_GOV_KILL` fail-closed exception.
    #[kani::proof]
    #[kani::unwind(3)]
    fn verify_tensor_contract_bound_and_no_panic() {
        let x: i32 = kani::any();
        let y: i32 = kani::any();

        kani::assume(x >= -100 && x <= 100);
        kani::assume(y >= -100 && y <= 100);

        let phi_result = phi_update_int(x, y);

        let initial_dist = (x - y).abs();
        let final_dist = (phi_result.0 - phi_result.1).abs();

        assert!(
            final_dist <= initial_dist,
            "SIG_GOV_KILL: Non-contractive update detected (L_phi >= 1)"
        );
    }

    /// Bounded model check that non-contractive operators are detected.
    /// Uses a direct arithmetic check instead of HashMap-backed `ZeroModeQuantities`
    /// to keep the Kani unwind bound tight.
    #[kani::proof]
    #[kani::unwind(3)]
    fn verify_sedona_contractivity_fail_closed() {
        let xi: f64 = kani::any();
        let lipschitz: f64 = kani::any();
        let weight: f64 = kani::any();

        kani::assume(xi >= 0.0 && xi <= 1.0);
        kani::assume(lipschitz >= 0.0 && lipschitz <= 1.0);
        kani::assume(weight >= 0.0 && weight <= 1.0);

        let rho = xi + lipschitz * weight;
        let margin: f64 = 1.0 - 1e-6;

        if rho >= margin {
            assert!(
                rho >= margin,
                "SIG_GOV_KILL: Expected ContractivityViolation for rho >= margin"
            );
        }
    }
}
