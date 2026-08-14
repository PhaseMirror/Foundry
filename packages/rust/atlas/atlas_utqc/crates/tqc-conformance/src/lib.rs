//! Conformance: the honesty meta-gate and the workspace-root helper that the BDD runner and
//! the audit test share.

#![forbid(unsafe_code)]

pub mod honesty;

pub use honesty::{audit, AuditReport};

/// The workspace root, relative to this crate's manifest.
#[must_use]
pub fn workspace_root() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}
