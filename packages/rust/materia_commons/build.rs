// build.rs
fn main() {
    // Emit configuration for conditional compilation
    println!("cargo:rustc-check-cfg=cfg(kani)");
    // This allows #[cfg(kani)] to be used without warnings when the feature is enabled.
}
