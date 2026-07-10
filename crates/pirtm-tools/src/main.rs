use rustyline::error::ReadlineError;
use rustyline::{DefaultEditor, Result};
use std::fs::OpenOptions;
use std::io::Write;
use chrono::Utc;
use sha2::{Sha256, Digest};
use pirtm_parser::ast::{Expr, Stmt};
use pirtm_tools::{eval_nf_program, calc_resonance};

fn append_to_ledger(input: &str, valid: bool, pweh: &str, nf_hash: &str, c: f64, rsc: f64) {
    if let Ok(mut file) = OpenOptions::new().create(true).append(true).open("repl_ledger.jsonl") {
        let _ = writeln!(
            file,
            "{{\"timestamp\":\"{}\",\"input\":\"{}\",\"valid\":{},\"pweh\":\"{}\",\"nf_hash\":\"{}\",\"c\":{:.4},\"rsc\":{:.4}}}",
            Utc::now().to_rfc3339(), input, valid, pweh, nf_hash, c, rsc
        );
    }
}

fn main() -> Result<()> {
    println!("PIRTM Interactive REPL");
    println!("Type 'exit' or press Ctrl-C to quit.\n");
    println!("Note: Operations are governed by the Sedona Spine.");

    let mut rl = DefaultEditor::new()?;
    let _ = rl.load_history("history.txt");

    // Null-calibrated tau_r
    let tau_r = 1.0;
    let eps = 1e-6;

    loop {
        let readline = rl.readline("pirtm> ");
        match readline {
            Ok(line) => {
                let line = line.trim();
                if line == "exit" || line == "quit" { break; }
                if line.is_empty() { continue; }
                let _ = rl.add_history_entry(line);

                // Parse the input using the governed parser FIRST
                match pirtm_parser::parse(line) {
                    Ok(ast) => {
                        // 1. EvalNF(w; Q, p) from core parser
                        let (c, r1, r2, r3) = eval_nf_program(&ast);
                        
                        // 2. Wire resonance Rsc
                        let rsc = calc_resonance(r1, r2, r3);
                        
                        // 3. PWEH Attestation Hash
                        let mut hasher = Sha256::new();
                        hasher.update(line.as_bytes());
                        let pweh = format!("{:x}", hasher.finalize());

                        // Full NF Hash
                        let mut nf_hasher = Sha256::new();
                        nf_hasher.update(format!("{:.4}{:.4}{:.4}{:.4}", c, r1, r2, r3).as_bytes());
                        let nf_hash = format!("{:x}", nf_hasher.finalize());

                        if c >= 1.0 - eps {
                            eprintln!("Phase Mirror Rejection: Contraction bound violated (c = {:.4} >= 1 - eps). PWEH: {}", c, pweh);
                            append_to_ledger(line, false, &pweh, &nf_hash, c, rsc);
                            continue;
                        }

                        if rsc < tau_r {
                            eprintln!("Phase Mirror Rejection: Resonance below threshold (Rsc = {:.4} < {}). PWEH: {}", rsc, tau_r, pweh);
                            append_to_ledger(line, false, &pweh, &nf_hash, c, rsc);
                            continue;
                        }

                        println!("[Phase Mirror] Check passed: c = {:.4} < 1 - ε, Rsc = {:.4} >= τ_R", c, rsc);
                        println!("PWEH Attestation: {}", pweh);
                        println!("NF Trace Hash: {}", nf_hash);
                        println!("AST: {:#?}", ast);
                        append_to_ledger(line, true, &pweh, &nf_hash, c, rsc);
                    }
                    Err(e) => {
                        eprintln!("Parse Error: {}", e);
                    }
                }
            },
            Err(ReadlineError::Interrupted) => break,
            Err(ReadlineError::Eof) => break,
            Err(err) => { println!("Error: {:?}", err); break; }
        }
    }
    
    let _ = rl.save_history("history.txt");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_eval_nf_lawful() {
        let ast = pirtm_parser::parse("Ap(2)").unwrap();
        let (c, _, _, _) = eval_nf_program(&ast);
        assert!(c < 1.0 - 1e-6);
    }

    #[test]
    fn test_eval_nf_unlawful() {
        let ast = pirtm_parser::parse("Ap(1)").unwrap();
        let (c, _, _, _) = eval_nf_program(&ast);
        assert!(c >= 1.0 - 1e-6);
    }
    
    #[test]
    fn test_resonance_distinct() {
        let ast1 = pirtm_parser::parse("Ap(2)").unwrap();
        let ast2 = pirtm_parser::parse("Ap(3)").unwrap();
        let (c1, r1a, r2a, r3a) = eval_nf_program(&ast1);
        let (c2, r1b, r2b, r3b) = eval_nf_program(&ast2);
        
        let rsc1 = calc_resonance(r1a, r2a, r3a);
        let rsc2 = calc_resonance(r1b, r2b, r3b);
        
        assert_ne!(rsc1, rsc2); // Distinct resonance
        assert_ne!(c1, c2); // Distinct contraction
    }
}
