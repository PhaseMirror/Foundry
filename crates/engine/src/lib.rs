// crates/engine/src/lib.rs
//! Engine crate – provides telemetry framing and lawful‑recursion‑hash.
//! The public API consists of `FPGATelemetryFrame`, `SecurityState`, and
//! `compute_lawful_recursion_hash`.

mod crmf_binding;
pub use crmf_binding::{FPGATelemetryFrame, SecurityState, compute_lawful_recursion_hash};

