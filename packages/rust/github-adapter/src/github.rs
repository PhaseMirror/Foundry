//! Port of `app/github_client.py` — a reqwest-based GitHub REST client
//! shaped like PyGithub's `Github` facade.
//!
//! Each method returns an [`ApiCall`] (method + URL + body), which the
//! caller materializes into a request with [`GithubClient::execute`]:
//! - `get_repo(...).get_pull(n)`      -> `GET /repos/{repo}/pulls/{number}`
//! - `pr.create_issue_comment(...)`   -> `POST /repos/{repo}/issues/{n}/comments`
//! - `pr.create_review(event=...)`    -> `POST /repos/{repo}/pulls/{n}/reviews`
//! - `repo.create_check_run(...)`     -> `POST /repos/{repo}/check-runs`
//! - `check_run.edit(...)`            -> `PATCH /repos/{repo}/check-runs/{id}`

use reqwest::Method;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// `name="Sigma Governance"` default for check runs.
pub const CHECK_RUN_NAME: &str = "Sigma Governance";

/// The body sent by `approve_pr` (`body="✅ Governance passed; transition
/// ratified."`).
pub const APPROVE_REVIEW_BODY: &str = "✅ Governance passed; transition ratified.";

/// REST fields of a pull request that `mapper.py` consumes.
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct RestPullRequest {
    pub number: u64,
    pub additions: u64,
    pub deletions: u64,
    pub changed_files: u64,
}

/// Minimal create-check-run response (only `id` is consumed downstream).
#[derive(Debug, Clone, PartialEq, Deserialize)]
pub struct CheckRunCreated {
    pub id: u64,
}

/// `output` dict for check-run edits (`title`, `summary`, `text`).
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct CheckRunOutput {
    pub title: String,
    pub summary: String,
    pub text: String,
}

/// A single GitHub REST call in materialized (method, URL, JSON body) form.
/// Kept executable via [`GithubClient::execute`] and directly assertable in
/// tests without a live server.
#[derive(Debug, Clone, PartialEq)]
pub struct ApiCall {
    pub method: Method,
    pub url: String,
    pub body: Option<Value>,
}

/// Thin wrapper matching the shape of PyGithub's `Github(token)`.
#[derive(Debug, Clone)]
pub struct GithubClient {
    pub client: reqwest::Client,
    pub api_base: String,
    pub token: String,
}

impl GithubClient {
    /// `Github(self.token or Config.GITHUB_ACCESS_TOKEN)`.
    ///
    /// An empty token is allowed (public repos only); GitHub requires a
    /// `User-Agent` header regardless.
    pub fn new(token: &str) -> Self {
        Self {
            client: reqwest::Client::new(),
            api_base: String::from("https://api.github.com"),
            token: String::from(token),
        }
    }

    /// Materializes an [`ApiCall`] into a `reqwest::RequestBuilder`.
    pub fn build(&self, call: ApiCall) -> reqwest::RequestBuilder {
        let mut builder = self.client.request(call.method, &call.url);
        builder = builder.header("User-Agent", "github-adapter");
        if !self.token.is_empty() {
            builder = builder.bearer_auth(&self.token);
        }
        if let Some(body) = call.body {
            builder = builder.json(&body);
        }
        builder
    }

    /// Executes an [`ApiCall`]; callers chain `error_for_status()` /
    /// `.json::<T>()` exactly as with a raw request builder.
    pub async fn execute(&self, call: ApiCall) -> reqwest::Result<reqwest::Response> {
        self.build(call).send().await
    }

    /// `repo.get_pull(pr_number)`.
    pub fn get_pr(&self, repo_full_name: &str, pr_number: u64) -> ApiCall {
        ApiCall {
            method: Method::GET,
            url: format!(
                "{}/repos/{}/pulls/{}",
                self.api_base, repo_full_name, pr_number
            ),
            body: None,
        }
    }

    /// `pr.create_issue_comment(message)`.
    pub fn post_comment(&self, repo_full_name: &str, pr_number: u64, message: &str) -> ApiCall {
        ApiCall {
            method: Method::POST,
            url: format!(
                "{}/repos/{}/issues/{}/comments",
                self.api_base, repo_full_name, pr_number
            ),
            body: Some(json!({ "body": message })),
        }
    }

    /// `pr.create_review(event="APPROVE", body=...)`.
    pub fn approve_pr(&self, repo_full_name: &str, pr_number: u64) -> ApiCall {
        ApiCall {
            method: Method::POST,
            url: format!(
                "{}/repos/{}/pulls/{}/reviews",
                self.api_base, repo_full_name, pr_number
            ),
            body: Some(json!({ "event": "APPROVE", "body": APPROVE_REVIEW_BODY })),
        }
    }

    /// `pr.create_review(event="REQUEST_CHANGES", body=message)`.
    pub fn request_changes(&self, repo_full_name: &str, pr_number: u64, message: &str) -> ApiCall {
        ApiCall {
            method: Method::POST,
            url: format!(
                "{}/repos/{}/pulls/{}/reviews",
                self.api_base, repo_full_name, pr_number
            ),
            body: Some(json!({ "event": "REQUEST_CHANGES", "body": message })),
        }
    }

    /// `repo.create_check_run(name, head_sha, status, started_at)`.
    ///
    /// `started_at` follows the Python `datetime.now(timezone.utc).isoformat()`
    /// string form when provided.
    pub fn create_check_run(
        &self,
        repo_full_name: &str,
        head_sha: &str,
        name: &str,
        status: &str,
        started_at: Option<&str>,
    ) -> ApiCall {
        let mut body = json!({
            "name": name,
            "head_sha": head_sha,
            "status": status,
        });
        if let Some(started_at) = started_at {
            body["started_at"] = Value::String(String::from(started_at));
        }
        ApiCall {
            method: Method::POST,
            url: format!("{}/repos/{}/check-runs", self.api_base, repo_full_name),
            body: Some(body),
        }
    }

    /// `repo.get_check_run(id).edit(status, conclusion, completed_at, output)`.
    pub fn update_check_run(
        &self,
        repo_full_name: &str,
        check_run_id: u64,
        status: &str,
        conclusion: &str,
        completed_at: Option<&str>,
        output: Option<&CheckRunOutput>,
    ) -> ApiCall {
        let mut body = json!({
            "status": status,
            "conclusion": conclusion,
        });
        if let Some(completed_at) = completed_at {
            body["completed_at"] = Value::String(String::from(completed_at));
        }
        if let Some(output) = output {
            body["output"] = serde_json::to_value(output).unwrap_or(Value::Null);
        }
        ApiCall {
            method: Method::PATCH,
            url: format!(
                "{}/repos/{}/check-runs/{}",
                self.api_base, repo_full_name, check_run_id
            ),
            body: Some(body),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn client() -> GithubClient {
        GithubClient::new("test-token")
    }

    #[test]
    fn get_pr_uses_repos_pulls() {
        let call = client().get_pr("owner/repo", 42);
        assert_eq!(call.method, Method::GET);
        assert_eq!(call.url, "https://api.github.com/repos/owner/repo/pulls/42");
        assert_eq!(call.body, None);
    }

    #[test]
    fn post_comment_uses_issues_comments() {
        let call = client().post_comment("owner/repo", 9, "hello");
        assert_eq!(call.method, Method::POST);
        assert!(call.url.contains("/issues/9/comments"));
        assert_eq!(call.body, Some(json!({ "body": "hello" })));
    }

    #[test]
    fn approve_posts_approve_review() {
        let call = client().approve_pr("owner/repo", 3);
        assert_eq!(call.method, Method::POST);
        assert_eq!(
            call.body,
            Some(json!({ "event": "APPROVE", "body": APPROVE_REVIEW_BODY }))
        );
    }

    #[test]
    fn request_changes_posts_request_changes_review() {
        let call = client().request_changes("owner/repo", 3, "nope");
        assert_eq!(
            call.body,
            Some(json!({ "event": "REQUEST_CHANGES", "body": "nope" }))
        );
    }

    #[test]
    fn create_check_run_builds_payload() {
        let call = client().create_check_run(
            "owner/repo",
            "abc123",
            CHECK_RUN_NAME,
            "in_progress",
            Some("2026-01-01T00:00:00+00:00"),
        );
        assert_eq!(call.method, Method::POST);
        assert!(call.url.ends_with("/check-runs"));
        assert_eq!(
            call.body,
            Some(json!({
                "name": CHECK_RUN_NAME,
                "head_sha": "abc123",
                "status": "in_progress",
                "started_at": "2026-01-01T00:00:00+00:00"
            }))
        );
    }

    #[test]
    fn update_check_run_builds_patch() {
        let output = CheckRunOutput {
            title: String::from("t"),
            summary: String::from("s"),
            text: String::from("x"),
        };
        let call = client().update_check_run(
            "owner/repo",
            12,
            "completed",
            "success",
            Some("2026-01-01T00:00:00+00:00"),
            Some(&output),
        );
        assert_eq!(call.method, Method::PATCH);
        assert_eq!(
            call.url,
            "https://api.github.com/repos/owner/repo/check-runs/12"
        );
        assert_eq!(
            call.body,
            Some(json!({
                "status": "completed",
                "conclusion": "success",
                "completed_at": "2026-01-01T00:00:00+00:00",
                "output": { "title": "t", "summary": "s", "text": "x" }
            }))
        );
    }
}
