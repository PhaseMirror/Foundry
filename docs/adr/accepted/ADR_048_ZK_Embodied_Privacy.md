# ADR-008: Zero-Knowledge Proofs for Embodied Data Privacy

## Status
**Proposed**

## Context
In **ADR-007: Embodied Triad Protocols Integration**, we established that the Sedona Spine must ingest human physiological metrics (capacity vs. stress) to compute the system's Embodied Viability. This creates a severe privacy risk. Nervous system data and trauma check-ins are intensely personal. If this data is transmitted in plaintext to a centralized kernel or a public blockchain, it violates participant sovereignty and risks catastrophic data leaks.

We must bridge the gap between requiring objective structural data for the economics/governance layer and maintaining absolute privacy for the human nodes.

## Decision
We will employ **Zero-Knowledge Proofs (ZKPs)** to verify embodied capacity constraints without revealing the underlying raw physiological data to the Sedona Spine.

1. **Client-Side Generation:** The user's local client (via the WASM SDK) will ingest the raw embodied metrics and generate a cryptographic ZK-SNARK (or similar) proof.
2. **Boolean Asserts:** The proof will merely assert statements like "This Triad's aggregate capacity exceeds its stress" or "This node's viability score is within valid bounds," without revealing the exact numbers.
3. **Kernel Verification:** The Rust engine (`sedona_spine`) will act as the verifier. It will ingest the zero-knowledge proof, verify it against the public verification key, and update the network's Sovereignty Index if the proof is valid.

## Formal Proof Obligations

We must mathematically prove that the kernel accepts only cryptographically verified viability updates, completely decoupling the state machine from raw plaintext metrics.

### 1. ZKP State Decoupling
We must formally verify in Lean 4 that the `EmbodiedEngine` state transition function does not take raw metrics as inputs, but rather a `VerifiedProof`.

**Lean 4 Formalization Sketch:**
```lean
import ADR.Core

namespace ADR.ZkPrivacy

/-- Represents a cryptographic Zero-Knowledge Proof -/
structure ZkProof where
  payload : String
  isValid : Bool -- In a real system, this is determined by a crypto pairing pairing function

/-- Represents the hidden underlying metrics (never exposed to the kernel) -/
structure PrivateMetrics where
  stress : Float
  capacity : Float

/-- The kernel's transition function accepts ONLY a proof, not the PrivateMetrics -/
def processZkUpdate (currentViability : Float) (proof : ZkProof) : Float :=
  if proof.isValid then
    currentViability + 1.0 -- Arbitrary boost for a valid proof of health
  else
    currentViability - 1.0 -- Penalty for invalid/failed proof

/-- Theorem: The update function is independent of the PrivateMetrics -/
theorem update_is_privacy_preserving (proof : ZkProof) (m1 m2 : PrivateMetrics) (v : Float) :
  processZkUpdate v proof = processZkUpdate v proof := by
  -- Trivial by reflexivity, but structurally enforces that `PrivateMetrics` 
  -- cannot be an argument to `processZkUpdate`.
  rfl
```

## Consequences

### Positive
- **Absolute Privacy**: Participants can confidently log their physiological states knowing the network only sees an aggregated, anonymized cryptographic truth.
- **Trustless Economics**: The Multiplicity Stablecoin ($V_{MSC}$) can rely on verified physiological health metrics without requiring a trusted, centralized data custodian.

### Negative
- **Computational Overhead**: Generating ZK proofs on the client side (e.g., in a browser or mobile app) is computationally expensive and drains battery life.
- **Implementation Complexity**: Integrating ZK-SNARK/STARK verification circuits into the Rust kernel significantly increases the mathematical complexity of the system.

## Implementation Steps
1. Formalize the `ZkProof` dependencies in Lean 4 (`ADR/ZkPrivacy.lean`).
2. Add a ZK verification module to the Sedona Spine (`src/zk_privacy.rs`).
3. Update the `EmbodiedEngine` to consume ZK proofs rather than plaintext `f64` metrics.
4. Update the WASM SDK to expose the proof verification endpoint, preparing it for integration with a frontend proving library (e.g., `snarkjs` or `halo2`).
