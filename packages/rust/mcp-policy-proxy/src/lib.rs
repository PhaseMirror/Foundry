//! Rust port of the SAT-verified MCP policy proxies.
//!
//! `materia_commons/mcp_server/python_proxy.py` and `github_adapter.py` are
//! JSON-RPC (MCP) shims that require an In-band Service Attestation Token
//! (`_sat`) signed with Ed25519 before a `tools/call` request is honoured.
//! This crate ports:
//!
//! * [`signature`] — Ed25519 SAT verification with Python-identical canonical
//!   payload serialization (`json.dumps(token, separators=(",", ":"), sort_keys=True)`),
//! * [`gate`] — the missing/invalid/valid SAT gate shared by both proxies,
//! * [`proxy`] — the `python-proxy` request handlers and stdio loop,
//! * [`github`] — the GitHub-adapter decision logic and subprocess loop.
//!
//! Both proxy entry points are [`crate::proxy::run`]-style stdio loops; the
//! difference is that `github_proxy` delegates non-governed requests to a
//! spawned `@modelcontextprotocol/server-github` subprocess instead of
//! answering them locally.

#![forbid(unsafe_code)]

pub mod gate;
pub mod github;
pub mod jsonrpc;
pub mod proxy;
pub mod signature;