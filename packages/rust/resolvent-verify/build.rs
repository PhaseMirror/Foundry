// build.rs

use std::env;
use std::fs;
use std::path::Path;

fn main() {
    // Only run if the lean_certified feature is enabled.
    // We detect this via the CARGO_FEATURE_LEAN_CERTIFIED environment variable.
    if env::var("CARGO_FEATURE_LEAN_CERTIFIED").is_ok() {
        let out_dir = env::var("OUT_DIR").unwrap();
        let dest_path = Path::new(&out_dir).join("generated_vals_array.rs");

        // Read the Lean-certified JSON (assumed to be in the lean project root).
        let json_path = Path::new("../../lean/basis_factors.json");
        if !json_path.exists() {
            panic!("basis_factors.json not found at ../../lean/basis_factors.json. Run the Lean certificate generator first.");
        }

        let json_content = fs::read_to_string(json_path).expect("Failed to read basis_factors.json");
        let data: serde_json::Value = serde_json::from_str(&json_content).expect("Invalid JSON");

        // Extract the basis array.
        let basis = data["basis"].as_array().expect("Missing 'basis' array");
        let mut rust_code = String::new();
        rust_code.push_str("// Auto-generated from Lean-certified basis_factors.json\n");
        rust_code.push_str("pub const N_STATES: usize = ");
        rust_code.push_str(&basis.len().to_string());
        rust_code.push_str(";\n");
        rust_code.push_str("pub const PRIMES: [u32; 4] = [2, 3, 5, 7];\n");
        
        // Add NUMBERS
        rust_code.push_str("pub const NUMBERS: [usize; N_STATES] = [\n");
        for entry in basis {
            let n = entry["n"].as_u64().unwrap();
            rust_code.push_str(&format!("    {},\n", n));
        }
        rust_code.push_str("];\n");

        rust_code.push_str("pub static VALS: [[u8; 4]; N_STATES] = [\n");

        for entry in basis {
            let exps = entry["exponents"].as_array().expect("Missing exponents");
            let exps_str: Vec<String> = exps.iter().map(|v| v.as_u64().unwrap().to_string()).collect();
            rust_code.push_str(&format!("    [{}],\n", exps_str.join(", ")));
        }
        rust_code.push_str("];\n");

        fs::write(&dest_path, rust_code).expect("Failed to write generated array");
        println!("cargo:rerun-if-changed=../../lean/basis_factors.json");
        println!("cargo:rerun-if-changed=build.rs");
    }
}
