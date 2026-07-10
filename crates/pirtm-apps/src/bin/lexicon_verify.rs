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
            println!("[VALID]   \"{}\" (c: {:.4}, Rsc: {:.4})", sentence, c, rsc);
        }
        Err(e) => {
            // We only print failures if we are scanning for them, to avoid spam
            // For the audit report, let's flag specific types of failures
            if sentence.contains("all") && !e.contains("PrimeOneForbidden") {
                 println!("[HOLE?]   \"{}\" should be forbidden but failed for wrong reason: {}", sentence, e);
            } else if !sentence.contains("all") && e.contains("ContractionBound") {
                 println!("[REJECTED] \"{}\" -> {}", sentence, e);
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
        Token { word: "deploy", prime: 2 },
        Token { word: "scale", prime: 3 },
        Token { word: "destroy", prime: 17 }, // Destructive action, high prime to test bounds
        Token { word: "web-service", prime: 5 },
        Token { word: "database", prime: 7 },
        Token { word: "replicas", prime: 11 },
        Token { word: "all", prime: 1 }, // Universally expansive, strictly forbidden
    ];

    println!("--- CNL Lexicon Static Analyzer ---");
    println!("Vocabulary size: {}", lexicon.len());
    println!("Generating permutations up to length 3...\n");

    let mut current = Vec::new();
    generate_permutations(&lexicon, &mut current, 3);
    
    println!("\nAnalysis Complete.");
}
