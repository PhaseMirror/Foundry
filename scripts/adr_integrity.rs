// scripts/adr_integrity.rs
use std::fs::File;
use std::io::Read;
use std::path::{Path, PathBuf};
use sha2::{Digest, Sha256};
use walkdir::WalkDir;

const EXPECTED_HASH_FILE: &str = "Prime/lean/ADR/.adr-proof-hash";
const ADR_BUILD_DIR: &str = "Prime/lean/ADR/build/lib/ADR";

pub fn compute_adr_hash(workspace_root: &Path) -> Option<String> {
    let adr_dir = workspace_root.join(ADR_BUILD_DIR);
    if !adr_dir.exists() {
        return None;
    }

    let mut hasher = Sha256::new();
    let mut entries: Vec<PathBuf> = WalkDir::new(&adr_dir)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().map_or(false, |ext| ext == "olean"))
        .map(|e| e.into_path())
        .collect();
    entries.sort();

    for path in entries {
        let mut file = File::open(&path).ok()?;
        let mut buffer = Vec::new();
        file.read_to_end(&mut buffer).ok()?;
        hasher.update(&buffer);
    }

    Some(format!("{:x}", hasher.finalize()))
}

pub fn read_expected_hash(workspace_root: &Path) -> Option<String> {
    let path = workspace_root.join(EXPECTED_HASH_FILE);
    if !path.exists() {
        return None;
    }
    std::fs::read_to_string(&path)
        .ok()
        .map(|s| s.trim().to_string())
}

pub fn verify_adr_integrity(workspace_root: &Path) -> Result<(), String> {
    let computed = compute_adr_hash(workspace_root)
        .ok_or_else(|| "Failed to compute ADR hash: build directory missing or empty.".to_string())?;

    let expected = read_expected_hash(workspace_root)
        .unwrap_or_else(|| {
            eprintln!("⚠️  .adr-proof-hash not found; skipping verification (dev mode).");
            return computed.clone();
        });

    if computed != expected {
        return Err(format!(
            "\n⛔ SEDONA SPINE INTEGRITY VIOLATION ⛔\n            ADR proof hash mismatch.\n            Expected: {}\n            Actual:   {}\n            \n            Action: Update Prime/lean/ADR/.adr-proof-hash to match the new hash,\n            or ensure the Lean ADR library is rebuilt and committed.\n",
            expected, computed
        ));
    }

    println!("cargo:info=✅ ADR proof hash matches Sedona Spine invariant.");
    Ok(())
}
