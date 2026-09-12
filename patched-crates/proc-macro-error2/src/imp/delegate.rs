#![allow(dead_code, unused_imports)]

//! Minimal stub of proc-macro-error2 for Kani verification.
//! Diagnostic functionality is disabled to avoid nightly features.

use std::cell::Cell;

pub mod diagnostic {
    #[derive(Debug)]
    pub struct Diagnostic;
    #[derive(Debug)]
    pub enum Level { Warning, Error }
    #[derive(Debug)]
    pub enum SuggestionKind { Note, Help }
}

use diagnostic::{Diagnostic, Level, SuggestionKind};

pub fn abort_if_dirty() {
    // No-op for verification.
    let _ = ();
}

pub(crate) fn cleanup() -> Vec<Diagnostic> {
    vec![]
}

/// No‑op diagnostic emitter used during Kani verification.
pub(crate) fn emit_diagnostic(_diag: Diagnostic) {
    // intentionally empty
}

thread_local! {
    static IS_DIRTY: Cell<bool> = Cell::new(false);
}


//! Minimal stub of proc-macro-error2 for Kani verification.
//! Diagnostic functionality is disabled to avoid nightly features.

use std::cell::Cell;

pub mod diagnostic {
    #[derive(Debug)]
    pub struct Diagnostic;
    #[derive(Debug)]
    pub enum Level { Warning, Error }
    #[derive(Debug)]
    pub enum SuggestionKind { Note, Help }
}

use diagnostic::{Diagnostic, Level, SuggestionKind};

pub fn abort_if_dirty() {
    // No-op for verification.
    let _ = ();
}

pub(crate) fn cleanup() -> Vec<Diagnostic> {
    vec![]
}

/// No‑op diagnostic emitter used during Kani verification.
pub(crate) fn emit_diagnostic(_diag: Diagnostic) {
    // intentionally empty
}

thread_local! {
    static IS_DIRTY: Cell<bool> = Cell::new(false);
    diagnostic::{Diagnostic, Level, SuggestionKind},
};

pub fn abort_if_dirty() {
    check_correctness();
    if IS_DIRTY.with(|c| c.get()) {
        abort_now();
    }
}

pub(crate) fn cleanup() -> Vec<Diagnostic> {
    IS_DIRTY.with(|c| c.set(false));
    vec![]
}

/// No‑op diagnostic emitter used during Kani verification.
pub(crate) fn emit_diagnostic(_diag: Diagnostic) {
    // Intentionally empty – diagnostics are not required for verification.
}

thread_local! {
    static IS_DIRTY: Cell<bool> = Cell::new(false);
}

use std::cell::Cell;

// Stubbed out proc-macro diagnostics for Kani verification.
pub fn abort_if_dirty() {
    // No-op for verification.
}

pub(crate) fn cleanup() -> Vec<Diagnostic> {
    vec![]
}

pub(crate) fn emit_diagnostic(_diag: Diagnostic) {
    // No-op for verification.
}

thread_local! {
    static IS_DIRTY: Cell<bool> = Cell::new(false);
}
