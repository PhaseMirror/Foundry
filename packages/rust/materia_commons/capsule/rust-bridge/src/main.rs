use std::env;
use std::fs;
use serde::{Deserialize, Serialize};

#[derive(Deserialize, Debug)]
struct QiskitResult {
    simulated_norm: u32,
    h_immutable: bool,
    decoherence_variance: f64,
}

#[derive(Deserialize, Debug)]
struct HardwarePayload {
    job_id: String,
    timestamp: String,
    hardware: String,
    qudits: u32,
    shots: u32,
    results: QiskitResult,
}

#[derive(Serialize)]
struct CertifiedFact {
    job_id: String,
    hardware: String,
    upper_bound: u32,
    verified: bool,
    decoherence_variance: f64,
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: rust-bridge <path_to_raw_json>");
        std::process::exit(1);
    }

    let raw_data = fs::read_to_string(&args[1]).expect("Unable to read raw data file");
    let payload: HardwarePayload = serde_json::from_str(&raw_data).expect("Invalid JSON format");

    // L0 invariant: fail-closed exactly at 3900 ceiling
    if payload.results.simulated_norm > 3900 {
        eprintln!("SIG_GOV_KILL: Norm exceeds 3900 L0 ceiling.");
        std::process::exit(1);
    }

    let certified = CertifiedFact {
        job_id: payload.job_id,
        hardware: payload.hardware,
        upper_bound: payload.results.simulated_norm,
        verified: payload.results.h_immutable,
        decoherence_variance: payload.results.decoherence_variance,
    };

    let serialized = serde_json::to_string_pretty(&certified).unwrap();
    println!("{}", serialized);
}
