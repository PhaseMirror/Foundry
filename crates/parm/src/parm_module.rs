//! Hebrew lexicon PARM functions.
//!
//! These functions provide the Hebrew letter-to-prime mapping, gematria computation,
//! and resonance quotient calculation used by `analysis.rs` and `lexicon.rs`.

use std::collections::HashMap;

/// Hebrew letter shapes mapped to prime indices.
/// The mapping covers the 22 standard Hebrew letters (Aleph–Tav).
fn shape_map() -> HashMap<char, u32> {
    let mut m = HashMap::new();
    let letters = [
        ('\u{05D0}', 1), ('\u{05D1}', 2), ('\u{05D2}', 3), ('\u{05D3}', 4),
        ('\u{05D4}', 5), ('\u{05D5}', 6), ('\u{05D6}', 7), ('\u{05D7}', 8),
        ('\u{05D8}', 9), ('\u{05D9}', 10), ('\u{05DA}', 11), ('\u{05DB}', 12),
        ('\u{05DC}', 13), ('\u{05DD}', 14), ('\u{05DE}', 15), ('\u{05DF}', 16),
        ('\u{05E0}', 17), ('\u{05E1}', 18), ('\u{05E2}', 19), ('\u{05E3}', 20),
        ('\u{05E4}', 21), ('\u{05E5}', 22), ('\u{05E6}', 23), ('\u{05E7}', 24),
        ('\u{05E8}', 25), ('\u{05E9}', 26), ('\u{05EA}', 27),
    ];
    for (c, idx) in letters { m.insert(c, idx); }
    m
}

/// Small gematria values for Hebrew letters (standard mispar katan).
fn small_gematria_map() -> HashMap<char, u32> {
    let mut m = HashMap::new();
    let values = [
        ('\u{05D0}', 1), ('\u{05D1}', 2), ('\u{05D2}', 3), ('\u{05D3}', 4),
        ('\u{05D4}', 5), ('\u{05D5}', 6), ('\u{05D6}', 7), ('\u{05D7}', 8),
        ('\u{05D8}', 9), ('\u{05D9}', 1), ('\u{05DA}', 2), ('\u{05DB}', 3),
        ('\u{05DC}', 4), ('\u{05DD}', 5), ('\u{05DE}', 6), ('\u{05DF}', 7),
        ('\u{05E0}', 8), ('\u{05E1}', 9), ('\u{05E2}', 1), ('\u{05E3}', 2),
        ('\u{05E4}', 3), ('\u{05E5}', 4), ('\u{05E6}', 5), ('\u{05E7}', 6),
        ('\u{05E8}', 7), ('\u{05E9}', 8), ('\u{05EA}', 9),
    ];
    for (c, v) in values { m.insert(c, v); }
    m
}

/// The first 30 primes for mapping small gematria to prime indices.
const PRIMES: [u32; 30] = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
];

/// Look up the shape-based prime index for a Hebrew character.
pub fn get_shape_map(c: char) -> Option<u32> {
    shape_map().get(&c).copied()
}

/// Get the n-th prime (1-indexed).
pub fn get_prime(idx: usize) -> u32 {
    if idx == 0 || idx > PRIMES.len() { 0 } else { PRIMES[idx - 1] }
}

/// Compute small gematria for a Hebrew character.
pub fn small_gematria(c: char) -> u32 {
    small_gematria_map().get(&c).copied().unwrap_or(0)
}

/// Map a small gematria value to a prime.
pub fn get_small_gematria_to_prime(sg: u32) -> Option<u32> {
    if sg == 0 || sg as usize > PRIMES.len() { None } else { Some(PRIMES[(sg - 1) as usize]) }
}

/// Compute the resonance quotient R_Q for a sequence of primes.
/// R_Q = ∏(p_i / p_{i-1}) normalized, which simplifies to p_last / p_first
/// when the sequence is non-empty, or 1.0 for an empty sequence.
pub fn calculate_rq(primes: &[u32], _normalize: bool) -> f64 {
    if primes.len() < 2 {
        return 1.0;
    }
    let first = primes[0] as f64;
    let last = *primes.last().unwrap() as f64;
    if first == 0.0 { 1.0 } else { last / first }
}
