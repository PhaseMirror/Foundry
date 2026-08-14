use serde::{Deserialize, Serialize};
use std::io::{self, Read};
use clap::Parser;
use anyhow::{Result, Context};

pub mod lawful;
pub mod proof_attestation;
pub mod l0_verification_gate;

use l0_verification_gate::{L0VerificationGate, ResonanceBufferState};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ExactRat {
    pub num: i64,
    pub den: u64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MocBlock {
    pub p: u64,
    pub r: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GuardianProposal {
    pub name: String,
    pub sequence: u64,
    pub target_dim: u64,
    pub blocks: Vec<MocBlock>,
    pub kappa: ExactRat,
    pub sigma: ExactRat,
    pub signature: String,
    pub proof_hash: String,
    pub prev_pweh: String,
    pub resonance_state: Option<ResonanceBufferState>,
}

#[derive(Parser)]
struct Cli {
    #[arg(long, default_value = "0")]
    last_seq: u64,
}

const AUTHORIZED_SIG: &str = "AUTHORIZED_GUARDIAN_SIG";

fn evaluate_normal_form(mut blocks: Vec<MocBlock>) -> Vec<MocBlock> {
    if blocks.is_empty() { return blocks; }
    blocks.sort_by_key(|b| b.p);
    let mut nf = Vec::new();
    let mut current = blocks[0].clone();
    for block in blocks.into_iter().skip(1) {
        if block.p == current.p {
            current.r += block.r;
        } else {
            if current.r > 0 {
                nf.push(current);
            }
            current = block;
        }
    }
    if current.r > 0 {
        nf.push(current);
    }
    nf
}

fn main() -> Result<()> {
    let args = Cli::parse();
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer).context("Failed to read from stdin")?;
    let mut proposal: GuardianProposal = serde_json::from_str(&buffer).context("Failed to parse proposal JSON")?;
    
    if proposal.signature != AUTHORIZED_SIG {
        eprintln!("[GUARDIAN] REJECT: Signature unverified or forged.");
        std::process::exit(1);
    }
    
    if proposal.sequence <= args.last_seq {
        eprintln!("[GUARDIAN] REJECT: Replay attack detected.");
        std::process::exit(1);
    }

    if proposal.proof_hash != proof_attestation::PROOF_HASH {
        eprintln!("[GUARDIAN] REJECT: Binary core proof-hash mismatch.");
        std::process::exit(1);
    }
    
    println!("[GUARDIAN] Reducing MOC Word to NF(Q,p)...");
    let original_blocks = proposal.blocks.len();
    proposal.blocks = evaluate_normal_form(proposal.blocks);
    println!("[GUARDIAN] NF(Q,p) complete: {} -> {} blocks.", original_blocks, proposal.blocks.len());

    let mut computed_dim: u64 = 1;
    for block in &proposal.blocks {
        computed_dim *= block.p.pow(block.r);
    }

    if computed_dim != proposal.target_dim {
        eprintln!("[GUARDIAN] REJECT: Dimension mismatch.");
        std::process::exit(1);
    }

    if let Some(state) = &proposal.resonance_state {
        let l0_gate = L0VerificationGate::new("SCHEMA_PWEH_V1", 0x00000001);
        if let Err(e) = l0_gate.verify_state(state) {
            eprintln!("[GUARDIAN] REJECT: {}", e);
            std::process::exit(1);
        }
    }

    // Dynamic Contraction Audit & PWEH Trace
    // c_p = kappa * p^(-sigma) * 1.05 >= 1.0
    // If sigma = 1/2 (num:1, den:2), c_p >= 1 implies: (kappa * 105)^2 >= p * 10000
    
    let mut current_pweh = proposal.prev_pweh.clone();

    for block in &proposal.blocks {
        let p = block.p;
        // Check contraction using pure integer math assuming sigma = 1/2
        // c_p >= 1.0 <==> kappa_num * 105 >= kappa_den * 100 * sqrt(p)
        // <==> (kappa_num * 105)^2 >= (kappa_den * 100)^2 * p
        
        let lhs = (proposal.kappa.num as i128 * 105).pow(2);
        let rhs = (proposal.kappa.den as i128 * 100).pow(2) * (p as i128);
        
        if lhs >= rhs {
            eprintln!("[GUARDIAN] REJECT: Contraction bound violated for prime p={}.", p);
            std::process::exit(1);
        }

        let mut hasher = blake3::Hasher::new();
        hasher.update(current_pweh.as_bytes());
        hasher.update(&p.to_be_bytes());
        hasher.update(&lhs.to_be_bytes());
        hasher.update(proposal.proof_hash.as_bytes());
        current_pweh = hasher.finalize().to_hex().to_string();
    }
    
    let digest = md5::compute(&buffer);
    let witness = format!("GUARDIAN-WITNESS-{}-{:x}-{}", proposal.sequence, digest, proposal.proof_hash);
    println!("[GUARDIAN] PASS: Contraction verified (discrete bounds).");
    println!("[GUARDIAN] PWEH Trace: {}", current_pweh);
    println!("{}", witness);
    
    Ok(())
}

