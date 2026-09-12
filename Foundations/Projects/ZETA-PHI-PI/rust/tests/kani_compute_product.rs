#[cfg(kani)]
#[kani::proof]
#[kani::unwind(64)]
fn verify_compute_product() {
    // bound n to avoid overflow (64! fits in u128, but we use u64 here)
    let n: u32 = kani::any();
    kani::assume(n <= 20);
    let result = zeta_phi_pi::compute_product(n as u64);
    // compute expected factorial using Rust iterator (same as library logic)
    let expected: u64 = (1..=n as u64).product();
    kani::assert(result == expected, "product should match factorial");
}
