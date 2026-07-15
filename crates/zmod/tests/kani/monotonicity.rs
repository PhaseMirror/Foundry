#[kani::proof]
fn proof_tensor_monotone() {
    let grads1: Vec<u64> = kani::any();
    let mut grads2 = grads1.clone();
    // Append an extra gradient to ensure supersets
    grads2.push(kani::any());
    let p: u64 = kani::any();
    let engine = ZmodEngine;
    let v1 = engine.multiplicity_tensor(&grads1, p).unwrap();
    let v2 = engine.multiplicity_tensor(&grads2, p).unwrap();
    assert!(v1 <= v2);
}
