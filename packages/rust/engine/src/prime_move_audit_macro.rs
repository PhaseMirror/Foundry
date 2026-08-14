// src/prime_move_audit_macro.rs
//! Production‑grade implementation of the **Prime Move Sequence Audit Macro**.
//!
//! This module provides a thin, policy‑compliant wrapper around the existing
//! audit chain (`src/audit.rs`) and telemetry infrastructure (`src/telemetry.rs`).
//! It does **not** compute preservation risk itself – it merely records audit
//! events and emits a `[PRESERVATION ALERT]` according to the Sedona Spine
//! mandate (Engine → SDK → CONTRACT → UI).
//!
//! # Design
//! - `PrimeMoveAudit` owns an `AuditChain` and a reference‑counted `TelemetryBus`.
//! - Convenience methods (`record_step`, `record_certificate`, `record_gate`)
//!   append to the audit chain using the same hashing strategy as `AuditChain`.
//! - `emit_preservation_alert` creates a telemetry alert with a fixed name
//!   `"PRESERVATION ALERT"` and a JSON payload describing the context.
//! - All public functions are `pub` and `#[inline]` to keep the binary size low.
//!
//! # Usage example
//! ```rust
//! use pirtm::prime_move_audit_macro::PrimeMoveAudit;
//! use pirtm::telemetry::TelemetryBus;
//! // assume `bus` is configured elsewhere
//! let mut audit = PrimeMoveAudit::new(bus.clone());
//! // record a step
//! audit.record_step(&step_info);
//! // emit a preservation alert when required
//! audit.emit_preservation_alert(serde_json::json!({"reason": "risk detected"}));
//! ```

use crate::audit::AuditChain;
use crate::telemetry::{TelemetryBus, TelemetryEvent};
use crate::types::StepInfo;
use crate::certify::AceCertificate;
use serde_json::Value;
use std::sync::Arc;

/// Wrapper that encapsulates the audit chain and telemetry bus.
pub struct PrimeMoveAudit {
    /// The cryptographic audit chain (see `src/audit.rs`).
    pub chain: AuditChain,
    /// Shared telemetry bus for emitting events and alerts.
    pub telemetry: Arc<TelemetryBus>,
}

impl PrimeMoveAudit {
    /// Create a new audit macro instance.
    #[inline]
    pub fn new(telemetry: Arc<TelemetryBus>) -> Self {
        Self {
            chain: AuditChain::new(),
            telemetry,
        }
    }

    /// Record a regular step using the underlying `AuditChain`.
    #[inline]
    pub fn record_step(&mut self, info: &StepInfo) {
        let event = self.chain.append_step(info);
        let te = TelemetryEvent::new("step", info.step as i64, serde_json::to_value(info).unwrap());
        self.telemetry.dispatch(&te);
        // The audit event itself is not emitted as telemetry – only the step payload.
        let _ = event; // suppress unused warning
    }

    /// Record a certificate event.
    #[inline]
    pub fn record_certificate(&mut self, cert: &AceCertificate) {
        let event = self.chain.append_certificate(cert);
        let te = TelemetryEvent::new(
            "certificate",
            -1,
            serde_json::json!({
                "certified": cert.certified,
                "margin": cert.margin,
                "tail_bound": cert.tail_bound,
                "details": cert.details,
            }),
        );
        self.telemetry.dispatch(&te);
        let _ = event;
    }

    /// Record a gate decision (emitted / suppressed).
    #[inline]
    pub fn record_gate(&mut self, step_index: usize, emitted: bool, policy: &str, reason: &str) {
        let event = self.chain.append_gate(step_index, emitted, policy, reason);
        let te = TelemetryEvent::new(
            "gate",
            step_index as i64,
            serde_json::json!({
                "emitted": emitted,
                "policy": policy,
                "reason": reason,
            }),
        );
        self.telemetry.dispatch(&te);
        let _ = event;
    }

    /// Emit a *Preservation Alert* according to the `[PRESERVATION ALERT]` protocol.
    ///
    /// The macro itself does **not** calculate any risk level; it simply forwards the
    /// caller‑provided detail to the telemetry system. The caller must ensure the
    /// alert conforms to the contract defined in `CONTRACT.md`.
    #[inline]
    pub fn emit_preservation_alert(&self, detail: Value) {
        self.telemetry.emit_alert("PRESERVATION ALERT", detail);
    }
}

// Helper trait to expose a `dispatch` method on `TelemetryBus` – the original
// implementation only provides `emit_*` helpers. This keeps the macro decoupled
// from internal TelemetryBus details.
trait TelemetryDispatch {
    fn dispatch(&self, event: &TelemetryEvent);
}

impl TelemetryDispatch for TelemetryBus {
    #[inline]
    fn dispatch(&self, event: &TelemetryEvent) {
        // Forward to all registered sinks.
        for sink in &self.sinks {
            sink.emit(event);
        }
    }
}

// End of file
