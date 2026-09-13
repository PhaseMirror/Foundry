//! Decision-table tests for `app/main.py` step 6-8 semantics.

use github_adapter::mcp::TransitionResponse;
use github_adapter::webhook::{dispatch_error, dispatch_response, success_comment, utc_now_iso};
use serde_json::json;

fn response(status: &str) -> TransitionResponse {
    TransitionResponse {
        status: String::from(status),
        witness_id: None,
        ratified_block: None,
        breach_type: None,
        details: None,
        conflict_log_id: None,
    }
}

#[test]
fn ratified_simulate_marks_success_no_approval() {
    let mut r = response("ratified");
    r.witness_id = Some(String::from("w-7"));
    r.ratified_block = Some(json!({ "id": "blk-3" }));

    let d = dispatch_response(&r, "simulate", 12);

    assert_eq!(d.conclusion, "success");
    assert_eq!(d.output.title, "Sigma Governance Passed");
    assert_eq!(
        d.output.summary,
        "Transition ratified successfully.\nWitness: w-7"
    );
    assert_eq!(d.output.text, "Ratified block: {\"id\":\"blk-3\"}");
    assert!(!d.approve, "simulate mode never approves");
    assert_eq!(
        d.comment.as_deref(),
        Some("✅ Governance ratified (check run #12)")
    );
    assert_eq!(d.request_changes, None);
}

#[test]
fn simulated_reports_no_witness() {
    let d = dispatch_response(&response("simulated"), "simulate", 3);

    assert_eq!(d.conclusion, "success");
    assert_eq!(
        d.output.summary,
        "Transition simulated successfully.\nNo witness (simulation)"
    );
    assert_eq!(d.output.text, "Simulation result.");
    assert!(!d.approve);
}

#[test]
fn commit_mode_approves_only_on_ratified() {
    let ratified = dispatch_response(&response("ratified"), "commit", 1);
    assert!(ratified.approve);

    let simulated = dispatch_response(&response("simulated"), "commit", 1);
    assert!(
        !simulated.approve,
        "simulated cannot approve even in commit"
    );
}

#[test]
fn dissonance_trap_requests_changes() {
    let mut r = response("dissonance_trap");
    r.breach_type = Some(String::from("rl_collision"));
    r.details = Some(String::from("r_sc collides with pr-5"));

    let d = dispatch_response(&r, "simulate", 4);

    assert_eq!(d.conclusion, "failure");
    assert_eq!(d.output.title, "Sigma Governance Violation");
    assert_eq!(d.output.summary, "Breach: rl_collision");
    assert_eq!(
        d.request_changes.as_deref(),
        Some("🚫 Governance dissonance trap: rl_collision\nDetails: r_sc collides with pr-5")
    );
    // conflict_log_id None -> "Not logged".
    assert_eq!(
        d.output.text,
        "Details: r_sc collides with pr-5\nConflict log: Not logged"
    );
}

#[test]
fn dissonance_trap_logs_conflict_id_when_present() {
    let mut r = response("dissonance_trap");
    r.breach_type = Some(String::from("trap"));
    r.details = Some(String::from("x"));
    r.conflict_log_id = Some(String::from("cl-2"));

    let d = dispatch_response(&r, "commit", 4);
    assert!(d.output.text.ends_with("Conflict log: cl-2"));
    assert!(!d.approve);
}

#[test]
fn unknown_status_is_neutral() {
    let d = dispatch_response(&response("something_new"), "simulate", 1);

    assert_eq!(d.conclusion, "neutral");
    assert_eq!(d.output.title, "Sigma Governance Unknown");
    assert_eq!(d.output.summary, "Unexpected response status.");
    assert!(!d.approve);
    assert_eq!(d.comment, None);
    assert_eq!(d.request_changes, None);
}

#[test]
fn error_branch_fails_check_run_and_comment() {
    let (d, detail) = dispatch_error("boom");

    assert_eq!(detail, "boom");
    assert_eq!(d.conclusion, "failure");
    assert_eq!(d.output.title, "Sigma Governance Failed");
    assert_eq!(d.output.summary, "Internal error: boom");
    assert_eq!(
        d.comment.as_deref(),
        Some("❌ Governance evaluation failed: boom")
    );
    assert_eq!(d.request_changes, None);
    assert!(!d.approve);
}

#[test]
fn success_comment_pins_check_run_id() {
    assert_eq!(
        success_comment("ratified", 12),
        "✅ Governance ratified (check run #12)"
    );
}

#[test]
fn utc_now_iso_matches_python_isoformat_shape() {
    let now = utc_now_iso();
    // datetime.now(timezone.utc).isoformat() -> "...T...Z-like offset +00:00"?
    // Python emits "+00:00"; chrono's SecondsFormat::Micros with UTC uses the
    // same offset rendering.
    assert!(now.ends_with("+00:00"), "got {now}");
    assert!(
        now.as_bytes().contains(&b'.'),
        "microseconds present: {now}"
    );
}
