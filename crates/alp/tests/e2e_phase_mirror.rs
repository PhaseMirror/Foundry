//! End-to-end test harness for ADR-101: native ALP/CNL inference in place
//! of an LLM on the Phase Mirror agent control path.
//!
//! Run with: `cargo test -p alp-rs --test e2e_phase_mirror`
//! (the crate is a member of the `Prime` workspace).
//!
//! Categories:
//!   1. CNL parse determinism & shape
//!   2. Native CNL -> ALP -> Rta pipeline (deterministic, replayable)
//!   3. LLM-draft normalization routes through the CNL channel (off-path)
//!   4. Fail-closed: malformed CNL and contradictory policies are rejected

use alp_rs::cnl::{CnlCompiler, CnlError};
use alp_rs::engine::{AlpEngine, EngineError};
use alp_rs::llm::LlmDraft;
use alp_rs::{AlpPolicy, AlpRule, EvalError, RtaMetric, SystemState};

const SAMPLE_CNL: &str = "policy phase-mirror-governance
increase multiplicity by 1.5
decrease arta defect by 0.5";

fn base_state() -> SystemState {
    SystemState {
        arta_defect: 10.0,
        multiplicity_measure: 20.0,
    }
}

// --- 1. CNL parse determinism & shape -------------------------------------

#[test]
fn e2e_cnl_parse_is_deterministic() {
    let a = CnlCompiler::parse(SAMPLE_CNL).expect("sample CNL is well-formed");
    let b = CnlCompiler::parse(SAMPLE_CNL).expect("sample CNL is well-formed");
    assert_eq!(a, b, "parse must be deterministic (ADR-101 Lemma 1)");
    assert_eq!(a.name, "phase-mirror-governance");
    assert_eq!(
        a.rules,
        vec![
            AlpRule::IncreaseMultiplicity(1.5),
            AlpRule::DecreaseArtaDefect(0.5),
        ]
    );
}

// --- 2. Native CNL -> ALP -> Rta pipeline --------------------------------

#[test]
fn e2e_native_path_cnl_to_rta() {
    let state = base_state();
    let engine = AlpEngine;
    let policy = AlpEngine::load_policy(SAMPLE_CNL).expect("well-formed CNL");
    let rta = engine.evaluate(&policy, &state).expect("no contradiction");
    // 20 + 1.5 - (10 - 0.5) = 12.0
    assert!((rta.value - 12.0).abs() < 1e-9, "rta = {:.4}", rta.value);

    // Deterministic re-run: identical inputs -> identical result (replayable).
    let rta2 = engine.evaluate(&policy, &state).expect("no contradiction");
    assert_eq!(rta.value, rta2.value);
}

#[test]
fn e2e_evaluate_cnl_end_to_end() {
    let state = SystemState {
        arta_defect: 2.0,
        multiplicity_measure: 8.0,
    };
    let engine = AlpEngine;
    let (policy, rta) = engine
        .evaluate_cnl(&state, SAMPLE_CNL)
        .expect("full pipeline succeeds");
    assert_eq!(policy.name, "phase-mirror-governance");
    // 8 + 1.5 - (2 - 0.5) = 8.0
    assert!((rta.value - 8.0).abs() < 1e-9, "rta = {:.4}", rta.value);
}

#[test]
fn e2e_rta_preserved_or_improved() {
    // A pure multiplicity increase must not lower the Rta metric.
    let state = SystemState {
        arta_defect: 4.0,
        multiplicity_measure: 5.0,
    };
    let engine = AlpEngine;
    let policy = AlpEngine::load_policy("policy up\nincrease multiplicity by 2.0")
        .expect("well-formed CNL");
    let rta = engine.evaluate(&policy, &state).expect("no contradiction");
    assert!(rta.value >= (state.multiplicity_measure - state.arta_defect));
}

// --- 3. LLM-draft normalization (off-path) ------------------------------

#[test]
fn e2e_llm_draft_normalizes_through_cnl() {
    // An LLM emits prose + fenced CNL. It must be re-normalized, never admitted.
    let llm_output = "Sure! Here is the policy you asked for:\n```\npolicy llm-drafted\ndecrease arta defect by 0.25\n```\nLet me know if you need changes.";
    let draft = LlmDraft {
        raw: llm_output.to_string(),
    };
    let normalized = draft
        .normalize()
        .expect("LLM draft must route through CNL and compile");
    let direct = CnlCompiler::parse("policy llm-drafted\ndecrease arta defect by 0.25")
        .expect("inner CNL is well-formed");
    assert_eq!(
        normalized, direct,
        "normalize must equal parse(to_cnl(raw)) (ADR-101 invariant)"
    );
    assert_eq!(normalized.rules, vec![AlpRule::DecreaseArtaDefect(0.25)]);
}

#[test]
fn e2e_llm_nan_is_rejected_not_admitted() {
    // An LLM emitting a non-finite magnitude must NOT slip through.
    let draft = LlmDraft {
        raw: "policy bad\ndecrease arta defect by NaN".to_string(),
    };
    assert!(
        draft.normalize().is_err(),
        "non-finite LLM magnitude must be rejected"
    );
}

// --- 4. Fail-closed ------------------------------------------------------

#[test]
fn e2e_fail_closed_on_malformed_cnl() {
    let bad = "policy x\nincrease multiplicty by 1.0\n"; // typo -> unknown directive
    let parsed = CnlCompiler::parse(bad);
    assert!(
        matches!(parsed, Err(CnlError::UnknownDirective { .. })),
        "malformed CNL must be rejected, not loosely interpreted"
    );

    let engine = AlpEngine;
    let state = SystemState {
        arta_defect: 0.0,
        multiplicity_measure: 0.0,
    };
    let end_to_end = engine.evaluate_cnl(&state, bad);
    assert!(
        matches!(end_to_end, Err(EngineError::Cnl(_))),
        "engine must propagate the compile failure (no silent admission)"
    );
}

#[test]
fn e2e_contradictory_policy_rejected() {
    // Mixing NoOp with a concrete perturbation is contradictory.
    let contradictory = "policy bad\nincrease multiplicity by 1.0\nnoop";
    let engine = AlpEngine;
    let state = SystemState {
        arta_defect: 0.0,
        multiplicity_measure: 0.0,
    };
    let res = engine.evaluate_cnl(&state, contradictory);
    assert!(
        matches!(res, Err(EngineError::Eval(EvalError::ContradictoryPolicy))),
        "contradictory policy must be vetoed (fail-closed)"
    );
}

#[test]
fn e2e_empty_cnl_rejected() {
    assert!(matches!(
        CnlCompiler::parse("   \n  "),
        Err(CnlError::EmptyPolicy)
    ));
    assert!(matches!(
        CnlCompiler::parse("increase multiplicity by 1.0"),
        Err(CnlError::MissingHeader)
    ));
}

// Sanity re-export check so the public surface stays stable for agents.
#[allow(dead_code)]
fn _assert_surface() {
    let _: fn(&str) -> Result<AlpPolicy, CnlError> = AlpEngine::load_policy;
    let _: RtaMetric = RtaMetric { value: 0.0 };
}
