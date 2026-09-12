use godelian_truth::FormalSystem;
use kani::{any, assert};

#[kani::proof]
fn proof_always_false_is_false_root() {
    let pid: u32 = any();
    let sys = FormalSystem;
    let result = sys.always_false(pid);
    assert(result == false, "always_false must be false");
}
