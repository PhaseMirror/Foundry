use legalese_scopist::{EsiInputs, ace::{evaluate_esi_risk_with_ace, AceEnvelope, AceBudget}};
use serde_json;
use std::io::{self, BufRead, Write};

fn main() {
    let stdin = io::stdin();
    
    // State wrapper to persist the recursion gain across QuTiP frames
    let mut current_lambda_m = 0.5;

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };
        
        if line.trim().is_empty() { continue; }

        let mut inputs: EsiInputs = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(e) => {
                let error_output = serde_json::json!({
                    "error": format!("JSON parse error: {}", e),
                });
                println!("{}", serde_json::to_string(&error_output).unwrap());
                io::stdout().flush().unwrap();
                continue;
            }
        };

        // Override the inputs JSON lambda_m with our internal persistent state
        inputs.lambda_m = current_lambda_m;

        // Create an ACE envelope for the transaction
        let budget = AceBudget {
            max_ops: 10_000,
            max_memory_bytes: 1024 * 1024,
        };
        let envelope = AceEnvelope::new(budget);

        // Run the governance engine (p_factor=2, sigma=2.0 for default)
        match evaluate_esi_risk_with_ace(&inputs, 2, 2.0, envelope) {
            Ok(certified_result) => {
                // Determine effective lambda_m and c_lambda (since it might have been decayed)
                // For demonstration, we simply check the fallback status inside the signature.
                if certified_result.witness.signature.contains("RECURSION_STABILIZED") {
                    current_lambda_m *= 0.5;
                }
                
                // Effective c_lambda (approximation based on updated lambda_m)
                let c_lambda = 1.0 - current_lambda_m * (1.0 - inputs.l_g);

                let output = serde_json::json!({
                    "risk_level": format!("{:?}", certified_result.witness.compilation_result.risk_level),
                    "is_stable": certified_result.witness.compilation_result.is_stable,
                    "w0_exec": certified_result.witness.w0_exec_hash,
                    "w1_axiom": certified_result.witness.w1_axiom_hash,
                    "w2_phys": certified_result.witness.w2_phys_hash,
                    "c_total": certified_result.witness.signature,
                    "spectral_radius": certified_result.witness.compilation_result.spectral_radius,
                    "ops_consumed": certified_result.final_envelope.ops_consumed,
                    "c_lambda": c_lambda,
                });
                println!("{}", serde_json::to_string(&output).unwrap());
                io::stdout().flush().unwrap();
            }
            Err(e) => {
                let error_output = serde_json::json!({
                    "error": e,
                });
                println!("{}", serde_json::to_string(&error_output).unwrap());
                io::stdout().flush().unwrap();
            }
        }
    }
}
