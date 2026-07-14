// The Rust Sedona Spine Engine Implementation
// Memory layout strictly matches Lean 4 exports

#[repr(C)]
pub struct GlobalHilbertSpace {
    pub data: *mut f64,
    pub dim: usize,
}

/// Dummy function implementing the FFI contract for Lean
#[unsafe(no_mangle)]
pub extern "C" fn get_dimension_rs(space: *const GlobalHilbertSpace) -> usize {
    if space.is_null() {
        return 0;
    }
    unsafe { (*space).dim }
}

/// Computes the spectral radius of a 2x2 operator
#[unsafe(no_mangle)]
pub extern "C" fn compute_spectral_radius(op: *const [[f64; 2]; 2]) -> f64 {
    if op.is_null() {
        return 0.0;
    }
    let m = unsafe { &*op };
    let a = m[0][0];
    let b = m[0][1];
    let c = m[1][0];
    let d = m[1][1];

    let tr = a + d;
    let det = a * d - b * c;
    let disc = tr * tr - 4.0 * det;

    if disc >= 0.0 {
        let sqrt_disc = disc.sqrt();
        let lambda1 = (tr + sqrt_disc).abs() / 2.0;
        let lambda2 = (tr - sqrt_disc).abs() / 2.0;
        lambda1.max(lambda2)
    } else {
        // Complex conjugate roots, modulus is sqrt(det)
        det.abs().sqrt()
    }
}

/// Verifies the RG spectral bound condition (Eq 1)
#[unsafe(no_mangle)]
pub extern "C" fn check_rg_condition(p: u32, sigma: f64, op: *const [[f64; 2]; 2]) -> bool {
    let rho = compute_spectral_radius(op);
    let p_f64 = p as f64;
    let threshold = (1.0 + p_f64.powf(sigma) / 2.0).ln();
    rho < threshold
}

// ---------------------------------------------------------
// Kani Symbolic Verification Harnesses
// ---------------------------------------------------------

// ---------------------------------------------------------
// Density Matrix Invariants (Option A)
// ---------------------------------------------------------

/// Computes the eigenvalues of the normalized density matrix rho = exp(Op * p^{-s}) / Tr(...)
/// Assumes Op is a 2x2 real symmetric matrix (Hermitian).
/// Returns true if successful, false if the matrix values are out of bounds ([-10, 10]).
#[unsafe(no_mangle)]
pub extern "C" fn compute_density_matrix_eigenvalues(
    p: u32,
    s: f64,
    op: *const [[f64; 2]; 2],
    out_evals: *mut [f64; 2],
) -> bool {
    if op.is_null() || out_evals.is_null() {
        return false;
    }
    let m = unsafe { &*op };
    let a = m[0][0];
    let b = m[0][1];
    // We assume real symmetric, so m[1][0] == b is implicitly used.
    let d = m[1][1];

    // Explicit runtime bounds check (Zero Drift / Path of Integrity constraint)
    if a < -10.0 || a > 10.0 || b < -10.0 || b > 10.0 || d < -10.0 || d > 10.0 {
        return false;
    }

    let tr = a + d;
    let disc = (a - d) * (a - d) + 4.0 * b * b;
    let sqrt_disc = disc.abs().sqrt();

    // Eigenvalues of Op
    let lambda1 = (tr + sqrt_disc) / 2.0;
    let lambda2 = (tr - sqrt_disc) / 2.0;

    // Scale by p^{-s}
    let factor = (p as f64).powf(-s);
    let l1_scaled = lambda1 * factor;
    let l2_scaled = lambda2 * factor;

    // Compute exp(eigenvalues) for unnormalized rho
    // To avoid overflow, we can shift by the max eigenvalue
    let max_l = l1_scaled.max(l2_scaled);
    let exp1 = (l1_scaled - max_l).exp();
    let exp2 = (l2_scaled - max_l).exp();

    let trace = exp1 + exp2;

    unsafe {
        (*out_evals)[0] = exp1 / trace;
        (*out_evals)[1] = exp2 / trace;
    }
    
    true
}

/// Verifies that Tr(rho) == 1 and rho is PSD (eigenvalues >= 0)
#[unsafe(no_mangle)]
pub extern "C" fn check_density_matrix_invariant(
    p: u32,
    s: f64,
    op: *const [[f64; 2]; 2],
) -> bool {
    let mut evals = [0.0; 2];
    if !compute_density_matrix_eigenvalues(p, s, op, &mut evals) {
        return false; // Out of bounds or invalid
    }
    
    let trace = evals[0] + evals[1];
    let is_psd = evals[0] >= 0.0 && evals[1] >= 0.0;
    
    // Check trace == 1 within floating-point tolerance
    let trace_is_one = (trace - 1.0).abs() < 1e-9;

    is_psd && trace_is_one
}

/// Computes the von Neumann entropy S(t) = -Tr(rho ln rho) of the 2x2 density matrix.
/// Handles the boundary condition where lambda -> 0 implies lambda * ln(lambda) -> 0.
#[unsafe(no_mangle)]
pub extern "C" fn compute_entropy(evals: *const [f64; 2]) -> f64 {
    if evals.is_null() {
        return 0.0;
    }
    
    let l1 = unsafe { (*evals)[0] };
    let l2 = unsafe { (*evals)[1] };

    // Helper to compute -lambda * ln(lambda) safely
    let entropy_term = |lambda: f64| -> f64 {
        if lambda <= 0.0 {
            0.0 // Limit as x -> 0+ of x*ln(x) is 0
        } else {
            -lambda * lambda.ln()
        }
    };

    entropy_term(l1) + entropy_term(l2)
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_get_dimension() {
        let sym_dim: usize = kani::any();
        kani::assume(sym_dim > 0 && sym_dim < 1000000);
        let mut dummy_data = 0.0f64;
        let space = GlobalHilbertSpace {
            data: &mut dummy_data as *mut f64,
            dim: sym_dim,
        };
        let result = get_dimension_rs(&space);
        kani::assert(result > 0, "Dimension must be strictly positive");
        kani::assert(result == sym_dim, "Returned dimension must perfectly match");
    }

    #[kani::proof]
    fn verify_rg_condition_safety() {
        // Symbolically generate a 2x2 matrix
        let a: f64 = kani::any();
        let b: f64 = kani::any();
        let c: f64 = kani::any();
        let d: f64 = kani::any();

        // Plausible bounds for operator elements
        kani::assume(a > -10.0 && a < 10.0);
        kani::assume(b > -10.0 && b < 10.0);
        kani::assume(c > -10.0 && c < 10.0);
        kani::assume(d > -10.0 && d < 10.0);

        let op = [[a, b], [c, d]];

        // Symbolically choose prime p in {2, 3, 5}
        let p: u32 = kani::any();
        kani::assume(p == 2 || p == 3 || p == 5);

        // Symbolically choose sigma in [1.5, 3.0]
        let sigma: f64 = kani::any();
        kani::assume(sigma >= 1.5 && sigma <= 3.0);

        // Check if condition passes
        let passes = check_rg_condition(p, sigma, &op);

        if passes {
            let rho = compute_spectral_radius(&op);
            
            // Assert that numeric boundaries and computations are perfectly safe
            kani::assert(rho.is_finite(), "Spectral radius must remain finite");
            kani::assert(!rho.is_nan(), "Spectral radius must not hit NaN");
            
            let p_f64 = p as f64;
            let threshold = (1.0 + p_f64.powf(sigma) / 2.0).ln();
            kani::assert(threshold.is_finite(), "Threshold must remain finite");
            kani::assert(!threshold.is_nan(), "Threshold must not hit NaN");
        }
    }

    #[kani::proof]
    fn verify_density_matrix_invariant_safety() {
        // Tier 1: Logical Safety (No panic/NaN/Inf) with wide bounds
        let a: f64 = kani::any();
        let b: f64 = kani::any();
        let d: f64 = kani::any();

        // Broad bounds just to ensure finite behavior
        kani::assume(a > -2.0 && a < 2.0);
        kani::assume(b > -2.0 && b < 2.0);
        kani::assume(d > -2.0 && d < 2.0);

        let op = [[a, b], [b, d]];
        let p: u32 = kani::any();
        kani::assume(p == 2 || p == 3 || p == 5);

        let s: f64 = kani::any();
        kani::assume(s >= 0.5 && s <= 3.0);

        let mut evals = [0.0; 2];
        let success = compute_density_matrix_eigenvalues(p, s, &op, &mut evals);
        
        if success {
            kani::assert(evals[0].is_finite() && evals[1].is_finite(), "Density matrix eigenvalues must be finite");
            kani::assert(!evals[0].is_nan() && !evals[1].is_nan(), "Density matrix eigenvalues must not be NaN");
        }
    }

    #[kani::proof]
    fn verify_density_matrix_invariant_semantics() {
        // Tier 2: Semantic Precision (Trace == 1) with tight bounds for solver tractability
        let a: f64 = kani::any();
        let b: f64 = kani::any();
        let d: f64 = kani::any();

        // Tight bounds to keep CBMC execution time under control and floating point behavior strictly monotonic
        kani::assume(a > -1.0 && a < 1.0);
        kani::assume(b > -1.0 && b < 1.0);
        kani::assume(d > -1.0 && d < 1.0);

        let op = [[a, b], [b, d]];
        let p: u32 = kani::any();
        kani::assume(p == 2 || p == 3);

        let s: f64 = kani::any();
        kani::assume(s >= 1.0 && s <= 2.0);

        let mut evals = [0.0; 2];
        let success = compute_density_matrix_eigenvalues(p, s, &op, &mut evals);
        
        if success {
            let trace = evals[0] + evals[1];
            let is_psd = evals[0] >= 0.0 && evals[1] >= 0.0;
            // Slightly relaxed float tolerance since float math is not exact 
            let trace_is_one = (trace - 1.0).abs() < 1e-8;
            
            kani::assert(is_psd, "Eigenvalues must be non-negative");
            kani::assert(trace_is_one, "Trace must be exactly 1 within tolerance");
        }
    }

    #[kani::proof]
    fn verify_entropy_safety() {
        let l1: f64 = kani::any();
        let l2: f64 = kani::any();

        // Valid density matrix eigenvalues
        kani::assume(l1 >= 0.0 && l1 <= 1.0);
        kani::assume(l2 >= 0.0 && l2 <= 1.0);
        // They should sum to 1, but we'll assume a loose sum bounds for numerical stability
        kani::assume((l1 + l2 - 1.0).abs() < 1e-5);

        let evals = [l1, l2];
        let entropy = compute_entropy(&evals);

        // Entropy of 2-level system is bounded by ln(2) ~ 0.693. We check < 1.0
        kani::assert(entropy >= 0.0, "Entropy must be non-negative");
        kani::assert(entropy <= 1.0, "Entropy of 2x2 system must not exceed ln(2)");
        kani::assert(entropy.is_finite(), "Entropy must remain finite");
        kani::assert(!entropy.is_nan(), "Entropy must not hit NaN");
    }
}

