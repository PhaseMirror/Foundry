use elastic_tether::{Tether};
use kani::{any, assume, assert};

#[kani::proof]
fn proof_energy_nonnegative() {
    let k: f64 = any();
    let l0: f64 = any();
    let l: f64 = any();
    // Constrain parameters to be non‑negative.
    assume(k >= 0.0);
    assume(l0 >= 0.0);
    let tether = Tether { stiffness: k, rest_length: l0 };
    let e = tether.energy(l);
    assert(e >= 0.0);
}
