use pirtm_stdlib::prelude::*;
use pirtm_invariants::PhaseMirrorInvariants;

#[derive(Clone)]
struct Token {
    word: &'static str,
    prime: u64,
}

fn evaluate_sequence(seq: &[Token]) {
    if seq.is_empty() { return; }
    
    let mut ast = Ap(seq[0].prime);
    for token in &seq[1..] {
        ast = ast + Ap(token.prime);
    }
    
    let env = MOCWord::StratumBoundary(Box::new(ast));
    let sentence = seq.iter().map(|t| t.word).collect::<Vec<_>>().join(" ");

    match PhaseMirrorInvariants::enforce_all(&env) {
        Ok(_) => {
            let (c, r1, r2, r3) = EvalNF::evaluate(&env);
            let rsc = Resonance::calculate(r1, r2, r3);
            println!("[SAFE ] \"{}\" (c: {:.4}, Rsc: {:.4})", sentence, c, rsc);
        }
        Err(e) => {
            if sentence.contains("all") {
                println!("[BLOCKED - QUANTIFIER] \"{}\" -> {}", sentence, e);
            } else if e.contains("ContractionBound") {
                println!("[BLOCKED - EXCESSIVE TENSION] \"{}\" -> {}", sentence, e);
            }
        }
    }
}

fn generate_permutations(lexicon: &[Token], current: &mut Vec<Token>, max_depth: usize) {
    if current.len() > 0 && current.len() <= max_depth {
        evaluate_sequence(current);
    }
    if current.len() == max_depth {
        return;
    }

    for token in lexicon {
        current.push(token.clone());
        generate_permutations(lexicon, current, max_depth);
        current.pop();
    }
}

fn main() {
    let lexicon = vec![
        Token { word: "retain", prime: 2 },
        Token { word: "hold", prime: 3 },
        Token { word: "delete", prime: 17 }, // Destructive action, high tension
        Token { word: "clause", prime: 5 },
        Token { word: "contract", prime: 7 },
        Token { word: "immediately", prime: 13 },
        Token { word: "all", prime: 1 }, // Universally expansive, strictly forbidden
    ];

    println!("--- Phase Mirror: Legal Domain Lexicon Verification ---");
    println!("Vocabulary size: {}", lexicon.len());
    println!("Evaluating sentences up to 3 tokens for safe legal execution...\n");

    let mut current = Vec::new();
    generate_permutations(&lexicon, &mut current, 3);
    
    println!("\nAnalysis Complete.");
}
