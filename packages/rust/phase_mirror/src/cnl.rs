// src/cnl.rs
use crate::tools::Tool;

/// Very small CNL parser that maps known command strings to `Tool` variants.
/// Returns `None` when the command is not recognized.
pub fn parse_cnl(input: &str) -> Option<Tool> {
    match input.trim() {
        "apply_drmm" => Some(Tool::ApplyDRMMOperator),
        "verify_drmm" => Some(Tool::VerifyDRMMProof),
        // Add more mappings as needed.
        _ => None,
    }
}
