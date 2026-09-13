//! Port of `multiplicity/math/cas_registry.py` — content addressable storage
//! with cryptographic commitments for ACE witnesses.
//!
//! The Python module imports `pirtm.ace.types` / `pirtm.ace.witness`, which do
//! not exist anywhere in the repository. This port therefore defines minimal,
//! self-contained [`AceWitness`] / [`AceCertificate`] holders for exactly the
//! fields the registry code uses (`level`, `certified`, `lipschitz_upper`,
//! `gap_lb`, `prime_index`, `witness_id`, `timestamp_iso`) and reproduces the
//! registry semantics on top of the SHA-256 fallback crypto.

use crate::crypto::{self as crypto_mod, fallback_commitment, BridgeStatus};
use crate::jsonfmt::to_python_style;
use serde_json::{json, Value};
use std::collections::BTreeMap;
use std::sync::{Mutex, MutexGuard, OnceLock};

/// Certified level of an ACE certificate (`pirtm.ace.types.CertLevel` stand-in).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct CertLevel(u64);

impl CertLevel {
    /// Build a level from its numeric value.
    pub fn new(value: u64) -> Self {
        Self(value)
    }

    /// The numeric value of this level.
    pub fn value(self) -> u64 {
        self.0
    }
}

/// Minimal self-contained ACE certificate.
#[derive(Debug, Clone)]
pub struct AceCertificate {
    /// Certification level.
    pub level: CertLevel,
    /// Whether this certificate is certified.
    pub certified: bool,
    /// Lipschitz upper bound.
    pub lipschitz_upper: f64,
    /// Spectral gap lower bound.
    pub gap_lb: f64,
}

impl AceCertificate {
    /// Build a certificate.
    pub fn new(level: CertLevel, certified: bool, lipschitz_upper: f64, gap_lb: f64) -> Self {
        Self {
            level,
            certified,
            lipschitz_upper,
            gap_lb,
        }
    }
}

/// Minimal self-contained ACE witness.
#[derive(Debug, Clone)]
pub struct AceWitness {
    /// Unique witness identifier.
    pub witness_id: String,
    /// Prime index the witness certifies against.
    pub prime_index: u64,
    /// ISO-8601 timestamp of certification.
    pub timestamp_iso: String,
    /// Associated certificate.
    pub cert: AceCertificate,
}

impl AceWitness {
    /// Build a witness.
    pub fn new(
        witness_id: impl Into<String>,
        prime_index: u64,
        timestamp_iso: impl Into<String>,
        cert: AceCertificate,
    ) -> Self {
        Self {
            witness_id: witness_id.into(),
            prime_index,
            timestamp_iso: timestamp_iso.into(),
            cert,
        }
    }
}

/// The canonical witness data payload committed by [`CryptoBackedWitness`].
fn witness_data(witness: &AceWitness) -> String {
    to_python_style(&json!({
        "witness_id": witness.witness_id,
        "level": witness.cert.level.value(),
        "certified": witness.cert.certified,
        "lipschitz_upper": witness.cert.lipschitz_upper,
        "gap_lb": witness.cert.gap_lb,
        "prime_index": witness.prime_index,
        "timestamp": witness.timestamp_iso,
    }))
}

/// The canonical Merkle leaf payload for a batch member.
fn leaf_data(commitment: &str, witness_id: &str) -> String {
    to_python_style(&json!({
        "commitment": commitment,
        "witness_id": witness_id,
    }))
}

/// An ACE witness backed by a cryptographic commitment.
#[derive(Debug, Clone)]
pub struct CryptoBackedWitness {
    /// The underlying ACE witness.
    pub witness: AceWitness,
    /// Commitment to the witness data.
    pub commitment: String,
    /// Salt used for the commitment.
    pub salt: String,
    /// Merkle root of the batch this witness belongs to, if batched.
    pub merkle_root: Option<String>,
    /// Merkle membership proof within the batch, if batched.
    pub merkle_proof: Option<Vec<String>>,
    /// Leaf index within the batch's Merkle tree, if batched.
    pub leaf_index: Option<usize>,
}

impl CryptoBackedWitness {
    /// Create a cryptographically-backed witness.
    ///
    /// When `salt` is `None`, the salt is derived as
    /// `sha256("{witness_id}:{timestamp_iso}")` exactly like the Python.
    pub fn create(witness: AceWitness, salt: Option<&str>) -> Self {
        let salt = salt.map(str::to_string).unwrap_or_else(|| {
            crypto_mod::sha256_hex(&[&format!("{}:{}", witness.witness_id, witness.timestamp_iso)])
        });
        let data = witness_data(&witness);
        let commitment = fallback_commitment(&data, &salt);
        Self {
            witness,
            commitment,
            salt,
            merkle_root: None,
            merkle_proof: None,
            leaf_index: None,
        }
    }

    /// Verify witness integrity against the stored commitment.
    pub fn verify_integrity(&self) -> bool {
        let data = witness_data(&self.witness);
        fallback_commitment(&data, &self.salt) == self.commitment
    }

    /// Verify membership in a batch using the stored Merkle proof.
    pub fn verify_batch_membership(&self, expected_root: &str) -> bool {
        match (&self.merkle_proof, self.leaf_index) {
            (Some(proof), Some(_)) => {
                let leaf = leaf_data(&self.commitment, &self.witness.witness_id);
                crypto_mod::fallback_verify_merkle_proof(&leaf, proof, expected_root)
            }
            _ => false,
        }
    }
}

/// One audit-trail entry for a tracked identity.
#[derive(Debug, Clone)]
pub struct AuditEntry {
    /// UTC ISO timestamp of the entry.
    pub timestamp: String,
    /// Witness id involved.
    pub witness_id: String,
    /// Identity commitment.
    pub identity_commitment: String,
    /// Identity audit hash.
    pub identity_audit_hash: String,
    /// Redacted identity.
    pub redacted_identity: String,
    /// Crypto mode at registration time.
    pub crypto_mode: String,
    /// Action label.
    pub action: String,
}

impl AuditEntry {
    fn to_value(&self) -> Value {
        json!({
            "timestamp": self.timestamp,
            "witness_id": self.witness_id,
            "identity_commitment": self.identity_commitment,
            "identity_audit_hash": self.identity_audit_hash,
            "redacted_identity": self.redacted_identity,
            "crypto_mode": self.crypto_mode,
            "action": self.action,
        })
    }
}

/// Content-addressable storage registry for ACE witnesses.
#[derive(Debug)]
pub struct CasRegistry {
    /// witness_id -> backed witness.
    pub witnesses: BTreeMap<String, CryptoBackedWitness>,
    /// batch_id -> ordered witness ids.
    pub merkle_batches: BTreeMap<String, Vec<String>>,
    /// identity_commitment -> identity_audit_hash.
    pub identity_commitments: BTreeMap<String, String>,
    /// Audit trail entries, in registration order.
    pub audit_trail: Vec<AuditEntry>,
    /// Whether the crypto backend is available (always the fallback bridge here).
    pub crypto_available: bool,
    /// Crypto mode (`"fallback"`).
    pub crypto_mode: String,
    /// Full bridge status.
    pub bridge_status: BridgeStatus,
}

impl Default for CasRegistry {
    fn default() -> Self {
        Self::new()
    }
}

impl CasRegistry {
    /// Build an empty registry wired to the fallback crypto bridge.
    pub fn new() -> Self {
        Self {
            witnesses: BTreeMap::new(),
            merkle_batches: BTreeMap::new(),
            identity_commitments: BTreeMap::new(),
            audit_trail: Vec::new(),
            crypto_available: true,
            crypto_mode: "fallback".to_string(),
            bridge_status: crypto_mod::get_bridge_status(),
        }
    }

    /// Register an ACE witness with cryptographic backing.
    ///
    /// Mirrors `CasRegistry.register_witness`: creates the commitment, stores
    /// the witness, attaches Merkle membership when `batch_id` is given, and
    /// records an audit entry when `identity` is given.
    pub fn register_witness(
        &mut self,
        witness: AceWitness,
        identity: Option<&str>,
        batch_id: Option<&str>,
    ) -> CryptoBackedWitness {
        let backed = CryptoBackedWitness::create(witness, None);

        self.witnesses
            .insert(backed.witness.witness_id.clone(), backed.clone());

        if let Some(id) = batch_id {
            self.merkle_batches
                .entry(id.to_string())
                .or_default()
                .push(backed.witness.witness_id.clone());
            self.update_batch_merkle_proofs(id);
        }

        if let Some(identity) = identity {
            self.track_identity(identity, &backed.witness.witness_id);
        }

        backed
    }

    /// Verify a witness's integrity and, when `batch_root` is given, its
    /// membership in that batch.
    pub fn verify_witness(&self, witness_id: &str, batch_root: Option<&str>) -> bool {
        let Some(witness) = self.witnesses.get(witness_id) else {
            return false;
        };
        if !witness.verify_integrity() {
            return false;
        }
        if let Some(root) = batch_root {
            if !witness.verify_batch_membership(root) {
                return false;
            }
        }
        true
    }

    /// Merkle root over a batch's committed leaves, if computable.
    pub fn get_batch_root(&self, batch_id: &str) -> Option<String> {
        let witness_ids = self.merkle_batches.get(batch_id)?;
        let leaves: Vec<String> = witness_ids
            .iter()
            .filter_map(|id| self.witnesses.get(id))
            .map(|w| leaf_data(&w.commitment, &w.witness.witness_id))
            .collect();
        if leaves.is_empty() {
            return None;
        }
        crypto_mod::fallback_merkle_root(&leaves).ok()
    }

    /// (Re)compute Merkle proofs for every witness in a batch.
    fn update_batch_merkle_proofs(&mut self, batch_id: &str) {
        let witness_ids = self.merkle_batches.get(batch_id).cloned();
        let Some(witness_ids) = witness_ids else {
            return;
        };
        if witness_ids.len() < 2 {
            return;
        }

        let leaves: Vec<String> = witness_ids
            .iter()
            .filter_map(|id| self.witnesses.get(id))
            .map(|w| leaf_data(&w.commitment, &w.witness.witness_id))
            .collect();

        let Ok(proofs) = (0..witness_ids.len())
            .map(|i| crypto_mod::fallback_generate_merkle_proof(&leaves, i))
            .collect::<Result<Vec<_>, _>>()
        else {
            return;
        };

        for (i, witness_id) in witness_ids.iter().enumerate() {
            if let Some(witness) = self.witnesses.get_mut(witness_id) {
                witness.merkle_root = Some(proofs[i].root.clone());
                witness.merkle_proof = Some(proofs[i].proof.clone());
                witness.leaf_index = Some(i);
            }
        }
    }

    /// Track an identity with a committed audit entry.
    fn track_identity(&mut self, identity: &str, witness_id: &str) {
        let identity_commitment = crypto_mod::derive_identity_commitment(identity);
        let identity_audit_hash = crypto_mod::derive_identity_audit_hash(&identity_commitment);
        self.identity_commitments
            .insert(identity_commitment.clone(), identity_audit_hash.clone());

        let redacted_identity = crypto_mod::redact_identity(identity);
        self.audit_trail.push(AuditEntry {
            timestamp: now_utc_iso(),
            witness_id: witness_id.to_string(),
            identity_commitment,
            identity_audit_hash,
            redacted_identity,
            crypto_mode: self.crypto_mode.clone(),
            action: "witness_registration".to_string(),
        });
    }

    /// Audit trail, optionally filtered by identity commitment.
    pub fn get_audit_trail(&self, identity_commitment: Option<&str>) -> Vec<Value> {
        self.audit_trail
            .iter()
            .filter(|entry| {
                identity_commitment.is_none()
                    || Some(entry.identity_commitment.as_str()) == identity_commitment
            })
            .map(AuditEntry::to_value)
            .collect()
    }

    /// Statistics about the registry, mirroring `get_witness_stats`.
    pub fn get_witness_stats(&self) -> Value {
        let total_witnesses = self.witnesses.len();
        let certified_witnesses = self
            .witnesses
            .values()
            .filter(|w| w.witness.cert.certified)
            .count();
        let certification_rate = if total_witnesses > 0 {
            certified_witnesses as f64 / total_witnesses as f64
        } else {
            0.0
        };

        json!({
            "total_witnesses": total_witnesses,
            "certified_witnesses": certified_witnesses,
            "certification_rate": certification_rate,
            "batches": self.merkle_batches.len(),
            "identities_tracked": self.identity_commitments.len(),
            "audit_entries": self.audit_trail.len(),
            "crypto_available": self.crypto_available,
            "crypto_mode": self.crypto_mode,
            "crypto_status": {
                "available": self.bridge_status.available,
                "mode": self.bridge_status.mode,
                "reason": self.bridge_status.reason,
            },
        })
    }
}

/// UTC now formatted like Python's naive `datetime.utcnow().isoformat()`.
fn now_utc_iso() -> String {
    chrono::Utc::now()
        .format("%Y-%m-%dT%H:%M:%S%.6f")
        .to_string()
}

fn global_registry() -> &'static Mutex<CasRegistry> {
    static REGISTRY: OnceLock<Mutex<CasRegistry>> = OnceLock::new();
    REGISTRY.get_or_init(|| Mutex::new(CasRegistry::new()))
}

/// Get the global CAS registry instance.
pub fn get_registry() -> MutexGuard<'static, CasRegistry> {
    global_registry()
        .lock()
        .expect("CAS registry mutex poisoned")
}

/// Register an ACE witness in the global registry.
pub fn register_ace_witness(
    witness: AceWitness,
    identity: Option<&str>,
    batch_id: Option<&str>,
) -> CryptoBackedWitness {
    get_registry().register_witness(witness, identity, batch_id)
}

/// Verify an ACE witness in the global registry.
pub fn verify_ace_witness(witness_id: &str, batch_root: Option<&str>) -> bool {
    get_registry().verify_witness(witness_id, batch_root)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_witness(prime_index: u64, suffix: &str) -> AceWitness {
        AceWitness::new(
            format!("w-{suffix}"),
            prime_index,
            "2024-01-01T00:00:00.000000",
            AceCertificate::new(CertLevel::new(2), true, 1.0, 0.05),
        )
    }

    #[test]
    fn witness_commitment_deterministic_and_verifiable() {
        let a = CryptoBackedWitness::create(sample_witness(2, "a"), None);
        let b = CryptoBackedWitness::create(sample_witness(2, "a"), None);
        assert_eq!(a.commitment, b.commitment);
        assert!(a.commitment.starts_with("0x"));
        assert!(a.verify_integrity());

        let mut tampered = a.clone();
        tampered.witness.prime_index = 99;
        assert!(!tampered.verify_integrity());
    }

    #[test]
    fn default_salt_is_sha256_of_id_and_timestamp() {
        let w = sample_witness(2, "salted");
        let expected_salt =
            crypto_mod::sha256_hex(&[&format!("{}:{}", w.witness_id, w.timestamp_iso)]);
        let backed = CryptoBackedWitness::create(w.clone(), None);
        assert_eq!(backed.salt, expected_salt);
        assert_eq!(backed.salt.len(), 64);
    }

    #[test]
    fn explicit_salt_is_respected() {
        let backed = CryptoBackedWitness::create(sample_witness(2, "e"), Some("fixed-salt"));
        assert_eq!(backed.salt, "fixed-salt");
        let data = witness_data(&backed.witness);
        assert_eq!(backed.commitment, fallback_commitment(&data, "fixed-salt"));
    }

    #[test]
    fn batch_registration_produces_verifiable_membership() {
        let mut registry = CasRegistry::new();
        let first = registry.register_witness(
            sample_witness(2, "one"),
            Some("researcher@example.test"),
            Some("batch-1"),
        );
        let second = registry.register_witness(
            sample_witness(3, "two"),
            Some("reviewer@example.test"),
            Some("batch-1"),
        );
        let third = registry.register_witness(sample_witness(5, "three"), None, Some("batch-1"));
        assert!(third.commitment.starts_with("0x"));
        assert!(third.verify_integrity());

        assert!(first.commitment.starts_with("0x"));
        assert!(second.commitment.starts_with("0x"));

        let root = registry
            .get_batch_root("batch-1")
            .expect("batch root exists");
        assert!(root.starts_with("0x"));

        for id in ["w-one", "w-two", "w-three"] {
            assert!(registry.verify_witness(id, Some(&root)));
        }
    }

    #[test]
    fn batch_membership_fails_with_wrong_root() {
        let mut registry = CasRegistry::new();
        registry.register_witness(sample_witness(2, "x"), None, Some("b"));
        registry.register_witness(sample_witness(3, "y"), None, Some("b"));
        let root = registry.get_batch_root("b").unwrap();

        // Multi-witness batch proves membership against its own root.
        assert!(registry.verify_witness("w-x", Some(&root)));
        assert!(registry.verify_witness("w-y", Some(&root)));
        // But not against a fabricated root.
        assert!(!registry.verify_witness("w-x", Some("0xdeadbeef")));
        // A single-witness batch carries no Merkle proof (python returns early
        // when a batch has fewer than 2 witnesses).
        let unbatched = registry.register_witness(sample_witness(7, "z"), None, Some("solo"));
        assert_eq!(unbatched.merkle_proof, None);
        assert!(!unbatched.verify_batch_membership(&root));
    }

    #[test]
    fn identity_audit_trail_is_captured() {
        let mut registry = CasRegistry::new();
        registry.register_witness(sample_witness(2, "z"), Some("alice@example.test"), None);

        assert_eq!(registry.audit_trail.len(), 1);
        let entry = registry.audit_trail[0].to_value();
        assert!(entry["redacted_identity"]
            .as_str()
            .unwrap()
            .starts_with("redacted:"));
        assert_eq!(entry["action"], "witness_registration");
        assert_eq!(entry["crypto_mode"], "fallback");
        assert!((entry["identity_commitment"].as_str().unwrap()).starts_with("0x"));

        // The audit hash is committed over the identity commitment.
        let commitment = entry["identity_commitment"].as_str().unwrap();
        assert_eq!(
            entry["identity_audit_hash"],
            json!(crypto_mod::derive_identity_audit_hash(commitment))
        );
    }

    #[test]
    fn stats_match_python_shape() {
        let mut registry = CasRegistry::new();
        registry.register_witness(sample_witness(2, "a"), Some("id@example.test"), Some("b1"));
        registry.register_witness(sample_witness(3, "b"), None, None);

        let stats = registry.get_witness_stats();
        assert_eq!(stats["total_witnesses"], 2);
        assert_eq!(stats["certified_witnesses"], 2);
        assert_eq!(stats["certification_rate"], 1.0);
        assert_eq!(stats["batches"], 1);
        assert_eq!(stats["identities_tracked"], 1);
        assert_eq!(stats["audit_entries"], 1);
        assert_eq!(stats["crypto_available"], true);
        assert_eq!(stats["crypto_mode"], "fallback");
        assert_eq!(stats["crypto_status"]["mode"], "fallback");
    }

    #[test]
    fn unknown_witness_and_nonexistent_batch() {
        let registry = CasRegistry::new();
        assert!(!registry.verify_witness("missing", None));
        assert_eq!(registry.get_batch_root("nope"), None);
    }
}
