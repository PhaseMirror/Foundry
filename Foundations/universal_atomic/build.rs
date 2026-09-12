// build.rs
use std::process::Command;

fn main() {
    // Build Lean library via Lake before Rust compilation
    let status = Command::new("lake")
        .arg("build")
        .current_dir("lean")
        .status()
        .expect("Failed to run lake build");
    if !status.success() {
        panic!("Lake build failed with status: {}", status);
    }
    // Rebuild if any Lean source changes
    println!("cargo:rerun-if-changed=lean/src");
}
