use risc0_zkvm::{Executor, ExecutorEnv, Receipt};
use anyhow::Result;
use serde::{Deserialize, Serialize};

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

// Guest ELF binary. In production, this is built by `cargo risczero build` from the
// guest crate and embedded at compile time. The placeholder below is a compile-time
// sentinel that will cause a runtime error if the real ELF is not provided.
//
// To build the real guest:
//   cd governance-circuits/guest && cargo risczero build
// Then uncomment the include_bytes! line and remove the placeholder.
//
// const GUEST_ELF: &[u8] = include_bytes!("../guest/target/riscv32im-risc0-zkvm-elf/docker/release/guest");

/// Sentinel indicating the guest ELF has not been built.
/// Any call to `prove_compliance` will fail until the real ELF is provided.
const GUEST_ELF_PLACEHOLDER: &[u8] = b"PLACEHOLDER_GUEST_ELF_NOT_BUILT";

/// Returns the guest ELF binary, or an error if it has not been built yet.
fn load_guest_elf() -> Result<&'static [u8]> {
    // In production, this would be:
    //   Ok(GUEST_ELF)
    // For now, detect the placeholder and fail hard.
    if GUEST_ELF_PLACEHOLDER == b"PLACEHOLDER_GUEST_ELF_NOT_BUILT" {
        anyhow::bail!(
            "Governance circuit guest ELF has not been built. \
             Run `cd governance-circuits/guest && cargo risczero build` \
             and recompile. See the comment above this function for instructions."
        );
    }
    Ok(GUEST_ELF_PLACEHOLDER)
}

pub fn prove_compliance(input: ComplianceInput, rollback_receipt: Option<Receipt>) -> Result<Receipt> {
    let elf = load_guest_elf()?;

    let mut env_builder = ExecutorEnv::builder().write(&input)?;

    if let Some(r) = rollback_receipt {
        env_builder.add_assumption(r.claim())?;  // Composition
    }

    let env = env_builder.build()?;
    let mut exec = Executor::from_elf(env, elf)?;
    let session = exec.run()?;
    let receipt = session.prove()?;
    Ok(receipt)
}
