//! Rust port of the `multiplicity.crypto` Python interop package.
//!
//! Source of truth: `crates/multiplicity-crypto/py/multiplicity/**` (and its
//! `packages/rust/multiplicity-crypto/py` duplicate). The Python package is a
//! bridge to a TypeScript/WASM crypto backend with a deterministic SHA-256
//! compatibility ("fallback") mode. The modules that this port depends on but
//! that do not exist anywhere in the repo (`pirtm.ace.types`, `pirtm.ace.witness`,
//! `mkt_colored_braid`, `mkt_constants_estimation`, `mkt_invariant`) mean the
//! only ever-runnable semantics are precisely this fallback surface, plus the
//! self-contained modules (`math.core_math`, `math.cas_registry`, `crypto`,
//! `mkt.mkt_commitment`), which is what this crate reproduces.
//!
//! Notable deliberate divergences from the Python (all documented inline):
//! * Python `str(dict)` is used for hashing `qpaRunPrototype` params/shadows;
//!   Python's `str()` of a dict is insertion-order repr and is not stable. This
//!   port hashes the canonical `sort_keys` JSON of the params instead, keeping
//!   the structure identical and the digest deterministic.
//! * Python `json.dumps(payload, sort_keys=True)` uses default separators
//!   (`, ` and `: `). This is reproduced exactly by [`jsonfmt::to_python_style`],
//!   because `serde_json` always emits compact separators.
//! * The async wrappers collapse to synchronous functions (there is no event
//!   loop in Rust); camelCase aliases used to drive the Node bridge are dropped.

#![forbid(unsafe_code)]
#![warn(missing_docs)]

pub mod cas;
pub mod crypto;
pub mod jsonfmt;
pub mod math;
pub mod mkt;

pub use cas::{AceCertificate, AceWitness, CasRegistry, CryptoBackedWitness};
pub use crypto::MultiplicityCrypto;
