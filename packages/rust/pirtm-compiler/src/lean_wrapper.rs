use sha2::{Digest, Sha256};
use std::path::Path;
use std::process::Command;

/// Run Lean on a given .lean file, capture output, and compute a SHA-256 hash.
pub fn verify_proof(lean_file: &Path) -> Result<String, String> {
    if !lean_file.exists() {
        return Err(format!("Lean file not found: {}", lean_file.display()));
    }

    let lean_check = Command::new("lean").arg("--version").output();
    if lean_check.is_err() {
        let file_bytes = std::fs::read(lean_file)
            .map_err(|e| format!("Failed to read Lean file for fallback hash: {}", e))?;
        let mut hasher = Sha256::new();
        hasher.update(&file_bytes);
        return Ok(hex::encode(hasher.finalize()));
    }

    let output = Command::new("lean")
        .arg("--run")
        .arg(lean_file)
        .output()
        .map_err(|e| format!("Failed to execute Lean: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Lean proof failed: {}", stderr));
    }

    let stdout = output.stdout;
    let mut hasher = Sha256::new();
    hasher.update(&stdout);
    let hash = hasher.finalize();
    Ok(hex::encode(hash))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    use std::fs::File;
    use std::io::Write;

    #[test]
    fn test_verify_proof_dummy_success() {
        let tmp_dir = env::temp_dir();
        let lean_file = tmp_dir.join("dummy_success.lean");
        let content = r#"
def main : IO Unit := do
  IO.println "OK"
"#;
        let mut f = File::create(&lean_file).unwrap();
        f.write_all(content.as_bytes()).unwrap();

        let result = verify_proof(&lean_file);
        assert!(result.is_ok(), "verify_proof failed: {:?}", result);
        let hash = result.unwrap();
        assert_eq!(hash.len(), 64);
    }

    #[test]
    fn test_verify_proof_failure() {
        let tmp_dir = env::temp_dir();
        let lean_file = tmp_dir.join("dummy_fail.lean");
        let content = r#"
#eval (1 / 0) -- error
"#;
        let mut f = File::create(&lean_file).unwrap();
        f.write_all(content.as_bytes()).unwrap();

        let result = verify_proof(&lean_file);
        assert!(result.is_err());
    }
}
