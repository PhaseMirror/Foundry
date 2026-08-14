#[kani::proof]
fn proof_step_interaction_bounded() {
    let grad: u64 = kani::any();
    let p: u64 = kani::any();
    let engine = ZmodEngine;
    let res = engine.step_interaction(grad, p).unwrap();
    assert!(res <= ZmodEngine::SCALE);
}
