//! Webhook event payload parsing + event/action filters.

use github_adapter::payload::{is_supported_action, is_supported_event, PullRequestEvent};
use serde_json::json;

#[test]
fn parses_pull_request_event() {
    let raw = json!({
        "action": "opened",
        "number": 7,
        "pull_request": {
            "number": 7,
            "head": { "sha": "abc123" },
            "additions": 10,
            "deletions": 2,
            "changed_files": 3
        },
        "repository": { "full_name": "owner/repo" }
    })
    .to_string();

    let event: PullRequestEvent = serde_json::from_str(&raw).unwrap();
    assert_eq!(event.action, "opened");
    assert_eq!(event.pull_request.number, 7);
    assert_eq!(event.pull_request.head.sha, "abc123");
    assert_eq!(event.pull_request.additions, 10);
    assert_eq!(event.pull_request.deletions, 2);
    assert_eq!(event.pull_request.changed_files, 3);
    assert_eq!(event.repository.full_name, "owner/repo");
}

#[test]
fn optional_metrics_default_to_zero() {
    // Review events may omit the diff counters; `get_pr` re-fetches anyway.
    let raw = json!({
        "action": "submitted",
        "pull_request": { "number": 9, "head": { "sha": "def" } },
        "repository": { "full_name": "owner/repo" }
    })
    .to_string();

    let event: PullRequestEvent = serde_json::from_str(&raw).unwrap();
    assert_eq!(event.pull_request.additions, 0);
    assert_eq!(event.pull_request.changed_files, 0);
}

#[test]
fn event_filters_match_main_py() {
    assert!(is_supported_event(Some("pull_request")));
    assert!(is_supported_event(Some("pull_request_review")));
    assert!(!is_supported_event(Some("push")));
    assert!(!is_supported_event(None));
}

#[test]
fn action_filters_match_main_py() {
    for action in ["opened", "synchronize", "reopened", "edited"] {
        assert!(is_supported_action(action), "{action} should be supported");
    }
    for action in ["closed", "submitted", "converted_to_draft"] {
        assert!(!is_supported_action(action), "{action} should be ignored");
    }
}
