//! Typed registries parsed from model/*.toml.

#![deny(missing_docs)]
#![forbid(unsafe_code)]

pub mod codegen;
pub mod registry;
pub mod release;

pub use registry::{
    Authorities, AuthorityRow, Claim, CommandRow, Commands, ContractRow, Contracts, EmitterInputs,
    ErrorRow, Errors, ExecutionCorpus, ExecutionOracle, ExhaustiveCorpus, IdRow, Ids, Ledger,
    Level, OracleRow, OracleTrustRoot, PropertyCorpus, RuntimeRoots, SignatureTrustRoot,
    StandardRow, Standards,
};

use std::path::{Path, PathBuf};

/// All model registers parsed and checked.
#[derive(Debug, Clone)]
pub struct Model {
    /// model/ledger.toml
    pub ledger: Ledger,
    /// model/ids.toml
    pub ids: Ids,
    /// model/authorities.toml
    pub authorities: Authorities,
    /// model/errors.toml
    pub errors: Errors,
    /// model/standards.toml
    pub standards: Standards,
    /// model/contracts.toml
    pub contracts: Contracts,
    /// model/commands.toml
    pub commands: Commands,
    /// model/emitter-inputs.toml
    pub emitter_inputs: EmitterInputs,
    /// model/execution-corpus.toml
    pub execution_corpus: ExecutionCorpus,
    /// model/runtime-roots.toml
    pub runtime_roots: RuntimeRoots,
}

/// Model load/check failure.
#[derive(Debug)]
pub enum ModelError {
    /// I/O error reading file.
    Io(PathBuf, std::io::Error),
    /// Parse error in TOML.
    Parse(PathBuf, toml::de::Error),
    /// Inconsistency within or across model files.
    Inconsistent(String),
}

impl std::fmt::Display for ModelError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(p, e) => write!(f, "reading {}: {e}", p.display()),
            Self::Parse(p, e) => write!(f, "parsing {}: {e}", p.display()),
            Self::Inconsistent(m) => write!(f, "model is inconsistent: {m}"),
        }
    }
}

impl std::error::Error for ModelError {}

impl Model {
    /// Load all model files from a directory.
    pub fn load(dir: &Path) -> Result<Self, ModelError> {
        Ok(Self {
            ledger: read(dir, "ledger.toml")?,
            ids: read(dir, "ids.toml")?,
            authorities: read(dir, "authorities.toml")?,
            errors: read(dir, "errors.toml")?,
            standards: read(dir, "standards.toml")?,
            contracts: read(dir, "contracts.toml")?,
            commands: read(dir, "commands.toml")?,
            emitter_inputs: read(dir, "emitter-inputs.toml")?,
            execution_corpus: read(dir, "execution-corpus.toml")?,
            runtime_roots: read(dir, "runtime-roots.toml")?,
        })
    }

    /// Load model from repository root.
    pub fn load_from_repo_root() -> Result<Self, ModelError> {
        Self::load(&repo_root().join("model"))
    }

    /// Cross-check all model invariants.
    pub fn check(&self) -> Result<(), ModelError> {
        self.ledger.check()?;
        self.check_ids()?;
        self.check_authorities()?;
        self.errors.check()?;
        self.standards.check()?;
        self.contracts.check(&repo_root())?;
        self.commands.check()?;
        self.check_command_result_contracts()?;
        self.check_execution_corpus()?;
        Ok(())
    }

    fn check_command_result_contracts(&self) -> Result<(), ModelError> {
        let registered = self
            .contracts
            .contract
            .iter()
            .map(|row| row.schema.as_str())
            .collect::<std::collections::BTreeSet<_>>();
        let missing = self
            .commands
            .command
            .iter()
            .filter(|row| !registered.contains(row.result_schema.as_str()))
            .map(|row| format!("{} -> {}", row.name, row.result_schema))
            .collect::<Vec<_>>();
        if !missing.is_empty() {
            return Err(ModelError::Inconsistent(format!(
                "public command result schemas are not registered: {}",
                missing.join(", ")
            )));
        }
        Ok(())
    }

    fn check_execution_corpus(&self) -> Result<(), ModelError> {
        let corpus = &self.execution_corpus;
        let bad = |message: &str| ModelError::Inconsistent(message.to_owned());
        let width = corpus
            .exhaustive
            .value_max
            .checked_add(1)
            .ok_or_else(|| bad("execution corpus value range overflows"))?;
        let mut list_count = 0_u64;
        let mut width_power = 1_u64;
        for length in 0..=corpus.exhaustive.max_length {
            list_count = list_count
                .checked_add(width_power)
                .ok_or_else(|| bad("execution corpus size overflows"))?;
            if length != corpus.exhaustive.max_length {
                width_power = width_power
                    .checked_mul(width)
                    .ok_or_else(|| bad("execution corpus size overflows"))?;
            }
        }
        let exhaustive_cases = list_count;
        let property_cases = u64::try_from(corpus.property.case_count)
            .map_err(|_| bad("execution property count overflows"))?;
        let expected_cases = exhaustive_cases
            .checked_add(property_cases)
            .ok_or_else(|| bad("execution corpus size overflows"))?;
        let mut functions = corpus
            .oracle
            .iter()
            .map(|row| row.function.as_str())
            .collect::<Vec<_>>();
        let original = functions.clone();
        functions.sort_unstable();
        functions.dedup();
        let runtime_functions = corpus
            .oracle
            .iter()
            .filter(|row| row.runtime_root)
            .map(|row| row.function.as_str())
            .collect::<std::collections::BTreeSet<_>>();
        let runtime_roots = self
            .runtime_roots
            .roots
            .iter()
            .map(String::as_str)
            .collect::<std::collections::BTreeSet<_>>();
        if corpus.spec != "prismpm/execution-corpus/1"
            || corpus.strategy != "exhaustive-v1+lcg-v1"
            || corpus.seed.len() != 16
            || !corpus.seed.bytes().all(|byte| byte.is_ascii_hexdigit())
            || corpus.value_domain != "u64"
            || corpus.exhaustive.case_count != exhaustive_cases
            || corpus.property.shrink_result != "not-applicable-passed"
            || corpus.case_count != expected_cases
            || corpus.oracle.is_empty()
            || functions != original
            || self.runtime_roots.spec != "prismpm/runtime-roots/1"
            || self.runtime_roots.lean_module != "PrismPM.Runtime"
            || self.runtime_roots.ir_module != "PrismPM"
            || self
                .runtime_roots
                .roots
                .windows(2)
                .any(|pair| pair[0] >= pair[1])
            || runtime_roots.len() != self.runtime_roots.roots.len()
            || runtime_functions != runtime_roots
            || corpus.oracle.iter().any(|row| {
                let supported = |name: &str| {
                    name.starts_with("PrismPM.Foundation.Holo.")
                        || name.starts_with("PrismPM.Production.System.")
                        || name.starts_with("PrismPM.Production.SystemValidation.")
                        || name.starts_with("PrismPM.Production.SystemValidationCorpus.")
                        || name.starts_with("PrismPM.Production.Validation.")
                };
                !supported(&row.function) || !supported(&row.theorem)
            })
        {
            return Err(bad(
                "execution corpus is not canonical or internally consistent",
            ));
        }
        Ok(())
    }

    fn check_ids(&self) -> Result<(), ModelError> {
        let bad = |m: String| ModelError::Inconsistent(m);
        let mut seen = Vec::new();
        for row in &self.ids.id {
            if seen.contains(&row.id.as_str()) {
                return Err(bad(format!("{}: registered twice", row.id)));
            }
            seen.push(&row.id);
            if row.statement.trim().is_empty() {
                return Err(bad(format!("{}: empty statement", row.id)));
            }
            if row.suite.trim().is_empty() {
                return Err(bad(format!("{}: empty suite", row.id)));
            }
            if row.level != Level::Build {
                return Err(bad(format!("{}: level must be build", row.id)));
            }
        }
        Ok(())
    }

    fn check_authorities(&self) -> Result<(), ModelError> {
        let bad = |m: String| ModelError::Inconsistent(m);
        let mut authority_ids = std::collections::BTreeSet::new();
        for a in &self.authorities.authority {
            let fetched = a.source_role != "binding-only";
            if !authority_ids.insert(a.id.as_str())
                || a.issuer.trim().is_empty()
                || a.name.trim().is_empty()
                || a.canonical_identifier.trim().is_empty()
                || a.edition.trim().is_empty()
                || !matches!(
                    a.source_role.as_str(),
                    "normative" | "informative" | "binding-only"
                )
                || !a.immutable_url.starts_with("https://")
                || a.media_type.trim().is_empty()
                || a.license.trim().is_empty()
                || !matches!(
                    a.redistribution.as_str(),
                    "redistributable" | "citation-only"
                )
                || a.retrieval_date.len() != 10
                || a.retrieval_date.as_bytes().get(4) != Some(&b'-')
                || a.retrieval_date.as_bytes().get(7) != Some(&b'-')
                || a.supersession_policy != "explicit-lock-update-only"
                || a.statement.trim().is_empty()
                || a.immutable_url.to_ascii_lowercase().contains("latest")
                || a.revision.to_ascii_lowercase().contains("latest")
                || (fetched
                    && (a.revision.trim().is_empty()
                        || a.acquired_sha256.len() != 64
                        || !a
                            .acquired_sha256
                            .bytes()
                            .all(|byte| byte.is_ascii_hexdigit())))
                || (!fetched
                    && (a.revision != "not-published"
                        || a.acquired_sha256 != "not-acquired"
                        || a.redistribution != "citation-only"))
            {
                return Err(bad(format!(
                    "{}: invalid immutable authority binding",
                    a.id
                )));
            }
            let signed_tag = a.signature.starts_with("signed-tag-object:");
            let trust_root_valid = a.signature_trust_root.as_ref().is_some_and(|root| {
                matches!(root.algorithm.as_str(), "openpgp" | "ssh")
                    && root.path.starts_with("standards/trust/github-")
                    && root.path.ends_with(if root.algorithm == "openpgp" {
                        ".asc"
                    } else {
                        ".pub"
                    })
                    && root.sha256.len() == 64
                    && root
                        .sha256
                        .bytes()
                        .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
                    && if root.algorithm == "openpgp" {
                        root.fingerprint.len() == 40
                            && root
                                .fingerprint
                                .bytes()
                                .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_lowercase())
                    } else {
                        root.fingerprint.starts_with("SHA256:")
                            && root.fingerprint.len() >= 50
                            && root.fingerprint.len() <= 64
                    }
                    && !root.owner.trim().is_empty()
                    && root.source_url.starts_with("https://api.github.com/users/")
                    && root
                        .source_record_id
                        .bytes()
                        .all(|byte| byte.is_ascii_digit())
                    && root.license == "public-key-material-published-for-verification"
                    && root.redistribution == "verification-use"
            });
            if signed_tag != trust_root_valid {
                return Err(bad(format!(
                    "{}: signed-tag policy and independent trust-root binding disagree",
                    a.id
                )));
            }
            for id in &a.realized_by {
                if self.ids.get(id).is_none() {
                    return Err(bad(format!(
                        "{}: authority realized_by unknown ID {id}",
                        a.id
                    )));
                }
            }
        }
        let mut oracle_ids = std::collections::BTreeSet::new();
        for oracle in &self.authorities.oracle {
            if !oracle_ids.insert(oracle.id.as_str())
                || oracle.authority_ids.is_empty()
                || oracle
                    .authority_ids
                    .iter()
                    .any(|id| !authority_ids.contains(id.as_str()))
                || oracle.executable.is_empty()
                || oracle.executable.contains(char::is_whitespace)
                || oracle.supported_platforms
                    != ["linux/amd64".to_owned(), "linux/arm64".to_owned()]
                || oracle.input_media_types.is_empty()
                || !oracle.output_schema.starts_with("prismpm/")
                || oracle.arguments.is_empty()
                || (oracle.corpus.is_none()
                    && !oracle.arguments.iter().any(|arg| {
                        matches!(
                            arg.as_str(),
                            "{input}"
                                | "{bundle}"
                                | "{subject}"
                                | "{provenance}"
                                | "{trusted-root}"
                        )
                    }))
                || oracle.arguments.iter().any(|arg| {
                    arg.starts_with('{')
                        && !matches!(
                            arg.as_str(),
                            "{input}"
                                | "{bundle}"
                                | "{subject}"
                                | "{provenance}"
                                | "{trusted-root}"
                                | "{source-uri}"
                                | "{identity}"
                                | "{issuer}"
                        )
                })
                || oracle.timeout_ms == 0
                || oracle.memory_bytes < 1_048_576
                || oracle.output_bytes == 0
                || !matches!(oracle.network.as_str(), "deny" | "isolated-subject")
                || oracle.normalization != "prismpm/oracle-diagnostics/1"
                || oracle.covers.is_empty()
                || oracle.does_not_cover.is_empty()
                || oracle.expected_exits.is_empty()
                || oracle.upstream_payload_sha256.len() != 64
                || !oracle
                    .upstream_payload_sha256
                    .bytes()
                    .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
                || oracle.corpus.as_ref().is_some_and(|corpus| {
                    corpus.sha256.len() != 64
                        || !corpus
                            .sha256
                            .bytes()
                            .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
                        || !corpus.path.starts_with("standards/")
                        || corpus.path.contains("..")
                        || !repo_root().join(&corpus.path).is_dir()
                })
                || oracle.subject.as_ref().is_some_and(|subject| {
                    !subject.contains("@sha256:")
                        || subject.rsplit_once("@sha256:").is_none_or(|(_, digest)| {
                            digest.len() != 64
                                || !digest.bytes().all(|byte| {
                                    byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase()
                                })
                        })
                })
                || oracle
                    .arguments
                    .iter()
                    .any(|argument| argument == "{trusted-root}")
                    != oracle.trusted_root.is_some()
                || oracle.trusted_root.as_ref().is_some_and(|root| {
                    root.role != "sigstore-verification-root"
                        || !root.path.starts_with("standards/trust/")
                        || root.path.contains("..")
                        || root.sha256.len() != 64
                        || !root
                            .sha256
                            .bytes()
                            .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
                })
                || oracle.wrapper_source.starts_with('/')
                || oracle.wrapper_source.contains("..")
                || !repo_root().join(&oracle.wrapper_source).is_file()
            {
                return Err(bad(format!(
                    "{}: invalid oracle execution contract",
                    oracle.id
                )));
            }
        }
        for c in &self.ledger.claim {
            if c.level == Level::SomeTrue {
                let Some(name) = &c.authority else {
                    return Err(bad(format!("{}: some-true claim missing authority", c.id)));
                };
                if !self.authorities.authority.iter().any(|a| &a.id == name) {
                    return Err(bad(format!("{}: cites unknown authority {name}", c.id)));
                }
            }
        }
        Ok(())
    }
}

fn read<T: serde::de::DeserializeOwned>(dir: &Path, name: &str) -> Result<T, ModelError> {
    let path = dir.join(name);
    let text = std::fs::read_to_string(&path).map_err(|e| ModelError::Io(path.clone(), e))?;
    toml::from_str(&text).map_err(|e| ModelError::Parse(path, e))
}

/// Repository root resolved relative to CARGO_MANIFEST_DIR.
pub fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("crates/model is two levels below repository root")
        .to_path_buf()
}

#[cfg(test)]
mod tests {
    use super::Model;

    #[test]
    fn every_public_command_result_schema_is_registered() {
        let model = Model::load_from_repo_root().expect("load repository model");
        model
            .check_command_result_contracts()
            .expect("all public command results must be public contracts");

        let mut planted = model;
        planted
            .contracts
            .contract
            .retain(|row| row.schema != "prismpm/check-result/1");
        let error = planted
            .check_command_result_contracts()
            .expect_err("an undeclared result schema must fail closed");
        assert!(error
            .to_string()
            .contains("check -> prismpm/check-result/1"));
    }

    #[test]
    fn fixed_corpus_oracles_need_no_subject_but_dynamic_oracles_do() {
        let model = Model::load_from_repo_root().expect("load repository model");
        model
            .check()
            .expect("locked fixed-corpus oracles are valid");

        let mut planted = model;
        let oracle = planted
            .authorities
            .oracle
            .iter_mut()
            .find(|row| row.id == "oci-layout-1.1")
            .expect("OCI Image official corpus oracle");
        oracle.corpus = None;
        let error = planted
            .check()
            .expect_err("a dynamic oracle without a subject binding must fail closed");
        assert!(error
            .to_string()
            .contains("oci-layout-1.1: invalid oracle execution contract"));
    }
}
