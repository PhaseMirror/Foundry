//! Typed shape of model/*.toml registers for PrismPM.

use crate::ModelError;
use serde::{Deserialize, Serialize};

/// Honesty levels for claims.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Level {
    /// Fact reproduced from an authority.
    SomeTrue,
    /// Constructed and validated against its oracle.
    Build,
    /// Measured and reported, never asserted.
    Open,
}

impl Level {
    /// String token representation.
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::SomeTrue => "some-true",
            Self::Build => "build",
            Self::Open => "open",
        }
    }
}

/// model/ledger.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Ledger {
    /// Schema spec identifier.
    pub spec: String,
    /// List of claims.
    pub claim: Vec<Claim>,
}

/// Single claim in the ledger.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Claim {
    /// Claim ID.
    pub id: String,
    /// Honesty level.
    pub level: Level,
    /// Statement of claim.
    pub statement: String,
    /// Scenario feature file for build claims.
    #[serde(default)]
    pub feature: Option<String>,
    /// Authority cited for some-true claims.
    #[serde(default)]
    pub authority: Option<String>,
    /// Sample size for statistics.
    #[serde(default)]
    pub sample_size: Option<u64>,
    /// Seed for random generators.
    #[serde(default)]
    pub seed: Option<u64>,
}

impl Ledger {
    /// Validate structural invariants of the ledger.
    pub fn check(&self) -> Result<(), ModelError> {
        for c in &self.claim {
            match c.level {
                Level::SomeTrue => {
                    if c.authority.is_none() {
                        return Err(ModelError::Inconsistent(format!(
                            "{}: some-true claim must name an authority",
                            c.id
                        )));
                    }
                }
                Level::Build => {
                    if c.authority.is_some() {
                        return Err(ModelError::Inconsistent(format!(
                            "{}: build claim cannot cite an authority",
                            c.id
                        )));
                    }
                }
                Level::Open => {}
            }
        }
        Ok(())
    }
}

/// model/ids.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Ids {
    /// Schema spec identifier.
    pub spec: String,
    /// List of capability IDs.
    pub id: Vec<IdRow>,
}

/// Single capability row.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct IdRow {
    /// Capability ID.
    pub id: String,
    /// Gherkin suite name.
    pub suite: String,
    /// Honesty level.
    pub level: Level,
    /// Capability statement.
    pub statement: String,
}

impl Ids {
    /// Find row by ID.
    pub fn get(&self, id: &str) -> Option<&IdRow> {
        self.id.iter().find(|r| r.id == id)
    }
}

/// model/authorities.toml
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Authorities {
    /// Schema spec identifier.
    pub spec: String,
    /// List of authorities.
    pub authority: Vec<AuthorityRow>,
    /// Executable validation oracles, distinct from standards authorities.
    #[serde(default)]
    pub oracle: Vec<OracleRow>,
}

/// Single authority entry.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct AuthorityRow {
    /// Authority ID.
    pub id: String,
    /// Display name.
    pub name: String,
    /// Organization or upstream project that owns the cited material.
    pub issuer: String,
    /// Canonical standard or source identifier.
    pub canonical_identifier: String,
    /// Exact edition or version.
    pub edition: String,
    /// Role of the acquired source (`normative`, `informative`, or `binding-only`).
    pub source_role: String,
    /// Immutable acquired-byte URL, or the lawful catalog citation for a binding-only row.
    pub immutable_url: String,
    /// Exact source commit, or `not-published` for a binding-only row.
    pub revision: String,
    /// SHA-256 of acquired bytes, or `not-acquired` for a binding-only row.
    pub acquired_sha256: String,
    /// Published signature identity, or an explicit `not-published` value.
    pub signature: String,
    /// Exact upstream-published public key used to replay a claimed tag signature.
    #[serde(default)]
    pub signature_trust_root: Option<SignatureTrustRoot>,
    /// Media type of the acquired source.
    pub media_type: String,
    /// Applicable source license or controlled-document terms.
    pub license: String,
    /// Redistribution decision.
    pub redistribution: String,
    /// Acquisition date; evidence metadata, never a content identity input.
    pub retrieval_date: String,
    /// Explicit supersession policy.
    pub supersession_policy: String,
    /// Authoritative statement.
    pub statement: String,
    /// Realized capability IDs.
    pub realized_by: Vec<String>,
}

/// An upstream-maintained public key selected for independent offline tag verification.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct SignatureTrustRoot {
    /// Signature format accepted by the pinned verifier (`openpgp` or `ssh`).
    pub algorithm: String,
    /// Repository-relative path of the exact packaged public-key bytes.
    pub path: String,
    /// SHA-256 of the packaged public-key bytes.
    pub sha256: String,
    /// Full OpenPGP or SHA-256 SSH fingerprint expected from verification.
    pub fingerprint: String,
    /// Upstream account that publishes the key.
    pub owner: String,
    /// Authoritative upstream key-list endpoint from which the selected record was acquired.
    pub source_url: String,
    /// Stable key-record identifier returned by that endpoint.
    pub source_record_id: String,
    /// Legal classification of the public-key material.
    pub license: String,
    /// Explicit redistribution decision for the verification key.
    pub redistribution: String,
}

/// One validation oracle whose authority and execution boundary are explicit.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct OracleRow {
    /// Stable oracle identifier.
    pub id: String,
    /// Authority rows whose assets define this oracle's scope.
    pub authority_ids: Vec<String>,
    /// Exact upstream edition implemented by the oracle.
    pub edition: String,
    /// SDK-inventory executable name, never a shell command.
    pub executable: String,
    /// Exact OCI platforms on which the oracle is packaged and supported.
    pub supported_platforms: Vec<String>,
    /// Input media types accepted by the runner.
    pub input_media_types: Vec<String>,
    /// Output contract identifier.
    pub output_schema: String,
    /// Canonical argument vector with `{input}` as the only substitution.
    pub arguments: Vec<String>,
    /// Maximum wall-clock duration.
    pub timeout_ms: u64,
    /// Maximum resident memory.
    pub memory_bytes: u64,
    /// Maximum captured stdout plus stderr.
    pub output_bytes: u64,
    /// Network policy. `isolated-subject` permits only the disposable subject
    /// service created by the conformance runner, never public networking.
    pub network: String,
    /// Deterministic diagnostic normalization profile.
    pub normalization: String,
    /// Exact requirements the upstream payload can establish.
    pub covers: Vec<String>,
    /// Requirements explicitly outside the oracle's authority.
    pub does_not_cover: Vec<String>,
    /// Accepted upstream process exits and their mapping.
    pub expected_exits: Vec<String>,
    /// Untouched upstream payload digest.
    pub upstream_payload_sha256: String,
    /// Exact imported finite corpus or upstream oracle source tree, when one
    /// is executed by this profile.
    #[serde(default)]
    pub corpus: Option<OracleCorpus>,
    /// Optional immutable implementation subjected to an interoperability
    /// suite; this is evidence input, not a normative authority.
    #[serde(default)]
    pub subject: Option<String>,
    /// Optional pinned trust material consumed by the executable verifier.
    #[serde(default)]
    pub trusted_root: Option<OracleTrustRoot>,
    /// Wrapper implementation source whose digest is resolved into the lock.
    pub wrapper_source: String,
}

/// Content-addressed repository copy of an upstream conformance asset.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct OracleCorpus {
    /// Repository-relative directory containing only the reviewed bytes.
    pub path: String,
    /// SHA-256 tree digest over length-prefixed sorted paths and file bytes.
    pub sha256: String,
}

/// One content-addressed verification root used by an oracle.
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct OracleTrustRoot {
    /// Repository-relative path packaged by the SDK.
    pub path: String,
    /// Exact SHA-256 of the trust-root bytes.
    pub sha256: String,
    /// Narrow semantic role; this material is not itself a standards authority.
    pub role: String,
}

/// model/errors.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Errors {
    /// Schema spec identifier.
    pub spec: String,
    /// List of error entries.
    pub error: Vec<ErrorRow>,
}

/// Single error entry.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ErrorRow {
    /// Error code (e.g. PP1001).
    pub code: String,
    /// Error title.
    pub title: String,
    /// Error class.
    pub class: String,
    /// Process exit code.
    pub exit: i32,
    /// Explanatory statement.
    pub statement: String,
}

impl Errors {
    /// Validate error codes and uniqueness.
    pub fn check(&self) -> Result<(), ModelError> {
        let mut seen = Vec::new();
        for e in &self.error {
            if seen.contains(&e.code.as_str()) {
                return Err(ModelError::Inconsistent(format!(
                    "{}: duplicate error code",
                    e.code
                )));
            }
            seen.push(&e.code);
            if !e.code.starts_with("PP") || e.code.len() != 6 {
                return Err(ModelError::Inconsistent(format!(
                    "{}: invalid error code shape",
                    e.code
                )));
            }
        }
        Ok(())
    }
}

/// model/standards.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Standards {
    /// Schema spec identifier.
    pub spec: String,
    /// List of standard entries.
    pub standard: Vec<StandardRow>,
}

/// Single standard row.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct StandardRow {
    /// Standard identifier.
    pub id: String,
    /// Full standard name.
    pub name: String,
    /// Standard edition.
    pub edition: String,
    /// Exact public catalog reference.
    pub reference: String,
    /// Evidence basis (`public-catalog` or `authorized-clause-review`).
    pub basis: String,
    /// Modeled scope.
    pub scope: String,
    /// Provenance citation.
    pub provenance: String,
    /// Interpretation.
    pub interpretation: String,
    /// Responsible facet package.
    pub facet_package: String,
    /// Exact facet entry IDs implementing this interpretation.
    pub facet_entries: Vec<String>,
    /// Coverage state.
    pub coverage_state: String,
    /// Included in release scope.
    pub release_scope: bool,
}

impl Standards {
    /// Validate standards list invariants.
    pub fn check(&self) -> Result<(), ModelError> {
        for s in &self.standard {
            if s.edition.trim().is_empty() {
                return Err(ModelError::Inconsistent(format!(
                    "{}: missing edition",
                    s.id
                )));
            }
            if s.provenance.trim().is_empty() {
                return Err(ModelError::Inconsistent(format!(
                    "{}: missing provenance",
                    s.id
                )));
            }
            if !matches!(
                s.basis.as_str(),
                "public-catalog" | "authorized-clause-review"
            ) {
                return Err(ModelError::Inconsistent(format!(
                    "{}: unsupported standards evidence basis",
                    s.id
                )));
            }
            if !s.reference.starts_with("https://www.iso.org/standard/") {
                return Err(ModelError::Inconsistent(format!(
                    "{}: reference is not an exact ISO catalog URL",
                    s.id
                )));
            }
            if s.basis == "public-catalog"
                && (s.scope.to_ascii_lowercase().contains("clause")
                    || s.interpretation
                        .to_ascii_lowercase()
                        .contains("conforms to"))
            {
                return Err(ModelError::Inconsistent(format!(
                    "{}: catalog metadata cannot support clause-level conformance",
                    s.id
                )));
            }
            let claim_text = format!("{} {}", s.scope, s.interpretation).to_ascii_lowercase();
            if claim_text.contains("iso certified") || claim_text.contains("iso certification") {
                return Err(ModelError::Inconsistent(format!(
                    "{}: unsupported certification claim",
                    s.id
                )));
            }
            if !matches!(s.coverage_state.as_str(), "implemented" | "known") {
                return Err(ModelError::Inconsistent(format!(
                    "{}: unsupported coverage state",
                    s.id
                )));
            }
            if s.release_scope && s.coverage_state != "implemented" {
                return Err(ModelError::Inconsistent(format!(
                    "{}: release-scope row is not implemented",
                    s.id
                )));
            }
        }
        Ok(())
    }
}

/// model/contracts.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Contracts {
    /// Schema spec identifier.
    pub spec: String,
    /// Public canonical data contracts.
    pub contract: Vec<ContractRow>,
}

/// One public canonical data contract.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ContractRow {
    /// Value of the contract's required `schema` member.
    pub schema: String,
    /// Repository-relative JSON Schema path.
    pub path: String,
    /// Registered content media type.
    pub media_type: String,
    /// Content identity algorithm.
    pub identity: String,
    /// Maximum canonical input size.
    pub maximum_bytes: u64,
    /// Maximum aggregate collection item count.
    pub maximum_items: u64,
    /// Unknown-field and extension policy.
    pub extension_policy: String,
    /// Version compatibility policy.
    pub compatibility: String,
}

impl Contracts {
    /// Validate public contract registry invariants.
    pub fn check(&self, root: &std::path::Path) -> Result<(), ModelError> {
        if self.spec != "prismpm/contracts/1" || self.contract.len() != 40 {
            return Err(ModelError::Inconsistent(
                "public contract registry is incomplete".to_owned(),
            ));
        }
        let mut schemas = std::collections::BTreeSet::new();
        let mut paths = std::collections::BTreeSet::new();
        let mut media_types = std::collections::BTreeSet::new();
        for row in &self.contract {
            if !schemas.insert(&row.schema)
                || !paths.insert(&row.path)
                || !media_types.insert(&row.media_type)
                || !(row.schema.starts_with("prismpm/") || row.schema.starts_with("uor/"))
                || !(row.schema.ends_with("/1") || row.schema == "prismpm/ecosystem-release/2")
                || !row.path.starts_with("schemas/")
                || !row.path.ends_with(".schema.json")
                || !root.join(&row.path).is_file()
                || !(row.media_type.starts_with("application/vnd.prismpm.")
                    || row.media_type.starts_with("application/vnd.uor."))
                || !row.media_type.ends_with("+json")
                || row.identity != "sha256-canonical-json"
                || row.maximum_bytes == 0
                || row.maximum_items == 0
                || row.extension_policy != "closed"
                || !matches!(
                    row.compatibility.as_str(),
                    "exact-major" | "exact-major-additive-minor"
                )
            {
                return Err(ModelError::Inconsistent(format!(
                    "{}: invalid public contract row",
                    row.schema
                )));
            }
            let bytes = std::fs::read(root.join(&row.path))
                .map_err(|error| ModelError::Io(root.join(&row.path), error))?;
            let value: serde_json::Value = serde_json::from_slice(&bytes).map_err(|error| {
                ModelError::Inconsistent(format!("{}: invalid JSON Schema: {error}", row.path))
            })?;
            if value.get("additionalProperties") != Some(&serde_json::Value::Bool(false))
                || value.get("$schema").and_then(serde_json::Value::as_str)
                    != Some("https://json-schema.org/draft/2020-12/schema")
            {
                return Err(ModelError::Inconsistent(format!(
                    "{}: schema root is not closed draft 2020-12",
                    row.path
                )));
            }
            jsonschema::validator_for(&value).map_err(|error| {
                ModelError::Inconsistent(format!(
                    "{}: JSON Schema does not compile without external resolution: {error}",
                    row.path
                ))
            })?;
        }
        Ok(())
    }
}

/// model/commands.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Commands {
    /// Schema spec identifier.
    pub spec: String,
    /// Stable public command contracts.
    pub command: Vec<CommandRow>,
}

/// One stable public command contract.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CommandRow {
    /// Canonical command name.
    pub name: String,
    /// Declared mutation boundary.
    pub mutates: String,
    /// Whether artifact selection requires an immutable digest.
    pub requires_digest: bool,
    /// Canonical machine result schema.
    pub result_schema: String,
}

impl Commands {
    /// Validate the complete stable command surface.
    pub fn check(&self) -> Result<(), ModelError> {
        const EXPECTED: [&str; 28] = [
            "backup",
            "authority",
            "build",
            "check",
            "clean",
            "completion",
            "conformance",
            "deploy",
            "destroy",
            "fetch",
            "finalize-contract",
            "inspect",
            "lock",
            "plan",
            "prepare-promotion",
            "promote",
            "pull",
            "push",
            "rollback",
            "restore",
            "run",
            "sign",
            "sign-evidence",
            "status",
            "template",
            "verify",
            "verify-release",
            "verify-signature",
        ];
        let names = self
            .command
            .iter()
            .map(|row| row.name.as_str())
            .collect::<Vec<_>>();
        if self.spec != "prismpm/command-contract/1"
            || names != EXPECTED
            || self.command.iter().any(|row| {
                row.mutates.is_empty()
                    || !row.result_schema.starts_with("prismpm/")
                    || !row.result_schema.ends_with("/1")
            })
        {
            return Err(ModelError::Inconsistent(
                "public command contract is incomplete or noncanonical".to_owned(),
            ));
        }
        Ok(())
    }
}

/// model/emitter-inputs.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct EmitterInputs {
    /// Schema spec identifier.
    pub spec: String,
    /// Canonical framed tree digest of the exact input list.
    pub digest: String,
    /// List of input file paths.
    pub inputs: Vec<String>,
}

/// model/execution-corpus.toml
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ExecutionCorpus {
    /// Schema spec identifier.
    pub spec: String,
    /// Fixed finite execution strategy identifier.
    pub strategy: String,
    /// Canonical hexadecimal deterministic seed.
    pub seed: String,
    /// Total exhaustive plus deterministic-property case count.
    pub case_count: u64,
    /// Runtime scalar domain.
    pub value_domain: String,
    /// Exhaustive finite-list bounds.
    pub exhaustive: ExhaustiveCorpus,
    /// Deterministic property-test bounds.
    pub property: PropertyCorpus,
    /// Runtime functions and their LexLean-authored oracle theorems.
    pub oracle: Vec<ExecutionOracle>,
}

/// Exhaustive finite-list strategy parameters.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ExhaustiveCorpus {
    /// Inclusive maximum list length.
    pub max_length: usize,
    /// Inclusive maximum generated value.
    pub value_max: u64,
    /// Exclusive bound supplied to the all-below validator.
    pub all_below_bound: u64,
    /// Number of exhaustive generated input cases.
    pub case_count: u64,
}

/// Deterministic property-test strategy parameters.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct PropertyCorpus {
    /// Number of deterministic generated cases.
    pub case_count: usize,
    /// Inclusive maximum generated list length.
    pub max_length: usize,
    /// Exclusive bound supplied to the flattened validator.
    pub all_below_bound: u64,
    /// Modulus used to generate ordinary values.
    pub generated_value_modulus: u64,
    /// Shrink outcome; passing fixed corpora have no counterexample to shrink.
    pub shrink_result: String,
}

/// One runtime function bound to its formal oracle theorem.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ExecutionOracle {
    /// Fully qualified executable function.
    pub function: String,
    /// Fully qualified LexLean-generated theorem stating its expected result.
    pub theorem: String,
    /// Whether the function must occur in the exact named-export root set.
    pub runtime_root: bool,
}

/// Exact generated Lean definitions selected for named LCNF export.
#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct RuntimeRoots {
    /// Schema spec identifier.
    pub spec: String,
    /// Generated Lean module containing the roots.
    pub lean_module: String,
    /// Logical LCNF module name.
    pub ir_module: String,
    /// Sorted, unique, fully qualified generated Lean definition names.
    pub roots: Vec<String>,
}
