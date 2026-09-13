//! # github-adapter
//!
//! Faithful port of the Python GitHub governance adapter
//! (`materia_commons/agents/github_adapter` + `agents/mcp_client`).
//!
//! The adapter turns GitHub Pull Request webhooks into `sigma::StateTransition`
//! candidates, evaluates them through the multiplicity MCP server
//! (`evaluate_transition`), and reflects the verdict back onto the PR as check
//! runs, reviews, and comments.
//!
//! Module layout mirrors the Python package:
//! - [`config`]     — port of `config.py` (env-driven configuration)
//! - [`mapper`]     — port of `app/mapper.py` (PR -> StateTransition)
//! - [`payload`]    — webhook event payload types
//! - [`signature`]  — port of `verify_signature` (HMAC-SHA256 verify)
//! - [`github`]     — port of `app/github_client.py` (reqwest REST client)
//! - [`mcp`]        — port of `agents/mcp_client/client.py` (JSON-RPC client)
//! - [`webhook`]    — port of `app/main.py` orchestration + decision table
//! - `bin/server`   — axum entrypoint (`/health`, `POST /webhook`)

pub mod config;
pub mod github;
pub mod mapper;
pub mod mcp;
pub mod payload;
pub mod signature;
pub mod webhook;

pub use webhook::Outcome;

use serde::{Deserialize, Serialize};

/// Serialization contract matching `sigma::StateTransition`
/// (`{ id, r_sc, l_eff }`) and the dict emitted by `map_pr_to_transition`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TransitionData {
    pub id: String,
    pub r_sc: f64,
    pub l_eff: f64,
}
