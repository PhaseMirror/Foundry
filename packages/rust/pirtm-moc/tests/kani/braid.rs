#[cfg(kani)]
#[kani::proof]
fn braid_termination() {
    use crate::*;
    // Empty word should trivially terminate.
    let word = OperatorWord { ops: vec![], prime_grade: kani::any::<u64>() };
    let _ = braid(&word);
    // If we reach here, the function returned.
}
