# ADR-086: Goldilocks Finite Field as Core Algebraic Primitive

## Status
**Adopted**

## Context
The `Prime/lean/GOLDILOCKS/Core.lean` module defines the **Goldilocks finite field**:
- `p : Nat := 2^64 - 2^32 + 1` (the Goldilocks prime)
- `Field := Fin p` — the finite field over `p`
- `Coe Nat Field` — natural number coercion into the field
- `Sub Field` — field subtraction
- `Field.pow` — field exponentiation

The Goldilocks field is the **foundational algebraic primitive** for the entire Multiplicity cryptographic and arithmetic stack. It is used by:
- `pasta-curves` Rust crate (Pallas/Vesta curves over Goldilocks)
- `recursive-prover` Rust crate (ZK proof aggregation)
- `goldilocks` and `goldilocks-pro` Rust crates
- `digital-twin` Rust crate (LambdaTraceAtom TEE binding)

Currently, Goldilocks exists as a standalone Lean module in `Prime/lean/GOLDILOCKS/` without:
- Integration into `Prime/lean/Core/` as a base algebraic primitive
- Formal proof of field axioms (associativity, commutativity, distributivity, inverses)
- ADR ratification of its production role
- CI enforcement that all field operations are verified

Without formal integration into `Core/`, the Goldilocks field risks:
- **Algebraic drift**: Different modules may assume different field properties without proof.
- **Implementation divergence**: Rust `pasta-curves` and Lean `GOLDILOCKS` may disagree on edge cases (e.g., subtraction modulo `p`).
- **Missing proof obligations**: The field's use in ZK proofs and TEE attestation lacks mechanized verification.

## Decision
We will integrate the Goldilocks finite field as a **foundational Core algebraic primitive** with the following mandates:

### 1. Core Integration
- Move `GOLDILOCKS/Core.lean` content into `Prime/lean/Core/Goldilocks.lean` as the canonical base module for finite field arithmetic.
- All other Lean modules requiring finite field operations must import `Core.Goldilocks`.
- The `p = 2^64 - 2^32 + 1` prime becomes the **global field modulus** for the `Core/` layer.

### 2. Formal Proof Expansion
- Extend `Core/Goldilocks.lean` with proofs:
  - `field_add_comm`, `field_mul_comm`, `field_add_assoc`, `field_mul_assoc`
  - `field_add_identity`, `field_mul_identity`
  - `field_add_inverse`, `field_mul_inverse` (for non-zero elements)
  - `field_distrib`: `a * (b + c) = a * b + a * c`
  - `pow_add`: `a^(m + n) = a^m * a^n`
  - `pow_mul`: `(a^m)^n = a^(m * n)`

### 3. Rust Engine Parity
- The existing `Prime/crates/pasta-curves/` and `Prime/crates/goldilocks/` crates must be verified to implement the same field arithmetic as `Core/Goldilocks.lean`.
- Implement Kani harnesses in `Prime/crates/goldilocks/tests/kani/` proving:
  - `proof_add_mod_p`: Addition wraps correctly modulo `p`.
  - `proof_sub_mod_p`: Subtraction wraps correctly modulo `p`.
  - `proof_mul_mod_p`: Multiplication wraps correctly modulo `p`.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/Core/` and `cargo kani -p goldilocks` on every PR.
- The Guardian lock must verify field operation witnesses before approving cryptographic operations.
- The Examiner lock must audit field arithmetic for modular correctness.
- The Publisher lock must sign Goldilocks configurations into `Archivum`.

## Formal Proof Obligations

### 1. Field Addition Commutativity
```lean
namespace Core.Goldilocks

/-- The Goldilocks Prime p = 2^64 - 2^32 + 1 -/
def p : Nat := 2^64 - 2^32 + 1

instance : NeZero p := ⟨by decide⟩

/-- Goldilocks Finite Field -/
abbrev Field := Fin p

instance : Coe Nat Field where
  coe n := ⟨n % p, Nat.mod_lt _ (by decide)⟩

instance : Add Field where
  add a b := ⟨(a.val + b.val) % p, Nat.mod_lt _ (by decide)⟩

@[proof]
theorem field_add_comm (a b : Field) : a + b = b + a := by
  unfold Add.add
  simp [Fin.ext_iff]
  exact Nat.add_comm a.val b.val

@[proof]
theorem field_add_assoc (a b c : Field) : (a + b) + c = a + (b + c) := by
  unfold Add.add
  simp [Fin.ext_iff]
  exact Nat.add_assoc a.val b.val c.val

end Core.Goldilocks
```

### 2. Rust Runtime Contract
```rust
// crates/goldilocks/src/lib.rs
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct GoldilocksField(pub u64);

const P: u64 = u64::MAX - u32::MAX as u64 + 1; // 2^64 - 2^32 + 1

impl GoldilocksField {
    pub fn add(&self, other: Self) -> Self {
        Self((self.0 + other.0) % P)
    }

    pub fn sub(&self, other: Self) -> Self {
        Self((self.0 + P - other.0) % P)
    }

    pub fn mul(&self, other: Self) -> Self {
        Self(((self.0 as u128 * other.0 as u128) % P as u128) as u64)
    }
}
```

## Consequences

### Positive
- **Algebraic Foundation**: Goldilocks becomes the single source of truth for finite field arithmetic across Lean and Rust.
- **ZK Proof Compatibility**: The formalized field properties directly support `recursive-prover` and `pasta-curves` correctness.
- **TEE Binding Soundness**: LambdaTraceAtom's cryptographic commitments rely on Goldilocks field operations.
- **Audit-Ready**: Every field operation emits a witness to `Archivum`.

### Negative
- **Import Restructuring**: Moving Goldilocks into `Core/` requires updating imports across all dependent modules.
- **Proof Overhead**: Proving all field axioms in Lean 4 requires significant effort, though most are straightforward.
- **Rust-Lean Sync**: The Rust `pasta-curves` and `goldilocks` crates must be kept in sync with the Lean definitions.

## Implementation Steps

1. **Refactor `GOLDILOCKS/Core.lean`** into `Core/Goldilocks.lean`, preserving namespace as `Core.Goldilocks`.
2. **Prove field axioms** in `Core/Goldilocks.lean`.
3. **Update all imports** in dependent modules.
4. **Implement Kani harness** proving modular arithmetic correctness.
5. **Wire Triple-Lock integration**: Guardian → field op approval → Examiner → `GoldilocksWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p goldilocks`.
7. **Emit Archivum witness** `GoldilocksOpProof` on every field operation.

## References
- `Prime/lean/GOLDILOCKS/Core.lean` — Source module
- `Prime/lean/GOLDILOCKS/Theorems.lean` — Existing theorems
- `Prime/crates/pasta-curves/` — Pallas/Vesta curve implementation
- `Prime/crates/goldilocks/` — Goldilocks field Rust crate
- `Prime/crates/recursive-prover/` — ZK proof aggregation
- ADR-078 (Sovereign Stack) — LambdaTraceAtom TEE binding
