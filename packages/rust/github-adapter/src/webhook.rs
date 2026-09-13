//! Port of `app/main.py` orchestration and decision logic.
//!
//! The decision table (`dispatch_response`, `dispatch_error`) and the
//! orchestration (`evaluate_pull_request`) are separated so the branch
//! semantics (ratified / simulated / dissonance_trap / unknown / error) are
//! unit-testable without a live GitHub or MCP connection.

use crate::config::evaluation_mode;
use crate::config::Config;
use crate::github::{CheckRunOutput, GithubClient, RestPullRequest};
use crate::mapper::{map_pr_to_transition, PullRequestMetrics};
use crate::mcp::{McpClient, TransitionRequest, TransitionResponse};
use crate::payload::PullRequestEvent;
use chrono::SecondsFormat::Micros;
use chrono::Utc;

/// `datetime.now(timezone.utc).isoformat()` — microsecond RFC3339 with a
/// `+00:00` offset (Python uses the explicit offset form, never `Z`).
pub fn utc_now_iso() -> String {
    Utc::now().to_rfc3339_opts(Micros, false)
}

/// Everything the adapter does with a verdict, as a pure value.
#[derive(Debug, Clone, PartialEq)]
pub struct Dispatch {
    /// The `conclusion` passed to the final check-run update.
    pub conclusion: String,
    /// The `output` dict for the final check-run update (always set, mirroring
    /// main.py's per-branch dicts).
    pub output: CheckRunOutput,
    /// `github_client.approve_pr(pr)` when set.
    pub approve: bool,
    /// `github_client.post_comment(pr, msg)` when set (audit comment).
    pub comment: Option<String>,
    /// `github_client.request_changes(pr, msg)` when set.
    pub request_changes: Option<String>,
}

/// Builds the check-run `output` for a successful (ratified/simulated) result.
///
/// `summary` mirrors the Python f-string:
/// `"Transition {status} successfully.\n" +
///  ("Witness: {witness_id}" if witness_id else "No witness (simulation)")`.
pub fn success_output(response: &TransitionResponse) -> CheckRunOutput {
    let witness = match &response.witness_id {
        Some(id) => format!("Witness: {id}"),
        None => String::from("No witness (simulation)"),
    };
    let text = match &response.ratified_block {
        Some(block) => format!("Ratified block: {block}"),
        None => String::from("Simulation result."),
    };
    CheckRunOutput {
        title: String::from("Sigma Governance Passed"),
        summary: format!("Transition {} successfully.\n{witness}", response.status),
        text,
    }
}

fn violation_output(response: &TransitionResponse) -> CheckRunOutput {
    let conflict = response
        .conflict_log_id
        .clone()
        .unwrap_or_else(|| String::from("Not logged"));
    CheckRunOutput {
        title: String::from("Sigma Governance Violation"),
        summary: format!(
            "Breach: {}",
            response.breach_type.clone().unwrap_or_default()
        ),
        text: format!(
            "Details: {}\nConflict log: {conflict}",
            response.details.clone().unwrap_or_default()
        ),
    }
}

/// The result type of `evaluate_transition` + its side effects, mirroring
/// main.py's `conclusion` variable.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Outcome {
    /// Normal branch — the check run is updated and the HTTP handler returns
    /// `{"status": conclusion}`.
    Evaluated(String),
    /// The MCP call raised — check run marked failure + error comment, and
    /// the HTTP handler returns `500 {"detail": <str(e)>}`.
    Failed(String),
}

/// Main.py's step 7 decision table (status -> conclusion/output/effects).
///
/// `check_run_id` is known from step 4 and feeds the audit comment
/// (`f"✅ Governance {status} (check run #{check_run.id})"`).
pub fn dispatch_response(response: &TransitionResponse, mode: &str, check_run_id: u64) -> Dispatch {
    match response.status.as_str() {
        "ratified" | "simulated" => {
            let approve = mode == "commit" && response.status == "ratified";
            Dispatch {
                conclusion: String::from("success"),
                output: success_output(response),
                approve,
                comment: Some(success_comment(&response.status, check_run_id)),
                request_changes: None,
            }
        }
        "dissonance_trap" => {
            let breach = response.breach_type.clone().unwrap_or_default();
            let details = response.details.clone().unwrap_or_default();
            Dispatch {
                conclusion: String::from("failure"),
                output: violation_output(response),
                approve: false,
                comment: None,
                request_changes: Some(format!(
                    "🚫 Governance dissonance trap: {breach}\nDetails: {details}"
                )),
            }
        }
        _ => Dispatch {
            conclusion: String::from("neutral"),
            output: CheckRunOutput {
                title: String::from("Sigma Governance Unknown"),
                summary: String::from("Unexpected response status."),
                text: String::new(),
            },
            approve: false,
            comment: None,
            request_changes: None,
        },
    }
}

/// The exception branch (main.py step 6 catch): failure output + error comment.
pub fn dispatch_error(error: &str) -> (Dispatch, String) {
    let output = CheckRunOutput {
        title: String::from("Sigma Governance Failed"),
        summary: format!("Internal error: {error}"),
        text: String::from(
            "The governance engine encountered an error. Please check the server logs.",
        ),
    };
    let dispatch = Dispatch {
        conclusion: String::from("failure"),
        output,
        approve: false,
        comment: Some(format!("❌ Governance evaluation failed: {error}")),
        request_changes: None,
    };
    // `HTTPException(status_code=500, detail=str(e))`.
    (dispatch, String::from(error))
}

/// Full `POST /webhook` flow for supported pull-request events (main.py steps
/// 3-8), wired to real clients.
pub async fn run_transition(
    github: &GithubClient,
    mcp: &mut McpClient,
    event: &PullRequestEvent,
    config: &Config,
) -> Result<Outcome, anyhow::Error> {
    let repo = &event.repository.full_name;
    let number = event.pull_request.number;
    let head_sha = &event.pull_request.head.sha;

    // 3. Get fresh PR metrics (extra metadata not necessarily in the payload).
    let pr_json = github
        .execute(github.get_pr(repo, number))
        .await?
        .error_for_status()?
        .json::<RestPullRequest>()
        .await?;

    // 4. Create an in-progress Check Run.
    let started_at = utc_now_iso();
    let check_run_json = github
        .execute(github.create_check_run(
            repo,
            head_sha,
            crate::github::CHECK_RUN_NAME,
            "in_progress",
            Some(&started_at),
        ))
        .await?
        .error_for_status()?
        .json::<crate::github::CheckRunCreated>()
        .await?;
    let check_run_id = check_run_json.id;

    // 5. Map PR -> StateTransition serialization.
    let metrics = PullRequestMetrics {
        number: pr_json.number,
        additions: pr_json.additions,
        deletions: pr_json.deletions,
        changed_files: pr_json.changed_files,
    };
    let transition = map_pr_to_transition(&metrics);
    let mode = evaluation_mode(config);
    let mcp_request = TransitionRequest {
        agent_request_id: format!("github-check-{check_run_id}"),
        transition_data: serde_json::to_value(&transition)?,
        mode: mode.clone(),
    };

    // 6. Evaluate via MCP.
    let response = match mcp.evaluate_transition(&mcp_request).await {
        Ok(response) => response,
        Err(error) => {
            let (dispatch, detail) = dispatch_error(&error.to_string());
            apply_effectful(github, repo, number, check_run_id, &dispatch).await?;
            return Ok(Outcome::Failed(detail));
        }
    };

    // 7-8. Decision table + final check-run update.
    let dispatch = dispatch_response(&response, &mode, check_run_id);
    apply_effectful(github, repo, number, check_run_id, &dispatch).await?;

    Ok(Outcome::Evaluated(dispatch.conclusion))
}

/// Applies a [`Dispatch`] through the GitHub client (comments, approvals,
/// reviews) and updates the check run to `completed`.
async fn apply_effectful(
    github: &GithubClient,
    repo: &str,
    number: u64,
    check_run_id: u64,
    dispatch: &Dispatch,
) -> Result<(), anyhow::Error> {
    if let Some(comment) = &dispatch.comment {
        github
            .execute(github.post_comment(repo, number, comment))
            .await?
            .error_for_status()?;
    }
    if dispatch.approve {
        github.execute(github.approve_pr(repo, number)).await?;
    }
    if let Some(message) = &dispatch.request_changes {
        github
            .execute(github.request_changes(repo, number, message))
            .await?;
    }
    let completed_at = utc_now_iso();
    github
        .execute(github.update_check_run(
            repo,
            check_run_id,
            "completed",
            &dispatch.conclusion,
            Some(&completed_at),
            Some(&dispatch.output),
        ))
        .await?
        .error_for_status()?;
    Ok(())
}

/// Builds the audit comment for a successful verdict:
/// `"✅ Governance {status} (check run #{id})"`.
pub fn success_comment(status: &str, check_run_id: u64) -> String {
    format!("✅ Governance {status} (check run #{check_run_id})")
}
