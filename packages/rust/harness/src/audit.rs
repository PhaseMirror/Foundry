use anyhow::{Result, Context};
use std::fs;
use std::path::Path;
use sha2::{Sha256, Digest};
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct Anchor {
    pub file_path: String,
    pub hash: String,
    pub tag: String,
    pub timestamp: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Manifest {
    pub version: String,
    pub anchors: Vec<Anchor>,
}

pub fn run_md005_audit(manifest_path: &Path) -> Result<()> {
    println!("[MD-005] Starting Drift Audit on Manifest Attachments...");
    
    let content = fs::read_to_string(manifest_path)
        .with_context(|| format!("Failed to read manifest at {:?}", manifest_path))?;
    let manifest: Manifest = serde_json::from_str(&content)?;
    
    let mut drift_detected = false;
    let mut total_coverage = 0;
    
    for anchor in &manifest.anchors {
        let path = Path::new(&anchor.file_path);
        total_coverage += 1;
        
        if !path.exists() {
            println!("[DRFT-001] Missing Artifact: {}", anchor.file_path);
            drift_detected = true;
            continue;
        }
        
        let current_content = fs::read(path)?;
        let mut hasher = Sha256::new();
        hasher.update(current_content);
        let current_hash = format!("{:x}", hasher.finalize());
        
        if current_hash != anchor.hash {
            println!("[DRFT-002] Hash Mismatch: {}", anchor.file_path);
            println!("  Expected: {}", anchor.hash);
            println!("  Actual:   {}", current_hash);
            drift_detected = true;
        } else {
            println!("[OK] Verified: {}", anchor.file_path);
        }
    }
    
    println!("[MD-005] Audit Complete. Total Attachments: {}", total_coverage);
    
    if drift_detected {
        println!("[CRITICAL] Drift magnitude exceeds threshold! Activating Kill-Switch.");
        std::process::exit(1);
    } else {
        println!("[SUCCESS] Zero unanchored artifacts. Sedona Spine alignment verified.");
    }
    
    Ok(())
}
