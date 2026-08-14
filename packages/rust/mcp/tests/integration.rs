// crates/mcp/tests/integration.rs
use assert_matches::assert_matches;
use multiplicity_mcp::schema::{EvaluateTransitionRequest, EvaluateTransitionResponse, EvaluationMode};
use multiplicity_mcp::archivum::InMemoryArchivum;
use sigma::{SigmaKernel, StateTransition, PolicyEngine, WitnessLedger};
use std::sync::Arc;
use tokio::sync::Mutex;

/// A helper that constructs a valid (passing) transition for testing.
fn valid_transition() -> StateTransition {
    StateTransition {
        id: "tx-pass-001".to_string(),
        r_sc: 47.06998778,
        l_eff: 0.14,
    }
}

/// A helper that constructs a transition that will trigger a dissonance trap.
fn invalid_transition() -> StateTransition {
    StateTransition {
        id: "tx-fail-001".to_string(),
        r_sc: 47.06998778, // tau_r is correct
        l_eff: 1.5,        // l_eff_max is 1.0 (or 0.15 depending on thresholds), 1.5 will fail
    }
}

/// Helper to get a kernel
fn get_test_kernel() -> SigmaKernel {
    let engine = PolicyEngine::new();
    let ledger = WitnessLedger::new("test_witnesses.jsonl");
    SigmaKernel::from_lean_export(engine, ledger, "dummy.postcard", "dummy.json")
}

#[tokio::test]
async fn test_simulate_valid_transition() {
    let kernel = Arc::new(Mutex::new(get_test_kernel()));
    let archivum: Arc<dyn multiplicity_mcp::archivum::Archivum> = Arc::new(InMemoryArchivum::new());

    let req = EvaluateTransitionRequest {
        agent_request_id: "test-sim-001".to_string(),
        transition_data: valid_transition(),
        mode: EvaluationMode::Simulate,
    };

    let response = multiplicity_mcp::handler::handle_evaluate_transition(&kernel, &archivum, req).await;

    assert_matches!(response, EvaluateTransitionResponse::Simulated { .. });
}

#[tokio::test]
async fn test_commit_valid_transition() {
    let kernel = Arc::new(Mutex::new(get_test_kernel()));
    let archivum: Arc<dyn multiplicity_mcp::archivum::Archivum> = Arc::new(InMemoryArchivum::new());

    let req = EvaluateTransitionRequest {
        agent_request_id: "test-commit-001".to_string(),
        transition_data: valid_transition(),
        mode: EvaluationMode::Commit,
    };

    let response = multiplicity_mcp::handler::handle_evaluate_transition(&kernel, &archivum, req).await;

    assert_matches!(response, EvaluateTransitionResponse::Ratified { .. });
}

#[tokio::test]
async fn test_simulate_dissonance_trap() {
    let kernel = Arc::new(Mutex::new(get_test_kernel()));
    let archivum: Arc<dyn multiplicity_mcp::archivum::Archivum> = Arc::new(InMemoryArchivum::new());

    let req = EvaluateTransitionRequest {
        agent_request_id: "test-trap-001".to_string(),
        transition_data: invalid_transition(),
        mode: EvaluationMode::Simulate,
    };

    let response = multiplicity_mcp::handler::handle_evaluate_transition(&kernel, &archivum, req).await;

    assert_matches!(response, EvaluateTransitionResponse::DissonanceTrap { conflict_log_id: None, .. });
}

#[tokio::test]
async fn test_commit_dissonance_trap_logs_conflict() {
    let kernel = Arc::new(Mutex::new(get_test_kernel()));
    let archivum: Arc<dyn multiplicity_mcp::archivum::Archivum> = Arc::new(InMemoryArchivum::new());

    let req = EvaluateTransitionRequest {
        agent_request_id: "test-trap-commit-001".to_string(),
        transition_data: invalid_transition(),
        mode: EvaluationMode::Commit,
    };

    let response = multiplicity_mcp::handler::handle_evaluate_transition(&kernel, &archivum, req).await;

    assert_matches!(response, EvaluateTransitionResponse::DissonanceTrap { conflict_log_id: Some(_), .. });
}
