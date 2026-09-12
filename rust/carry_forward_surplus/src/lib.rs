/// Carry‑Forward Surplus implementation
///
/// Implements the canonical update rule from ADR‑0039:
///   Sₓ' = λ·Sₓ − tanh(β·(Sₓ−Sᵧ))
///   Sᵧ' = λ·Sᵧ + tanh(β·(Sₓ−Sᵧ))
/// where `λ` (lam) ∈ [0,1] and `β` > 0.
///
/// The public API consists of two `#[no_mangle]` functions for FFI use:
///   * `kernel(delta: f64, beta: f64) -> f64`
///   * `update(sx: f64, sy: f64, beta: f64, lam: f64) -> (f64, f64)`
/// Both are pure and suitable for verification with Kani.

/// Compute the interaction kernel `‑tanh(beta * delta)`.
#[no_mangle]
pub extern "C" fn kernel(delta: f64, beta: f64) -> f64 {
    -(beta * delta).tanh()
}

/// Perform one update step for a pair of surplus values.
#[no_mangle]
pub extern "C" fn update(sx: f64, sy: f64, beta: f64, lam: f64) -> (f64, f64) {
    let delta = sx - sy;
    let f = kernel(delta, beta);
    let sx_next = lam * sx + f;
    let sy_next = lam * sy - f;
    (sx_next, sy_next)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn kernel_symmetry() {
        let b = 1.3;
        let d = 0.7;
        let f = kernel(d, b);
        assert!((f + kernel(-d, b)).abs() < 1e-12);
    }
    #[test]
    fn update_conservation_lambda_one() {
        let sx = 2.5;
        let sy = -1.5;
        let (sx_n, sy_n) = update(sx, sy, 0.9, 1.0);
        let total_before = sx + sy;
        let total_after = sx_n + sy_n;
        assert!((total_before - total_after).abs() < 1e-12);
    }
    #[test]
    fn update_decay_lambda_half() {
        let sx = 3.0;
        let sy = 1.0;
        let (sx_n, sy_n) = update(sx, sy, 0.8, 0.5);
        let total_before = sx + sy;
        let total_after = sx_n + sy_n;
        assert!((total_after - 0.5 * total_before).abs() < 1e-12);
    }
}
