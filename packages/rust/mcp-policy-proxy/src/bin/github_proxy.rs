//! `github-proxy` — SAT-verified GitHub MCP adapter (port of
//! `materia_commons/mcp_server/github_adapter.py`).
//!
//! Proxies stdio JSON-RPC to `npx -y @modelcontextprotocol/server-github`,
//! intercepting `tools/call` to verify the In-band SAT. Requires
//! `COMMANDER_SAT_PUBLIC_KEY` (hex Ed25519 public key).

use mcp_policy_proxy::github;
use std::process::exit;

#[tokio::main]
async fn main() {
    let pub_key_hex = match std::env::var("COMMANDER_SAT_PUBLIC_KEY") {
        Ok(key) if !key.is_empty() => key,
        _ => {
            eprintln!("COMMANDER_SAT_PUBLIC_KEY environment variable is required");
            exit(1);
        }
    };
    if let Err(e) = github::run(&pub_key_hex).await {
        eprintln!("Error handling request: {e}");
        exit(1);
    }
}