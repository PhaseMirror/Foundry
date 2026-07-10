use anyhow::{Context, Result};
use std::{env, fs};
use prover::StarkProof;
use recursive_prover::verifier_gadget::StarkVerifierGadget;
use num_bigint::BigUint;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Usage: wrap-proof <inner_proof.json>");
        return Ok(());
    }

    let proof_path = &args[1];
    let proof_json = fs::read_to_string(proof_path)
        .with_context(|| format!("Failed to read proof from {}", proof_path))?;
    
    let inner_proof: StarkProof = serde_json::from_str(&proof_json)
        .context("Failed to deserialize inner proof")?;

    println!("=== Starting Recursive Proof Wrap POC ===");
    println!("  Inner Proof Commitment: 0x{}", hex::encode(&inner_proof.trace_commitment));
    
    let gadget = StarkVerifierGadget::new();
    let blinding = BigUint::from(987654321u64);
    
    println!("Step 1: Wrapping STARK into RPO v1...");
    // For POC, we assume empty public inputs or extract them from a real AIR later.
    let rpo = gadget.wrap_stark(&inner_proof, vec![], &blinding)?;
    
    println!("  Recursive Pedersen Commitment (Affine):");
    println!("    X: 0x{}", rpo.seal_x);
    println!("    Y: 0x{}", rpo.seal_y);

    println!("\nStep 2: Saving Recursive Proof Object (RPO)...");
    let rpo_json = serde_json::to_string_pretty(&rpo)?;
    let rpo_path = "recursive_proof.json";
    fs::write(rpo_path, &rpo_json)?;
    println!("  Saved: {} ({} bytes)", rpo_path, rpo_json.len());

    println!("\n=== Recursive Wrap Complete ===");
    Ok(())
}
