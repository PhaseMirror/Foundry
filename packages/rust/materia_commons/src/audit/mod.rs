// src/audit/mod.rs
//! Audit integration submodule for materia_commons.
//!
//! Provides a thin wrapper around the Prime Move Sequence Audit Macro defined in the
//! top‑level `prime` crate. The actual implementation lives in
//! `prime/src/prime_move_audit_macro.rs`. This module re‑exports the public API so
//! that dependent crates can depend on `materia_commons` without a direct path
//! dependency on the binary crate.
//!
//! The integration currently only defines the public module hierarchy. The
//! concrete linking (e.g., adding a workspace path dependency) should be handled
//! in `materia_commons/Cargo.toml` by the maintainer.

pub mod prime_move_sequence;
