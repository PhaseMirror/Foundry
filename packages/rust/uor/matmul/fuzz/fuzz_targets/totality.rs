//! `CT-01`: no representable input errors or panics.
//!
//! The claim is total, so the fuzzer's job is not to find an input that returns
//! the wrong answer --- the differential tests do that --- but to find one that
//! *fails at all*. Any panic here falsifies C6 directly.

#![no_main]

use libfuzzer_sys::fuzz_target;
use uor_matmul::prelude::*;
use uor_matmul_core::{EncodeMode, Strides};

fuzz_target!(|data: &[u8]| {
    if data.len() < 8 {
        return;
    }
    // Shapes small enough to run fast, wide enough to reach every edge: zero
    // dimensions, single rows, and non-multiples of every block size.
    let m = (data[0] % 17) as usize;
    let k = (data[1] % 37) as usize;
    let n = (data[2] % 17) as usize;
    // Strides drawn from the fuzzer too, including negative and zero on the
    // inputs, which is what S7 promises and what a checked view must survive.
    let rsa = (data[3] as i8) as isize;
    let csa = (data[4] as i8) as isize;
    let mode = match data[5] % 4 {
        0 => EncodeMode::Nearest,
        1 => EncodeMode::TowardZero,
        2 => EncodeMode::Saturating,
        _ => EncodeMode::Wrapping,
    };

    let body = &data[6..];
    let a: Vec<i8> = body.iter().map(|&b| b as i8).cycle().take((m * k).max(1)).collect();
    let b: Vec<i8> = body.iter().rev().map(|&b| b as i8).cycle().take((k * n).max(1)).collect();
    let mut c = vec![0i32; (m * n).max(1)];

    // View construction is where non-existence is reported. A `None` here is
    // the library working, not failing.
    let sa = if rsa == 0 && csa == 0 { Strides::row_major(k) } else { Strides { rs: rsa, cs: csa } };
    let Some(av) = MatView::new(as_alphabet_full(&a), m, k, sa) else { return };
    let Some(bv) = MatView::row_major(as_alphabet_full(&b), k, n) else { return };
    let Some(cv) = MatViewMut::row_major(&mut c, m, n) else { return };
    let Ok(mut t) = Triple::new(av, bv, cv) else { return };

    // Past this point nothing may fail. That is the whole claim.
    gemm(
        &mut t,
        &Linear { alpha: 1, beta: 0 },
        GemmOptions { encode: mode, ..Default::default() },
        &mut Scratch::none(),
    );
});
