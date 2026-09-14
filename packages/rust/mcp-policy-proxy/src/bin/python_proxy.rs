//! `python-policy-proxy` — stdio MCP policy proxy (port of
//! `materia_commons/mcp_server/python_proxy.py`).
//!
//! Reads JSON-RPC lines from stdin and writes responses to stdout. Requires
//! `COMMANDER_SAT_PUBLIC_KEY` (hex Ed25519 public key) for the In-band SAT
//! gate.

use mcp_policy_proxy::proxy;

fn main() {
    let pub_key_hex = match std::env::var("COMMANDER_SAT_PUBLIC_KEY") {
        Ok(key) if !key.is_empty() => key,
        _ => {
            eprintln!("COMMANDER_SAT_PUBLIC_KEY environment variable is required");
            std::process::exit(1);
        }
    };
    if let Err(e) = proxy::run_stdio(&pub_key_hex) {
        eprintln!("Error handling request: {e}");
        std::process::exit(1);
    }
}