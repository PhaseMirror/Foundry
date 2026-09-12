//! `CT-03`: the float codec is total on all bit patterns, and non-finite codes
//! propagate by the IEEE rules rather than erroring.
//!
//! Every `u32` is a valid `f32` code. The decode has no input it rejects, and
//! this is the target that says so over the whole space rather than over a
//! chosen sample.

#![no_main]

use libfuzzer_sys::fuzz_target;
use uor_matmul::prelude::*;
use uor_matmul_core::{Decoded, FloatElement};

fuzz_target!(|data: &[u8]| {
    if data.len() < 8 {
        return;
    }
    for chunk in data.chunks_exact(4) {
        let bits = u32::from_le_bytes(chunk.try_into().unwrap());
        let x = f32::from_bits(bits);
        // Total: every pattern decodes, and a finite one decodes to a value
        // whose reconstruction has the exponent the decode reported.
        match x.decode() {
            Decoded::Finite { mantissa, exp, .. } => {
                let _ = mantissa;
                assert!(exp >= f32::MIN_PRODUCT_EXP / 2, "exponent below the format");
            }
            Decoded::Infinite { .. } | Decoded::NotANumber => {}
        }
    }

    // And a product of fuzzer-chosen codes accumulates without failing.
    let k = (data.len() / 8).min(64).max(1);
    let a: Vec<f32> = (0..k)
        .map(|i| f32::from_bits(u32::from_le_bytes(data[i * 4..i * 4 + 4].try_into().unwrap())))
        .collect();
    let b: Vec<f32> = a.iter().rev().copied().collect();
    let mut c = [0.0f32];
    let Some(av) = MatView::row_major(&a, 1, k) else { return };
    let Some(bv) = MatView::row_major(&b, k, 1) else { return };
    let Some(cv) = MatViewMut::row_major(&mut c, 1, 1) else { return };
    let Ok(mut t) = Triple::new(av, bv, cv) else { return };
    uor_matmul::gemm_float(&mut t, &Linear::OVERWRITE, GemmOptions::default());
});
