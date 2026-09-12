use ace::*;
use crmf::*;
use std::fs;
use anyhow::Context;

fn main() -> anyhow::Result<()> {
    let payload_path = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "payload.json".to_string());
    let output_path = std::env::args()
        .nth(2)
        .unwrap_or_else(|| "witness.json".to_string());

    let payload_bytes = fs::read(&payload_path)
        .with_context(|| format!("Failed to read payload from {}", payload_path))?;

    let keypair = CrmfKeypair::generate();
    let params = CertificationParams::default();

    let payload = EnvelopePayload {
        event_type: "witness_generation".to_string(),
        data: serde_json::from_slice(&payload_bytes)?,
        proof_hashes: vec![],
    };

    let metadata = EnvelopeMetadata::new("witness-generator")
        .with_lawful_hash("epoch-2026-08-29")
        .with_wardmonitor("healthy")
        .with_drift(0.005);

    let envelope = AceEnvelope::certify(
        payload,
        metadata,
        &params,
        100,
        &keypair,
    )?;

    let witness_input = generate_witness_input(&envelope);

    fs::write(&output_path, serde_json::to_string_pretty(&witness_input)?)?;

    println!("Witness generated: {}", output_path);
    println!("State payload elements: {}", witness_input.state_payload.len());
    println!("Lawful recursion hash: {}", witness_input.lawful_recursion_hash);

    Ok(())
}

/// Generate Circom witness input from ACE envelope.
///
/// Maps the ACE-certified payload to the 8-element state_payload array
/// expected by the ACEGuardian(t=9, r=8) Circom circuit.
fn generate_witness_input(envelope: &AceEnvelope) -> CircomWitnessInput {
    use sha2::{Digest, Sha256};

    let payload_json = serde_json::to_vec(&envelope.payload).unwrap();
    let mut hasher = Sha256::new();
    hasher.update(&payload_json);
    let hash = hasher.finalize();

    let mut state_payload = Vec::with_capacity(8);
    for i in 0..8 {
        let start = i * 4;
        let mut bytes = [0u8; 8];
        bytes[4..8].copy_from_slice(&hash[start..start + 4]);
        state_payload.push(u64::from_be_bytes(bytes));
    }

    let lawful_hash = u64::from_be_bytes([
        hash[0], hash[1], hash[2], hash[3],
        hash[4], hash[5], hash[6], hash[7],
    ]);

    CircomWitnessInput {
        state_payload,
        lawful_recursion_hash: lawful_hash,
    }
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
struct CircomWitnessInput {
    state_payload: Vec<u64>,
    lawful_recursion_hash: u64,
}
