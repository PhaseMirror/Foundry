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

fn main() {
    let mut schemas_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    schemas_dir.push("schemas");

    if !schemas_dir.exists() {
        fs::create_dir_all(&schemas_dir).expect("Failed to create schemas directory");
    }

    macro_rules! export_schema {
        ($type:ty, $name:expr) => {
            let schema = schema_for!($type);
            let schema_json =
                serde_json::to_string_pretty(&schema).expect("Failed to serialize schema");
            let file_path = schemas_dir.join(format!("{}.json", $name));
            fs::write(&file_path, schema_json).unwrap_or_else(|_| {
                panic!("Failed to write schema for {}", $name);
            });
            println!("Exported {}.json", $name);
        };
    }

    // types.rs
    export_schema!(ProposalRequest, "ProposalRequest");
    export_schema!(ToolResponse, "ToolResponse");
    export_schema!(UnifiedWitness, "UnifiedWitness");
    export_schema!(TrustLevel, "TrustLevel");
    export_schema!(McpServerDescriptor, "McpServerDescriptor");
    export_schema!(SignedAdmissionToken, "SignedAdmissionToken");
    export_schema!(McpRegistry, "McpRegistry");
    export_schema!(VetoStatus, "VetoStatus");
    export_schema!(CompilationResult, "CompilationResult");
    export_schema!(SpoliationRiskLevel, "SpoliationRiskLevel");

    // constitution.rs
    export_schema!(ConstitutionModel, "ConstitutionModel");
    export_schema!(ConstitutionViolation, "ConstitutionViolation");
    export_schema!(CritiqueResult, "CritiqueResult");
    export_schema!(PrimeGate, "PrimeGate");
    export_schema!(L0Invariant, "L0Invariant");

    // identity.rs
    export_schema!(ExternalIssuerConfig, "ExternalIssuerConfig");
    export_schema!(IdentityOnboardingConfig, "IdentityOnboardingConfig");
    export_schema!(UniquenessAnchorInput, "UniquenessAnchorInput");
    export_schema!(UniquenessAnchor, "UniquenessAnchor");
    export_schema!(ValidatedIdToken, "ValidatedIdToken");
    export_schema!(VerifiedVerifiableCredential, "VerifiedVerifiableCredential");

    // ledger.rs
    export_schema!(LedgerHistoryEntry, "LedgerHistoryEntry");
    export_schema!(ProposalEntry, "ProposalEntry");

    // replication.rs
    export_schema!(ReplicationConfig, "ReplicationConfig");
    export_schema!(ReplicationRole, "ReplicationRole");

    // task.rs
    export_schema!(Workflow, "Workflow");
    export_schema!(Task, "Task");

    println!("All schemas exported successfully to {:?}", schemas_dir);
}
