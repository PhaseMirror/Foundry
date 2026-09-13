//! Webhook event payload types (the subset `main.py` consumes).

use serde::Deserialize;

/// Top-level GitHub webhook payload for `pull_request` / `pull_request_review`
/// events. Only the fields read by `main.py` are modeled; unknown fields are
/// ignored.
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct PullRequestEvent {
    pub action: String,
    #[serde(rename = "pull_request")]
    pub pull_request: PullRequestData,
    pub repository: RepositoryData,
}

/// The `pull_request` object inside a webhook payload. `additions`,
/// `deletions` and `changed_files` are optional (GitHub may omit them for
/// some review events); the live PR is fetched anyway via `get_pr`.
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct PullRequestData {
    pub number: u64,
    pub head: HeadCommit,
    #[serde(default)]
    pub additions: u64,
    #[serde(default)]
    pub deletions: u64,
    #[serde(default)]
    pub changed_files: u64,
}

/// `pull_request.head` — the head commit of the PR.
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct HeadCommit {
    pub sha: String,
}

/// `repository` — `full_name` (owner/repo).
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct RepositoryData {
    #[serde(rename = "full_name")]
    pub full_name: String,
}

/// `True` when `event_type in ["pull_request", "pull_request_review"]`
/// (main.py step 2).
pub fn is_supported_event(event_type: Option<&str>) -> bool {
    matches!(event_type, Some("pull_request" | "pull_request_review"))
}

/// `True` when `action in ["opened", "synchronize", "reopened", "edited"]`
/// (main.py step 2).
pub fn is_supported_action(action: &str) -> bool {
    matches!(action, "opened" | "synchronize" | "reopened" | "edited")
}
