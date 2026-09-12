/// A link to an external artifact related to an ADR.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ArtifactLink {
    pub name: String,
    pub url: String,
}
