//! Port of `multiplicity/crypto/__init__.py` — the deterministic SHA-256
//! compatibility ("fallback") mode of the crypto bridge.
//!
//! Only the fallback surface is ported: there is no Node/WASM backend inside
//! this crate, so the bridge always resolves to fallback mode (mirroring an
//! environment where the TypeScript bridge script is absent).
//!
//! Divergences from the Python (by necessity, documented inline):
//! * `qpaRunPrototype` hashes a canonical `sort_keys` JSON of `params` where
//!   Python used `str(dict)` (an unstable insertion-order repr).
//! * All async functions collapse to synchronous ones; camelCase bridge-driver
//!   aliases are omitted. The snake_case module-level API is preserved.

use pyjson::to_python_style;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use sha2::{Digest, Sha256};
use std::sync::OnceLock;

/// Environment variable that forces fallback mode.
pub const BRIDGE_ENV_VAR: &str = "MULTIPLICITY_CRYPTO_FORCE_FALLBACK";

/// Version reported by the Python `multiplicity/__init__.py`.
pub const PACKAGE_VERSION: &str = "0.2.0";

/// Errors produced by the crypto bridge.
#[derive(Debug, thiserror::Error)]
pub enum CryptoError {
    /// `merkleRoot` / `generateMerkleProof` on zero leaves.
    #[error("Cannot compute Merkle root of empty leaves")]
    EmptyLeaves,
    /// `generateMerkleProof` with an out-of-range leaf index.
    #[error("Invalid leaf index")]
    InvalidLeafIndex,
    /// A malformed proof step (missing `:` separator).
    #[error("Malformed Merkle proof step")]
    MalformedProof,
    /// Unknown bridge command.
    #[error("Unknown bridge command: {0}")]
    UnknownCommand(String),
}

/// Resolved status of the crypto bridge.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BridgeStatus {
    /// Always `true` in fallback mode (the bridge responds to its API).
    pub available: bool,
    /// `"fallback"` in this crate.
    pub mode: String,
    /// Why fallback mode was chosen.
    pub reason: String,
}

impl BridgeStatus {
    /// Build the status the same way `_resolve_bridge_status` would when the
    /// TS script is absent: `force_fallback` short-circuits to `"forced"`.
    pub fn resolve(force_fallback: bool) -> Self {
        if force_fallback {
            Self {
                available: true,
                mode: "fallback".to_string(),
                reason: "forced".to_string(),
            }
        } else {
            Self {
                available: true,
                mode: "fallback".to_string(),
                reason: "bridge-script-missing".to_string(),
            }
        }
    }
}

/// Parse the `MULTIPLICITY_CRYPTO_FORCE_FALLBACK` env var like Python's
/// `os.getenv(...).lower() in {"1", "true", "yes"}`.
pub fn force_fallback_from_env() -> bool {
    match std::env::var(BRIDGE_ENV_VAR) {
        Ok(v) => matches!(v.trim().to_ascii_lowercase().as_str(), "1" | "true" | "yes"),
        Err(_) => false,
    }
}

/// Prefix `value` with `0x` unless it already starts with `0x`.
pub fn normalize_hex(value: &str) -> String {
    if value.starts_with("0x") {
        value.to_string()
    } else {
        format!("0x{value}")
    }
}

/// SHA-256 hex digest of the concatenation of `parts` (UTF-8).
pub fn sha256_hex(parts: &[&str]) -> String {
    let mut hasher = Sha256::new();
    for part in parts {
        hasher.update(part.as_bytes());
    }
    hex::encode(hasher.finalize())
}

/// Fallback commitment `sha256(message + ":commit:" + randomness)`, hex-normalized.
pub fn fallback_commitment(message: &str, randomness: &str) -> String {
    normalize_hex(&sha256_hex(&[message, ":commit:", randomness]))
}

/// Merkle root over committed leaves; odd nodes are duplicated at each level.
pub fn fallback_merkle_root(leaves: &[String]) -> Result<String, CryptoError> {
    if leaves.is_empty() {
        return Err(CryptoError::EmptyLeaves);
    }
    let mut nodes: Vec<String> = leaves
        .iter()
        .map(|leaf| fallback_commitment(leaf, "merkle-leaf"))
        .collect();
    while nodes.len() > 1 {
        let mut next_level = Vec::with_capacity(nodes.len().div_ceil(2));
        let mut index = 0;
        while index < nodes.len() {
            let left = &nodes[index];
            let right = if index + 1 < nodes.len() {
                &nodes[index + 1]
            } else {
                left
            };
            next_level.push(fallback_commitment(
                &format!("{left}:{right}"),
                "merkle-node",
            ));
            index += 2;
        }
        nodes = next_level;
    }
    nodes.into_iter().next().ok_or(CryptoError::EmptyLeaves)
}

/// A Merkle membership proof over committed leaves.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MerkleProof {
    /// Sibling path steps, each prefixed `left:` / `right:`.
    pub proof: Vec<String>,
    /// Root the proof closes over.
    pub root: String,
}

/// Generate a Merkle membership proof for `leaf_index` over `leaves`.
pub fn fallback_generate_merkle_proof(
    leaves: &[String],
    leaf_index: usize,
) -> Result<MerkleProof, CryptoError> {
    if leaf_index >= leaves.len() {
        return Err(CryptoError::InvalidLeafIndex);
    }
    let mut proof = Vec::new();
    let mut nodes: Vec<String> = leaves
        .iter()
        .map(|leaf| fallback_commitment(leaf, "merkle-leaf"))
        .collect();
    let mut current_index = leaf_index;

    while nodes.len() > 1 {
        let is_left_child = current_index.is_multiple_of(2);
        if is_left_child {
            let sibling = if current_index + 1 < nodes.len() {
                &nodes[current_index + 1]
            } else {
                &nodes[current_index]
            };
            proof.push(format!("right:{sibling}"));
        } else {
            proof.push(format!("left:{}", nodes[current_index - 1]));
        }

        let mut next_level = Vec::with_capacity(nodes.len().div_ceil(2));
        let mut index = 0;
        while index < nodes.len() {
            let left = &nodes[index];
            let right = if index + 1 < nodes.len() {
                &nodes[index + 1]
            } else {
                left
            };
            next_level.push(fallback_commitment(
                &format!("{left}:{right}"),
                "merkle-node",
            ));
            index += 2;
        }
        nodes = next_level;
        current_index /= 2;
    }

    Ok(MerkleProof {
        proof,
        root: nodes.into_iter().next().ok_or(CryptoError::EmptyLeaves)?,
    })
}

/// Verify a Merkle membership proof against `root`.
///
/// Malformed proof steps report `false` (the Python raises `ValueError`; the
/// boolean-returning verify contract makes `false` the defensive equivalent).
pub fn fallback_verify_merkle_proof(leaf: &str, proof: &[String], root: &str) -> bool {
    let mut current = fallback_commitment(leaf, "merkle-leaf");
    for proof_item in proof {
        let Some((position, sibling)) = proof_item.split_once(':') else {
            return false;
        };
        let combined = if position == "left" {
            format!("{sibling}:{current}")
        } else {
            format!("{current}:{sibling}")
        };
        current = fallback_commitment(&combined, "merkle-node");
    }
    current == root
}

/// A BLS-shaped signature produced by the fallback mode.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BlsSignature {
    /// `0x`-normalized signature digest.
    pub signature: String,
    /// `0x`-normalized public key digest.
    pub public_key: String,
    /// Message that was signed.
    pub message: String,
}

/// Fallback BLS sign: `pk = sha256("bls-pk:" + sk)`, `sig = sha256(pk + ":bls-sign:" + message)`.
pub fn fallback_bls_sign(private_key: &str, message: &str) -> BlsSignature {
    let public_key = normalize_hex(&sha256_hex(&[&format!("bls-pk:{private_key}")]));
    let signature = normalize_hex(&sha256_hex(&[&public_key, ":bls-sign:", message]));
    BlsSignature {
        signature,
        public_key,
        message: message.to_string(),
    }
}

/// Fallback BLS verify: recompute and compare the signature digest.
pub fn fallback_bls_verify(payload: &BlsSignature) -> bool {
    let expected = normalize_hex(&sha256_hex(&[
        &payload.public_key,
        ":bls-sign:",
        &payload.message,
    ]));
    payload.signature == expected
}

/// Fallback BLS aggregate: `sha256(concat(signatures) + ":aggregate:")`.
pub fn fallback_bls_aggregate(signatures: &[BlsSignature]) -> String {
    let combined: String = signatures
        .iter()
        .map(|sig| sig.signature.as_str())
        .collect();
    normalize_hex(&sha256_hex(&[&combined, ":aggregate:"]))
}

/// Derive an identity commitment: `commit(identity, "identity:v1")`.
pub fn derive_identity_commitment(input: &str) -> String {
    fallback_commitment(input, "identity:v1")
}

/// Derive an identity audit hash: commit the commitment (or the `0x` input)
/// with `"audit:v1"`.
pub fn derive_identity_audit_hash(input: &str) -> String {
    let base = if input.starts_with("0x") {
        input.to_string()
    } else {
        derive_identity_commitment(input)
    };
    fallback_commitment(&base, "audit:v1")
}

/// Redact an identity: `"redacted:" + commit(identity, "redact:v1")`.
pub fn redact_identity(input: &str) -> String {
    format!("redacted:{}", fallback_commitment(input, "redact:v1"))
}

/// Compute a gap witness commitment over gap/slope and prime-sorted couplings.
///
/// The payload is serialized with Python-default separators (`, ` / `: `),
/// matching `json.dumps(..., sort_keys=True)` in the Python `computeGapWitness`.
pub fn compute_gap_witness(gap_lb: f64, slope_ub: f64, couplings: &[Value], salt: &str) -> String {
    let mut sorted_couplings: Vec<Value> = couplings.to_vec();
    sorted_couplings
        .sort_by_key(|coupling| coupling.get("prime").and_then(Value::as_u64).unwrap_or(0));

    let mut object = Map::new();
    object.insert("couplings".to_string(), Value::Array(sorted_couplings));
    object.insert("gapLB".to_string(), Value::from(gap_lb));
    object.insert("slopeUB".to_string(), Value::from(slope_ub));
    object.insert("version".to_string(), Value::String("1.0.0".to_string()));
    object.insert(
        "engine".to_string(),
        Value::String("multiplicity.qpa".to_string()),
    );
    let payload = to_python_style(&Value::Object(object));
    fallback_commitment(&payload, salt)
}

/// Run the QPA prototype and return its fallback result document.
///
/// `params` is serialized canonically (sorted keys) for the shadow/commitment
/// digests; Python used an unstable `str(dict)` there.
pub fn qpa_run_prototype(params: &Value, message: &str, mode: &str, shadow_count: usize) -> Value {
    let primes = params
        .get("primes")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let partition_count = params
        .get("partitionCount")
        .and_then(Value::as_u64)
        .unwrap_or(2);
    let description = params.get("description").cloned().unwrap_or(Value::Null);
    let params_repr = params.to_string();
    let created_at = "1970-01-01T00:00:00Z";

    let instance = json!({
        "id": "qpa-fallback-1",
        "params": params,
        "createdAt": created_at,
    });

    let shadows: Vec<Value> = (0..shadow_count)
        .map(|i| {
            json!({
                "index": i,
                "basis": format!("pauli-{i}"),
                "outcome": normalize_hex(&sha256_hex(&[&params_repr, &i.to_string()])),
            })
        })
        .collect();

    let assignment: Vec<Value> = primes.iter().map(|_| Value::from(0)).collect();

    json!({
        "instance": instance,
        "pmhpInstance": {
            "id": "pmhp-fallback-1",
            "description": description,
            "primes": primes,
            "partitionCount": partition_count,
            "hyperedges": [],
            "constraints": [],
            "createdAt": created_at,
        },
        "state": {
            "instance": instance,
            "status": "committed",
            "summary": { "note": "fallback qpa prototype result" },
        },
        "shadows": shadows,
        "invariant": format!("qpa-invariant-fallback:{message}"),
        "commitment": {
            "commitment": normalize_hex(&sha256_hex(&[&params_repr, message, mode])),
            "mode": mode,
            "description": "fallback qpa prototype commitment",
            "createdAt": created_at,
        },
        "evaluation": {
            "assignment": assignment,
            "cutCost": 0,
            "constraintResiduals": [],
            "totalResidual": 0,
            "objective": 0,
        },
    })
}

/// The multi-crypto bridge, mirroring `MultiplicityCrypto`.
#[derive(Debug, Clone)]
pub struct MultiplicityCrypto {
    bridge_status: BridgeStatus,
}

impl Default for MultiplicityCrypto {
    fn default() -> Self {
        Self::new()
    }
}

impl MultiplicityCrypto {
    /// Create the bridge with `force_fallback` from the environment.
    pub fn new() -> Self {
        Self::with_force_fallback(None)
    }

    /// Create the bridge with an explicit fallback override.
    ///
    /// `force_fallback: None` falls back to the `MULTIPLICITY_CRYPTO_FORCE_FALLBACK`
    /// environment variable, matching the Python constructor.
    pub fn with_force_fallback(force_fallback: Option<bool>) -> Self {
        let force = force_fallback.unwrap_or_else(force_fallback_from_env);
        Self {
            bridge_status: BridgeStatus::resolve(force),
        }
    }

    /// Current bridge status.
    pub fn get_bridge_status(&self) -> BridgeStatus {
        self.bridge_status.clone()
    }

    /// Whether this bridge resolves to fallback (always true here).
    pub fn mode(&self) -> &str {
        &self.bridge_status.mode
    }

    /// `computeCommitment`.
    pub fn compute_commitment(&self, leaf: &str, salt: &str) -> String {
        fallback_commitment(leaf, salt)
    }

    /// `verifyCommitment`.
    pub fn verify_commitment(&self, commitment: &str, leaf: &str, salt: &str) -> bool {
        fallback_commitment(leaf, salt) == commitment
    }

    /// `merkleRoot`.
    pub fn merkle_root(&self, leaves: &[String]) -> Result<String, CryptoError> {
        fallback_merkle_root(leaves)
    }

    /// `generateMerkleProof`.
    pub fn generate_merkle_proof(
        &self,
        leaves: &[String],
        leaf_index: usize,
    ) -> Result<MerkleProof, CryptoError> {
        fallback_generate_merkle_proof(leaves, leaf_index)
    }

    /// `verifyMerkleProof`.
    pub fn verify_merkle_proof(&self, leaf: &str, proof: &[String], root: &str) -> bool {
        fallback_verify_merkle_proof(leaf, proof, root)
    }

    /// `deriveIdentityCommitment`.
    pub fn derive_identity_commitment(&self, input: &str) -> String {
        derive_identity_commitment(input)
    }

    /// `deriveIdentityAuditHash`.
    pub fn derive_identity_audit_hash(&self, input: &str) -> String {
        derive_identity_audit_hash(input)
    }

    /// `redactIdentity`.
    pub fn redact_identity(&self, input: &str) -> String {
        redact_identity(input)
    }

    /// `blsSign`.
    pub fn bls_sign(&self, private_key: &str, message: &str) -> BlsSignature {
        fallback_bls_sign(private_key, message)
    }

    /// `blsVerify`.
    pub fn bls_verify(&self, payload: &BlsSignature) -> bool {
        fallback_bls_verify(payload)
    }

    /// `blsAggregate`.
    pub fn bls_aggregate(&self, signatures: &[BlsSignature]) -> String {
        fallback_bls_aggregate(signatures)
    }

    /// `qpaRunPrototype`.
    pub fn qpa_run_prototype(
        &self,
        params: &Value,
        message: &str,
        mode: &str,
        shadow_count: usize,
    ) -> Value {
        qpa_run_prototype(params, message, mode, shadow_count)
    }

    /// `computeGapWitness`.
    pub fn compute_gap_witness(
        &self,
        gap_lb: f64,
        slope_ub: f64,
        couplings: &[Value],
        salt: &str,
    ) -> String {
        compute_gap_witness(gap_lb, slope_ub, couplings, salt)
    }
}

fn default_bridge() -> &'static MultiplicityCrypto {
    static BRIDGE: OnceLock<MultiplicityCrypto> = OnceLock::new();
    BRIDGE.get_or_init(MultiplicityCrypto::new)
}

/// Module-level `getBridgeStatus` mirror.
pub fn get_bridge_status() -> BridgeStatus {
    default_bridge().get_bridge_status()
}

/// Module-level `compute_commitment`.
pub fn compute_commitment(leaf: &str, salt: &str) -> String {
    fallback_commitment(leaf, salt)
}

/// Module-level `verify_commitment`.
pub fn verify_commitment(commitment: &str, leaf: &str, salt: &str) -> bool {
    fallback_commitment(leaf, salt) == commitment
}

/// Module-level `merkle_root`.
pub fn merkle_root(leaves: &[String]) -> Result<String, CryptoError> {
    fallback_merkle_root(leaves)
}

/// Module-level `generate_merkle_proof`.
pub fn generate_merkle_proof(
    leaves: &[String],
    leaf_index: usize,
) -> Result<MerkleProof, CryptoError> {
    fallback_generate_merkle_proof(leaves, leaf_index)
}

/// Module-level `verify_merkle_proof`.
pub fn verify_merkle_proof(leaf: &str, proof: &[String], root: &str) -> bool {
    fallback_verify_merkle_proof(leaf, proof, root)
}

/// Module-level `derive_identity_commitment`.
pub fn derive_identity_commitment_fn(input: &str) -> String {
    derive_identity_commitment(input)
}

/// Module-level `derive_identity_audit_hash`.
pub fn derive_identity_audit_hash_fn(input: &str) -> String {
    derive_identity_audit_hash(input)
}

/// Module-level `redact_identity`.
pub fn redact_identity_fn(input: &str) -> String {
    redact_identity(input)
}

/// Module-level `compute_gap_witness`.
pub fn compute_gap_witness_fn(
    gap_lb: f64,
    slope_ub: f64,
    couplings: &[Value],
    salt: &str,
) -> String {
    compute_gap_witness(gap_lb, slope_ub, couplings, salt)
}

/// Module-level `bls_sign`.
pub fn bls_sign(private_key: &str, message: &str) -> BlsSignature {
    fallback_bls_sign(private_key, message)
}

/// Module-level `bls_verify`.
pub fn bls_verify(payload: &BlsSignature) -> bool {
    fallback_bls_verify(payload)
}

/// Module-level `bls_aggregate`.
pub fn bls_aggregate(signatures: &[BlsSignature]) -> String {
    fallback_bls_aggregate(signatures)
}

/// Module-level `qpa_run_prototype`.
pub fn qpa_run_prototype_fn(
    params: &Value,
    message: &str,
    mode: &str,
    shadow_count: usize,
) -> Value {
    qpa_run_prototype(params, message, mode, shadow_count)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn normalize_hex_prefixes() {
        assert_eq!(normalize_hex("abc"), "0xabc");
        assert_eq!(normalize_hex("0xabc"), "0xabc");
    }

    #[test]
    fn commitment_and_verify_roundtrip() {
        let commitment = fallback_commitment("fallback-leaf", "fallback-salt");
        assert!(commitment.starts_with("0x"));
        assert_eq!(
            commitment,
            normalize_hex(&sha256_hex(&["fallback-leaf", ":commit:", "fallback-salt"]))
        );
        assert!(verify_commitment(
            &commitment,
            "fallback-leaf",
            "fallback-salt"
        ));
        assert!(!verify_commitment(&commitment, "tampered", "fallback-salt"));
    }

    #[test]
    fn merkle_root_is_deterministic_and_odd_nodes_duplicated() {
        let leaves: Vec<String> = vec!["a".into(), "b".into(), "c".into()];
        let root = fallback_merkle_root(&leaves).unwrap();
        let root_again = fallback_merkle_root(&leaves).unwrap();
        assert_eq!(root, root_again);
        assert!(root.starts_with("0x"));

        // The single-leaf root is just the leaf commitment.
        let single: Vec<String> = vec!["x".into()];
        assert_eq!(
            fallback_merkle_root(&single).unwrap(),
            fallback_commitment("x", "merkle-leaf")
        );

        assert!(matches!(
            fallback_merkle_root(&[]),
            Err(CryptoError::EmptyLeaves)
        ));
    }

    #[test]
    fn merkle_proof_roundtrip_covers_all_leaves() {
        let leaves: Vec<String> = (0..6).map(|i| format!("leaf-{i}")).collect();
        let root = fallback_merkle_root(&leaves).unwrap();
        for index in 0..leaves.len() {
            let proof = fallback_generate_merkle_proof(&leaves, index).unwrap();
            assert_eq!(proof.root, root);
            assert!(fallback_verify_merkle_proof(
                &leaves[index],
                &proof.proof,
                &root
            ));
        }
    }

    #[test]
    fn merkle_proof_rejects_tampering() {
        let leaves: Vec<String> = vec!["a".into(), "b".into(), "c".into(), "d".into()];
        let root = fallback_merkle_root(&leaves).unwrap();
        let proof = fallback_generate_merkle_proof(&leaves, 1).unwrap();
        assert!(!fallback_verify_merkle_proof("a", &proof.proof, &root));
        assert!(!fallback_verify_merkle_proof("zzz", &proof.proof, &root));
        assert!(matches!(
            fallback_generate_merkle_proof(&leaves, 42),
            Err(CryptoError::InvalidLeafIndex)
        ));
    }

    #[test]
    fn bls_sign_verify_aggregate() {
        let sig = fallback_bls_sign("supersecret", "message");
        assert_eq!(
            sig.signature,
            normalize_hex(&sha256_hex(&[&sig.public_key, ":bls-sign:", "message"]))
        );
        assert!(fallback_bls_verify(&sig));

        let second = fallback_bls_sign("anotherkey", "message");
        let aggregate = fallback_bls_aggregate(&[sig.clone(), second.clone()]);
        let combined = format!("{}{}", sig.signature, second.signature);
        assert_eq!(
            aggregate,
            normalize_hex(&sha256_hex(&[&combined, ":aggregate:"]))
        );
    }

    #[test]
    fn identity_commitment_and_redaction() {
        let identity = "alice@example.test";
        let commitment = derive_identity_commitment(identity);
        assert_eq!(commitment, fallback_commitment(identity, "identity:v1"));
        assert!(commitment.starts_with("0x"));

        // Audit hash hashes the *commitment* when the input is bare.
        let bare_audit = derive_identity_audit_hash(identity);
        assert_eq!(bare_audit, fallback_commitment(&commitment, "audit:v1"));

        // And hashes the `0x` input directly when already normalized.
        let prefixed_audit = derive_identity_audit_hash(&commitment);
        assert_eq!(prefixed_audit, fallback_commitment(&commitment, "audit:v1"));
        assert_eq!(bare_audit, prefixed_audit);

        assert_eq!(
            redact_identity(identity),
            format!("redacted:{}", fallback_commitment(identity, "redact:v1"))
        );
        assert!(redact_identity(identity).starts_with("redacted:"));
    }

    #[test]
    fn gap_witness_payload_is_sort_keys_and_prime_sorted() {
        let couplings = json!([
            {"prime": 7, "coupling": 0.9},
            {"prime": 2, "coupling": 0.4},
            {"prime": 3, "coupling": 0.3},
        ]);
        let left_hand = compute_gap_witness(0.5, 0.25, couplings.as_array().unwrap(), "salt");
        assert!(left_hand.starts_with("0x"));

        // Re-sorting identical couplings yields the identical commitment.
        let reordered = json!([
            {"prime": 3, "coupling": 0.3},
            {"prime": 2, "coupling": 0.4},
            {"prime": 7, "coupling": 0.9},
        ]);
        let right_hand = compute_gap_witness(0.5, 0.25, reordered.as_array().unwrap(), "salt");
        assert_eq!(left_hand, right_hand);

        // The committed payload contains the fully-qualified, sorted form.
        let payload = {
            let mut sorted_couplings = couplings.as_array().unwrap().clone();
            sorted_couplings.sort_by_key(|c| c.get("prime").and_then(Value::as_u64).unwrap());
            let mut object = Map::new();
            object.insert("couplings".into(), Value::Array(sorted_couplings));
            object.insert("gapLB".into(), json!(0.5));
            object.insert("slopeUB".into(), json!(0.25));
            object.insert("version".into(), json!("1.0.0"));
            object.insert("engine".into(), json!("multiplicity.qpa"));
            to_python_style(&Value::Object(object))
        };
        assert_eq!(
            payload,
            r#"{"couplings": [{"coupling": 0.4, "prime": 2}, {"coupling": 0.3, "prime": 3}, {"coupling": 0.9, "prime": 7}], "engine": "multiplicity.qpa", "gapLB": 0.5, "slopeUB": 0.25, "version": "1.0.0"}"#
        );
        assert_eq!(left_hand, fallback_commitment(&payload, "salt"));
    }

    #[test]
    fn qpa_prototype_structure() {
        let params = json!({
            "description": "test topologies",
            "primes": [2, 3, 5],
            "partitionCount": 3,
        });
        let result = qpa_run_prototype(&params, "m", "experiment", 2);

        assert_eq!(result["instance"]["id"], "qpa-fallback-1");
        assert_eq!(result["pmhpInstance"]["partitionCount"], 3);
        assert_eq!(
            result["pmhpInstance"]["primes"].as_array().unwrap().len(),
            3
        );
        assert_eq!(result["state"]["status"], "committed");
        assert_eq!(result["shadows"].as_array().unwrap().len(), 2);
        assert_eq!(result["shadows"][0]["basis"], "pauli-0");
        assert!(result["shadows"][0]["outcome"]
            .as_str()
            .unwrap()
            .starts_with("0x"));
        assert_eq!(result["invariant"], "qpa-invariant-fallback:m");
        assert_eq!(result["commitment"]["mode"], "experiment");
        assert_eq!(
            result["evaluation"]["assignment"].as_array().unwrap().len(),
            3
        );
        assert_eq!(result["evaluation"]["objective"], 0);

        // Deterministic across calls.
        assert_eq!(qpa_run_prototype(&params, "m", "experiment", 2), result);
    }

    #[test]
    fn qpa_defaults_match_python() {
        let params = json!({"description": "bare"});
        let result = qpa_run_prototype(&params, "m", "prototype", 0);
        assert_eq!(result["pmhpInstance"]["partitionCount"], 2);
        assert!(result["pmhpInstance"]["primes"]
            .as_array()
            .unwrap()
            .is_empty());
        assert_eq!(
            result["evaluation"]["assignment"].as_array().unwrap().len(),
            0
        );
    }

    #[test]
    fn bridge_resolves_to_fallback_always() {
        let forced = MultiplicityCrypto::with_force_fallback(Some(true));
        let unforced = MultiplicityCrypto::with_force_fallback(Some(false));

        assert_eq!(forced.get_bridge_status().reason, "forced");
        assert_eq!(unforced.get_bridge_status().reason, "bridge-script-missing");
        assert_eq!(forced.mode(), "fallback");
        assert_eq!(unforced.mode(), "fallback");
        assert!(forced.get_bridge_status().available);
    }

    #[test]
    fn bridge_typed_methods_agree_with_free_functions() {
        let bridge = MultiplicityCrypto::with_force_fallback(Some(true));
        assert_eq!(
            bridge.compute_commitment("leaf", "salt"),
            compute_commitment("leaf", "salt")
        );
        assert!(bridge.verify_commitment(
            &bridge.compute_commitment("leaf", "salt"),
            "leaf",
            "salt"
        ));
        assert_eq!(
            bridge.derive_identity_commitment("alice"),
            derive_identity_commitment("alice")
        );
        assert_eq!(bridge.redact_identity("alice"), redact_identity("alice"));
    }
}
