// Build script for MOC crate – runs Lean lake build

use std::process::Command;
use std::path::Path;

fn main() {
    // Lean project root (relative to crate)
    let lean_root = Path::new("../lean");
    assert!(lean_root.join("lakefile.lean").exists(), "Lakefile not found");

    let status = Command::new("lake")
        .arg("build")
        .current_dir(&lean_root)
        .status()
        .expect("Failed to execute `lake build`");

    if !status.success() {
        panic!("`lake build` failed with status: {}", status);
    }
}
