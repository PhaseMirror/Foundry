//! Port of `multiplicity/mkt/mkt_commitment.py` — ADR-104 Phase 0
//! Multiplicity-Based Commitment (MBC) prototype scaffold.
//!
//! The Python module imports `mkt_colored_braid.BraidWord`,
//! `mkt_constants_estimation.{c0_of_x,z_of_x}` and `mkt_invariant.p_of_braid_x`,
//! none of which exist in the repository (the Python module cannot import at
//! all). This port therefore defines a [`BraidWord`] holder for exactly the
//! `"l:r;l:r"` serialization the commitment code uses, and makes the constant
//! estimation / invariant functions explicit parameters so the commitment
//! machinery itself is fully deterministic and testable.

use crate::crypto::sha256_hex;
use pyjson::to_compact;
use serde_json::json;

/// A colored braid word: a sequence of `(left, right)` crossings.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BraidWord {
    tokens: Vec<(i64, i64)>,
}

impl BraidWord {
    /// Build a braid word from `(left, right)` tokens.
    pub fn new(tokens: Vec<(i64, i64)>) -> Self {
        Self { tokens }
    }

    /// The contained tokens.
    pub fn tokens(&self) -> &[(i64, i64)] {
        &self.tokens
    }

    /// Serialize as `"l:r;l:r"` (matches `BraidWord.serialize()` and the
    /// round-trip handled by `_deserialize_braid`).
    pub fn serialize(&self) -> String {
        self.tokens
            .iter()
            .map(|(left, right)| format!("{left}:{right}"))
            .collect::<Vec<_>>()
            .join(";")
    }

    /// Parse the `"l:r;l:r"` form back into a braid word.
    ///
    /// An empty string yields the empty braid word (as `_deserialize_braid` does).
    pub fn deserialize(serialized: &str) -> Result<BraidWord, String> {
        if serialized.is_empty() {
            return Ok(BraidWord::new(Vec::new()));
        }
        let mut tokens = Vec::new();
        for token in serialized.split(';') {
            let (left, right) = token
                .split_once(':')
                .ok_or_else(|| format!("malformed braid token: {token:?}"))?;
            let left = left.parse::<i64>().map_err(|e| e.to_string())?;
            let right = right.parse::<i64>().map_err(|e| e.to_string())?;
            tokens.push((left, right));
        }
        Ok(BraidWord::new(tokens))
    }
}

/// MBC public parameters, mirroring the `setup()` result.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MbcParams {
    /// Sorted, deduplicated, integer cutoffs all strictly greater than 1.
    pub cutoffs: Vec<i64>,
    /// Hash function label.
    pub hash: &'static str,
    /// Version label.
    pub version: &'static str,
}

/// MBC `setup(cutoffs)`: sorted unique integers `> 1`.
pub fn setup(cutoffs: impl IntoIterator<Item = i64>) -> MbcParams {
    let mut xs: Vec<i64> = cutoffs.into_iter().filter(|&x| x > 1).collect();
    xs.sort_unstable();
    xs.dedup();
    MbcParams {
        cutoffs: xs,
        hash: "sha256",
        version: "mbc_phase0",
    }
}

/// Serialize the commit payload exactly as
/// `json.dumps(..., sort_keys=True, separators=(",", ":"))` — compact with
/// sorted keys.
pub fn serialize_commit_payload(message: &str, braid_serialized: &str) -> String {
    to_compact(&json!({
        "message": message,
        "braid": braid_serialized,
    }))
}

/// An MBC commitment.
#[derive(Debug, Clone, PartialEq)]
pub struct Commitment {
    /// SHA-256 hex digest of the commit payload.
    pub digest: String,
    /// Invariant vector, one entry per cutoff.
    pub invariant_vector: Vec<f64>,
}

/// Opening data needed to verify an MBC commitment.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OpeningData {
    /// The committed message.
    pub message: String,
    /// Serialized braid used in the committed payload.
    pub braid_serialized: String,
}

/// Constant estimation for a cutoff — stand-in for
/// `mkt_constants_estimation.{c0_of_x,z_of_x}` (returns `(c0_x, z_x)`).
pub type ConstantsEstimation = fn(i64) -> (f64, f64);

/// Per-cutoff invariant — stand-in for `mkt_invariant.p_of_braid_x`.
pub type POfBraidX = fn(&BraidWord, x_cutoff: i64, c0_x: f64, z_x: f64) -> f64;

/// Commit a message with a braid under `params`, mirroring `commit()`.
///
/// `constants` and `invariant` are supplied by the caller because their Python
/// counterparts (`mkt_constants_estimation`, `mkt_invariant`) do not exist in
/// the repository.
pub fn commit(
    params: &MbcParams,
    message: &str,
    braid: &BraidWord,
    constants: ConstantsEstimation,
    invariant: POfBraidX,
) -> (Commitment, OpeningData) {
    let braid_serialized = braid.serialize();
    let payload = serialize_commit_payload(message, &braid_serialized);
    let digest = sha256_hex(&[&payload]);

    let mut vector = Vec::with_capacity(params.cutoffs.len());
    for &x in &params.cutoffs {
        let (c0_x, z_x) = constants(x);
        vector.push(invariant(braid, x, c0_x, z_x));
    }

    let commitment = Commitment {
        digest,
        invariant_vector: vector,
    };
    let opening = OpeningData {
        message: message.to_string(),
        braid_serialized,
    };
    (commitment, opening)
}

/// Open and verify a commitment, mirroring `open_commitment()`.
pub fn open_commitment(
    params: &MbcParams,
    commitment: &Commitment,
    message: &str,
    opening: &OpeningData,
    constants: ConstantsEstimation,
    invariant: POfBraidX,
) -> bool {
    if message != opening.message {
        return false;
    }
    let Ok(braid) = BraidWord::deserialize(&opening.braid_serialized) else {
        return false;
    };
    let (recomputed, _) = commit(params, message, &braid, constants, invariant);
    recomputed.digest == commitment.digest
        && recomputed.invariant_vector == commitment.invariant_vector
}

#[cfg(test)]
mod tests {
    use super::*;

    fn constants(_x: i64) -> (f64, f64) {
        (1.0, 1.0)
    }

    fn invariant(braid: &BraidWord, x_cutoff: i64, _c0_x: f64, _z_x: f64) -> f64 {
        let sum: i64 = braid.tokens().iter().map(|(l, r)| l - r).sum();
        (sum as f64).rem_euclid(x_cutoff as f64)
    }

    #[test]
    fn braid_serialization_roundtrip() {
        let braid = BraidWord::new(vec![(1, 2), (3, 4)]);
        let serialized = braid.serialize();
        assert_eq!(serialized, "1:2;3:4");
        assert_eq!(BraidWord::deserialize(&serialized).unwrap(), braid);
        assert_eq!(
            BraidWord::deserialize("").unwrap(),
            BraidWord::new(Vec::new())
        );
        assert!(BraidWord::deserialize("1,2").is_err());
        assert!(BraidWord::deserialize("a:2").is_err());
    }

    #[test]
    fn setup_filters_sorts_dedupes() {
        let params = setup([100, 1, 1000, 5, 5, -3]);
        assert_eq!(params.cutoffs, vec![5, 100, 1000]);
        assert_eq!(params.hash, "sha256");
        assert_eq!(params.version, "mbc_phase0");

        let empty = setup([]);
        assert!(empty.cutoffs.is_empty());
    }

    #[test]
    fn commit_payload_is_compact_sorted_json() {
        let braid = BraidWord::new(vec![(1, 2)]);
        assert_eq!(
            serialize_commit_payload("msg", &braid.serialize()),
            r#"{"braid":"1:2","message":"msg"}"#
        );
    }

    #[test]
    fn commit_and_open_roundtrip() {
        let params = setup([100, 5]);
        let braid = BraidWord::new(vec![(7, 2)]);
        let (commitment, opening) = commit(&params, "message", &braid, constants, invariant);

        assert_eq!(commitment.invariant_vector.len(), 2);
        assert_eq!(commitment.digest.len(), 64);
        assert_eq!(
            commitment.digest,
            sha256_hex(&[&serialize_commit_payload("message", &braid.serialize())])
        );

        assert!(open_commitment(
            &params,
            &commitment,
            "message",
            &opening,
            constants,
            invariant
        ));

        // Tampered message / wrong digest / wrong opening all fail.
        assert!(!open_commitment(
            &params,
            &commitment,
            "other",
            &opening,
            constants,
            invariant
        ));

        let mut bad = commitment.clone();
        bad.digest = "0".repeat(64);
        assert!(!open_commitment(
            &params, &bad, "message", &opening, constants, invariant
        ));

        let bad_opening = OpeningData {
            message: "message".to_string(),
            braid_serialized: "1:99".to_string(),
        };
        assert!(!open_commitment(
            &params,
            &commitment,
            "message",
            &bad_opening,
            constants,
            invariant
        ));
    }
}
