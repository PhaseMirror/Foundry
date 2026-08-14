//! Structured logging macros for the Sigma Kernel governed loop.
//! Provides consistent, observable, and Phase-Mirror-aligned logging
//! for deserialization, threshold validation, evaluation, and dissonance traps.

use tracing::{event, Level};

/// Log a detailed deserialization or validation issue with rich context.
#[macro_export]
macro_rules! log_deser_detail {
    ($level:path, $err:expr, $file:expr, $offset:expr, $context:expr) => {{
        tracing::event!(
            $level,
            error = %$err,
            file = $file,
            byte_offset = $offset,
            context = $context,
            rpi_bound = 7,           // Lean invariant
            lambda1_positive = true, // Lean invariant
            "Detailed deserialization / validation issue"
        );
    }};
}

/// Log successful threshold load from Lean export.
macro_rules! log_threshold_load {
    ($status:literal, $source:expr) => {{
        let atlas_sig = (10, 14);
        tracing::event!(
            Level::INFO,
            status = $status,
            source = $source,
            rpi_upper = 7,
            lambda1_positive = true,
            atlas_signature = ?atlas_sig,
            "Lean thresholds loaded and validated"
        );
    }};
}

/// Log a governed transition (observability event).
#[macro_export]
macro_rules! log_governed_transition {
    ($transition_id:expr, $pweh:expr) => {{
        let _ = ($transition_id, $pweh);
        tracing::event!(
            Level::INFO,
            transition_id = %$transition_id,
            pweh_hash = %$pweh,
            rpi_bound = 7,
            l_eff_max = 0.15,
            "Governed transition started"
        );
    }};
}

/// Log a dissonance trap with full context.
macro_rules! log_dissonance_trap {
    ($transition_id:expr, $breach_type:expr, $details:expr) => {{
        tracing::event!(
            Level::WARN,
            transition_id = %$transition_id,
            breach_type = ?$breach_type,
            details = $details,
            rpi_bound = 7,
            lambda1_positive = true,
            "Dissonance trap triggered – Phase Mirror enforcement"
        );
    }};
}

/// Log validation failure against Lean invariants.
macro_rules! log_validation_failure {
    ($field:expr, $value:expr, $bound:expr) => {{
        tracing::event!(
            Level::ERROR,
            field = $field,
            value = %$value,
            bound = $bound,
            "Validation failed against verified Lean bounds"
        );
    }};
}

/// Convenience macro for quick error logging (used in DeserError paths).
macro_rules! log_error {
    ($err:expr, $($field:tt)*) => {{
        tracing::error!(
            error = %$err,
            $($field)*
        );
    }};
}
