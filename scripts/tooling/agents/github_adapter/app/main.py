import asyncio
import hashlib
import hmac
import json
from datetime import datetime, timezone
from fastapi import FastAPI, Request, HTTPException
from contextlib import asynccontextmanager
from config import Config
from .github_client import GitHubClient
from .mapper import map_pr_to_transition

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from mcp_client import SigmaMCPClient, TransitionRequest

global github_client, mcp_client
github_client = None
mcp_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global github_client, mcp_client
    github_client = GitHubClient()
    if Config.MCP_HOST and Config.MCP_PORT:
        mcp_client = SigmaMCPClient(host=Config.MCP_HOST, port=Config.MCP_PORT)
    else:
        mcp_client = SigmaMCPClient(server_cmd=Config.MCP_SERVER_CMD)
    await mcp_client.__aenter__()
    yield
    await mcp_client.__aexit__(None, None, None)

app = FastAPI(lifespan=lifespan)


@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.on_event("shutdown")
async def shutdown_event():
    await mcp_client.__aexit__(None, None, None)

def verify_signature(payload_body: bytes, signature_header: str) -> bool:
    if not signature_header:
        return False
    secret = Config.GITHUB_WEBHOOK_SECRET.encode()
    digest = hmac.new(secret, payload_body, hashlib.sha256).hexdigest()
    expected = f"sha256={digest}"
    return hmac.compare_digest(expected, signature_header)

@app.post("/webhook")
async def webhook_handler(request: Request):
    # 1. Verify signature
    body_bytes = await request.body()
    signature = request.headers.get("X-Hub-Signature-256")
    if not verify_signature(body_bytes, signature):
        raise HTTPException(status_code=401, detail="Invalid signature")

    # 2. Parse event
    event_type = request.headers.get("X-GitHub-Event")
    if event_type not in ["pull_request", "pull_request_review"]:
        return {"msg": "Ignored event"}

    data = json.loads(body_bytes)
    action = data.get("action")
    if action not in ["opened", "synchronize", "reopened", "edited"]:
        return {"msg": "Ignored action"}

    pr_data = data["pull_request"]
    repo_full = data["repository"]["full_name"]
    pr_number = pr_data["number"]
    head_sha = pr_data["head"]["sha"]

    # 3. Get PR object (for extra metadata if needed)
    pr = github_client.get_pr(repo_full, pr_number)

    # 4. Create a Check Run (in_progress)
    check_run = github_client.create_check_run(
        repo_full_name=repo_full,
        head_sha=head_sha,
        name="Sigma Governance",
        status="in_progress",
        started_at=datetime.now(timezone.utc).isoformat(),
    )

    # 5. Map PR to StateTransition
    transition_dict = map_pr_to_transition(pr)
    mode = "simulate" if Config.EVALUATION_MODE == "simulate" else "commit"

    mcp_req = TransitionRequest(
        agent_request_id=f"github-check-{check_run.id}",
        transition_data=transition_dict,
        mode=mode
    )

    # 6. Evaluate via MCP
    try:
        response = await mcp_client.evaluate_transition(mcp_req)
    except Exception as e:
        # Update check run to failure
        output = {
            "title": "Sigma Governance Failed",
            "summary": f"Internal error: {str(e)}",
            "text": "The governance engine encountered an error. Please check the server logs.",
        }
        github_client.update_check_run(
            repo_full_name=repo_full,
            check_run_id=check_run.id,
            status="completed",
            conclusion="failure",
            completed_at=datetime.now(timezone.utc).isoformat(),
            output=output,
        )
        # Also comment on PR for visibility
        github_client.post_comment(pr, f"❌ Governance evaluation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

    # 7. Prepare output and conclusion
    conclusion = None
    output = None

    if response.status == "ratified" or response.status == "simulated":
        conclusion = "success"
        output = {
            "title": "Sigma Governance Passed",
            "summary": f"Transition {response.status} successfully.\n" +
                       (f"Witness: {response.witness_id}" if response.witness_id else "No witness (simulation)"),
            "text": f"Ratified block: {response.ratified_block}" if response.ratified_block else "Simulation result.",
        }
        # Optionally approve PR if commit mode and ratified
        if mode == "commit" and response.status == "ratified":
            github_client.approve_pr(pr)
        # Comment for audit
        github_client.post_comment(pr, f"✅ Governance {response.status} (check run #{check_run.id})")

    elif response.status == "dissonance_trap":
        conclusion = "failure"
        output = {
            "title": "Sigma Governance Violation",
            "summary": f"Breach: {response.breach_type}",
            "text": (
                f"Details: {response.details}\n"
                f"Conflict log: {response.conflict_log_id or 'Not logged'}"
            ),
        }
        # Request changes
        github_client.request_changes(pr, f"🚫 Governance dissonance trap: {response.breach_type}\nDetails: {response.details}")
    else:
        conclusion = "neutral"
        output = {
            "title": "Sigma Governance Unknown",
            "summary": "Unexpected response status.",
        }

    # 8. Update the check run with final conclusion
    github_client.update_check_run(
        repo_full_name=repo_full,
        check_run_id=check_run.id,
        status="completed",
        conclusion=conclusion,
        completed_at=datetime.now(timezone.utc).isoformat(),
        output=output,
    )

    return {"status": conclusion}
