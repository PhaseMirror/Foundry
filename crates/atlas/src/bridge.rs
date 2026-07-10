use std::process::{Command, Stdio};
use std::io::Write;
use clap::Parser;
use anyhow::{Result, bail, anyhow};
use lexpr::Value;

#[derive(Parser)]
struct Cli {
    #[arg(index = 1)]
    sexpr: String,
    #[arg(index = 2)]
    last_seq: u64,
    #[arg(index = 3)]
    schema_path: String,
}

fn call_verifier(schema_json: &str, last_seq: u64) -> Result<String> {
    // Hardcoded absolute path for stability within the workspace
    let verifier_path = "/home/multiplicity/multiplicity/target/debug/moc-verifier";
    
    let mut child = Command::new(verifier_path)
        .arg("--last-seq")
        .arg(last_seq.to_string())
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn().map_err(|e| anyhow!("Failed to spawn {}: {}", verifier_path, e))?;

    let mut stdin = child.stdin.take().ok_or_else(|| anyhow!("Failed to open stdin"))?;
    stdin.write_all(schema_json.as_bytes())?;
    drop(stdin);

    let output = child.wait_with_output()?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!("Verifier Failure: {}", stderr);
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

fn to_lean(val: &Value) -> Result<String> {
    match val {
        Value::Cons(_) => {
            let list = val.to_vec().ok_or_else(|| anyhow!("Invalid list structure"))?;
            if list.is_empty() { return Ok("[]".to_string()); }
            
            if let Some(kind) = list[0].as_symbol() {
                match kind {
                    "slide" => {
                        let i = list[1].as_u64().ok_or_else(|| anyhow!("Expected i"))?;
                        let j = list[2].as_u64().ok_or_else(|| anyhow!("Expected j"))?;
                        let eps = list[3].as_i64().ok_or_else(|| anyhow!("Expected epsilon"))?;
                        Ok(format!("(MOC.RewriteOp.slide (Fin.mk {} (by sorry)) (Fin.mk {} (by sorry)) {})", i, j, eps))
                    }
                    "blowup" => {
                        let sig = list[1].as_i64().ok_or_else(|| anyhow!("Expected sigma"))?;
                        Ok(format!("(MOC.RewriteOp.blowup {})", sig))
                    }
                    "blowdown" => {
                        let sig = list[1].as_i64().ok_or_else(|| anyhow!("Expected sigma"))?;
                        Ok(format!("(MOC.RewriteOp.blowdown {})", sig))
                    }
                    "hyp_add" => {
                        Ok("(MOC.RewriteOp.hyp_add)".to_string())
                    }
                    "hyp_cancel" => {
                        Ok("(MOC.RewriteOp.hyp_cancel)".to_string())
                    }

                    _ => {
                        // Recurse for each element
                        let parts: Result<Vec<_>> = list.iter().map(to_lean).collect();
                        Ok(format!("[{}]", parts?.join(", ")))
                    }
                }
            } else {
                // First element is not a symbol, must be a list of operators
                let parts: Result<Vec<_>> = list.iter().map(to_lean).collect();
                Ok(format!("[{}]", parts?.join(", ")))
            }
        }
        _ => bail!("Unexpected value type: {:?}", val),
    }
}

fn main() -> Result<()> {
    let args = Cli::parse();
    
    let schema_json = std::fs::read_to_string(&args.schema_path)?;
    
    // 1. MANDATORY ENCLAVE GATE
    let witness = call_verifier(&schema_json, args.last_seq)?;
    eprintln!("Verifier Success. Witness: {}", witness);
    
    // Extract hash (format: WITNESS-{seq}-{md5}-{proof_hash})
    let parts: Vec<&str> = witness.split('-').collect();
    let proof_hash = parts.last().ok_or_else(|| anyhow!("Failed to extract proof hash"))?;
    
    // 2. Generate Proof Attestation
    let attestation_code = format!(
        "pub const PROOF_HASH: &str = \"{}\";\n",
        proof_hash
    );
    std::fs::write("rust/src/proof_attestation.rs", attestation_code)?;
    
    // 3. Parse and Translate
    let val = lexpr::from_str(&args.sexpr)?;
    let lean_ast = to_lean(&val)?;
    
    println!("{}", lean_ast);
    
    Ok(())
}

// LawfulRecursionVersion:1.0
