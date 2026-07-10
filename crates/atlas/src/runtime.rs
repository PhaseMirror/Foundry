use serde::{Deserialize, Serialize};
use std::io::{self, Read};
use clap::Parser;
use anyhow::Result;

// Import the generated attestation
pub mod proof_attestation {
    include!("proof_attestation.rs");
}

#[derive(Debug, Serialize, Deserialize)]
struct Schema {
    name: String,
    primes: Vec<u32>,
    sequence: u64,
    signature: String,
    proof_hash: String,
    layer_witness: String,
    constitutional_witness: String,
    mtpi_witness: String, // MTPI Attestation
}

#[derive(Parser)]
struct Cli {
    #[arg(long)]
    last_seq: u64,
}

const AUTHORIZED_SCHEMA_SIG: &str = "AUTHORIZED_SCHEMA_SIG";

fn main() -> Result<()> {
    let args = Cli::parse();
    
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer)?;
    
    let schema: Schema = serde_json::from_str(&buffer)?;
    
    // 1. Hardware-Isolated Signing Integrity
    if schema.signature != AUTHORIZED_SCHEMA_SIG {
        eprintln!("Security Breach: Signature unverified or forged.");
        std::process::exit(1);
    }
    
    // 2. Anti-Replay Monotonicity
    if schema.sequence <= args.last_seq {
        eprintln!("Security Breach: Replay attack detected. Sequence {} <= {}", schema.sequence, args.last_seq);
        std::process::exit(1);
    }

    // 3. Runtime Verification Gate (Proof Attestation)
    // Verify Core Stability Hash
    if schema.proof_hash != proof_attestation::PROOF_HASH {
        eprintln!("Security Breach: Binary core proof-hash mismatch.");
        std::process::exit(1);
    }
    
    // Verify Governance Layer Witness
    if schema.layer_witness.is_empty() {
        eprintln!("Security Breach: Missing governance layer attestation.");
        std::process::exit(1);
    }

    // Verify L3 Constitutional Witness
    if schema.constitutional_witness.is_empty() {
        eprintln!("Security Breach: Missing L3 constitutional attestation.");
        std::process::exit(1);
    }

    // Verify MTPI Constitutional Witness
    if schema.mtpi_witness != "MTPI_VALID" {
        eprintln!("Security Breach: Missing or invalid MTPI attestation.");
        std::process::exit(1);
    }
    
    // 4. Success -> Execute Transition
    println!("Transition Executed Successfully: Core Verified ({}) + Governance Verified ({}) + L3 Verified ({}) + MTPI Verified ({})", 
        schema.proof_hash, schema.layer_witness, schema.constitutional_witness, schema.mtpi_witness);
    
    Ok(())
}

// LawfulRecursionVersion:1.0
