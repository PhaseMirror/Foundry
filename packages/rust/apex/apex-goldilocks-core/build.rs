use std::process::Command;
use std::path::Path;

fn main() {
    // We want to check all crates in the workspace
    let workspace_crates_dir = Path::new(".."); 
    
    let output = Command::new("grep")
        .arg("-r")
        .arg("-E")
        .arg("f32|f64")
        .arg("--exclude=build.rs")
        .arg("--exclude-dir=node_modules")
        .arg("--exclude-dir=docs")
        .arg("--exclude-dir=target")
        .arg("--exclude-dir=hologram-app")
        .arg("--exclude-dir=holoapp-cli")
        .arg("--exclude-dir=tests")
        .arg(workspace_crates_dir)
        .output()
        .expect("Failed to execute grep");

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        if !stdout.is_empty() {
            panic!("L0 Invariant Violation: Floating point types (f32/f64) found in Goldilocks Zone!\n{}", stdout);
        }
    }
    
    println!("cargo:rerun-if-changed=src");
    println!("cargo:rerun-if-changed=../multiplicity-runtime/src");
}
