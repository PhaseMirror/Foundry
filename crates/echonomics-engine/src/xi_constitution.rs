//! # echonomics_engine::xi_constitution — ADR-0005: Ξ-Constitution & Ξ-License Governance Invariants
//!
//! Formal, fail-closed implementation of the Ξ-Constitution v2.0 / Ξ-License
//! v1.0 governance contract:
//!
//! - **CSL gate** `(N, B, S)`: Neutrality, Beneficence, Silence — passes iff
//!   all three operators hold, and fails closed on any rejection.
//! - **Lawful Recursion**: semantic drift `δ ≤ ε` (bounded drift).
//! - **Composite certificate** `Ψ = PIRTM ∘ CSL ∘ zk`: certified iff every
//!   pipeline stage passes; fails closed on any rejected stage.
//! - **Fail-closed license**: granted iff certified and carrying no
//!   prohibited characteristic (surveillance / profiling / exploitation /
//!   weaponization / black-box); any prohibited flag denies execution.
//!
//! All the license predicates are pure functions over booleans and `u64`
//! counters with no allocation or hashing, so Kani can discharge them
//! symbolically. The `XiLicense` engine delegates to the same pure core.

use serde::{Deserialize, Serialize};

/// Conscious Sovereignty Layer three-operator gate `(N, B, S)`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct CslOperators {
    pub is_neutral: bool,
    pub is_beneficent: bool,
    pub is_silent: bool,
}

/// CSL gate: passes only when all three operators hold.
#[inline]
pub const fn evaluate_csl_gate(ops: &CslOperators) -> bool {
    ops.is_neutral && ops.is_beneficent && ops.is_silent
}

/// Lawful Recursion drift state: `drift_delta` is `δ`, `bound_epsilon` is `ε`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct LawfulRecursionState {
    pub drift_delta: u64,
    pub bound_epsilon: u64,
}

/// Lawful Recursion holds exactly when the drift is within its bound: `δ ≤ ε`.
#[inline]
pub const fn is_lawful_recursion(st: &LawfulRecursionState) -> bool {
    st.drift_delta <= st.bound_epsilon
}

/// The three-stage certificate pipeline `PIRTM ∘ CSL ∘ zk`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct CertPipeline {
    pub pirtm_pass: bool,
    pub csl_pass: bool,
    pub zk_pass: bool,
}

/// Composite certification: the conjunction of every pipeline stage.
#[inline]
pub const fn flow_certificates(p: &CertPipeline) -> bool {
    p.pirtm_pass && p.csl_pass && p.zk_pass
}

/// Prohibited characteristics that MUST fail closed under the license.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProhibitedFlags {
    pub is_surveillance: bool,
    pub is_profiling: bool,
    pub is_exploitation: bool,
    pub is_weaponized: bool,
    pub is_black_box: bool,
}

/// Prohibited when any characteristic is present.
#[inline]
pub const fn is_prohibited(pf: &ProhibitedFlags) -> bool {
    pf.is_surveillance
        || pf.is_profiling
        || pf.is_exploitation
        || pf.is_weaponized
        || pf.is_black_box
}

/// Ξ-Certification requires the CSL gate, Lawful Recursion, and the composite
/// pipeline all to pass.
#[inline]
pub const fn is_xi_certified(ops: &CslOperators, st: &LawfulRecursionState, p: &CertPipeline) -> bool {
    evaluate_csl_gate(ops) && is_lawful_recursion(st) && flow_certificates(p)
}

/// A license is granted iff the system is Ξ-Certified and carries no
/// prohibited characteristic.
#[inline]
pub const fn is_license_granted(
    ops: &CslOperators,
    st: &LawfulRecursionState,
    p: &CertPipeline,
    pf: &ProhibitedFlags,
) -> bool {
    is_xi_certified(ops, st, p) && !is_prohibited(pf)
}

/// A discrete system state `Ξ`: an epoch index `t` and a carried semantic
/// magnitude. The semantic magnitude is what drifts under transition.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct XiState {
    pub epoch: u64,
    pub semantic: u64,
}

impl XiState {
    pub const fn new(epoch: u64, semantic: u64) -> Self {
        Self { epoch, semantic }
    }
}

/// Semantic drift `δ` between two states: the nonnegative distance between
/// their semantic magnitudes.
#[inline]
pub const fn measure_drift(a: &XiState, b: &XiState) -> u64 {
    if a.semantic <= b.semantic {
        b.semantic - a.semantic
    } else {
        a.semantic - b.semantic
    }
}

/// Decision 1: the CSL-gated lawful transition `Ψ`. The CSL gate `(N,B,S)` is
/// evaluated **before** mutation:
///
/// - gate passes → advance to `next_epoch` and drift the semantic magnitude by
///   `drift` (caller must supply `drift ≤ bound_epsilon`).
/// - gate fails  → NO-OP: return the input state unchanged (fail closed,
///   Silence Clause default).
#[inline]
pub const fn csl_gated_step(ops: &CslOperators, drift: u64, next_epoch: u64, s: &XiState) -> XiState {
    if evaluate_csl_gate(ops) {
        XiState { epoch: next_epoch, semantic: s.semantic.saturating_add(drift) }
    } else {
        *s
    }
}

/// Decision 2: the composite transition `Ψ = PIRTM ∘ CSL ∘ zk` read off a
/// `CertPipeline`. The pipeline's CSL stage `csl_pass` is the transition gate,
/// evaluated before mutation; a certified pipeline advances the state lawfully.
#[inline]
pub const fn certified_gated_step(
    p: &CertPipeline,
    drift: u64,
    next_epoch: u64,
    s: &XiState,
) -> XiState {
    if p.csl_pass {
        XiState { epoch: next_epoch, semantic: s.semantic.saturating_add(drift) }
    } else {
        *s
    }
}

/// Decision 1: Lawful Recursion over a transition — a CSL-passed step with an
/// in-bound drift yields `δ ≤ ε`.
#[inline]
pub const fn transition_lawful(
    ops: &CslOperators,
    drift: u64,
    next_epoch: u64,
    s: &XiState,
    bound_epsilon: u64,
) -> bool {
    if evaluate_csl_gate(ops) {
        measure_drift(s, &csl_gated_step(ops, drift, next_epoch, s)) <= bound_epsilon
    } else {
        true // NO-OP keeps the state unchanged -> zero drift -> always lawful
    }
}

/// Stateful engine delegating to the pure license core.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct XiLicense {
    pub csl: CslOperators,
    pub recursion: LawfulRecursionState,
    pub pipeline: CertPipeline,
    pub flags: ProhibitedFlags,
}

impl XiLicense {
    pub fn new(csl: CslOperators, recursion: LawfulRecursionState, pipeline: CertPipeline, flags: ProhibitedFlags) -> Self {
        Self { csl, recursion, pipeline, flags }
    }

    pub fn is_certified(&self) -> bool {
        is_xi_certified(&self.csl, &self.recursion, &self.pipeline)
    }

    pub fn is_licensed(&self) -> bool {
        is_license_granted(&self.csl, &self.recursion, &self.pipeline, &self.flags)
    }
}

impl CslOperators {
    pub fn evaluate_gate(&self) -> bool {
        evaluate_csl_gate(self)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn clean() -> CslOperators {
        CslOperators { is_neutral: true, is_beneficent: true, is_silent: true }
    }
    fn in_bound() -> LawfulRecursionState {
        LawfulRecursionState { drift_delta: 3, bound_epsilon: 10 }
    }
    fn passing_pipeline() -> CertPipeline {
        CertPipeline { pirtm_pass: true, csl_pass: true, zk_pass: true }
    }
    fn clean_flags() -> ProhibitedFlags {
        ProhibitedFlags {
            is_surveillance: false,
            is_profiling: false,
            is_exploitation: false,
            is_weaponized: false,
            is_black_box: false,
        }
    }

    #[test]
    fn test_csl_gate_requires_all() {
        assert!(evaluate_csl_gate(&clean()));
        let no_ben = CslOperators { is_beneficent: false, ..clean() };
        assert!(!evaluate_csl_gate(&no_ben));
        let no_sil = CslOperators { is_silent: false, ..clean() };
        assert!(!evaluate_csl_gate(&no_sil));
        let no_neu = CslOperators { is_neutral: false, ..clean() };
        assert!(!evaluate_csl_gate(&no_neu));
    }

    #[test]
    fn test_lawful_recursion_drift_bound() {
        assert!(is_lawful_recursion(&in_bound()));
        let over = LawfulRecursionState { drift_delta: 20, bound_epsilon: 10 };
        assert!(!is_lawful_recursion(&over));
    }

    #[test]
    fn test_certified_requires_pipeline_and_gates() {
        assert!(is_xi_certified(&clean(), &in_bound(), &passing_pipeline()));
        let no_zk = CertPipeline { zk_pass: false, ..passing_pipeline() };
        assert!(!is_xi_certified(&clean(), &in_bound(), &no_zk));
        let over = LawfulRecursionState { drift_delta: 20, bound_epsilon: 10 };
        assert!(!is_xi_certified(&clean(), &over, &passing_pipeline()));
    }

    #[test]
    fn test_license_requires_certification_and_cleanliness() {
        assert!(is_license_granted(&clean(), &in_bound(), &passing_pipeline(), &clean_flags()));
        let surv = ProhibitedFlags { is_surveillance: true, ..clean_flags() };
        assert!(!is_license_granted(&clean(), &in_bound(), &passing_pipeline(), &surv));
        let no_pirtm = CertPipeline { pirtm_pass: false, ..passing_pipeline() };
        assert!(!is_license_granted(&clean(), &in_bound(), &no_pirtm, &clean_flags()));
    }

    #[test]
    fn test_fail_closed_on_each_prohibited_flag() {
        let base = (clean(), in_bound(), passing_pipeline());
        let mut make = |f: fn() -> ProhibitedFlags| is_license_granted(&base.0, &base.1, &base.2, &f());
        assert!(!make(|| ProhibitedFlags { is_surveillance: true, ..clean_flags() }));
        assert!(!make(|| ProhibitedFlags { is_profiling: true, ..clean_flags() }));
        assert!(!make(|| ProhibitedFlags { is_exploitation: true, ..clean_flags() }));
        assert!(!make(|| ProhibitedFlags { is_weaponized: true, ..clean_flags() }));
        assert!(!make(|| ProhibitedFlags { is_black_box: true, ..clean_flags() }));
    }

    #[test]
    fn test_license_granted_implies_certified_and_clean() {
        let licence = XiLicense::new(clean(), in_bound(), passing_pipeline(), clean_flags());
        assert!(licence.is_licensed());
        assert!(licence.is_certified());
    }

    #[test]
    fn test_csl_gated_step_proceeds_lawfully_when_gate_passes() {
        let s = XiState::new(0, 5);
        let out = csl_gated_step(&clean(), 3, 1, &s);
        assert_eq!(out.epoch, 1);
        assert_eq!(out.semantic, 8);
        assert_eq!(measure_drift(&s, &out), 3);
        assert!(transition_lawful(&clean(), 3, 1, &s, 10));
    }

    #[test]
    fn test_csl_gated_step_noop_when_gate_fails() {
        let s = XiState::new(0, 5);
        let bad = CslOperators { is_silent: false, ..clean() };
        let out = csl_gated_step(&bad, 100, 9, &s);
        assert_eq!(out, s); // NO-OP: state unchanged (fail closed / Silence Clause)
        assert_eq!(measure_drift(&s, &out), 0);
        assert!(transition_lawful(&bad, 100, 9, &s, 0)); // zero drift always lawful
    }

    #[test]
    fn test_certified_step_lawful_when_pipeline_certified() {
        let s = XiState::new(0, 2);
        let out = certified_gated_step(&passing_pipeline(), 4, 1, &s);
        assert_eq!(out.epoch, 1);
        assert_eq!(out.semantic, 6);
        assert_eq!(measure_drift(&s, &out), 4);
    }

    #[test]
    fn test_certified_step_noop_on_csl_reject() {
        let s = XiState::new(0, 2);
        let rejected = CertPipeline { csl_pass: false, ..passing_pipeline() };
        let out = certified_gated_step(&rejected, 4, 1, &s);
        assert_eq!(out, s); // NO-OP: CSL stage rejected freezes the transition
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    // CSL gate soundness: passing gate entails every operator.
    #[kani::proof]
    fn verify_csl_gate_sound() {
        let ops = CslOperators { is_neutral: kani::any(), is_beneficent: kani::any(), is_silent: kani::any() };
        kani::assume(evaluate_csl_gate(&ops));
        kani::assert(ops.is_neutral, "golden: neutral holds");
        kani::assert(ops.is_beneficent, "golden: beneficent holds");
        kani::assert(ops.is_silent, "golden: silent holds");
    }

    // CSL gate completeness: all operators -> passing gate.
    #[kani::proof]
    fn verify_csl_gate_complete() {
        let ops = CslOperators { is_neutral: true, is_beneficent: true, is_silent: true };
        kani::assert(evaluate_csl_gate(&ops), "all operators pass the gate");
    }

    // CSL gate fail-closed: any single operator rejection denies.
    #[kani::proof]
    fn verify_csl_gate_fail_closed() {
        let ops = CslOperators { is_neutral: kani::any(), is_beneficent: kani::any(), is_silent: kani::any() };
        let rejected = !ops.is_neutral || !ops.is_beneficent || !ops.is_silent;
        kani::assume(rejected);
        kani::assert(!evaluate_csl_gate(&ops), "CSL gate fails closed on any operator rejection");
    }

    // Lawful recursion soundness: lawful -> drift within bound.
    #[kani::proof]
    fn verify_lawful_recursion_sound() {
        let st = LawfulRecursionState { drift_delta: kani::any(), bound_epsilon: kani::any() };
        kani::assume(is_lawful_recursion(&st));
        kani::assert(st.drift_delta <= st.bound_epsilon, "lawful recursion drift is bounded");
    }

    // Pipeline fail-closed: any rejected stage revokes certification.
    #[kani::proof]
    fn verify_pipeline_fail_closed() {
        let p = CertPipeline { pirtm_pass: kani::any(), csl_pass: kani::any(), zk_pass: kani::any() };
        let rejected = !p.pirtm_pass || !p.csl_pass || !p.zk_pass;
        kani::assume(rejected);
        kani::assert(!flow_certificates(&p), "pipeline fails closed on any rejected stage");
    }

    // License fail-closed: any prohibited characteristic denies execution.
    #[kani::proof]
    fn verify_license_fail_closed_on_prohibited() {
        let ops = CslOperators { is_neutral: true, is_beneficent: true, is_silent: true };
        let st = LawfulRecursionState { drift_delta: 0, bound_epsilon: 100 };
        let p = CertPipeline { pirtm_pass: true, csl_pass: true, zk_pass: true };
        let pf = ProhibitedFlags {
            is_surveillance: kani::any(),
            is_profiling: kani::any(),
            is_exploitation: kani::any(),
            is_weaponized: kani::any(),
            is_black_box: kani::any(),
        };
        kani::assume(is_prohibited(&pf));
        kani::assert(!is_license_granted(&ops, &st, &p, &pf), "license fails closed on any prohibited characteristic");
    }

    // License granted implies certified and not prohibited (soundness).
    #[kani::proof]
    fn verify_license_granted_implies_certified_clean() {
        let ops = CslOperators { is_neutral: kani::any(), is_beneficent: kani::any(), is_silent: kani::any() };
        let st = LawfulRecursionState { drift_delta: kani::any(), bound_epsilon: kani::any() };
        let p = CertPipeline { pirtm_pass: kani::any(), csl_pass: kani::any(), zk_pass: kani::any() };
        let pf = ProhibitedFlags {
            is_surveillance: kani::any(),
            is_profiling: kani::any(),
            is_exploitation: kani::any(),
            is_weaponized: kani::any(),
            is_black_box: kani::any(),
        };
        kani::assume(is_license_granted(&ops, &st, &p, &pf));
        kani::assert(is_xi_certified(&ops, &st, &p), "licensed implies certified");
        kani::assert(!is_prohibited(&pf), "licensed implies not prohibited");
    }

    // License completeness: certified + clean -> granted.
    #[kani::proof]
    fn verify_license_granted_if_certified_clean() {
        let ops = CslOperators { is_neutral: true, is_beneficent: true, is_silent: true };
        let st = LawfulRecursionState { drift_delta: 2, bound_epsilon: 5 };
        let p = CertPipeline { pirtm_pass: true, csl_pass: true, zk_pass: true };
        let pf = ProhibitedFlags {
            is_surveillance: false,
            is_profiling: false,
            is_exploitation: false,
            is_weaponized: false,
            is_black_box: false,
        };
        kani::assert(is_license_granted(&ops, &st, &p, &pf), "certified and clean implies licensed");
    }

    // Decision 1, fail-closed: a CSL-rejected transition is a NO-OP — the
    // state is returned unchanged (Silence Clause default).
    #[kani::proof]
    fn verify_csl_gated_step_noop_on_gate_reject() {
        let ops = CslOperators { is_neutral: kani::any(), is_beneficent: kani::any(), is_silent: kani::any() };
        let s = XiState { epoch: kani::any(), semantic: kani::any() };
        let drift: u64 = kani::any();
        let next_epoch: u64 = kani::any();
        kani::assume(!evaluate_csl_gate(&ops));
        let out = csl_gated_step(&ops, drift, next_epoch, &s);
        kani::assert(out == s, "CSL-rejected transition is NO-OP (state unchanged)");
    }

    // Decision 1: a CSL-passed transition with in-bound drift keeps the
    // measured semantic drift within the bound.
    #[kani::proof]
    fn verify_csl_gated_step_drift_bounded() {
        let ops = CslOperators { is_neutral: true, is_beneficent: true, is_silent: true };
        let s = XiState { epoch: kani::any(), semantic: kani::any() };
        let drift: u64 = kani::any();
        let bound_epsilon: u64 = kani::any();
        let next_epoch: u64 = kani::any();
        kani::assume(drift <= bound_epsilon);
        let out = csl_gated_step(&ops, drift, next_epoch, &s);
        kani::assert(
            measure_drift(&s, &out) <= bound_epsilon,
            "CSL-passed transition drift is bounded by epsilon",
        );
    }

    // Decision 2: a certified composite pipeline yields a transition whose
    // drift is bounded by the admissible epsilon.
    #[kani::proof]
    fn verify_certified_step_drift_bounded() {
        let p = CertPipeline { pirtm_pass: kani::any(), csl_pass: kani::any(), zk_pass: kani::any() };
        let s = XiState { epoch: kani::any(), semantic: kani::any() };
        let drift: u64 = kani::any();
        let bound_epsilon: u64 = kani::any();
        let next_epoch: u64 = kani::any();
        kani::assume(flow_certificates(&p));
        kani::assume(drift <= bound_epsilon);
        let out = certified_gated_step(&p, drift, next_epoch, &s);
        kani::assert(
            measure_drift(&s, &out) <= bound_epsilon,
            "certified composite transition drift is bounded by epsilon",
        );
    }

    // Decision 1: transition is declared lawful precisely when its CSL gate
    // passes under an in-bound drift (or it is a NO-OP, which is trivially
    // lawful).
    #[kani::proof]
    fn verify_transition_lawful_when_drift_bounded() {
        let ops = CslOperators { is_neutral: kani::any(), is_beneficent: kani::any(), is_silent: kani::any() };
        let s = XiState { epoch: kani::any(), semantic: kani::any() };
        let drift: u64 = kani::any();
        let bound_epsilon: u64 = kani::any();
        let next_epoch: u64 = kani::any();
        kani::assume(evaluate_csl_gate(&ops));
        kani::assume(drift <= bound_epsilon);
        kani::assert(
            transition_lawful(&ops, drift, next_epoch, &s, bound_epsilon),
            "CSL-passed transition with in-bound drift is lawful",
        );
    }

    // Decision 1, fail-closed: a CSL-rejected transition is always lawful
    // because it is a NO-OP (zero drift).
    #[kani::proof]
    fn verify_transition_lawful_noop_is_trivially_lawful() {
        let ops = CslOperators { is_neutral: kani::any(), is_beneficent: kani::any(), is_silent: kani::any() };
        let s = XiState { epoch: kani::any(), semantic: kani::any() };
        let drift: u64 = kani::any();
        let bound_epsilon: u64 = kani::any();
        let next_epoch: u64 = kani::any();
        kani::assume(!evaluate_csl_gate(&ops));
        kani::assert(
            transition_lawful(&ops, drift, next_epoch, &s, bound_epsilon),
            "CSL-rejected NO-OP transition is trivially lawful (zero drift)",
        );
    }
}
