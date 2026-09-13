//! Port of `packages/rust/archivum/scripts/generate-vectors.py`.
//!
//! Writes canonical CBOR test vectors (`{test_id}.cbor`) plus a companion
//! blake3 hex digest file (`{test_id}.hash`) into the vectors output dir.

use archivum_scripts::{write_generated_vectors, DEFAULT_VECTOR_OUTPUT_DIR};
use std::path::PathBuf;

fn main() {
    let out_dir = std::env::args()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(DEFAULT_VECTOR_OUTPUT_DIR));

    match write_generated_vectors(&out_dir) {
        Ok((cbor_path, hash_path)) => {
            println!("Test vectors generated.");
            println!("  CBOR:  {}", cbor_path.display());
            println!("  hash:  {}", hash_path.display());
        }
        Err(err) => {
            eprintln!("ERROR: {err}");
            std::process::exit(1);
        }
    }
}
