//! Hebrew lexicon PARM stubs.
//!
//! These functions are placeholders for the full Hebrew lexicon implementation
//! that was originally planned alongside the sealed state primitive. They exist
//! solely to preserve backward compatibility with `analysis.rs` and `lexicon.rs`.

pub fn get_shape_map(_c: char) -> Option<u32> {
    None
}

pub fn get_prime(_idx: usize) -> u32 {
    2
}

pub fn small_gematria(_c: char) -> u32 {
    0
}

pub fn get_small_gematria_to_prime(_sg: u32) -> Option<u32> {
    None
}

pub fn calculate_rq(_primes: &[i32], _normalize: bool) -> f64 {
    1.0
}
