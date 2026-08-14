//! Raw FFI bindings to Lean exported functions

#[link(name = "certificate_core", kind = "static")]
extern "C" {
    pub fn certificate_check(
        n: u64,
        ratio: f64,
        alpha: f64,
        lambda_2: f64,
        lambda_max: f64,
    ) -> bool;
}
