//! Named defect codes. Every structural violation of an ADR-0022…0028 invariant
//! is mapped to one of these; the observ gate kills (or reports) on their count.

use serde::{Deserialize, Serialize};

/// Δ — the named defect classes emitted by the observ gate.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize, Hash)]
#[serde(rename_all = "snake_case")]
pub enum DefectCode {
    /// The program violates shape/bounds/cross-reference invariants.
    ProgramMalformed,
    /// An identified-then-unidentified stage attribution inconsistency.
    NullMisattribution,
    /// A claim declares closure in a channel whose obstruction dimension is > 0.
    ClaimMigration,
    /// A component is closed while its source gate is contaminated.
    DownstreamBeforeSourceGate,
    /// A source claim closes without a predeclared admissible reference.
    ReferenceInapplicable,
    /// A reversal character into a declared-forbidden sector is non-zero.
    ForbiddenSectorLeak,
    /// The reversal maps are not involutive-and-commuting.
    ReversalPathBreach,
    /// Lockdown/stage caps exceeded by the declared pipeline.
    ExpansiveTransition,
    /// Exact arithmetic overflowed `i128`.
    ArithmeticOverflow,
}

impl DefectCode {
    /// English phrase bound into the verdict and the defect receipt.
    pub fn message(self) -> &'static str {
        match self {
            DefectCode::ProgramMalformed => {
                "program violates shape, bound, or cross-reference invariants"
            }
            DefectCode::NullMisattribution => {
                "stage attribution inconsistent with the null filtration"
            }
            DefectCode::ClaimMigration => {
                "claim declared resolved in a channel that cannot resolve it"
            }
            DefectCode::DownstreamBeforeSourceGate => {
                "downstream component closed while the source gate is contaminated"
            }
            DefectCode::ReferenceInapplicable => {
                "source claim closed without an admissible declared reference"
            }
            DefectCode::ForbiddenSectorLeak => {
                "non-zero reversal character in a declared-forbidden sector"
            }
            DefectCode::ReversalPathBreach => "reversal maps are not involutive-and-commuting",
            DefectCode::ExpansiveTransition => "declared pipeline exceeds lockdown/stage caps",
            DefectCode::ArithmeticOverflow => "exact arithmetic overflowed i128",
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            DefectCode::ProgramMalformed => "program_malformed",
            DefectCode::NullMisattribution => "null_misattribution",
            DefectCode::ClaimMigration => "claim_migration",
            DefectCode::DownstreamBeforeSourceGate => "downstream_before_source_gate",
            DefectCode::ReferenceInapplicable => "reference_inapplicable",
            DefectCode::ForbiddenSectorLeak => "forbidden_sector_leak",
            DefectCode::ReversalPathBreach => "reversal_path_breach",
            DefectCode::ExpansiveTransition => "expansive_transition",
            DefectCode::ArithmeticOverflow => "arithmetic_overflow",
        }
    }

    /// Severity band used by the gate: hard defects kill, soft ones escalate.
    pub const fn severity(self) -> u8 {
        match self {
            DefectCode::ProgramMalformed => 0,
            DefectCode::NullMisattribution => 1,
            DefectCode::ClaimMigration => 0,
            DefectCode::DownstreamBeforeSourceGate => 0,
            DefectCode::ReferenceInapplicable => 1,
            DefectCode::ForbiddenSectorLeak => 0,
            DefectCode::ReversalPathBreach => 0,
            DefectCode::ExpansiveTransition => 1,
            DefectCode::ArithmeticOverflow => 0,
        }
    }
}

/// A concrete, named defect of one `measure` call.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ObservDefect {
    pub code: DefectCode,
    /// Δ named in English a node can act on.
    pub english: String,
    /// The affected pipeline element: stage index, channel index, or 0.
    pub owner: u64,
    /// Integer metric (obstruction dimension, leakage count, dimension delta).
    pub metric: u64,
}

impl ObservDefect {
    pub fn new(code: DefectCode, metric: u64) -> Self {
        ObservDefect {
            code,
            english: code.message().to_string(),
            owner: 0,
            metric,
        }
    }

    pub fn at(mut self, owner: u64) -> Self {
        self.owner = owner;
        self
    }

    /// Override the English phrase (e.g. report a validation message).
    pub fn with_english(mut self, english: &str) -> Self {
        self.english = english.to_string();
        self
    }
}

impl From<DefectCode> for &'static str {
    fn from(d: DefectCode) -> Self {
        d.as_str()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_defect_has_language() {
        let all = [
            DefectCode::ProgramMalformed,
            DefectCode::NullMisattribution,
            DefectCode::ClaimMigration,
            DefectCode::DownstreamBeforeSourceGate,
            DefectCode::ReferenceInapplicable,
            DefectCode::ForbiddenSectorLeak,
            DefectCode::ReversalPathBreach,
            DefectCode::ExpansiveTransition,
            DefectCode::ArithmeticOverflow,
        ];
        for d in all {
            assert!(!d.message().is_empty());
            assert!(!d.as_str().is_empty());
        }
    }
}
