//! Kani harnesses for automorphic-core.
//!
//! Run with: kani kani/group_harness.rs

use automorphic_core::group::{AglElement, legendre_symbol, CrtEmbedding};

#[kani::proof]
fn check_agl_apply_deterministic() {
    let u: u32 = kani::any();
    let k: u32 = kani::any();
    let p: u32 = kani::any();
    kani::assume(p >= 3 && p % 2 == 1);
    kani::assume(u >= 1 && u < p);
    kani::assume(k < p);
    
    let g = AglElement::new(u, k, p).unwrap();
    
    let i: u32 = kani::any();
    kani::assume(i < p);
    
    let r1 = g.apply(i);
    let r2 = g.apply(i);
    assert_eq!(r1, r2);
}

#[kani::proof]
fn check_agl_permutation_valid() {
    let u: u32 = kani::any();
    let k: u32 = kani::any();
    let p: u32 = kani::any();
    kani::assume(p >= 3 && p % 2 == 1 && p <= 100);
    kani::assume(u >= 1 && u < p);
    kani::assume(k < p);
    
    let g = AglElement::new(u, k, p).unwrap();
    
    // Check that apply is a permutation (injective)
    for i in 0..p {
        for j in (i + 1)..p {
            assert_ne!(g.apply(i), g.apply(j));
        }
    }
}

#[kani::proof]
fn check_legendre_symbol_values() {
    let a: u32 = kani::any();
    let p: u32 = kani::any();
    kani::assume(p >= 3 && p % 2 == 1 && p <= 100);
    kani::assume(a < p);
    
    let chi = legendre_symbol(a, p);
    
    // Legendre symbol is in {-1, 0, 1}
    assert!(chi == -1 || chi == 0 || chi == 1);
    
    // If a == 0, chi == 0
    if a == 0 {
        assert_eq!(chi, 0);
    }
}

#[kani::proof]
fn check_crt_embedding_injective() {
    let p1: u32 = kani::any();
    let p2: u32 = kani::any();
    kani::assume(p1 >= 3 && p1 % 2 == 1 && p1 <= 10);
    kani::assume(p2 >= 3 && p2 % 2 == 1 && p2 <= 10);
    kani::assume(p1 != p2);
    
    let n = p1 * p2;
    let crt = CrtEmbedding::new(p1, p2, n as usize);
    
    // Check injectivity
    for i in 0..n {
        for j in (i + 1)..n {
            assert_ne!(crt.embed(i as usize), crt.embed(j as usize));
        }
    }
}
