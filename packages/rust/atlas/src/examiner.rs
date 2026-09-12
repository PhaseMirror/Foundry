use serde::{Deserialize, Serialize};
use std::io::{self, Read};
use clap::Parser;
use anyhow::{Result, Context};

/// MD-005 Drift Manifest: The authoritative baseline for an ensemble.
#[derive(Debug, Serialize, Deserialize)]
pub struct DriftManifest {
    pub ensemble_id: String,
    pub baseline_weights: Vec<i64>, // Scaled by 1_000_000
    pub delta_threshold: i64, // Scaled by 1_000_000 (e.g. 100 for 1e-4)
    pub timestamp: String,
}

/// The current state snapshot provided for auditing.
#[derive(Debug, Serialize, Deserialize)]
pub struct CurrentState {
    pub weights: Vec<i64>, // Scaled by 1_000_000
}

#[derive(Parser)]
struct Cli {
    /// Path to the authoritative drift manifest (JSON).
    #[arg(long)]
    manifest: String,
}

fn main() -> Result<()> {
    let args = Cli::parse();
    
    // 1. Load the authoritative Drift Manifest
    let manifest_content = std::fs::read_to_string(&args.manifest)
        .context("Failed to read drift manifest file")?;
    let manifest: DriftManifest = serde_json::from_str(&manifest_content)
        .context("Failed to parse drift manifest JSON")?;

    // 2. Read current state from stdin
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer).context("Failed to read current state from stdin")?;
    let current: CurrentState = serde_json::from_str(&buffer).context("Failed to parse current state JSON")?;

    // 3. Convexity Audit (ADR-002: ∑ α_p = 1)
    let sum: i64 = current.weights.iter().sum();
    // Allow small epsilon due to discrete scaling (e.g. off by 1 in 1_000_000)
    if (sum - 1_000_000).abs() > 10 {
        eprintln!("[EXAMINER] REJECT: Convexity violation (ADR-002). Sum α_p (scaled) = {}", sum);
        std::process::exit(1);
    }

    for (i, &w) in current.weights.iter().enumerate() {
        if w < 0 || w > 1_000_000 {
            eprintln!("[EXAMINER] REJECT: Weight α_{} = {} is out of bounds [0, 1M].", i, w);
            std::process::exit(1);
        }
    }

    // 4. MD-005 Drift Audit (δ < threshold)
    if current.weights.len() != manifest.baseline_weights.len() {
        eprintln!("[EXAMINER] REJECT: Weight dimension mismatch. Expected {}, got {}", 
            manifest.baseline_weights.len(), current.weights.len());
        std::process::exit(1);
    }

    let mut l2_drift_sq: i128 = 0;
    for i in 0..current.weights.len() {
        let diff = (current.weights[i] as i128) - (manifest.baseline_weights[i] as i128);
        l2_drift_sq += diff * diff;
    }

    let threshold_sq = (manifest.delta_threshold as i128) * (manifest.delta_threshold as i128);

    println!("[EXAMINER] Performing MD-005 Drift Audit for {}...", manifest.ensemble_id);

    if l2_drift_sq > threshold_sq {
        eprintln!("[EXAMINER] REJECT: MD-005 Drift threshold exceeded.");
        std::process::exit(1);
    }

    // 5. Success -> Emit Witness
    let digest = md5::compute(&buffer);
    let witness = format!("EXAMINER-WITNESS-{}-DRIFT-{:x}", manifest.ensemble_id, digest);
    println!("[EXAMINER] PASS: Drift within discrete bounds.");
    println!("{}", witness);

    Ok(())
}

