//! The UTQC conceptual model, as typed and self-validating data.
//!
//! The model is authored once in `model/*.toml` (see [`docs/conceptual-model`]) and embedded
//! here at compile time. [`Model::load`] parses it and enforces the structural invariants the
//! honesty meta-gate relies on: every dictionary row names a known status and oracle, names a
//! feature, and status discipline holds (an `open` row can never be a gating `suite`). The
//! vocabulary is `some-true` / `build` / `open`.
//!
//! This crate contains **no mathematics and no substrate** — only the model.
//!
//! [`docs/conceptual-model`]: https://github.com/afflom/UOR-Atlas-UTQC/tree/main/docs/conceptual-model

#![forbid(unsafe_code)]

use serde::Deserialize;
use std::collections::BTreeSet;
use std::fmt;

const STATUS_TOML: &str = include_str!("../../../model/status.toml");
const ORACLES_TOML: &str = include_str!("../../../model/oracles.toml");
const USECASES_TOML: &str = include_str!("../../../model/usecases.toml");
const DICTIONARY_TOML: &str = include_str!("../../../model/dictionary.toml");

/// A V&V tier: how a dictionary row is realized and gated.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Tier {
    /// Implemented, gating, green.
    Suite,
    /// Defined behavior, not yet built; expected-RED, non-gating.
    Target,
}

/// One honesty level from the status ledger (`model/status.toml`).
#[derive(Debug, Clone, Deserialize)]
pub struct Status {
    /// Identifier: `some-true`, `build`, or `open`.
    pub id: String,
    /// One-line meaning.
    pub summary: String,
    /// What the V&V suite may assert for a row at this level.
    pub may_assert: String,
    /// Whether a row at this level participates in the gating suite.
    pub gating: bool,
}

/// One authoritative external oracle (`model/oracles.toml`).
#[derive(Debug, Clone, Deserialize)]
pub struct Oracle {
    /// Identifier referenced by dictionary rows.
    pub id: String,
    /// Human description of the authority.
    pub authority: String,
    /// Where it comes from.
    pub source: String,
    /// Pinned commit / version.
    pub pin: String,
    /// SPDX license of the source.
    pub license: String,
    /// `generated-from-source` | `realized-operation` | `substrate-witness` | `predicate`.
    pub kind: String,
    /// Committed artifact path (empty for linked-code / predicate oracles).
    pub artifact: String,
    /// Expected sha256 of `artifact` (empty if none).
    pub sha256: String,
    /// Free-form note.
    #[serde(default)]
    pub note: String,
}

/// One use-case instance of the parametric framework (`model/usecases.toml`).
#[derive(Debug, Clone, Deserialize)]
pub struct UseCase {
    /// Identifier, e.g. `atlas`.
    pub id: String,
    /// Whether this is the canonical (Atlas) instance.
    pub canonical: bool,
    /// Scope parameter `q`.
    pub scope: u32,
    /// Modality parameter `T`.
    pub modality: u32,
    /// Context parameter `O`.
    pub context: u32,
    /// Oracle id validating this instance (empty for non-canonical).
    #[serde(default)]
    pub oracle: String,
    /// Free-form note.
    #[serde(default)]
    pub note: String,
}

/// One dictionary row (`model/dictionary.toml`).
#[derive(Debug, Clone, Deserialize)]
pub struct Row {
    /// Kebab-case row identifier; matches a feature tag `@row:<id>`.
    pub id: String,
    /// The UTQC primitive.
    pub tqc: String,
    /// The Atlas / uor-addr realization summary.
    pub atlas: String,
    /// The F1 / uor-addr / holospaces anchor.
    pub source: String,
    /// Status level id (must exist in the ledger).
    pub status: String,
    /// Build stage `S0`..`S4`.
    pub stage: String,
    /// Oracle id (must exist in the registry, or empty if none).
    pub oracle: String,
    /// V&V tier.
    pub tier: Tier,
    /// Path of the Gherkin feature.
    pub feature: String,
}

#[derive(Deserialize)]
struct StatusFile {
    level: Vec<Status>,
}
#[derive(Deserialize)]
struct OracleFile {
    oracle: Vec<Oracle>,
}
#[derive(Deserialize)]
struct UseCaseFile {
    usecase: Vec<UseCase>,
}
#[derive(Deserialize)]
struct DictionaryFile {
    row: Vec<Row>,
}

/// An error while loading or validating the model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ModelError(String);

impl fmt::Display for ModelError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "model invariant violated: {}", self.0)
    }
}

impl std::error::Error for ModelError {}

/// The whole conceptual model: ledger + oracles + use-cases + dictionary.
#[derive(Debug, Clone)]
pub struct Model {
    /// The status ledger.
    pub statuses: Vec<Status>,
    /// The oracle registry.
    pub oracles: Vec<Oracle>,
    /// The use-case instances.
    pub usecases: Vec<UseCase>,
    /// The dictionary rows.
    pub rows: Vec<Row>,
}

impl Model {
    /// Parse the embedded model and enforce all structural invariants.
    ///
    /// # Errors
    /// Returns [`ModelError`] if the TOML fails to parse or any invariant is violated.
    pub fn load() -> Result<Self, ModelError> {
        let statuses = toml::from_str::<StatusFile>(STATUS_TOML)
            .map_err(|e| ModelError(format!("status.toml: {e}")))?
            .level;
        let oracles = toml::from_str::<OracleFile>(ORACLES_TOML)
            .map_err(|e| ModelError(format!("oracles.toml: {e}")))?
            .oracle;
        let usecases = toml::from_str::<UseCaseFile>(USECASES_TOML)
            .map_err(|e| ModelError(format!("usecases.toml: {e}")))?
            .usecase;
        let rows = toml::from_str::<DictionaryFile>(DICTIONARY_TOML)
            .map_err(|e| ModelError(format!("dictionary.toml: {e}")))?
            .row;

        let model = Self {
            statuses,
            oracles,
            usecases,
            rows,
        };
        model.validate()?;
        Ok(model)
    }

    /// Look up a status level by id.
    #[must_use]
    pub fn status(&self, id: &str) -> Option<&Status> {
        self.statuses.iter().find(|s| s.id == id)
    }

    /// Look up an oracle by id.
    #[must_use]
    pub fn oracle(&self, id: &str) -> Option<&Oracle> {
        self.oracles.iter().find(|o| o.id == id)
    }

    /// The canonical (Atlas) use-case, if exactly one is marked canonical.
    #[must_use]
    pub fn canonical_usecase(&self) -> Option<&UseCase> {
        let mut it = self.usecases.iter().filter(|u| u.canonical);
        let first = it.next()?;
        if it.next().is_some() {
            return None;
        }
        Some(first)
    }

    /// Rows at a given tier.
    pub fn rows_in_tier(&self, tier: Tier) -> impl Iterator<Item = &Row> {
        self.rows.iter().filter(move |r| r.tier == tier)
    }

    /// Enforce the structural invariants the honesty gate depends on.
    fn validate(&self) -> Result<(), ModelError> {
        let status_ids: BTreeSet<&str> = self.statuses.iter().map(|s| s.id.as_str()).collect();
        let oracle_ids: BTreeSet<&str> = self.oracles.iter().map(|o| o.id.as_str()).collect();

        let mut seen = BTreeSet::new();
        for r in &self.rows {
            if !seen.insert(r.id.as_str()) {
                return Err(ModelError(format!("duplicate row id `{}`", r.id)));
            }
            let status = self.status(&r.status).ok_or_else(|| {
                ModelError(format!("row `{}`: unknown status `{}`", r.id, r.status))
            })?;
            if !status_ids.contains(r.status.as_str()) {
                return Err(ModelError(format!("row `{}`: unknown status", r.id)));
            }

            // Every row names a feature and (if any) a known oracle.
            if r.feature.is_empty() {
                return Err(ModelError(format!(
                    "row `{}`: a row requires a feature path",
                    r.id
                )));
            }
            if !r.oracle.is_empty() && !oracle_ids.contains(r.oracle.as_str()) {
                return Err(ModelError(format!(
                    "row `{}`: unknown oracle `{}`",
                    r.id, r.oracle
                )));
            }

            // Status discipline: a non-gating level (open) can never be a gating suite.
            if r.tier == Tier::Suite && !status.gating {
                return Err(ModelError(format!(
                    "row `{}`: status `{}` is non-gating and may not be a gating `suite`",
                    r.id, r.status
                )));
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn model_loads_and_validates() {
        let m = Model::load().expect("model must load and satisfy its invariants");
        assert!(!m.rows.is_empty(), "dictionary must have rows");
        assert!(m.status("some-true").is_some());
        assert!(m.status("build").is_some());
    }

    #[test]
    fn canonical_usecase_is_the_atlas() {
        let m = Model::load().unwrap();
        let uc = m
            .canonical_usecase()
            .expect("exactly one canonical use-case");
        assert_eq!(uc.id, "atlas");
        assert_eq!((uc.scope, uc.modality, uc.context), (4, 3, 8));
    }

    #[test]
    fn vocabulary_is_three_levels_with_no_crux() {
        let m = Model::load().unwrap();
        assert!(
            m.status("none").is_none(),
            "the RH crux level must not exist in the UTQC"
        );
        for level in ["some-true", "build", "open"] {
            assert!(m.status(level).is_some(), "missing status level `{level}`");
        }
        assert!(
            m.rows.iter().all(|r| r.status != "none"),
            "no row may carry status `none`"
        );
    }
}
