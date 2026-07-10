use schemars::schema_for;
use std::fs;
use std::path::Path;
use multiplicity_common::types::{ProposalRequest, ToolResponse, UnifiedWitness, McpRegistry, SignedAdmissionToken};
use multiplicity_common::constitution::ConstitutionModel;
use multiplicity_common::replication::ReplicationConfig;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let out_dir = Path::new("packages/infra-config");
    fs::create_dir_all(out_dir)?;

    let schemas = [
        ("ProposalRequest", schema_for!(ProposalRequest)),
        ("ToolResponse", schema_for!(ToolResponse)),
        ("UnifiedWitness", schema_for!(UnifiedWitness)),
        ("ConstitutionModel", schema_for!(ConstitutionModel)),
        ("McpRegistry", schema_for!(McpRegistry)),
        ("SignedAdmissionToken", schema_for!(SignedAdmissionToken)),
        ("ReplicationConfig", schema_for!(ReplicationConfig)),
    ];

    for (name, schema) in schemas {
        let path = out_dir.join(format!("{}.schema.json", name));
        let json = serde_json::to_string_pretty(&schema)?;
        fs::write(&path, json)?;
        println!("Exported schema {} to {:?}", name, path);
    }

    Ok(())
}
