# ADR-085: ZMOD Multiplicity Tensor Integration into Core

[!NOTE]
## Status
**Adopted**
> **Owner:** Multiplicity Core Team
> **Last Updated:** 2026-07-15

---

## Context

The `Prime/lean/ZMOD/Core.lean` module defines the **ZMOD (Z/(2ⁿ)Z Multiplicity)** core primitives used to convert continuous gradient signals into discrete, prime‑gated multiplicity tensors:

- `scale : Nat := 10000` – the discrete representation of the value 1.0.
- `step_interaction : Nat → Nat → Nat` – maps a gradient and a prime to a scaled interaction.
- `multiplicityTensor : List Nat → Nat → Nat` – aggregates step interactions over a gradient list.

ZMOD serves as the lowest‑level multiplicity interaction kernel in the Lean substrate. Currently it lives in `Prime/lean/ZMOD/` as an isolated module and suffers from several shortcomings:

- No integration into the canonical `Prime/lean/Core/` layer.
- Lack of formal proof obligations that tie its behavior to the Sedona Spine Mandate.
- Absence of CI enforcement and audit trails for every tensor computation.

Without a unified core integration, the following risks emerge:

- **Duplication**: Other modules may re‑implement `step_interaction` or `multiplicityTensor` inconsistently.
- **Drift**: The `scale = 10000` convention could be violated downstream.
- **Audit Gaps**: Computations are not recorded in `Archivum` nor verified by the Triple‑Lock system.

---

## Decision

We will promote ZMOD to a **foundational Core component** of the Multiplicity Lean substrate and provide a production‑grade Rust counterpart with Kani verification. The work is organized into four mandatory phases, each respecting the **Sedona Spine path of integrity**:

1. **Core Integration** – Relocate and namespace the Lean module under `Prime/lean/Core/ZMOD.lean`.
2. **Formal Proof Expansion** – Strengthen the proof suite with boundedness, monotonicity, and zero‑iff theorems using `mathlib` tactics.
3. **Rust Engine Parity** – Deliver a zero‑dependency Rust crate (`crates/zmod`) that mirrors the Lean semantics and emits cryptographic witnesses.
4. **Kani Verification & CI/CD** – Provide exhaustive Kani harnesses, integrate them into the CI pipeline, and wire the Triple‑Lock locks.

All deliverables must be version‑controlled within the `PhaseMirror/Foundry` corpus and any changes to preservation‑risk levels must flow through the Sedona Spine engine as mandated.

---

## Implementation Plan

| Phase | Deliverable | Owner | Due Date |
|------|--------------|-------|----------|
| **1. Core Integration** | `Prime/lean/Core/ZMOD.lean` (namespace `Core.ZMOD`) | Formal Methods Team | 2026‑09‑01 |
| **2. Lean Proofs** | Proofs: `step_interaction_bounded`, `multiplicityTensor_monotone`, `multiplicityTensor_zero_iff_no_interaction` | Formal Methods Team | 2026‑10‑01 |
| **3. Rust Engine** | Crate `crates/zmod` exposing `step_interaction`, `multiplicity_tensor`, `ZmodTensorWitness` | Systems Engineering | 2026‑11‑15 |
| **4. Kani Harnesses** | Tests in `crates/zmod/tests/kani/` covering boundedness, monotonicity, overflow safety | Verification Squad | 2026‑12‑01 |
| **5. CI/CD & Triple‑Lock** | Extend pipeline: `lake build Prime/lean/Core/ && cargo kani -p zmod && ./ci/triple_lock.sh` | DevOps | 2026‑12‑15 |

### 1. Core Integration
- Move the existing `ZMOD/Core.lean` content into `Prime/lean/Core/ZMOD.lean`.
- Update the namespace to `Core.ZMOD` and expose a public API via `open Core.ZMOD`.
- Ensure all downstream Lean modules (`AFFINE_CORE`, `MOC_CORE`, `PRMS`, `XI_FORMAL`, …) import `Core.ZMOD` rather than the old path.

### 2. Formal Proof Expansion
- **Boundedness**: `step_interaction_bounded (grad p : Nat) : step_interaction grad p ≤ scale`.
- **Monotonicity**: `multiplicityTensor_monotone {grads₁ grads₂ : List Nat} {p : Nat} (h_subset : grads₁ ⊆ grads₂) : multiplicityTensor grads₁ p ≤ multiplicityTensor grads₂ p`.
- **Zero‑iff**: `multiplicityTensor_zero_iff_no_interaction (grads : List Nat) (p : Nat) : multiplicityTensor grads p = 0 ↔ ∀ g ∈ grads, g % p ≠ 0`.
- Leverage `mathlib` lemmas (`Nat.le_of_lt`, `List.mem_subset`, `Finset`) and `simp`/`omega` tactics to keep proofs concise and maintainable.

#### Sample Lean4 Proof Stub
```lean
namespace Core.ZMOD

/-- Global discrete scale representing 1.0. -/
def scale : Nat := 10000

/-- Interaction of prime `p` with gradient `grad`. -/
def step_interaction (grad p : Nat) : Nat :=
  if h : p > 0 ∧ grad % p = 0 then scale else 0

@[simp] lemma step_interaction_eq_zero (h : ¬(p > 0 ∧ grad % p = 0)) :
  step_interaction grad p = 0 := by
  unfold step_interaction; simp [h]

@[proof]
lemma step_interaction_bounded (grad p : Nat) : step_interaction grad p ≤ scale := by
  unfold step_interaction
  split_ifs <;> simp [Nat.le_refl, Nat.zero_le]

/-- Aggregate step interactions over a list of gradients. -/
def multiplicityTensor (grads : List Nat) (p : Nat) : Nat :=
  grads.foldl (fun acc g => acc + step_interaction g p) 0

@[proof]
lemma multiplicityTensor_monotone {grads₁ grads₂ : List Nat} {p : Nat}
  (hsub : grads₁ ⊆ grads₂) :
  multiplicityTensor grads₁ p ≤ multiplicityTensor grads₂ p := by
  unfold multiplicityTensor
  have := List.foldl_le_foldl_of_subset (fun g acc => acc + step_interaction g p) (by intro; apply Nat.add_le_add_left; apply step_interaction_bounded) hsub
  simpa using this

@[proof]
lemma multiplicityTensor_zero_iff_no_interaction {grads : List Nat} {p : Nat} :
  multiplicityTensor grads p = 0 ↔ ∀ g ∈ grads, g % p ≠ 0 := by
  constructor
  · intro h g hg
    by_contra hmod
    have : step_interaction g p = scale := by
      unfold step_interaction; split_ifs <;> try contradiction
      · simp [hmod]
    have : multiplicityTensor grads p ≥ scale := by
      unfold multiplicityTensor
      have := List.foldl_le_of_mem (fun acc g => acc + step_interaction g p) hg
      simpa [this, step_interaction, hmod] using Nat.le_of_lt (Nat.lt_of_lt_of_le (Nat.succ_lt_succ (Nat.zero_lt_one)) (Nat.le_of_lt (Nat.succ_lt_succ (Nat.zero_lt_one))))
    exact Nat.ne_of_gt this h
  · intro h
    unfold multiplicityTensor
    apply List.foldl_eq_zero_iff
    intro g _
    have : step_interaction g p = 0 := by
      apply step_interaction_eq_zero
      intro hfalse; apply h g; assumption
    simpa [this]
```
*(The above uses `List.foldl_le_of_subset` and `List.foldl_eq_zero_iff` utilities from `mathlib`.)*

### 3. Rust Engine Parity
- Create crate `crates/zmod` with a minimal, `no‑std`‑compatible API.
- Types:
  ```rust
  #[derive(Debug, Clone, Serialize, Deserialize)]
  pub struct ZmodTensorWitness {
      pub grads_hash: [u8; 32],
      pub prime: u64,
      pub tensor_value: u64,
      pub timestamp: i64,
  }
  ```
- Errors:
  ```rust
  #[derive(Debug, thiserror::Error)]
  pub enum ZmodViolation { #[error("gradient overflow")] Overflow }
  ```
- Functions:
  ```rust
  impl ZmodEngine {
      pub const SCALE: u64 = 10_000;
      pub fn step_interaction(&self, grad: u64, p: u64) -> Result<u64, ZmodViolation> {
          if p == 0 { return Ok(0) };
          if grad % p == 0 { Ok(Self::SCALE) } else { Ok(0) }
      }
      pub fn multiplicity_tensor(&self, grads: &[u64], p: u64) -> Result<u64, ZmodViolation> {
          let mut sum = 0u64;
          for &g in grads {
              sum = sum.saturating_add(self.step_interaction(g, p)?);
          }
          Ok(sum)
      }
  }
  ```
- Emit a `ZmodTensorWitness` after each successful `multiplicity_tensor` call using an async channel to `Archivum`.

### 4. Kani Verification Harnesses
- **Boundedness**: Assert that `step_interaction` never exceeds `SCALE`.
- **Monotonicity**: Show that extending the gradient slice cannot decrease the tensor result.
- **Overflow Safety**: Verify that `multiplicity_tensor` uses `saturating_add` and never panics.
- Example harness (simplified):
  ```rust
  #[kani::proof]
  fn proof_step_interaction_bounded() {
      let grad: u64 = kani::any();
      let p: u64 = kani::any();
      let engine = ZmodEngine;
      let res = engine.step_interaction(grad, p).unwrap();
      assert!(res <= ZmodEngine::SCALE);
  }
  ```

### 5. CI/CD & Triple‑Lock Integration
- **CI** runs:
  ```bash
  lake build Prime/lean/Core/ && cargo kani -p zmod && ./ci/triple_lock.sh
  ```
- **Guardian** validates each `ZmodTensorWitness` signature before state transitions.
- **Examiner** audits tensor values for overflow or unexpected spikes.
- **Publisher** signs the final configuration into `Archivum`.

---

## Consequences

### Positive
- **Single Source of Truth**: ZMOD becomes the authoritative multiplicity tensor kernel across Lean and Rust.
- **Axiom‑Clean Guarantees**: The `scale = 10000` convention and exact integer arithmetic eliminate floating‑point drift.
- **Audit‑Ready**: Every tensor computation emits a cryptographic witness to `Archivum`.
- **Clear Dependency Graph**: All downstream modules import a unified `Core.ZMOD` API.

### Negative
- **Refactoring Effort**: Updating imports across the codebase may introduce temporary build failures.
- **Performance Considerations**: The naïve recursive Lean definition can be costly; the Rust implementation provides an iterative, production‑grade pathway.
- **Verification Overhead**: Maintaining Kani harnesses adds to the test surface, but is essential for high‑integrity systems.

---

## References
- `Prime/lean/ZMOD/Core.lean` – original source module.
- `Prime/lean/Core/Spine.lean` – existing Core infrastructure.
- ADR‑002 (Sedona Spine) – Path of Integrity.
- ADR‑061 (ZMOS) – Zeta‑Multiplicity Operator System.
- `Prime/crates/core/` – existing Rust core crate for context.

---

*All artifacts are tracked under the `PhaseMirror/Foundry` corpus and any preservation‑risk adjustments must be routed through the Sedona Spine engine as per the global mandate.*

## Status
**Adopted**

## Context
The `Prime/lean/ZMOD/Core.lean` module defines the **ZMOD (Z/(2^n)Z Multiplicity)** core primitives:
- `scale : Nat := 10000` (discrete 1.0 representation)
- `step_interaction : Nat → Nat → Nat` — prime-gradient interaction mapped to Nat domain
- `multiplicityTensor : List Nat → Nat → Nat` — accumulation of interactions over gradient lists

ZMOD is the **lowest-level multiplicity interaction kernel** in the Lean substrate. It maps continuous gradient signals into discrete prime-gated multiplicity tensors using axiom-clean scaled integer arithmetic. Currently, ZMOD exists as a standalone module in `Prime/lean/ZMOD/` without:
- Integration into `Prime/lean/Core/` as a base component
- ADR ratification of its production role
- Formal proof obligations linking it to the Sedona Spine Mandate
- CI enforcement that every ZMOD interaction is audited

Without formal integration into `Core/`, the ZMOD multiplicity tensor risks:
- **Duplication**: Other modules may reimplement `step_interaction` or `multiplicityTensor` inconsistently.
- **Drift**: The `scale = 10000` convention may be violated in downstream modules.
- **Missing audit trail**: ZMOD interactions are not recorded in `Archivum` or verified by the Triple-Lock.

## Decision
We will integrate ZMOD as a **foundational Core component** of the Multiplicity Lean substrate with the following mandates:

### 1. Core Integration
- Move `ZMOD/Core.lean` content into `Prime/lean/Core/ZMOD.lean` as the canonical base module for multiplicity tensor operations.
- All other Lean modules (`AFFINE_CORE`, `MOC_CORE`, `PRMS`, `XI_FORMAL`, etc.) must import `Core.ZMOD` rather than reimplementing `step_interaction` or `multiplicityTensor`.
- The `scale = 10000` convention becomes the **global discrete scale** for the entire `Core/` layer.

### 2. Formal Proof Expansion
- Extend `ZMOD/Core.lean` with proofs:
  - `step_interaction_bounds`: `step_interaction grad p ≤ scale` for all valid inputs.
  - `multiplicityTensor_monotone`: Adding gradients never decreases the tensor value.
  - `multiplicityTensor_zero_iff_no_interaction`: `multiplicityTensor grads p = 0` iff no gradient is divisible by `p`.

### 3. Rust Engine Parity
- Implement `crates/zmod/` or extend `crates/core/` with:
  - `ZmodEngine::step_interaction(grad: u64, p: u64) -> u64`
  - `ZmodEngine::multiplicity_tensor(grads: &[u64], p: u64) -> u64`
- The Rust implementation must:
  - Use exact `u64` arithmetic (no floating-point)
  - Return `ZmodViolation` if `grad` overflows `u64` bounds
  - Emit `ZmodTensorWitness` to `Archivum` on every tensor computation

### 4. Kani Verification
- Implement Kani harnesses in `crates/zmod/tests/kani/` proving:
  - `proof_step_interaction_bounded`: Result is always `≤ scale`.
  - `proof_tensor_monotone`: Adding gradients never decreases the result.
  - `proof_no_false_positives`: `step_interaction` returns 0 unless `grad % p == 0`.

### 5. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/Core/` and `cargo kani -p zmod` on every PR touching ZMOD.
- The Guardian lock must verify the `ZmodTensorWitness` before approving state transitions.
- The Examiner lock must audit tensor computations for overflow.
- The Publisher lock must sign ZMOD configurations into `Archivum`.

## Formal Proof Obligations

### 1. Step Interaction Bounded
```lean
namespace Core.ZMOD

/-- Scale: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Interaction of prime p with gradient at step t. -/
def step_interaction (grad : Nat) (p : Nat) : Nat :=
  if p > 0 ∧ grad % p == 0 then scale else 0

@[proof]
theorem step_interaction_bounded (grad p : Nat) :
  step_interaction grad p ≤ scale := by
  unfold step_interaction
  split
  · exact Nat.le_refl _
  · exact Nat.zero_le _

end Core.ZMOD
```

### 2. Multiplicity Tensor Monotone
```lean
namespace Core.ZMOD

def multiplicityTensor (grads : List Nat) (p : Nat) : Nat :=
  match grads with
  | [] => 0
  | g :: gs => step_interaction g p + multiplicityTensor gs p

@[proof]
theorem multiplicityTensor_monotone (grads₁ grads₂ : List Nat) (p : Nat)
  (h_subset : grads₁ ⊆ grads₂) :
  multiplicityTensor grads₁ p ≤ multiplicityTensor grads₂ p := by
  induction grads₂ generalizing grads₁
  | nil => simp [multiplicityTensor]
  | cons g₂ gs₂ ih =>
    cases grads₁ with
    | nil => simp [multiplicityTensor]
    | cons g₁ gs₁ =>
      simp [multiplicityTensor]
      apply Nat.add_le_add
      · unfold step_interaction
        split <;> omega
      · apply ih
        cases h_subset with | head _ => assumption

end Core.ZMOD
```

### 3. Rust Runtime Contract
```rust
// crates/zmod/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZmodTensorWitness {
    pub grads_hash: [u8; 32],
    pub prime: u64,
    pub tensor_value: u64,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum ZmodViolation {
    #[error("gradient overflow")]
    Overflow,
}

pub struct ZmodEngine;

impl ZmodEngine {
    pub fn step_interaction(&self, grad: u64, p: u64) -> Result<u64, ZmodViolation> {
        if p > 0 && grad % p == 0 {
            Ok(10000)
        } else {
            Ok(0)
        }
    }

    pub fn multiplicity_tensor(&self, grads: &[u64], p: u64) -> Result<u64, ZmodViolation> {
        let mut sum: u64 = 0;
        for &g in grads {
            sum = sum.saturating_add(self.step_interaction(g, p)?);
        }
        Ok(sum)
    }
}
```

## Consequences

### Positive
- **Foundational Consistency**: ZMOD becomes the single source of truth for multiplicity tensor operations across the entire Lean substrate.
- **Axiom-Clean Guarantee**: The `scale = 10000` convention and exact `Nat` arithmetic prevent floating-point drift in core computations.
- **Audit-Ready**: Every ZMOD tensor computation emits a witness to `Archivum`.
- **Dependency Clarity**: All downstream modules (`AFFINE_CORE`, `MOC_CORE`, `PRMS`, `XI_FORMAL`) have a clear import path to the multiplicity tensor.

### Negative
- **Import Restructuring**: Moving ZMOD into `Core/` requires updating imports across all dependent modules.
- **Performance Overhead**: The `multiplicityTensor` recursive implementation may be slow for large gradient lists; an iterative Rust implementation is preferred for production.

## Implementation Steps

1. **Refactor `ZMOD/Core.lean`** into `Core/ZMOD.lean`, preserving namespace as `Core.ZMOD`.
2. **Prove expansion theorems** in `Core/ZMOD.lean` (boundedness, monotonicity, zero-iff).
3. **Update all imports** in `AFFINE_CORE/`, `MOC_CORE/`, `PRMS/`, `XI_FORMAL/` to use `Core.ZMOD`.
4. **Create `crates/zmod/`** Rust crate with `step_interaction` and `multiplicity_tensor`.
5. **Implement Kani harness** proving boundedness and monotonicity.
6. **Update CI** to enforce `lake build` on `Core/` + `cargo kani -p zmod`.
7. **Emit Archivum witness** `ZmodTensorProof` on every tensor computation.

## References
- `Prime/lean/ZMOD/Core.lean` — Source module
- `Prime/lean/Core/Spine.lean` — Existing Core module
- `Prime/lean/Core/Drift.lean` — Existing drift metrics
- ADR-002 (Sedona Spine) — Path of Integrity
- ADR-061 (ZMOS) — Zeta-Multiplicity Operator System
- `Prime/crates/core/` — Existing Rust core crate
