use std::fs;
use std::path::Path;
use sha2::{Sha256, Digest};
use regex::Regex;

fn main() {
    // 1. Read the Lean constant
    let lean_path = "../../lean/SNAPKITTY/SnapKitty/Observability.lean";
    let lean_content = fs::read_to_string(lean_path).expect("Failed to read Observability.lean");
    
    // Extract ANOMALY_GOV_THRESHOLD
    let threshold_re = Regex::new(r"def ANOMALY_GOV_THRESHOLD\s*:\s*Float\s*:=\s*([0-9.-]+)").unwrap();
    let threshold = threshold_re.captures(&lean_content)
        .expect("Missing ANOMALY_GOV_THRESHOLD")[1].to_string();
        
    println!("cargo:rustc-env=ANOMALY_GOV_THRESHOLD={}", threshold);

    // 2. Validate the model hash
    let hash_re = Regex::new(r#"def ANOMALY_MODEL_HASH\s*:\s*String\s*:=\s*"([a-f0-9]+)""#).unwrap();
    let expected_hash = hash_re.captures(&lean_content)
        .expect("Missing ANOMALY_MODEL_HASH")[1].to_string();

    let model_path = "../../observability/anomaly_model.pkl";
    let mut file = fs::File::open(model_path).expect("Missing anomaly_model.pkl");
    let mut hasher = Sha256::new();
    std::io::copy(&mut file, &mut hasher).unwrap();
    let actual_hash = format!("{:x}", hasher.finalize());

    if actual_hash != expected_hash {
        panic!("CRITICAL SECURITY FAILURE: anomaly_model.pkl hash ({}) does not match the formally verified Observability.lean hash ({})!", actual_hash, expected_hash);
    }
    
    // Tell cargo to re-run if these files change
    println!("cargo:rerun-if-changed={}", lean_path);
    println!("cargo:rerun-if-changed={}", model_path);
}
