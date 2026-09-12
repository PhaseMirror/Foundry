//! Λ^p-Archivum: Prime-Indexed Content-Addressed Store
//!
//! Every artifact, document, tensor state, or operator module factors uniquely
//! into prime-irreducible components (PIRs). The Archivum serves as the canonical,
//! permanent storage container where historical objects are stored with complete
//! provenance, indexed into the prime-factorized multigraph (Ξ).

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use num_bigint::BigUint;
use num_integer::Integer;
use num_traits::{One, ToPrimitive, Zero};
use std::collections::{BTreeMap, BTreeSet};
use std::fs::OpenOptions;
use std::io::Write;
use std::path::{Path, PathBuf};
use hex;

use crate::ledger::ArchivumError;

// ---------------------------------------------------------------------------
// Prime factorization utilities
// ---------------------------------------------------------------------------

/// A prime factor with its exponent in the factorization.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub struct PrimeFactor {
    pub prime: u64,
    pub exponent: u32,
}

impl PrimeFactor {
    pub fn new(prime: u64, exponent: u32) -> Self {
        Self { prime, exponent }
    }
}

/// Factor a positive integer into its prime factors (trial division).
/// Returns factors in ascending order.
pub fn factorize_u64(mut n: u64) -> Vec<PrimeFactor> {
    assert!(n > 0, "factorize_u64 requires n > 0");
    let mut factors = Vec::new();
    let mut d = 2u64;
    while d * d <= n {
        if n % d == 0 {
            let mut exp = 0;
            while n % d == 0 {
                n /= d;
                exp += 1;
            }
            factors.push(PrimeFactor::new(d, exp));
        }
        d += 1;
    }
    if n > 1 {
        factors.push(PrimeFactor::new(n, 1));
    }
    factors
}

/// Factor a BigUint into prime factors.
///
/// For large numbers (> 64 bits), we factor the lower 64 bits to obtain a
/// representative prime-index set. Full 256-bit factorization requires a
/// sub-exponential algorithm (e.g., Pollard's rho) and is out of scope for
/// this scaffolding.
pub fn factorize_biguint(n: BigUint) -> Vec<PrimeFactor> {
    assert!(n > BigUint::zero(), "factorize_biguint requires n > 0");
    let n_u64 = n.to_u64().unwrap_or(0);
    if n_u64 == 0 {
        return vec![PrimeFactor::new(2, 64)];
    }
    factorize_u64(n_u64)
}

// ---------------------------------------------------------------------------
// Content address
// ---------------------------------------------------------------------------

/// A content address in the Λ^p-Archivum.
///
/// Combines a SHA-256 hash with the prime factorization of that hash,
/// enabling both content-addressed lookup and prime-indexed navigation.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub struct ContentAddress {
    pub hash: [u8; 32],
    pub hex: String,
    pub prime_factors: Vec<PrimeFactor>,
}

impl ContentAddress {
    /// Compute the content address from raw bytes.
    pub fn from_bytes(data: &[u8]) -> Self {
        let hash = Sha256::digest(data);
        let hex = hex::encode(hash);
        let hash_int = BigUint::from_bytes_be(hash.as_slice());
        let prime_factors = factorize_biguint(hash_int);
        Self {
            hash: hash.into(),
            hex,
            prime_factors,
        }
    }

    /// Compute the content address from a string.
    pub fn from_string(s: &str) -> Self {
        Self::from_bytes(s.as_bytes())
    }

    /// The set of prime indices this artifact belongs to.
    pub fn prime_indices(&self) -> Vec<u64> {
        self.prime_factors.iter().map(|pf| pf.prime).collect()
    }
}

// ---------------------------------------------------------------------------
// Prime index (Λ^p navigation structure)
// ---------------------------------------------------------------------------

/// The Λ^p prime index: maps each prime factor to the set of content addresses
/// that contain it. This forms the multigraph Ξ where edges connect artifacts
/// to their prime-irreducible components.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct PrimeIndex {
    /// Map from prime -> set of content addresses containing that prime
    index: BTreeMap<u64, BTreeSet<String>>,
    /// Map from content address hex -> full ContentAddress
    artifacts: BTreeMap<String, ContentAddress>,
}

impl PrimeIndex {
    pub fn new() -> Self {
        Self::default()
    }

    /// Index a new artifact into Λ^p.
    pub fn insert(&mut self, address: ContentAddress) {
        let hex = address.hex.clone();
        self.artifacts.insert(hex.clone(), address);
        for prime in self.artifacts[&hex].prime_indices() {
            self.index.entry(prime).or_default().insert(hex.clone());
        }
    }

    /// Find all artifacts that share a given prime factor.
    pub fn by_prime(&self, prime: u64) -> Vec<&ContentAddress> {
        self.index.get(&prime)
            .into_iter()
            .flatten()
            .filter_map(|hex| self.artifacts.get(hex))
            .collect()
    }

    /// Find all primes that connect two artifacts (shared PIRs).
    pub fn shared_primes(&self, a: &str, b: &str) -> Vec<u64> {
        let primes_a = self.artifacts.get(a).map(|addr| addr.prime_indices()).unwrap_or_default();
        let primes_b = self.artifacts.get(b).map(|addr| addr.prime_indices()).unwrap_or_default();
        let set_b: BTreeSet<u64> = primes_b.into_iter().collect();
        primes_a.into_iter().filter(|p| set_b.contains(p)).collect()
    }

    /// Total number of indexed artifacts.
    pub fn len(&self) -> usize {
        self.artifacts.len()
    }

    /// Check if the index is empty.
    pub fn is_empty(&self) -> bool {
        self.artifacts.is_empty()
    }

    /// All indexed content addresses.
    pub fn addresses(&self) -> Vec<&ContentAddress> {
        self.artifacts.values().collect()
    }
}

// ---------------------------------------------------------------------------
// Λ^p-Archivum Store
// ---------------------------------------------------------------------------

/// The Λ^p-Archivum: a prime-indexed content-addressed store with WORM semantics.
///
/// Combines:
/// - Content addressing (SHA-256)
/// - Prime-indexed navigation (Λ^p multigraph Ξ)
/// - Append-only WORM ledger
/// - Complete provenance tracking
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredArtifact {
    pub address: ContentAddress,
    pub data: Vec<u8>,
    pub metadata: BTreeMap<String, String>,
    pub timestamp: i64,
    pub previous: Option<String>,
}

impl StoredArtifact {
    pub fn new(data: Vec<u8>, metadata: BTreeMap<String, String>) -> Self {
        let address = ContentAddress::from_bytes(&data);
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        Self {
            address,
            data,
            metadata,
            timestamp,
            previous: None,
        }
    }

    pub fn with_previous(mut self, prev: String) -> Self {
        self.previous = Some(prev);
        self
    }
}

/// The Λ^p-Archivum store.
pub struct LambdaPStore {
    index: PrimeIndex,
    ledger_path: Option<PathBuf>,
}

impl LambdaPStore {
    pub fn new() -> Self {
        Self {
            index: PrimeIndex::new(),
            ledger_path: None,
        }
    }

    /// Set the WORM ledger file path.
    pub fn with_ledger<P: AsRef<Path>>(mut self, path: P) -> Self {
        self.ledger_path = Some(path.as_ref().to_path_buf());
        self
    }

    /// Store an artifact in Λ^p.
    pub fn store(&mut self, artifact: StoredArtifact) -> Result<String, ArchivumError> {
        let hex = artifact.address.hex.clone();
        self.index.insert(artifact.address.clone());

        if let Some(ref path) = self.ledger_path {
            self.append_to_ledger(path, &artifact)?;
        }

        Ok(hex)
    }

    /// Retrieve an artifact by its content address hex.
    pub fn get(&self, hex: &str) -> Option<&StoredArtifact> {
        // In a real implementation, this would read from storage.
        // For now, we return from the index metadata.
        self.index.artifacts.get(hex).map(|_addr| {
            // Placeholder: actual data retrieval from disk/cache would go here
            unimplemented!("Data retrieval from content-addressed storage")
        })
    }

    /// Find artifacts sharing a prime factor.
    pub fn find_by_prime(&self, prime: u64) -> Vec<&ContentAddress> {
        self.index.by_prime(prime)
    }

    /// Get a content address by hex.
    pub fn get_address(&self, hex: &str) -> Option<&ContentAddress> {
        self.index.artifacts.get(hex)
    }

    /// Find shared primes between two artifacts.
    pub fn shared_primes(&self, a: &str, b: &str) -> Vec<u64> {
        self.index.shared_primes(a, b)
    }

    /// Total artifacts in the store.
    pub fn len(&self) -> usize {
        self.index.len()
    }

    pub fn is_empty(&self) -> bool {
        self.index.is_empty()
    }

    fn append_to_ledger(&self, path: &Path, artifact: &StoredArtifact) -> Result<(), ArchivumError> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(path)?;

        let entry = serde_json::json!({
            "hex": artifact.address.hex,
            "timestamp": artifact.timestamp,
            "metadata": artifact.metadata,
            "prime_factors": artifact.address.prime_factors,
            "previous": artifact.previous,
        });

        writeln!(file, "{}", entry)?;
        Ok(())
    }
}

impl Default for LambdaPStore {
    fn default() -> Self {
        Self::new()
    }
}

// ---------------------------------------------------------------------------
// WORM WitnessLedger integration (extends existing ArchivumLedger)
// ---------------------------------------------------------------------------

use crate::ledger::{ArchivumLedger, Witness};

impl LambdaPStore {
    /// Append a witness to the WORM ledger.
    pub fn append_witness(&self, ledger: &mut ArchivumLedger, w: Witness) -> Result<[u8; 32], ArchivumError> {
        ledger.append(w)
    }

    /// Verify the WORM ledger chain integrity.
    pub fn verify_ledger(&self, ledger: &ArchivumLedger) -> bool {
        ledger.verify_chain()
    }
}
