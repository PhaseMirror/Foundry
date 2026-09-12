#[cfg(kani)]
#[kani::proof]
fn commutation_soundness() {
    use crate::*;
    let p1 = kani::any::<u64>();
    let p2 = kani::any::<u64>();
    let op1 = MocOperator::Sp(p1);
    let op2 = MocOperator::Sp(p2);
    let res = op1.commute(&op2);
    if p1 == p2 {
        kani::assert(res.value == 0);
    } else {
        kani::assert(res.value == 1);
    }
}
