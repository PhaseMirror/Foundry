use ed25519_dalek::{Signature, Signer, Verifier, SigningKey, VerifyingKey};
use rand::rngs::OsRng;
use pirtm_stdlib::prelude::*;
use pirtm_invariants::PhaseMirrorInvariants;
use serde::{Serialize, Deserialize};

#[derive(Serialize)]
struct UnifiedWitness {
    moc_word_ast: String,
    action: String,
    c_bound: f64,
    rsc: f64,
    signatures: Vec<Vec<u8>>,
    public_keys: Vec<Vec<u8>>,
}

struct MultiPartyLedger {
    parties: Vec<SigningKey>,
}

impl MultiPartyLedger {
    fn new(num_parties: usize) -> Self {
        let mut csprng = OsRng {};
        let parties = (0..num_parties)
            .map(|_| SigningKey::generate(&mut csprng))
            .collect();
        Self { parties }
    }

    fn simulate_consensus(&self, word: &MOCWord, action: &str, required_signatures: usize) -> Result<UnifiedWitness, String> {
        // Step 1: Geometric Validation (The Constitutional Check)
        if let Err(e) = PhaseMirrorInvariants::enforce_all(word) {
            return Err(format!("Consensus Rejected (Invariant Violation): {}", e));
        }

        let (c, r1, r2, r3) = EvalNF::evaluate(word);
        let rsc = Resonance::calculate(r1, r2, r3);

        println!("[KERNEL] MOCWord bounds validated: c = {:.4}, Rsc = {:.4}", c, rsc);

        // Step 2: Payload Serialization for Signing
        let payload = format!("{:?}::{}::{}::{}", word, action, c, rsc);
        let message = payload.as_bytes();

        let mut signatures = Vec::new();
        let mut public_keys = Vec::new();

        // Step 3: Multi-Party Signing
        for (i, key) in self.parties.iter().enumerate().take(required_signatures) {
            let signature = key.sign(message);
            signatures.push(signature.to_bytes().to_vec());
            public_keys.push(key.verifying_key().to_bytes().to_vec());
            println!("[PARTY {}] Cryptographically signed the action payload.", i);
        }

        // Return the fully formed UnifiedWitness
        Ok(UnifiedWitness {
            moc_word_ast: format!("{:?}", word),
            action: action.to_string(),
            c_bound: c,
            rsc,
            signatures,
            public_keys,
        })
    }
}

fn verify_witness(witness: &UnifiedWitness, message_payload: &[u8], threshold: usize) -> Result<(), String> {
    if witness.signatures.len() < threshold {
        return Err(format!("Insufficient signatures: {}/{}", witness.signatures.len(), threshold));
    }

    for (i, (sig_bytes, pk_bytes)) in witness.signatures.iter().zip(witness.public_keys.iter()).enumerate() {
        let mut pk_arr = [0u8; 32];
        pk_arr.copy_from_slice(pk_bytes);
        let pk = VerifyingKey::from_bytes(&pk_arr).map_err(|_| "Invalid public key".to_string())?;
        
        let mut sig_arr = [0u8; 64];
        sig_arr.copy_from_slice(sig_bytes);
        let sig = Signature::from_bytes(&sig_arr);
        
        if let Err(_) = pk.verify(message_payload, &sig) {
            return Err(format!("Signature validation failed for party {}", i));
        }
    }
    
    Ok(())
}

fn main() {
    println!("--- Phase Mirror: Multi-Party Consensus & Cryptographic Ledger ---");
    let ledger = MultiPartyLedger::new(5); // 5 governors

    // Scenario 1: A geometrically safe action
    let safe_word = MOCWord::StratumBoundary(Box::new(Ap(2) + Ap(5) + Ap(7)));
    let action = "DEPLOY web-service ON cluster";
    
    println!("\n[SCENARIO 1] Proposing: {}", action);
    match ledger.simulate_consensus(&safe_word, action, 3) { // Requires 3 signatures
        Ok(witness) => {
            println!("[LEDGER] Consensus achieved. Generating UnifiedWitness...");
            
            // Verify
            let payload = format!("{}::{}::{}::{}", witness.moc_word_ast, witness.action, witness.c_bound, witness.rsc);
            match verify_witness(&witness, payload.as_bytes(), 3) {
                Ok(_) => {
                    let json = serde_json::to_string_pretty(&witness).unwrap();
                    println!("[VERIFIED] UnifiedWitness committed to immutable ledger:\n{}", json);
                },
                Err(e) => println!("[VERIFICATION ERROR] {}", e),
            }
        },
        Err(e) => println!("[ERROR] {}", e),
    }

    // Scenario 2: A geometrically unsafe action (contains forbidden token)
    let unsafe_word = MOCWord::StratumBoundary(Box::new(Ap(2) + Ap(1) + Ap(7))); // Ap(1) is highly expansive
    let bad_action = "DEPLOY all ON cluster";

    println!("\n[SCENARIO 2] Proposing: {}", bad_action);
    match ledger.simulate_consensus(&unsafe_word, bad_action, 3) {
        Ok(_) => println!("This should not happen!"),
        Err(e) => println!("[LEDGER DENIED] Action never reached consensus phase.\nReason: {}", e),
    }
}
