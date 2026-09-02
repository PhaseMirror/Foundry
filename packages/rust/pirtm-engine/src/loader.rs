use std::path::Path;
use std::process::Command;

/// Translate an MLIR file to LLVM IR using `mlir-translate`.
/// Returns the LLVM IR text as a String.
pub fn translate_mlir_to_llvm(mlir_path: &Path) -> Result<String, Box<dyn std::error::Error>> {
    // Check if mlir-translate is in PATH.
    let output = Command::new("mlir-translate")
        .arg("--mlir-to-llvmir")
        .arg(mlir_path.as_os_str())
        .output()?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("mlir-translate failed: {}", stderr).into());
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
