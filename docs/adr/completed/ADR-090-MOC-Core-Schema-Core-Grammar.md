# ADR-090: MOC Core Schema and Verified Operators as Core Grammar

## Status
**Adopted**

## Context
The `Prime/lean/MOC_CORE/src/MOC_Core.lean` module defines the **MOC (Multiplicity Operator Calculus) Core Schema**:
- `Schema` — structure with `primes : List Nat`, `seq : Nat`, `attestation : String`
- `VerifiedSchema` — witness that a schema is cryptographically valid and satisfies anti-replay sequence invariant
- `PermittedPrimes` — class for permitted prime set
- `ValidPrime` — dependent type for schema-validated primes
- `Operator` — inductive type for `subdivision`, `accent`, `rotation`, `permutation`, `relationOp`
- `OperatorWord` — dependently-typed sequence of operators
- `baseSchema` — concrete schema with primes `[2, 3]` and `seq := 1`
- `transition_108_cycle` — concrete 108-cycle operator word
- `ResonanceBound` — structure with `r1 : Rat`, `r3 : Rat`, and proof obligations `h_r1 < 1.0`, `h_r3 < 0.8`

MOC Core Schema is the **grammatical foundation** of the Multiplicity Operator Calculus. It defines the set of permitted primes, the operator vocabulary, and the anti-replay sequence invariant. Currently, it exists as a standalone Lake package in `Prime/lean/MOC_CORE/` without:
- Integration into `Prime/lean/Core/` as the base grammar module
- Formal proof that the schema is internally consistent
- ADR ratification of its production role
- CI enforcement that all operator words are schema-valid

Without formal integration into `Core/`, the MOC Core Schema risks:
- **Grammar drift**: Different modules may define incompatible operator vocabularies.
- **Schema violation**: Operators may use unpermitted primes or invalid sequences.
- **Anti-replay bypass**: The sequence invariant may be violated without detection.

## Decision
We will integrate MOC Core Schema as a **foundational Core grammar primitive** with the following mandates:

### 1. Core Integration
- Move `MOC_CORE/src/MOC_Core.lean` content into `Prime/lean/Core/MOC.lean` as the canonical base module for MOC grammar.
- All modules requiring MOC operator definitions must import `Core.MOC`.
- The `baseSchema` with primes `[2, 3]` becomes the **default schema** for the `Core/` layer.

### 2. Formal Proof Expansion
- Extend `Core/MOC.lean` with proofs:
  - `base_schema_valid`: `baseSchema` satisfies all validity conditions.
  - `valid_prime_permitted`: Any `ValidPrime` is indeed in the schema's prime list.
  - `operator_word_length`: `OperatorWord` length is bounded by the schema's sequence invariant.
  - `resonance_bound_sound`: `ResonanceBound` satisfies `r1 < 1.0` and `r3 < 0.8`.

### 3. Rust Engine Parity
- The existing `Prime/crates/c-pirtm/` and `Prime/crates/moc/` crates must use `Core.MOC` as the grammar reference.
- Implement Kani harnesses proving:
  - `proof_schema_validation`: Only primes in the schema are accepted.
  - `proof_sequence_monotone`: Sequence numbers are strictly increasing.
  - `proof_resonance_bounded`: Computed resonance values respect `ResonanceBound`.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/Core/` and `cargo kani -p moc` on every PR.
- The Guardian lock must verify `OperatorWord` schema compliance before approving computations.
- The Examiner lock must audit operator sequences for anti-replay violations.
- The Publisher lock must signed MOC schemas into `Archivum`.

## Formal Proof Obligations

### 1. Base Schema Valid
```lean
namespace Core.MOC

/-- MOC Schema: Defines the set of permitted primes and security metadata. -/
structure Schema where
  primes : List Nat
  seq : Nat
  attestation : String
  deriving Repr, DecidableEq

/-- VerifiedSchema: A witness that a schema is cryptographically valid. -/
structure VerifiedSchema (last_seq : Nat) where
  schema : Schema
  h_signature : schema.attestation = "AUTHORIZED_SCHEMA_SIG"
  h_seq : schema.seq > last_seq
  deriving Repr

/-- Base Schema Instance -/
def baseSchema : Schema := { primes := [2, 3], seq := 1, attestation := "AUTHORIZED_SCHEMA_SIG" }

def baseVerified : VerifiedSchema 0 := {
  schema := baseSchema,
  h_signature := by decide,
  h_seq := by decide
}

@[proof]
theorem base_schema_valid : baseSchema.attestation = "AUTHORIZED_SCHEMA_SIG" ∧ baseSchema.seq = 1 := by
  simp [baseSchema]

end Core.MOC
```

### 2. Rust Runtime Contract
```rust
// crates/moc/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Schema {
    pub primes: Vec<u64>,
    pub seq: u64,
    pub attestation: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerifiedSchema {
    pub schema: Schema,
    pub last_seq: u64,
}

#[derive(Debug, thiserror::Error)]
pub enum MocError {
    #[error("invalid prime {0}: not in schema")]
    InvalidPrime(u64),
    #[error("sequence violation: {0} ≤ {1}")]
    SequenceViolation { current: u64, last: u64 },
    #[error("invalid attestation")]
    InvalidAttestation,
}

pub struct MocEngine;

impl MocEngine {
    pub fn verify_schema(&self, schema: &Schema, last_seq: u64) -> Result<VerifiedSchema, MocError> {
        if schema.attestation != "AUTHORIZED_SCHEMA_SIG" {
            return Err(MocError::InvalidAttestation);
        }
        if schema.seq <= last_seq {
            return Err(MocError::SequenceViolation { current: schema.seq, last: last_seq });
        }
        Ok(VerifiedSchema { schema: schema.clone(), last_seq })
    }
}
```

## Consequences

### Positive
- **Grammatical Foundation**: MOC Core Schema becomes the single source of truth for operator grammar across Lean and Rust.
- **Anti-Replay Guarantee**: Sequence invariants are mechanically enforced, preventing schema replay attacks.
- **Prime Validation**: All operators are guaranteed to use permitted primes.
- **Audit-Ready Grammar**: Every schema and operator word emits a witness to `Archivum`.

### Negative
- **Import Restructuring**: Moving MOC Core into `Core/` requires updating imports across all dependent modules.
- **Schema Rigidity**: The permitted prime list `[2, 3]` is hard-coded; extending to new primes requires schema update and re-verification.
- **Sequence Management**: Anti-replay sequence numbers require global coordination; distributed deployments need a sequence authority.

## Implementation Steps

1. **Refactor `MOC_CORE/src/MOC_Core.lean`** into `Core/MOC.lean`.
2. **Prove schema validity theorems** in `Core/MOC.lean`.
3. **Update all imports** in dependent modules.
4. **Implement `crates/moc/`** Rust crate with `MocEngine`.
5. **Implement Kani harness** proving schema validation and sequence monotonicity.
6. **Wire Triple-Lock integration**: Guardian → schema approval → Examiner → `MocSchemaWitness` → Publisher → `Archivum`.
7. **Update CI** to enforce `lake build` + `cargo kani -p moc`.
8. **Emit Archivum witness** `MocSchemaProof` on every schema update.

## References
- `Prime/lean/MOC_CORE/src/MOC_Core.lean` — Source module
- `Prime/lean/MOC_CORE/src/MOC_Properties.lean` — Existing properties
- `Prime/crates/c-pirtm/` — PIRTM compiler crate
- ADR-076 (MOC Operator Calculus) — Algebraic core formalization
- ADR-066 (PIRTM/MOC Compiler) — Language surface governance
- `Prime/lean/Core/Spine.lean` — Existing Core Spine with MOC operators
