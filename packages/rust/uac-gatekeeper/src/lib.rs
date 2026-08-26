//! `uac-gatekeeper` — Universal Access Control (UAC) to Axiom-Clean Lawful Proofs (ALP) Boundary Engine.
//!
//! Enforces:
//! - **INV-UAC-01**: Immediate fail-closed `L0_HALT` latch on active proof debt or uncertified levers.
//! - **INV-UAC-02**: Axiom leakage immunity — mutation authorization strictly requires an axiom-clean ALP witness.
//! - **INV-UAC-03**: Hardware safety interlock co-verification with latched fault state.
//! - **INV-UAC-04**: Reversible PETC signature preservation.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

/// Hardware / Software Interlock Status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum InterlockStatus {
    Normal,
    L0Halt,
}

/// Proof debt record associated with a permission token
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProofDebt {
    pub debt_count: usize,
    pub is_uncertified: bool,
    pub lever_id: Option<String>,
}

/// Permission Token presenting access claims across the boundary
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Token {
    pub token_id: u64,
    pub proof_debt: ProofDebt,
    pub expiry_timestamp: u64,
    pub signature: String,
}

/// Gatekeeper Operating State
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UACState {
    pub interlock: InterlockStatus,
    pub drift_warning: bool,
    pub rho_violation: bool,
}

impl Default for UACState {
    fn default() -> Self {
        Self {
            interlock: InterlockStatus::Normal,
            drift_warning: false,
            rho_violation: false,
        }
    }
}

/// ALP Certificate presenting formal mathematical verification proofs
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ALPCertificate {
    pub theorem_name: String,
    pub is_axiom_clean: bool,
    pub witness_hash: String,
}

/// Boundary Witness generated on lawful state mutation authorization
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BoundaryWitness {
    pub token_id: u64,
    pub theorem_name: String,
    pub is_authorized: bool,
    pub signature_hash: String,
}

/// Structured Diagnostic Log on Boundary Violation
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConflictLog {
    pub breach_kind: String,
    pub diagnostic_reason: String,
    pub token_id: u64,
    pub is_fail_closed: bool,
}

/// Authoritative Decision for Sedona Spine ingestion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum GovernanceDecision {
    Lawful {
        witness: BoundaryWitness,
    },
    FailClosedHalt {
        conflict: ConflictLog,
    },
}

// ---------------------------------------------------------------------------
// 1. Manifest Validator (alp_sorry_manifest.json Parser)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ManifestEntry {
    pub file: String,
    pub line: usize,
    pub deadline: Option<String>,
    pub governor: Option<String>,
    pub paired_witness: Option<String>,
}

#[derive(Debug, Clone, Default)]
pub struct ManifestValidator {
    pub debt_entries: HashMap<String, Vec<ManifestEntry>>,
}

impl ManifestValidator {
    pub fn new() -> Self {
        Self {
            debt_entries: HashMap::new(),
        }
    }

    pub fn from_json_str(json_str: &str) -> Result<Self, serde_json::Error> {
        let raw: HashMap<String, serde_json::Value> = serde_json::from_str(json_str)?;
        let mut debt_entries = HashMap::new();

        for (file_k, entries_v) in raw {
            if let Ok(entries) = serde_json::from_value::<Vec<ManifestEntry>>(entries_v) {
                debt_entries.insert(file_k, entries);
            }
        }

        Ok(Self { debt_entries })
    }

    pub fn has_proof_debt(&self, file_path: &str) -> bool {
        self.debt_entries
            .get(file_path)
            .map_or(false, |entries| !entries.is_empty())
    }
}

// ---------------------------------------------------------------------------
// 2. Hardware Safety Interlock Client
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Default)]
pub struct InterlockClient {
    pub fault_latched: bool,
}

impl InterlockClient {
    pub fn new() -> Self {
        Self { fault_latched: false }
    }

    pub fn step(&mut self, rho_violation: bool, drift_warning: bool) -> InterlockStatus {
        if rho_violation || drift_warning {
            self.fault_latched = true;
        }
        if self.fault_latched {
            InterlockStatus::L0Halt
        } else {
            InterlockStatus::Normal
        }
    }

    pub fn reset(&mut self) {
        self.fault_latched = false;
    }
}

// ---------------------------------------------------------------------------
// 3. UAC-ALP Boundary Gatekeeper
// ---------------------------------------------------------------------------

pub struct UacAlpGatekeeper {
    pub interlock_client: InterlockClient,
    pub manifest_validator: ManifestValidator,
}

impl UacAlpGatekeeper {
    pub fn new(manifest_validator: ManifestValidator) -> Self {
        Self {
            interlock_client: InterlockClient::new(),
            manifest_validator,
        }
    }

    pub fn evaluate_authorization(
        &mut self,
        st: &UACState,
        tok: &Token,
        cert: &ALPCertificate,
    ) -> GovernanceDecision {
        // Step hardware interlock
        let interlock_res = self.interlock_client.step(st.rho_violation, st.drift_warning);
        if interlock_res == InterlockStatus::L0Halt || st.interlock == InterlockStatus::L0Halt {
            return GovernanceDecision::FailClosedHalt {
                conflict: ConflictLog {
                    breach_kind: "HARDWARE_INTERLOCK_LATCH".to_string(),
                    diagnostic_reason: "L0_HALT asserted via rho violation or drift warning".to_string(),
                    token_id: tok.token_id,
                    is_fail_closed: true,
                },
            };
        }

        // INV-UAC-01: Reject on proof debt or uncertified lever
        if tok.proof_debt.debt_count > 0 || tok.proof_debt.is_uncertified {
            self.interlock_client.fault_latched = true;
            return GovernanceDecision::FailClosedHalt {
                conflict: ConflictLog {
                    breach_kind: "PROOF_DEBT_GATE_BREACH".to_string(),
                    diagnostic_reason: format!(
                        "Token {} references unverified proof debt (debt_count={}, is_uncertified={})",
                        tok.token_id, tok.proof_debt.debt_count, tok.proof_debt.is_uncertified
                    ),
                    token_id: tok.token_id,
                    is_fail_closed: true,
                },
            };
        }

        // INV-UAC-02: Reject on non-axiom-clean certificate
        if !cert.is_axiom_clean {
            self.interlock_client.fault_latched = true;
            return GovernanceDecision::FailClosedHalt {
                conflict: ConflictLog {
                    breach_kind: "AXIOM_CLEANNESS_VIOLATION".to_string(),
                    diagnostic_reason: format!(
                        "ALP certificate for '{}' is not axiom-clean",
                        cert.theorem_name
                    ),
                    token_id: tok.token_id,
                    is_fail_closed: true,
                },
            };
        }

        // Lawful authorization witness generation
        let mut hasher = Sha256::new();
        hasher.update(format!("token={}|cert={}|hash={}", tok.token_id, cert.theorem_name, cert.witness_hash).as_bytes());
        let sig = hex::encode(hasher.finalize());

        GovernanceDecision::Lawful {
            witness: BoundaryWitness {
                token_id: tok.token_id,
                theorem_name: cert.theorem_name.clone(),
                is_authorized: true,
                signature_hash: sig,
            },
        }
    }
}

// ---------------------------------------------------------------------------
// 4. Reversible PETC Encoding (INV-UAC-04)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrimeToken {
    pub grapheme_code: u64,
    pub prime_modulus: u64,
}

pub fn decompose_graphemes(codes: &[u64]) -> Vec<PrimeToken> {
    codes
        .iter()
        .map(|&c| PrimeToken {
            grapheme_code: c,
            prime_modulus: c * 2 + 3,
        })
        .collect()
}

pub fn reassemble_tokens(tokens: &[PrimeToken]) -> Vec<u64> {
    tokens.iter().map(|t| t.grapheme_code).collect()
}
