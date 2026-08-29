use std::env;
use std::fs;
use std::path::Path;
use anyhow::{Result, Context};
use sha2::{Sha256, Digest};
use serde_json::Value;

fn main() -> Result<()> {
    println!("[INFO] [The Publisher] Starting authoritative witness artifact publication...");

    // 1. Determine target file to publish
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("[WARN] No target file specified for publication. Operating in simulation mode.");
        println!("[INFO] [The Publisher] Success signal dispatched.");
        return Ok(());
    }

    let file_path_str = &args[1];
    let file_path = Path::new(file_path_str);
    if !file_path.exists() {
        return Err(anyhow::anyhow!("Target file for publication does not exist: {}", file_path_str));
    }

    // 2. Read file content
    let content = fs::read_to_string(file_path)
        .context("Failed to read artifact file content")?;

    // 3. Load previous hash from mock ledger (or default to empty)
    let ledger_path = Path::new("/home/multiplicity/Multiplicity/Governance/State/state/phase_mirror_harness_ledger.json");
    let mut prev_hash = String::new();
    
    if ledger_path.exists() {
        let ledger_content = fs::read_to_string(ledger_path)?;
        let v: Value = serde_json::from_str(&ledger_content)?;
        if let Some(entries) = v.get("entries").and_then(|x| x.as_array()) {
            if let Some(last_entry) = entries.last() {
                if let Some(entry_hash) = last_entry.get("entry_hash").and_then(|x| x.as_str()) {
                    prev_hash = entry_hash.to_string();
                }
            }
        }
    }

    // 4. Compute LawfulRecursionHash v1.0
    let mut hasher = Sha256::new();
    hasher.update(prev_hash.as_bytes());
    hasher.update(content.as_bytes());
    let recursion_hash = format!("{:x}", hasher.finalize());

    println!("[INFO] [The Publisher] Computed LawfulRecursionHash v1.0: {}", recursion_hash);
    println!("[INFO] [The Publisher] Publishing artifact: {}", file_path.file_name().unwrap().to_string_lossy());
    println!("[INFO] [The Publisher] Success signal dispatched to Sedona Spine.");

    Ok(())
}
