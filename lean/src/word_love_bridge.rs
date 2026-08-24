//! # Word Love FFI Bridge (ADR-0031 §4)
//!
//! C ABI declarations and Rust wrappers connecting to the Lean 4 Word Love kernel.

use std::ffi::c_char;
use crate::word_love::{GematriaScheme, PrimeMultiplicity, SemanticToken, string_gematria};

#[repr(C)]
pub struct WordLoveTokenFFI {
    pub id: *const c_char,
    pub name: *const c_char,
    pub hebrew: *const c_char,
}

#[repr(C)]
pub struct WordLoveEncodingFFI {
    pub token_id: *const c_char,
    pub scheme: u32,
    pub value: u32,
}

extern "C" {
    pub fn wordlove_gematria_standard_ffi(s: *const c_char) -> u32;
    pub fn wordlove_gematria_reduced_ffi(s: *const c_char) -> u32;
    pub fn wordlove_prime_omega_ffi(n: u32) -> u32;
    pub fn wordlove_prime_Omega_ffi(n: u32) -> u32;
    pub fn wordlove_is_prime_ffi(n: u32) -> bool;
    pub fn wordlove_verify_orthogonality_ffi(dummy: u32) -> bool;
    pub fn wordlove_verify_ahavah_echad_ffi(dummy: u32) -> bool;
}

/// Safe Rust wrapper for computing standard gematria.
pub fn verify_standard_gematria(hebrew: &str) -> u64 {
    string_gematria(GematriaScheme::Standard, hebrew)
}

/// Safe Rust wrapper for computing reduced gematria.
pub fn verify_reduced_gematria(hebrew: &str) -> u64 {
    string_gematria(GematriaScheme::Reduced, hebrew)
}
