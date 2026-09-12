//! Prism Platform Model (PrismPM) Core Library.

#![deny(missing_docs)]
#![forbid(unsafe_code)]
// Public failures deliberately carry the complete registered span, labels,
// notes, help, and cause chain by value. Boxing the error would weaken the
// stable Controller API solely to satisfy a size heuristic.
#![allow(clippy::result_large_err)]

mod application_build;
pub mod cli;
pub mod config;
pub mod controller;
pub mod error;
pub mod holo;
mod verification;

pub use controller::Controller;
pub use error::{DiagnosticCode, PrismError};
