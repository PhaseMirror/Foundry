#![no_main]

use risc0_zkvm::guest::env;
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};

#[derive(Serialize, Deserialize, Clone)]
pub struct Restrictions {
    pub allowed_tiers: Vec<String>,
    pub requires_rollback_ceiling: bool,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct BudgetToken {
    pub token_id: String,
    pub issuer: String,
    pub budget_limit: u64,
    pub expiry: u64,
    pub provenance_hash: [u8; 32],
    pub restrictions: Restrictions,
    pub iat: u64,
    pub nonce: String,
}

#[derive(Serialize, Deserialize)]
pub struct ComplianceInput {
    pub token: BudgetToken,
    pub proposed_cost: u64,
    pub rollback_loaded: bool,
}

risc0_zkvm::guest::entry!(main);

pub fn main() {
    // Single read - robust for composition
    let input: ComplianceInput = env::read();

    // 1. Ceiling Check
    assert!(input.proposed_cost <= input.token.budget_limit,
            "BudgetExceeded: proposed_cost > tau_limit");

    // 2. Provenance Hash Verification
    let mut hasher = Sha256::new();
    hasher.update(format!("{}|{}|{}|ADR-033|{}", 
        input.token.token_id, 
        input.token.iat, 
        input.token.nonce, 
        input.token.issuer).as_bytes());
    let computed = hasher.finalize();
    assert_eq!(computed.as_slice(), &input.token.provenance_hash[..],
               "ProvenanceHashMismatch");

    // 3. Rollback Check
    if input.token.restrictions.requires_rollback_ceiling {
        assert!(input.rollback_loaded, "RollbackModuleMissing");
    }

    // Commit validated output (journal for receipt)
    env::commit(&input.token.provenance_hash);
}
