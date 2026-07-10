use anyhow::{Context, Result};
use std::{env, fs};
use recursive_prover::verifier_gadget::{RecursiveProofObject, StarkVerifierGadget};
use num_bigint::BigUint;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Usage: aggregate-proofs <proof1.json> <proof2.json> ...");
        return Ok(());
    }

    let mut rpos = Vec::new();
    for path in args.iter().skip(1) {
        let json = fs::read_to_string(path)
            .with_context(|| format!("Failed to read RPO from {}", path))?;
        let rpo: RecursiveProofObject = serde_json::from_str(&json)
            .context(format!("Failed to deserialize RPO from {}", path))?;
        rpos.push(rpo);
    }

    println!("=== Starting Multi-RPO Aggregation POC ===");
    println!("  Aggregating {} proofs...", rpos.len());
    
    let gadget = StarkVerifierGadget::new();
    let blinding = BigUint::from(1122334455u64);
    
    println!("Step 1: Computing Aggregate Seal...");
    let apo = gadget.aggregate_rpos(&rpos, &blinding)?;
    
    println!("  Aggregate Root: 0x{}", hex::encode(&apo.aggregate_root));
    println!("  Aggregate Seal (Affine):");
    println!("    X: 0x{}", apo.seal_x);
    println!("    Y: 0x{}", apo.seal_y);

    println!("\nStep 2: Saving Aggregated Proof Object (APO)...");
    let apo_json = serde_json::to_string_pretty(&apo)?;
    let apo_path = "aggregated_proof.json";
    fs::write(apo_path, &apo_json)?;
    println!("  Saved: {} ({} bytes)", apo_path, apo_json.len());

    println!("\n=== Aggregation Complete ===");
    Ok(())
}
