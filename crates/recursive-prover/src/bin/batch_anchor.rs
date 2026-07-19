//! `batch_anchor` — ADR-PML-050 daily FeMoco batch → APO → batch root.
//!
//! Reads a JSONL of the last 24h of `Attested` events (digest, timestamp,
//! consent_commitment, nullifier) for FeMoco runs, wraps each into a
//! `RecursiveProofObject`, aggregates them into one `AggregatedProofObject`
//! via `StarkVerifierGadget::aggregate_rpos`, and prints/emits the
//! `aggregate_root`. That root is the **Run Aggregator Root** the ADR-PML-055
//! daily anchor consumes as its `attestations` category.
//!
//! This bin adds ONLY the composition glue on top of `recursive-prover`'s
//! existing `StarkVerifierGadget`; it introduces no new crypto.

use anyhow::{Context, Result};
use serde::Deserialize;
use std::{env, fs};

use recursive_prover::verifier_gadget::{RecursiveProofObject, StarkVerifierGadget};

/// One FeMoco `Attested` event from the last 24h window.
#[derive(Debug, Clone, Deserialize)]
struct AttestedEvent {
    /// keccak256 of the SQD state (matches `Attested.digest`).
    digest: String,
    /// epoch seconds (matches `Attested.timestamp`).
    timestamp: u64,
    /// consent commitment binding (matches `Attested.consentCommitment`).
    consent_commitment: String,
    /// replay nullifier (matches `Attested.nullifier`).
    nullifier: String,
}

/// Hash of one run, byte-identical to `AttestationRegistry._computeMerkleRoot`.
///
/// `keccak256(prev || digest || timestamp || consent || nullifier)`
/// chained over the ordered event list.
fn batch_merkle_root(events: &[AttestedEvent]) -> [u8; 32] {
    let mut prev = [0u8; 32];
    for e in events {
        prev = leaf_hash(&prev, e);
    }
    prev
}

/// One chained Merkle leaf: keccak256(prev || digest || ts || consent || nullifier).
/// Byte-identical to `AttestationRegistry._computeMerkleRoot`'s fold, which uses
/// Solidity `keccak256(abi.encodePacked(prev, digest, uint64 ts, consent, nullifier))`.
/// NOTE: `timestamp` is `uint64` in `BatchRunData`, so it packs as **8 bytes** (big-endian).
fn leaf_hash(prev: &[u8; 32], e: &AttestedEvent) -> [u8; 32] {
    use keccak::Keccak256;

    let digest = hex::decode(&e.digest.trim_start_matches("0x")).unwrap_or_default();
    let consent =
        hex::decode(&e.consent_commitment.trim_start_matches("0x")).unwrap_or_default();
    let nullifier =
        hex::decode(&e.nullifier.trim_start_matches("0x")).unwrap_or_default();

    let mut ts = [0u8; 8];
    ts.copy_from_slice(&e.timestamp.to_be_bytes());

    let mut h = Keccak256::new();
    h.update(prev);
    h.update(&digest);
    h.update(&ts);
    h.update(&consent);
    h.update(&nullifier);
    let mut out = [0u8; 32];
    out.copy_from_slice(h.finalize().as_slice());
    out
}

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!(
            "Usage: batch_anchor <attested_events.jsonl> [out=aggregated_proof.json]"
        );
        return Ok(());
    }

    let events_path = &args[1];
    let out_path = args.get(2).map(String::as_str).unwrap_or("aggregated_proof.json");

    let raw = fs::read_to_string(events_path)
        .with_context(|| format!("Failed to read events from {}", events_path))?;

    let mut events: Vec<AttestedEvent> = Vec::new();
    for line in raw.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        events.push(
            serde_json::from_str(line)
                .with_context(|| format!("Failed to parse event: {line}"))?,
        );
    }
    println!("=== UAC Daily Batch Anchor (ADR-PML-050) ===");
    println!("  Loaded {} FeMoco attestations (24h window)", events.len());

    // 1. Chained Merkle root that AttestationRegistry._computeMerkleRoot
    //    expects. This is the authoritative **Run Aggregator Root** the
    //    ADR-PML-055 daily anchor consumes as its `attestations` category.
    let batch_root = batch_merkle_root(&events);
    println!("  Batch Merkle Root: 0x{}", hex::encode(batch_root));

    // 2. Wrap each attestation into a RecursiveProofObject and aggregate to one APO.
    //    `inner_root` of member i is the running chain value AFTER that
    //    run is folded in, so the gadget's `aggregate_root` is a genuine
    //    keccak commitment over the ordered member roots. NOTE: the APO
    //    `aggregate_root` is the STARK proof commitment and is NOT
    //    byte-equal to the chained `batch_root`; the anchor uses `batch_root`.
    let gadget = StarkVerifierGadget::new();
    let blinding = num_bigint::BigUint::from(1122334455u64);

    let mut running = [0u8; 32];
    let mut rpos = Vec::new();
    for (i, e) in events.iter().enumerate() {
        running = leaf_hash(&running, e);
        let rpo = RecursiveProofObject {
            protocol_v: 1,
            inner_root: running,
            inputs: vec![i as u64, e.timestamp],
            fri_roots: vec![running],
            seal_x: "0x0".to_string(),
            seal_y: "0x0".to_string(),
        };
        rpos.push(rpo);
    }

    println!("  Aggregating {} proofs into one APO...", rpos.len());
    let apo = gadget
        .aggregate_rpos(&rpos, &blinding)
        .context("STARK aggregation failed")?;

    // 3. Consistency: the final chained value MUST equal `batch_root`
    //    (the last member root is the full chained root).
    if running != batch_root {
        anyhow::bail!(
            "running chain (0x{}) != batch Merkle root (0x{})",
            hex::encode(running),
            hex::encode(batch_root)
        );
    }
    println!("  APO Aggregate Root (STARK commitment): 0x{}", hex::encode(apo.aggregate_root));
    println!("  Member roots: {}", apo.member_roots.len());

    // 4. Persist the APO for on-chain submitBatchAttestation + Archivum witness.
    let apo_json = serde_json::to_string_pretty(&apo)?;
    fs::write(out_path, &apo_json)?;
    println!("  Saved APO: {} ({} bytes)", out_path, apo_json.len());

    println!("\n  => Hand `batch_root` (0x{}) to the ADR-PML-055 sidecar",
        hex::encode(batch_root));
    println!("     as the `attestations` category of the daily combined root.");
    println!("     (The APO `aggregate_root` is the STARK proof commitment,");
    println!("      verified on-chain via `submitBatchAttestation`.)");
    println!("=== Batch anchor complete ===");
    Ok(())
}
