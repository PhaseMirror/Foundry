use serde::{Deserialize, Serialize};
use std::io::{self, Read};
use clap::Parser;
use anyhow::Result;

#[derive(Debug, Serialize, Deserialize)]
struct Schema {
    name: String,
    primes: Vec<u32>,
    sequence: u64,
    signature: String,
    proof_hash: String,
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
    
    // 1. Hardware-Isolated Signing Integrity Simulation
    if schema.signature != AUTHORIZED_SCHEMA_SIG {
        eprintln!("Security Breach: Signature unverified or forged.");
        std::process::exit(1);
    }
    
    // Validate ProofHash presence (integrity gate)
    if schema.proof_hash.is_empty() {
        eprintln!("Security Breach: Missing proof hash attestation.");
        std::process::exit(1);
    }
    
    // 2. Anti-Replay Monotonicity
    if schema.sequence <= args.last_seq {
        eprintln!("Security Breach: Replay attack detected. Sequence {} <= {}", schema.sequence, args.last_seq);
        std::process::exit(1);
    }
    
    // 3. Success -> Emit Witness
    let digest = md5::compute(&buffer);
    let witness = format!("WITNESS-{}-{:x}-{}", schema.sequence, digest, schema.proof_hash);
    println!("{}", witness);
    
    Ok(())
}

// LawfulRecursionVersion:1.0
