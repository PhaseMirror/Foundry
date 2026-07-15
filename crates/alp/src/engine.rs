//! Native ALP/CNL inference engine (ADR-101).
//!
//! `AlpEngine` is the deterministic facade the Phase Mirror agent uses on its
//! control path. It replaces any LLM inference leg with:
//!
//! ```text
//! CNL parse -> ALP policy -> Rta-checked evaluation -> Triple-Lock witness
//! ```
//!
//! Every step is pure. For a fixed `SystemState` and CNL source the engine
//! returns one canonical `(AlpPolicy, RtaMetric)` pair, which is what makes
//! deterministic `Archivum` replay and the Zero-Drift mandate enforceable.

use crate::cnl::{CnlCompiler, CnlError};
use crate::{AlpPolicy, AlpRule, EvalError, RtaMetric, SystemState};

/// Native ALP/CNL inference engine.
#[derive(Debug, Clone, Copy, Default)]
pub struct AlpEngine;

impl AlpEngine {
    /// Load an ALP policy from CNL source (ADR-074 / ADR-101 surface).
    pub fn load_policy(source: &str) -> Result<AlpPolicy, CnlError> {
        CnlCompiler::parse(source)
    }

    /// Evaluate a policy against a system state, returning the Rta metric.
    ///
    /// Mirrors the contradiction rule used by `PolicyEngine`: a policy mixing
    /// `NoOp` with a concrete perturbation is contradictory and rejected.
    pub fn evaluate(&self, policy: &AlpPolicy, state: &SystemState) -> Result<RtaMetric, EvalError> {
        let mut has_increase = false;
        let mut has_decrease = false;
        let mut has_noop = false;
        for r in &policy.rules {
            match r {
                AlpRule::IncreaseMultiplicity(_) => has_increase = true,
                AlpRule::DecreaseArtaDefect(_) => has_decrease = true,
                AlpRule::NoOp => has_noop = true,
            }
        }
        if has_noop && (has_increase || has_decrease) {
            return Err(EvalError::ContradictoryPolicy);
        }

        let mut next = state.clone();
        for r in &policy.rules {
            match r {
                AlpRule::IncreaseMultiplicity(d) => next.multiplicity_measure += d,
                AlpRule::DecreaseArtaDefect(d) => next.arta_defect -= d,
                AlpRule::NoOp => {}
            }
        }

        Ok(RtaMetric {
            value: next.multiplicity_measure - next.arta_defect,
        })
    }

    /// Rta threshold check — the fail-closed boundary. `true` iff the
    /// multiplicity measure dominates the arta defect.
    pub fn check(&self, state: &SystemState) -> Result<bool, EvalError> {
        Ok(state.multiplicity_measure > state.arta_defect)
    }

    /// End-to-end CNL inference: parse, then evaluate. Returns the canonical
    /// `(policy, rta)` pair. Pure and deterministic (ADR-101 Lemma 1).
    pub fn evaluate_cnl(
        &self,
        state: &SystemState,
        cnl: &str,
    ) -> Result<(AlpPolicy, RtaMetric), EngineError> {
        let policy = CnlCompiler::parse(cnl).map_err(EngineError::Cnl)?;
        let rta = self.evaluate(&policy, state).map_err(EngineError::Eval)?;
        Ok((policy, rta))
    }
}

/// Union error for end-to-end CNL inference.
#[derive(Debug, Clone, PartialEq, thiserror::Error)]
pub enum EngineError {
    #[error("cnl compile error: {0}")]
    Cnl(#[from] CnlError),
    #[error("evaluation error: {0}")]
    Eval(#[from] EvalError),
}
