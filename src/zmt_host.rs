use risc0_zkvm::{default_prover, ExecutorEnv};
use std::fs;

fn main() {
    // Load prime/zero tables from the DVC-tracked npz (converted to JSON for simplicity)
    let primes: Vec<f64> = serde_json::from_str(
        &fs::read_to_string("data/primes.json").expect("primes.json missing")
    ).expect("invalid primes");
    let zeros: Vec<f64> = serde_json::from_str(
        &fs::read_to_string("data/zeros.json").expect("zeros.json missing")
    ).expect("invalid zeros");

    let env = ExecutorEnv::builder()
        .write(&primes)
        .unwrap()
        .write(&zeros)
        .unwrap()
        .build()
        .unwrap();

    let prover = default_prover();
    let receipt = prover.prove(env, "zmt_prove").unwrap();

    // Verify the receipt locally
    receipt.verify("zmt_prove").expect("STARK verification failed");

    // Extract the committed HS-norm
    let hs_norm_sq: f64 = receipt.journal.decode().unwrap();
    println!("Certified HS-norm²: {}", hs_norm_sq);

    // Save the receipt
    let receipt_path = "artifacts/stark_receipt.bin";
    fs::write(receipt_path, bincode::serialize(&receipt).unwrap()).unwrap();
    println!("Receipt saved to {}", receipt_path);
}
