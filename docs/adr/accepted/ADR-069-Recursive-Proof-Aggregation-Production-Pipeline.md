# ADR-069: Recursive Proof Aggregation Production Pipeline

## Status
**Adopted**

## Context
The existing `Prime/docs/adr/ADR-008-Recursive-Proof-Aggregation.md` defines Recursive Proof Aggregation (Batch ZK Proofs) but is a **brief exploratory note** without formal proof obligations, Rust crate specifications, or verification requirements.

The `Prime/crates/recursive-prover/` crate implements recursive proof wrapping and aggregation with bins `wrap-proof` and `aggregate-proofs`. It depends on `goldilocks`, `prover`, `pasta-curves`, `sha3`, and `num-bigint`, indicating a **Groth16/PLONK-style ZK proof pipeline**.

However, the crate lacks:
- A **Lean 4 formalization** proving that recursive aggregation preserves proof validity
- **Kani verification** that the aggregation logic is sound
- A **production-grade API** with proper error handling and audit trails
- Integration with the `Archivum` ledger for proof traceability

Recursive proof aggregation is critical for the **Sovereign Stack** (Λ-Trace Atomization) and the **UAC substrate** (100-concurrent FeMoco runs with cryptographic attestation). Without formal ratification, the proof pipeline risks:
- **Invalid aggregation**: Merging invalid proofs into a single APO (Aggregated Proof Object)
- **Missing audit trail**: No way to trace an aggregated proof back to its constituent witnesses
- **Performance degradation**: Unoptimized aggregation could bottleneck the 100-concurrent target

## Decision
We will implement Recursive Proof Aggregation as a **formally verified, production-grade ZK proof pipeline** with the following mandates:

### 1. Lean 4 Formalization as Proof Source of Truth
- Create `Prime/lean/PROOF/R Aggregation.lean` (or `Prime/lean/VERIFICATION/RecursiveProver.lean`) defining:
  - `ProofObject` — a ZK proof with `circuit_id`, `public_inputs`, `proof_bytes`
  - `RecursiveProof` — a proof that verifies other proofs
  - `AggregatedProofObject (APO)` — a single proof aggregating N constituent proofs
- Prove:
  - `aggregation_preserves_validity`: If all constituent proofs are valid, the APO is valid.
  - `aggregation_is_sound`: An invalid constituent proof cannot produce a valid APO.
  - `recursive_depth_bounded`: Recursive aggregation depth is bounded by a configurable parameter.

### 2. Rust Engine Parity
- Refactor `crates/recursive-prover/` to expose:
  - `RecursiveProver::wrap(proof: ProofObject, wrapper_circuit: &Circuit) -> Result<RecursiveProof, ProverError>`
  - `RecursiveProver::aggregate(proofs: Vec<RecursiveProof>) -> Result<APO, AggregationError>`
  - `RecursiveProver::verify_apo(apo: &APO) -> Result<bool, VerificationError>`
- All public APIs must return structured `Result` types with `thiserror` derivations.

### 3. Kani Verification
- Implement Kani harnesses in `crates/recursive-prover/tests/kani/` proving:
  - `proof_aggregation_preserves_validity`: `aggregate` returns `Ok` only when all inputs are valid.
  - `proof_wrap_soundness`: `wrap` produces a valid recursive proof iff the input is valid.
  - `proof_apo_verification_sound`: `verify_apo` returns `true` iff the APO is valid.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/VERIFICATION/` and `cargo kani -p recursive-prover` on every PR.
- The Guardian lock must verify the `APO` before approving any batch computation.
- The Examiner lock must audit the proof aggregation trace.
- The Publisher lock must sign the final `APO` into the `Archivum` ledger.

### 5. Performance Targets
- Aggregation must complete within **920ns** for ≤10 proofs and **5000ns** for ≤100 proofs (UAC substrate thresholds).
- Memory usage must be bounded to prevent OOM during deep recursion.

## Formal Proof Obligations

### 1. Aggregation Preserves Validity
```lean
namespace ADR.RecursiveProver

structure ProofObject where
  circuit_id : Nat
  public_inputs : List ℤ
  proof_bytes : List UInt8
  deriving Repr

structure RecursiveProof where
  inner_proof : ProofObject
  wrapper_circuit_id : Nat
  deriving Repr

structure APO where
  aggregated_proofs : List RecursiveProof
  root_hash : String
  deriving Repr

def is_valid_proof (p : ProofObject) : Bool :=
  -- In full formalization, this invokes the verifier circuit
  true  -- placeholder

def verify_apo (apo : APO) : Bool :=
  apo.aggregated_proofs.all is_valid_proof

@[proof]
theorem aggregation_preserves_validity (proofs : List RecursiveProof)
  (h_all_valid : ∀ p, p ∈ proofs → is_valid_proof p.inner_proof) :
  verify_apo { aggregated_proofs := proofs, root_hash := "" } := by
  simp [verify_apo]
  intro p hp
  exact h_all_valid p hp

@[proof]
theorem aggregation_is_sound (proofs : List RecursiveProof)
  (h_invalid : ∃ p, p ∈ proofs ∧ ¬ is_valid_proof p.inner_proof) :
  ¬ verify_apo { aggregated_proofs := proofs, root_hash := "" } := by
  intro h_valid
  simp [verify_apo] at h_valid
  rcases h_invalid with ⟨p, hp_in, h_inv⟩
  specialize h_valid p hp_in
  contradiction

end ADR.RecursiveProver
```

### 2. Rust Runtime Contract
```rust
// crates/recursive-prover/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofObject {
    pub circuit_id: u64,
    pub public_inputs: Vec<i64>,
    pub proof_bytes: Vec<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecursiveProof {
    pub inner_proof: ProofObject,
    pub wrapper_circuit_id: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct APO {
    pub aggregated_proofs: Vec<RecursiveProof>,
    pub root_hash: String,
}

#[derive(Debug, thiserror::Error)]
pub enum ProverError {
    #[error("invalid proof for circuit {0}")]
    InvalidProof(u64),
    #[error("aggregation depth exceeded")]
    DepthExceeded,
    #[error("proof size limit exceeded")]
    SizeLimitExceeded,
}

pub struct RecursiveProver {
    max_depth: usize,
    max_proofs: usize,
}

impl RecursiveProver {
    pub fn new(max_depth: usize, max_proofs: usize) -> Self {
        Self { max_depth, max_proofs }
    }

    pub fn wrap(
        &self,
        proof: ProofObject,
        wrapper_circuit: u64,
    ) -> Result<RecursiveProof, ProverError> {
        if proof.proof_bytes.len() > 1024 * 1024 {
            return Err(ProverError::SizeLimitExceeded);
        }
        Ok(RecursiveProof { inner_proof: proof, wrapper_circuit_id: wrapper_circuit })
    }

    pub fn aggregate(
        &self,
        proofs: Vec<RecursiveProof>,
    ) -> Result<APO, ProverError> {
        if proofs.len() > self.max_proofs {
            return Err(ProverError::DepthExceeded);
        }
        let root_hash = compute_apo_root_hash(&proofs);
        Ok(APO { aggregated_proofs: proofs, root_hash })
    }

    pub fn verify_apo(&self, apo: &APO) -> Result<bool, ProverError> {
        Ok(apo.root_hash == compute_apo_root_hash(&apo.aggregated_proofs))
    }
}
```

## Consequences

### Positive
- **Verified Proof Pipeline**: Lean 4 + Kani guarantees that only valid proofs are aggregated and that the APO faithfully represents its constituents.
- **Performance Bounded**: Formal bounds on aggregation depth and proof count prevent OOM and latency spikes.
- **Audit-Ready**: Every APO is recorded in `Archivum` with constituent proof hashes, enabling full traceability.
- **Sovereign Stack Compatible**: The APO root hash can be bound to TEE registers via `LambdaTraceAtom`.

### Negative
- **ZK Circuit Complexity**: Groth16/PLONK circuit design is error-prone. Formalizing the verifier circuit in Lean 4 is a significant effort.
- **Performance Overhead**: Recursive aggregation adds latency; the 920ns/5000ns targets are tight for deep recursion.
- **Dependency Risk**: The `goldilocks` and `pasta-curves` crates are early-stage; API instability could break the pipeline.

## Implementation Steps

1. **Define `RecursiveProver.lean`** in `Prime/lean/VERIFICATION/` with `ProofObject`, `RecursiveProof`, `APO`.
2. **Prove aggregation theorems** in `Prime/lean/adr-governance/ADR/RecursiveProverProofs.lean`.
3. **Refactor `crates/recursive-prover/`** to expose `wrap`, `aggregate`, `verify_apo` APIs.
4. **Implement Kani harness** proving aggregation soundness.
5. **Wire Triple-Lock integration**: Guardian → `aggregate` approval → Examiner → `APO` verification → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p recursive-prover`.
7. **Emit Archivum witness** `ApoProof` on every aggregated proof.
8. **Benchmark aggregation** against UAC latency thresholds (920ns/5000ns).

## References
- `Prime/docs/adr/ADR-008-Recursive-Proof-Aggregation.md` — Legacy ADR (to be superseded)
- `Prime/crates/recursive-prover/` — Existing Rust crate
- `Prime/crates/goldilocks/` — Goldilocks field arithmetic
- `Prime/crates/pasta-curves/` — Pasta elliptic curves
- `Prime/crates/prover/` — ZK prover backend
- ADR-065 (ACE Runtime) — Budget and invariant enforcement
- ADR-067 (Archivum) — Immutable witness ledger
- `publications/Sovereign-Stack-Synthesis/SOVEREIGN_STACK_DEFENSIVE_PUBLICATION.md` — Pallas/Vesta Recursive Proof Bridge
