//! Controlled Natural Language (CNL) compiler for the ALP policy plane.
//!
//! CNL is a closed, parseable surface. A well-formed CNL policy source
//! compiles deterministically to an [`AlpPolicy`]. This module is the single
//! sanctioned entry point from natural language into the ALP contract plane
//! (ADR-101: native ALP/CNL inference in place of an LLM).
//!
//! The compiler is **stateless and pure**: equal inputs always yield equal
//! outputs, which is what makes the Phase Mirror control path reproducible
//! and `Archivum`-replayable (cf. `proof_cnl_compiler_deterministic`).

use crate::{AlpPolicy, AlpRule};
use serde::{Deserialize, Serialize};

/// Error produced when CNL fails to compile to an ALP contract.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, thiserror::Error)]
pub enum CnlError {
    #[error("empty policy: a `policy <name>` header is required")]
    EmptyPolicy,
    #[error("missing `policy <name>` header on the first line")]
    MissingHeader,
    #[error("unknown CNL directive on line {line}: {text}")]
    UnknownDirective { line: usize, text: String },
    #[error("malformed numeric literal on line {line}: {text}")]
    MalformedNumber { line: usize, text: String },
    #[error("non-finite magnitude on line {line}: {text}")]
    NonFinite { line: usize, text: String },
}

/// An opaque, deterministic CNL source string.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CnlSource(pub String);

impl std::fmt::Display for CnlSource {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// The CNL compiler. Stateless: `parse(s)` is a total function.
#[derive(Debug, Clone, Copy, Default)]
pub struct CnlCompiler;

impl CnlCompiler {
    /// Parse a CNL policy source into an [`AlpPolicy`].
    ///
    /// Grammar (one directive per non-empty, trimmed line):
    /// ```text
    /// policy <name>
    /// increase multiplicity by <f64>
    /// decrease arta defect by <f64>
    /// noop
    /// ```
    ///
    /// Every input is either accepted as a policy or rejected with a
    /// [`CnlError`]; there is no loose interpretation. The function is
    /// deterministic (ADR-101 Lemma 1).
    pub fn parse(src: &str) -> Result<AlpPolicy, CnlError> {
        let mut body = src
            .lines()
            .map(str::trim)
            .filter(|l| !l.is_empty());

        let header = body.next().ok_or(CnlError::EmptyPolicy)?;
        let name = header
            .strip_prefix("policy")
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .ok_or(CnlError::MissingHeader)?
            .to_string();

        let mut rules: Vec<AlpRule> = Vec::new();
        for (idx, line) in body.enumerate() {
            let line_no = idx + 2; // header occupies line 1
            rules.push(parse_directive(line, line_no)?);
        }

        Ok(AlpPolicy { name, rules })
    }
}

fn parse_directive(line: &str, line_no: usize) -> Result<AlpRule, CnlError> {
    let lower = line.to_ascii_lowercase();
    if let Some(rest) = lower.strip_prefix("increase multiplicity by ") {
        let v: f64 = parse_magnitude(rest.trim(), line_no, line)?;
        Ok(AlpRule::IncreaseMultiplicity(v))
    } else if let Some(rest) = lower.strip_prefix("decrease arta defect by ") {
        let v: f64 = parse_magnitude(rest.trim(), line_no, line)?;
        Ok(AlpRule::DecreaseArtaDefect(v))
    } else if lower == "noop" {
        Ok(AlpRule::NoOp)
    } else {
        Err(CnlError::UnknownDirective {
            line: line_no,
            text: line.to_string(),
        })
    }
}

/// Parse and validate a finite magnitude. Rejects `NaN`/`inf` so that the
/// compiler cannot admit a non-finite Rta perturbation (soundness hole
/// closed relative to `f64::parse`, which accepts "NaN"/"inf").
fn parse_magnitude(token: &str, line_no: usize, raw: &str) -> Result<f64, CnlError> {
    let v: f64 = token
        .parse()
        .map_err(|_| CnlError::MalformedNumber {
            line: line_no,
            text: raw.to_string(),
        })?;
    if !v.is_finite() {
        return Err(CnlError::NonFinite {
            line: line_no,
            text: raw.to_string(),
        });
    }
    Ok(v)
}
