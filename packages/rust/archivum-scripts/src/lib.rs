//! Rust port of `packages/rust/archivum/scripts/` (`generate-vectors.py` and
//! `validate-determinism.py`).
//!
//! The Python used `cbor2.dumps(..., canonical=True)` and `blake3`. This port
//! reproduces the same canonical CBOR (RFC 8949 §4.2.1 — keys sorted by
//! encoded length, then bytewise) via `ciborium` after sorting map entries.

use ciborium::Value;
use std::cmp::Ordering;
use std::fmt;
use std::path::Path;

pub const DEFAULT_VECTOR_OUTPUT_DIR: &str = "../tests/vectors";
pub const DEFAULT_RUNNER_OUTPUT: &str = "../tests/results/validation.json";

/// Canonical key comparison per RFC 8949 §4.2.1: shorter encoded length
/// first, then bytewise. Applies to the definite-length text/byte/int keys
/// used by the archivum vectors (mirroring `cbor2` canonical mode).
pub fn canonical_key_cmp(a: &Value, b: &Value) -> Ordering {
    let mut ab = Vec::new();
    let mut bb = Vec::new();
    ciborium::into_writer(a, &mut ab).expect("serialize key");
    ciborium::into_writer(b, &mut bb).expect("serialize key");
    ab.len().cmp(&bb.len()).then_with(|| ab.cmp(&bb))
}

/// Sort every map's entries by canonical key order, recursively, then
/// serialize the whole value with minimal definite-length encodings.
pub fn encode_canonical(value: &Value) -> Vec<u8> {
    let sorted = sort_maps(value);
    let mut out = Vec::new();
    ciborium::into_writer(&sorted, &mut out).expect("canonical CBOR encode");
    out
}

fn sort_maps(value: &Value) -> Value {
    match value {
        Value::Array(items) => Value::Array(items.iter().map(sort_maps).collect()),
        Value::Map(pairs) => {
            let mut pairs: Vec<(Value, Value)> = pairs
                .iter()
                .map(|(k, v)| (k.clone(), sort_maps(v)))
                .collect();
            pairs.sort_by(|a, b| canonical_key_cmp(&a.0, &b.0));
            Value::Map(pairs)
        }
        other => other.clone(),
    }
}

/// Registry hash carried by the archived vector (33-byte hex in Python,
/// i.e. 1-byte encoded-ID prefix + 32-byte CIDv1 digest convention).
///
/// Python: `bytes.fromhex("32bd4f7e" + "00" * 29)`.
pub fn registry_hash_33b() -> Vec<u8> {
    let mut out = vec![0x32, 0xbd, 0x4f, 0x7e];
    out.extend_from_slice(&[0u8; 29]);
    out
}

/// Build the canonical CBOR for the single archived test vector
/// (`test-001-plain-text`), byte-for-byte matching
/// `generate-vectors.py` under `cbor2.dumps(..., canonical=True)`.
pub fn build_plain_text_vector() -> Vec<u8> {
    // input_data = {"cid_raw": "b5d4045c", "media_type": "text/plain",
    //               "norm_repr": b"Hello world\nThis is a test."}
    let norm_repr: &[u8] = b"Hello world\nThis is a test.";
    let object_cbor = encode_canonical(&Value::Map(vec![
        (
            Value::Text("cid_raw".into()),
            Value::Text("b5d4045c".into()),
        ),
        (
            Value::Text("media_type".into()),
            Value::Text("text/plain".into()),
        ),
        (
            Value::Text("norm_repr".into()),
            Value::Bytes(norm_repr.to_vec()),
        ),
    ]));

    // expected_cbor = cbor2.dumps("text/plain", canonical=True)
    let expected_cbor = encode_canonical(&Value::Text("text/plain".into()));
    let expected_hash = blake3::hash(&expected_cbor);

    // decomposition_hash = blake3(expected_cbor) — the decomposition yields
    // the plain-text blob, so its commitment hash covers that blob.
    let decomposition_hash = blake3::hash(&expected_cbor);

    let vector = Value::Map(vec![
        (
            Value::Text("test_id".into()),
            Value::Text("test-001-plain-text".into()),
        ),
        (
            Value::Text("description".into()),
            Value::Text("Plain text object, single decomposition, single output".into()),
        ),
        (
            Value::Text("registry_hash".into()),
            Value::Bytes(registry_hash_33b()),
        ),
        (Value::Text("object_cbor".into()), Value::Bytes(object_cbor)),
        (
            Value::Text("expected".into()),
            Value::Array(vec![Value::Map(vec![
                (
                    Value::Text("decomposition_hash".into()),
                    Value::Bytes(decomposition_hash.as_bytes().to_vec()),
                ),
                (
                    Value::Text("results".into()),
                    Value::Array(vec![Value::Map(vec![
                        (
                            Value::Text("prime_id".into()),
                            Value::Text("p-003-combative-cid".into()),
                        ),
                        (
                            Value::Text("prime_version".into()),
                            Value::Text("0.1.0".into()),
                        ),
                        (
                            Value::Text("output_cbor".into()),
                            Value::Bytes(expected_cbor.clone()),
                        ),
                        (
                            Value::Text("output_hash".into()),
                            Value::Bytes(expected_hash.as_bytes().to_vec()),
                        ),
                    ])]),
                ),
            ])]),
        ),
        (
            Value::Text("limits".into()),
            Value::Map(vec![
                (
                    Value::Text("max_fuel".into()),
                    Value::Integer(ciborium::value::Integer::from(1_000_000)),
                ),
                (
                    Value::Text("max_time_ms".into()),
                    Value::Integer(ciborium::value::Integer::from(1_000)),
                ),
                (
                    Value::Text("max_memory_pages".into()),
                    Value::Integer(ciborium::value::Integer::from(256)),
                ),
            ]),
        ),
    ]);

    encode_canonical(&vector)
}

/// Write the `test-001-plain-text.cbor` and `.hash` files into `out_dir`,
/// returning the two paths written.
pub fn write_generated_vectors(
    out_dir: &Path,
) -> Result<(std::path::PathBuf, std::path::PathBuf), String> {
    std::fs::create_dir_all(out_dir).map_err(|e| {
        format!(
            "failed to create output directory {}: {e}",
            out_dir.display()
        )
    })?;

    let cbor_path = out_dir.join("test-001-plain-text.cbor");
    let hash_path = out_dir.join("test-001-plain-text.hash");

    let vector_bytes = build_plain_text_vector();
    std::fs::write(&cbor_path, &vector_bytes)
        .map_err(|e| format!("failed to write {}: {e}", cbor_path.display()))?;

    let digest = blake3::hash(&vector_bytes);
    // Python writes the hex digest without a trailing newline.
    std::fs::write(&hash_path, digest.to_hex().as_str())
        .map_err(|e| format!("failed to write {}: {e}", hash_path.display()))?;

    Ok((cbor_path, hash_path))
}

/// Parse a blake3 `.hash` file, returning the raw 32 bytes.
pub fn read_hash_file(path: &Path) -> Result<[u8; 32], String> {
    let text = std::fs::read_to_string(path)
        .map_err(|e| format!("failed to read {}: {e}", path.display()))?;
    let hex = text.trim();
    if hex.len() != 64 {
        return Err(format!(
            "{}: expected 64 hex chars, got {}",
            path.display(),
            hex.len()
        ));
    }
    let mut out = [0u8; 32];
    for (pos, c) in hex.bytes().enumerate() {
        let v = match c {
            b'0'..=b'9' => c - b'0',
            b'a'..=b'f' => c - b'a' + 10,
            b'A'..=b'F' => c - b'A' + 10,
            _ => return Err(format!("{}: invalid hex char", path.display())),
        };
        if pos.is_multiple_of(2) {
            out[pos / 2] = v << 4;
        } else {
            out[pos / 2] |= v;
        }
    }
    Ok(out)
}

/// Error surfaced by the 1000-run determinism validation driver
/// (`validate-determinism.py`).
#[derive(Debug)]
pub enum DeterminismError {
    Spawn { run: usize, source: String },
    NonZeroExit { run: usize, stderr: String },
    OutputUnreadable { run: usize, path: String },
    OutputMismatch { run: usize },
}

impl fmt::Display for DeterminismError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            DeterminismError::Spawn { run, source } => {
                write!(f, "run {run}: failed to spawn runner: {source}")
            }
            DeterminismError::NonZeroExit { run, stderr } => {
                write!(f, "run {run}: runner exited non-zero:\n{stderr}")
            }
            DeterminismError::OutputUnreadable { run, path } => {
                write!(f, "run {run}: could not read output at {path}")
            }
            DeterminismError::OutputMismatch { run } => {
                write!(
                    f,
                    "MISMATCH at run {run}: validation output did not match baseline"
                )
            }
        }
    }
}

impl std::error::Error for DeterminismError {}

/// Run the `runner` command `runs` times (in `workdir`) and assert the file at
/// `output_path` is byte-identical every time. Port of
/// `validate-determinism.py` (Python fixed 1000 runs and killed on first
/// mismatch; the CLI here passes 50 by default, mirroring the script).
pub fn run_validation(
    mut runner: std::process::Command,
    runs: usize,
    output_path: &Path,
    workdir: &Path,
) -> Result<(), DeterminismError> {
    runner.current_dir(workdir);
    let mut baseline: Option<String> = None;

    for run in 1..=runs {
        if run % 100 == 0 {
            println!("Completed {run}/{runs} runs...");
        }

        let output = runner.output().map_err(|e| DeterminismError::Spawn {
            run,
            source: e.to_string(),
        })?;
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr).into_owned();
            return Err(DeterminismError::NonZeroExit { run, stderr });
        }

        let text = std::fs::read_to_string(output_path).map_err(|_| {
            DeterminismError::OutputUnreadable {
                run,
                path: output_path.display().to_string(),
            }
        })?;

        match baseline.as_ref() {
            None => baseline = Some(text),
            Some(prev) if *prev == text => {}
            Some(_) => return Err(DeterminismError::OutputMismatch { run }),
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use ciborium::Value;

    #[test]
    fn vector_embeds_consistent_hash_chain() {
        let bytes = build_plain_text_vector();
        let top: Value = ciborium::from_reader(bytes.as_slice()).expect("decode");

        fn get<'a>(key: &str, value: &'a Value) -> &'a Value {
            match value {
                Value::Map(map) => map
                    .iter()
                    .find(|(k, _)| k == &Value::Text(key.into()))
                    .map(|(_, v)| v)
                    .unwrap_or_else(|| panic!("missing key {key}")),
                other => panic!("expected a map, got {other:?}"),
            }
        }

        let expected = match get("expected", &top) {
            Value::Array(items) => &items[0],
            other => panic!("expected must be an array: {other:?}"),
        };
        let results = match get("results", expected) {
            Value::Array(items) => &items[0],
            other => panic!("results must be an array: {other:?}"),
        };

        let expected_cbor = encode_canonical(&Value::Text("text/plain".into()));
        assert_eq!(
            get("output_cbor", results),
            &Value::Bytes(expected_cbor.clone()),
            "output_cbor must be the canonical text/plain encoding"
        );
        assert_eq!(
            get("output_hash", results),
            &Value::Bytes(blake3::hash(&expected_cbor).as_bytes().to_vec()),
            "embedded output_hash must equal blake3(expected_cbor)"
        );

        assert_eq!(
            get("decomposition_hash", expected),
            &Value::Bytes(blake3::hash(&expected_cbor).as_bytes().to_vec()),
            "decomposition_hash must equal blake3(expected_cbor)"
        );
    }

    #[test]
    fn registry_hash_is_33_bytes() {
        assert_eq!(registry_hash_33b().len(), 33);
    }

    #[test]
    fn canonical_encoding_round_trips_and_is_idempotent() {
        let bytes = build_plain_text_vector();
        let decoded: Value = ciborium::from_reader(bytes.as_slice()).expect("decode");
        let re_encoded = encode_canonical(&decoded);
        assert_eq!(bytes, re_encoded, "canonical encoding must be stable");
    }

    #[test]
    fn vector_survives_file_round_trip() {
        let dir = tempfile::tempdir().expect("tempdir");
        let (cbor_path, hash_path) = write_generated_vectors(dir.path()).expect("write vectors");
        assert!(cbor_path.exists());
        assert!(hash_path.exists());

        let original = build_plain_text_vector();
        let on_disk = std::fs::read(&cbor_path).expect("read cbor");
        assert_eq!(original, on_disk);

        let header_hash: [u8; 32] = blake3::hash(&on_disk).into();
        assert_eq!(header_hash, read_hash_file(&hash_path).expect("read hash"));
    }

    #[test]
    fn canonical_key_cmp_sorts_shortest_first() {
        let a = Value::Text("limits".into());
        let b = Value::Text("expected".into());
        // "limits" (6) < "expected" (8) by length.
        assert_eq!(canonical_key_cmp(&a, &b), Ordering::Less);
    }
}
