// Suppress check-cfg warning for the `kani` cfg, which is set by the Kani
// verification tool during proof harness compilation.
fn main() {
    println!("cargo::rustc-check-cfg=cfg(kani)");
}
