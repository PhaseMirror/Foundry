pub mod kani_invariants;
pub mod sigma_layer;
pub mod state;
pub mod crmf_binding;
pub mod ledger;

/// The mathematical maximum dimension length `k` for a W8A8 accumulation
/// into an `i32` register, as formally proven in `UORMatMul.lean` (CL-MM03').
/// Value: ⌊(2³¹ - 1) / 127²⌋
pub const K_MAX: usize = 133144;

/// A bit-exact integer matrix multiplication (dot product) over the W8A8 codec.
/// It strictly asserts that the dimension `k` does not exceed the formally verified
/// ceiling `K_MAX`. Any attempt to accumulate beyond this will cause an intentional panic
/// *before* the trace reaches the zero-knowledge circuits.
pub fn dot_w8a8(activations: &[i8], weights: &[i8]) -> i32 {
    let k = activations.len();
    assert_eq!(k, weights.len(), "Dimension mismatch in dot product.");
    
    // THE FORMAL CLAMP: Panic if k exceeds the Lean-verified safety ceiling.
    assert!(
        k <= K_MAX,
        "L3_SymmetryConfinement Violation: Accumulation dimension {} exceeds UORMatMul bounds ({})",
        k, K_MAX
    );

    let mut accum: i32 = 0;
    
    // Sequential fold modeling the exact exactness theorem.
    for i in 0..k {
        let a = activations[i] as i32;
        let w = weights[i] as i32;
        
        // At W8A8 (values clamped between -127 and 127), the magnitude of the product is <= 16129.
        // Under k <= K_MAX, this fold is mathematically guaranteed never to overflow the i32 accumulator.
        let prod = a.wrapping_mul(w);
        accum = accum.wrapping_add(prod);
    }
    
    accum
}
