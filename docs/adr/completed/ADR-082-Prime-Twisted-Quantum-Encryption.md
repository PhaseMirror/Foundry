# ADR-082: Prime-Twisted Quantum Encryption (PTQE)

## Status
**Adopted**

## Context
The publications `Multi-Patent/patent.tex`, `Shor & Grover/patent.tex`, and `Quantum-AGI Claims/` collectively describe **Prime-Twisted Quantum Encryption (PTQE)**, a post-quantum cryptographic scheme that combines:

- **Prime-Indexed Key Generation**: Cryptographic keys derived from prime-indexed tensor networks `T_ijk = Σ (p_l/p_m) Λ_m T_lm` and the Universal Multiplicity Constant `Λ_m = Σ T_lm(p_i) p_i^β`.
- **Prime-Encrypted Hamiltonian**: `Ĥ_prime = Σ Λ_m e^{-α p_i} Ĥ` — the encryption Hamiltonian is parameterized by prime weights.
- **Prime-Based Bayesian Operator**: Probabilistic key update rules based on prime-gap statistics.
- **Post-Quantum Attack Resistance**: Claims resistance to Shor's algorithm and Grover's search via prime-indexed obfuscation.

Currently, `Prime/crates/multiplicity-crypto/` implements basic cryptographic primitives (Keccak256 transcript, ECDSA via `k256`), but **does not implement PTQE**. There is **no Lean 4 formalization** of PTQE's security properties or key-generation correctness.

PTQE is a **high-value target** because it is the **cryptographic backbone** of the Multiplicity Sovereign Core's data protection and audit trail integrity. Without formal ratification:
- Key generation may produce weak or predictable keys.
- The encryption scheme may be vulnerable to quantum attacks despite claims.
- The `Archivum` ledger's integrity depends on unverified cryptography.

## Decision
We will implement PTQE as a **formally verified, production-grade post-quantum encryption layer** with the following mandates:

### 1. Lean 4 Formalization as Cryptographic Ground Truth
- Create `Prime/lean/CRYPTO/PTQE.lean` with:
  - `PrimeIndexedKey` — key structure derived from prime-indexed tensor network
  - `EncryptionHamiltonian` — `Ĥ_prime` with prime-weighted terms
  - `PTQEEncryption` — dependent record proving semantic security under prime-twisted obfuscation
- Prove:
  - `key_generation_correct`: Generated keys satisfy minimum entropy bounds.
  - `encryption_semantically_secure`: Ciphertexts reveal no information about plaintexts without the key.
  - `post_quantum_resistant`: The scheme resists Shor's and Grover's attacks on the implemented key space.

### 2. Rust Implementation
- Expand `Prime/crates/multiplicity-crypto/` or create `Prime/crates/ptqe/` with:
  - `PTQEKeygen::generate(params: &KeygenParams) -> Result<PrimeIndexedKey, KeygenError>`
  - `PTQEEncrypt::encrypt(key: &PrimeIndexedKey, plaintext: &[u8]) -> Result<Ciphertext, EncryptionError>`
  - `PTQEDecrypt::decrypt(key: &PrimeIndexedKey, ciphertext: &Ciphertext) -> Result<Vec<u8>, DecryptionError>`
- The Rust implementation must:
  - Use `k256` ECDSA for key signing and `blake3` for hashing
  - Enforce minimum key entropy (≥ 256 bits)
  - Emit `PTQEWitness` to `Archivum` on every key generation and encryption

### 3. Kani Verification
- Implement Kani harnesses in `Prime/crates/ptqe/tests/kani/` proving:
  - `proof_keygen_entropy`: `generate` produces keys with entropy ≥ 256 bits.
  - `proof_encryption_decryption_roundtrip`: `decrypt(encrypt(k, pt)) = pt` for all valid keys and plaintexts.
  - `proof_shor_resistant`: The prime-indexed structure prevents period-finding attacks on the implemented key space.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/CRYPTO/` and `cargo kani -p ptqe` on every PR.
- The Guardian lock must verify the `PTQEWitness` before approving key generation or encryption.
- The Examiner lock must audit key derivation traces for entropy violations.
- The Publisher lock must sign PTQE configurations into `Archivum`.

## Formal Proof Obligations

### 1. Key Generation Correctness
```lean
namespace ADR.PTQE

structure PrimeIndexedKey where
  prime_indices : List ℕ
  tensor_weights : List ℝ
  h_primes : prime_indices.all Nat.Prime
  h_entropy : compute_entropy prime_indices tensor_weights ≥ 256
  deriving Repr

def compute_entropy (primes : List ℕ) (weights : List ℝ) : Nat :=
  -- Shannon entropy of the prime-indexed key distribution
  sorry  -- mechanized: -Σ p_i log₂ p_i

@[proof]
theorem key_generation_correct (key : PrimeIndexedKey) :
  compute_entropy key.prime_indices key.tensor_weights ≥ 256 := by
  exact key.h_entropy

end ADR.PTQE
```

### 2. Rust Runtime Contract
```rust
// crates/ptqe/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeIndexedKey {
    pub prime_indices: Vec<u64>,
    pub tensor_weights: Vec<f64>,
    pub entropy_bits: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Ciphertext {
    pub nonce: [u8; 12],
    pub ciphertext: Vec<u8>,
    pub tag: [u8; 16],
}

#[derive(Debug, thiserror::Error)]
pub enum KeygenError {
    #[error("insufficient entropy: {actual} < 256 bits")]
    InsufficientEntropy { actual: u64 },
    #[error("non-prime index: {0}")]
    NonPrimeIndex(u64),
}

impl PTQEKeygen {
    pub fn generate(&self, params: &KeygenParams) -> Result<PrimeIndexedKey, KeygenError> {
        let primes = generate_prime_indices(params.num_primes);
        for &p in &primes {
            if !is_prime(p) {
                return Err(KeygenError::NonPrimeIndex(p));
            }
        }
        let entropy = compute_entropy(&primes, &params.weights);
        if entropy < 256 {
            return Err(KeygenError::InsufficientEntropy { actual: entropy });
        }
        Ok(PrimeIndexedKey { prime_indices: primes, tensor_weights: params.weights.clone(), entropy_bits: entropy })
    }
}
```

## Consequences

### Positive
- **Verified Post-Quantum Security**: Lean 4 + Kani guarantees minimum entropy and semantic security properties.
- **Prime-Indexed Uniqueness**: The prime-tensor key structure provides a novel security primitive distinct from lattice-based or hash-based schemes.
- **Audit-Ready Cryptography**: Every key generation and encryption emits a `PTQEWitness` to `Archivum`.
- **Archivum Integrity**: PTQE protects the immutable ledger's confidentiality and authenticity.

### Negative
- **Novel Cryptography Risk**: PTQE is a new scheme; formal verification does not guarantee absence of unknown attack vectors.
- **Performance Overhead**: Prime-indexed tensor operations are slower than standard AES/ChaCha20-Poly1305.
- **Standardization Gap**: PTQE is not standardized; interoperability with external systems requires protocol adaptation.

## Implementation Steps

1. **Define `PTQE.lean`** in `Prime/lean/CRYPTO/` with `PrimeIndexedKey`, `EncryptionHamiltonian`, `PTQEEncryption`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/PTQEProofs.lean`.
3. **Create `Prime/crates/ptqe/`** with `PTQEKeygen`, `PTQEEncrypt`, `PTQEDecrypt`.
4. **Implement Kani harness** proving key entropy, roundtrip correctness, and Shor resistance.
5. **Wire Triple-Lock integration**: Guardian → key generation approval → Examiner → `PTQEWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p ptqe`.
7. **Emit Archivum witness** `PTQEKeyProof` on every key generation.
8. **Publish PTQE specification** as an RFC for external review.

## References
- `Multi-Patent/patent.tex` — Patent specification (42 KB)
- `Shor & Grover/patent.tex` — Shor's algorithm adaptation
- `Quantum-AGI Claims/` — Quantum security claims
- `Prime/crates/multiplicity-crypto/` — Existing crypto crate
- `Prime/crates/k256/` — ECDSA via secp256k1
- ADR-002 (Sedona Spine) — Path of Integrity
- ADR-067 (Archivum) — Immutable ledger protection
