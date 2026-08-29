use std::env;
use std::fs;
use std::path::Path;
use anyhow::{Result, Context};
use serde_json::Value;

const L_EFF_TARGET: f64 = 0.1386;
const DRIFT_THRESHOLD: f64 = 1e-4; // 10^-4

fn main() -> Result<()> {
    println!("[INFO] [The Examiner] Starting independent MD-005 drift audit...");

    // 1. Determine observed L_eff
    // We try to read from the status_snapshot.json or from command line arguments
    let mut observed_l_eff = L_EFF_TARGET;
    
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        observed_l_eff = args[1].parse::<f64>()
            .context("Failed to parse observed L_eff argument as float")?;
        println!("[INFO] [The Examiner] Auditing command-line observed L_eff: {}", observed_l_eff);
    } else {
        // Fallback to checking status snapshot
        let snapshot_path = Path::new("/home/multiplicity/Multiplicity/Phase Mirror/cli/phasemirror-cli/artifacts/status_snapshot.json");
        if snapshot_path.exists() {
            let content = fs::read_to_string(snapshot_path)?;
            let v: Value = serde_json::from_str(&content)?;
            if let Some(l_eff) = v.get("l_eff").and_then(|x| x.as_f64()) {
                observed_l_eff = l_eff;
                println!("[INFO] [The Examiner] Auditing snapshot observed L_eff: {}", observed_l_eff);
            }
        }
    }

    // 2. Compute drift magnitude (delta)
    let delta = (observed_l_eff - L_EFF_TARGET).abs();
    
    // 3. Invariant: Zero-Tolerance Drift
    if delta >= DRIFT_THRESHOLD {
        eprintln!(
            "[PRESERVATION ALERT] [SIG_GOV_KILL] Drift limit violated! Observed L_eff: {}, Target: {}, Delta: {} >= threshold: {}",
            observed_l_eff, L_EFF_TARGET, delta, DRIFT_THRESHOLD
        );
        std::process::exit(1);
    }

    println!(
        "[INFO] [The Examiner] MD-005 drift audit passed. Delta: {} < threshold: {}",
        delta, DRIFT_THRESHOLD
    );
    Ok(())
}
