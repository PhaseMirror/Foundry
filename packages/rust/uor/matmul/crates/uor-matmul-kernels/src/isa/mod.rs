//! One module per architecture. Each exports [`crate::KernelSpec`] values and
//! an availability predicate, and nothing else.
//!
//! The modules are always compiled; the ones for another architecture export
//! predicates that answer `false` and specs that are never reached. That keeps
//! `spec.rs` free of `cfg` blocks, so the list of what exists is one list
//! rather than one per target.

pub mod portable;

#[cfg(target_arch = "x86_64")]
#[path = "x86.rs"]
pub mod x86;
#[cfg(not(target_arch = "x86_64"))]
#[path = "absent_x86.rs"]
pub mod x86;

#[cfg(target_arch = "aarch64")]
#[path = "arm.rs"]
pub mod arm;
#[cfg(not(target_arch = "aarch64"))]
#[path = "absent_arm.rs"]
pub mod arm;

#[cfg(target_arch = "wasm32")]
#[path = "wasm.rs"]
pub mod wasm;
#[cfg(not(target_arch = "wasm32"))]
#[path = "absent_wasm.rs"]
pub mod wasm;
