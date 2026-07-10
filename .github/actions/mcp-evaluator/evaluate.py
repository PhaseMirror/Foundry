import os
import sys
import json
from datetime import datetime, timezone

# Make project root available for imports (client, mapper, config, github client)
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

# Import the shared components
from config import Config
from mcp_client import SigmaMCPClient, TransitionRequest
from agents.github_adapter.app.mapper import map_pr_to_transition
from agents.github_adapter.app.github_client import GitHubClient


def main():
    # Load GitHub event payload (provided by the workflow)
    event_path = os.getenv('GITHUB_EVENT_PATH')
    if not event_path:
        raise RuntimeError('GITHUB_EVENT_PATH not set')
    with open(event_path, 'r', encoding='utf-8') as f:
        event = json.load(f)

    # Basic sanity check – we only handle pull_request events
    if event.get('pull_request') is None:
        print('::notice ::No pull_request data – skipping action')
        return

    pr_data = event['pull_request']
    repo_full = event['repository']['full_name']
    pr_number = pr_data['number']
    head_sha = pr_data['head']['sha']

    # Initialise GitHub client (needs the access token)
    gh = GitHubClient()
    pr = gh.get_pr(repo_full, pr_number)

    # Create a pending check run so the UI shows progress
    check_run = gh.create_check_run(
        repo_full_name=repo_full,
        head_sha=head_sha,
        name="Sigma Governance",
        status="in_progress",
        started_at=datetime.now(timezone.utc).isoformat(),
    )

    # Map PR to a StateTransition dict (same logic as the long‑running adapter)
    transition_dict = map_pr_to_transition(pr)
    mode = "simulate" if Config.EVALUATION_MODE == "simulate" else "commit"

    # Initialise the MCP client (TCP connection – env vars already set by entrypoint)
    client = SigmaMCPClient(host=os.getenv('MCP_HOST'), port=int(os.getenv('MCP_PORT')))
    # Use async context manager manually (since we are not in an async function)
    import asyncio
    async def evaluate():
        async with client:
            req = TransitionRequest(
                agent_request_id=f"github-check-{check_run.id}",
                transition_data=transition_dict,
                mode=mode,
            )
            resp = await client.evaluate_transition(req)
            return resp
    response = asyncio.run(evaluate())

    # Build the check run output based on the MCP response
    if response.status in ("ratified", "simulated"):
        conclusion = "success"
        output = {
            "title": "Sigma Governance Passed",
            "summary": f"Transition {response.status} successfully.\n" +
                       (f"Witness: {response.witness_id}" if response.witness_id else "No witness (simulation)"),
            "text": f"Ratified block: {response.ratified_block}" if response.ratified_block else "Simulation result.",
        }
        if mode == "commit" and response.status == "ratified":
            gh.approve_pr(pr)
    elif response.status == "dissonance_trap":
        conclusion = "failure"
        output = {
            "title": "Sigma Governance Violation",
            "summary": f"Breach: {response.breach_type}",
            "text": f"Details: {response.details}\nConflict log: {response.conflict_log_id or 'Not logged'}",
        }
        gh.request_changes(pr, f"🚫 Governance dissonance trap: {response.breach_type}\nDetails: {response.details}")
    else:
        conclusion = "neutral"
        output = {"title": "Sigma Governance Unknown", "summary": "Unexpected response status."}

    # Update the check run with the final result
    gh.update_check_run(
        repo_full_name=repo_full,
        check_run_id=check_run.id,
        status="completed",
        conclusion=conclusion,
        completed_at=datetime.now(timezone.utc).isoformat(),
        output=output,
    )

    # Emit an action output for downstream steps if desired
    print(f"::set-output name=conclusion::{conclusion}")


if __name__ == "__main__":
    main()
