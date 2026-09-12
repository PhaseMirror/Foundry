/// ADR status enumeration.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ADRStatus {
    Proposed,
    Accepted,
    Deprecated,
    Superseded,
}

impl Default for ADRStatus {
    fn default() -> Self { ADRStatus::Proposed }
}
