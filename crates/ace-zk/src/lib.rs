/// ACE-ZK: Rust/Circom backend for ACE Core v1.0
///
/// Track B implementation providing:
/// - Cryptographic proof generation (Groth16 primary, PLONK secondary)
/// - Mathematical equivalence to Python Track A
/// - FFI bindings for Python interoperability
///
/// Module structure:
/// - `types`: Rust ports of Python ThetaBase, ThetaC6, StepInfo
/// - `parity`: Reference test vectors and mathematical equivalence validation
/// - `ffi`: PyO3 bindings for Python ↔ Rust interface

pub mod types;
pub mod parity;
pub mod ffi;
pub mod csc;

pub use types::{ThetaBase, ThetaC6, StepInfo, WacMode};
