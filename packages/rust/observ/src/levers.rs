//! Levers: one `[owner] — action — metric — horizon` per named defect,
//! mirrored from the UCC contract (ADR-0014): every Δ has an English lever a
//! node can act on, with the same fixed-point metric and an explicit horizon.

use serde::{Deserialize, Serialize};

use crate::defect::DefectCode;

/// A single actionable lever bound to one named defect.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Lever {
    /// The owner a node can act on — the affected stage/channel index
    /// (0 = the pipeline as a whole).
    pub owner: u64,
    /// The English action that clears the defect.
    pub action: String,
    /// The integer metric (obstruction dimension, leakage count, Δ gain…).
    pub metric: u64,
    /// The horizon in which the action must land.
    pub horizon: String,
}

impl Lever {
    pub fn new(owner: u64, action: &'static str, metric: u64, horizon: &'static str) -> Self {
        Lever {
            owner,
            action: action.to_string(),
            metric,
            horizon: horizon.to_string(),
        }
    }
}

/// The English action paired with each observ defect.
pub const fn lever_action(code: DefectCode) -> &'static str {
    match code {
        DefectCode::ProgramMalformed => {
            "revalidate the measurement program against the wire schema"
        }
        DefectCode::NullMisattribution => {
            "attribute the erased direction to the stage that first kills it"
        }
        DefectCode::ClaimMigration => {
            "attach the claim to a channel whose obstruction dimension is zero"
        }
        DefectCode::DownstreamBeforeSourceGate => {
            "defer source-state closure until the microstructure gate is clean"
        }
        DefectCode::ReferenceInapplicable => {
            "declare an admissible reference sector before closing any source claim"
        }
        DefectCode::ForbiddenSectorLeak => {
            "remove the measured weight from the declared-forbidden character sector"
        }
        DefectCode::ReversalPathBreach => {
            "replace the reversal maps with a commuting involuntary set"
        }
        DefectCode::ExpansiveTransition => "reduce the declared pipeline below the lockdown caps",
        DefectCode::ArithmeticOverflow => "reduce coefficient magnitudes below the i128 envelope",
    }
}

/// The horizon of every observ lever: before the Q2 exit gate (mirrors UCC's
/// "before the Q0 exit gate" phrasing for this calculus).
pub const fn horizon() -> &'static str {
    "before the Q2 exit gate"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_code_has_a_lever() {
        for code in [
            DefectCode::ProgramMalformed,
            DefectCode::NullMisattribution,
            DefectCode::ClaimMigration,
            DefectCode::DownstreamBeforeSourceGate,
            DefectCode::ReferenceInapplicable,
            DefectCode::ForbiddenSectorLeak,
            DefectCode::ReversalPathBreach,
            DefectCode::ExpansiveTransition,
            DefectCode::ArithmeticOverflow,
        ] {
            assert!(!lever_action(code).is_empty());
        }
    }

    #[test]
    fn lever_carries_metric_and_horizon() {
        let l = Lever::new(0, lever_action(DefectCode::ClaimMigration), 3, horizon());
        assert_eq!(l.metric, 3);
        assert_eq!(l.horizon, "before the Q2 exit gate");
    }
}
