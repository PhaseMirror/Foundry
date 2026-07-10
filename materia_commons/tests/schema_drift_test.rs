use multiplicity_common::constitution::{ConstitutionModel, ConstitutionViolation, CritiqueResult, PrimeGate, L0Invariant};
use multiplicity_common::identity::{
    ExternalIssuerConfig, IdentityOnboardingConfig, UniquenessAnchor, UniquenessAnchorInput,
    ValidatedIdToken, VerifiedVerifiableCredential,
};
use multiplicity_common::ledger::{LedgerHistoryEntry, ProposalEntry};
use multiplicity_common::replication::{ReplicationConfig, ReplicationRole};
use multiplicity_common::task::{Task, Workflow};
use multiplicity_common::types::{
    McpRegistry, McpServerDescriptor, ProposalRequest, SignedAdmissionToken, ToolResponse,
    TrustLevel, UnifiedWitness, VetoStatus, CompilationResult, SpoliationRiskLevel,
};
use schemars::schema_for;
use std::fs;
use std::path::PathBuf;

#[test]
fn test_schema_drift() {
    let mut schemas_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    schemas_dir.push("schemas");

    macro_rules! check_schema {
        ($type:ty, $name:expr) => {
            let schema = schema_for!($type);
            let expected_json = serde_json::to_string_pretty(&schema).unwrap();
            
            let file_path = schemas_dir.join(format!("{}.json", $name));
            let actual_json = fs::read_to_string(&file_path)
                .unwrap_or_else(|_| format!("Missing schema file for {}", $name));
            
            assert_eq!(
                expected_json, actual_json,
                "Schema drift detected for type '{}'. Please run `cargo run --bin export_schemas` to update.",
                $name
            );
        };
    }

    // types.rs
    check_schema!(ProposalRequest, "ProposalRequest");
    check_schema!(ToolResponse, "ToolResponse");
    check_schema!(UnifiedWitness, "UnifiedWitness");
    check_schema!(TrustLevel, "TrustLevel");
    check_schema!(McpServerDescriptor, "McpServerDescriptor");
    check_schema!(SignedAdmissionToken, "SignedAdmissionToken");
    check_schema!(McpRegistry, "McpRegistry");
    check_schema!(VetoStatus, "VetoStatus");
    check_schema!(CompilationResult, "CompilationResult");
    check_schema!(SpoliationRiskLevel, "SpoliationRiskLevel");

    // constitution.rs
    check_schema!(ConstitutionModel, "ConstitutionModel");
    check_schema!(ConstitutionViolation, "ConstitutionViolation");
    check_schema!(CritiqueResult, "CritiqueResult");
    check_schema!(PrimeGate, "PrimeGate");
    check_schema!(L0Invariant, "L0Invariant");

    // identity.rs
    check_schema!(ExternalIssuerConfig, "ExternalIssuerConfig");
    check_schema!(IdentityOnboardingConfig, "IdentityOnboardingConfig");
    check_schema!(UniquenessAnchorInput, "UniquenessAnchorInput");
    check_schema!(UniquenessAnchor, "UniquenessAnchor");
    check_schema!(ValidatedIdToken, "ValidatedIdToken");
    check_schema!(VerifiedVerifiableCredential, "VerifiedVerifiableCredential");

    // ledger.rs
    check_schema!(LedgerHistoryEntry, "LedgerHistoryEntry");
    check_schema!(ProposalEntry, "ProposalEntry");

    // replication.rs
    check_schema!(ReplicationConfig, "ReplicationConfig");
    check_schema!(ReplicationRole, "ReplicationRole");

    // task.rs
    check_schema!(Workflow, "Workflow");
    check_schema!(Task, "Task");
}
