# ADR-091: XI_FORMAL Stability Dynamics into dynamics/

## Status
**Adopted**

## Context
The `Prime/lean/XI_FORMAL/StabilityDynamics.lean` module defines the **Ξ-Formal stability dynamics**:
- `scale : Nat := 10000` (discrete 1.0 representation)
- `dist : Nat → Nat → Nat` — absolute difference distance metric over `Nat`
- `is_contraction : (Nat → Nat) → Nat → Prop` — discrete Banach contraction: `kappa < scale ∧ ∀ x y, dist (f x) (f y) * scale ≤ kappa * dist x y`
- `is_stable_attractor : (Nat → Nat) → Prop` — operator `T` is a stable attractor if it is a contraction on the discrete space

`Prime/lean/XI_FORMAL/TightCfBound.lean` provides additional contraction bound tightness proofs.

Ξ-Formal stability dynamics are the **foundational dynamical systems primitives** for the Multiplicity framework. They provide:
- Discrete Banach contraction framework (replacing continuous `MetricSpace` with `Nat`-based metrics)
- Singular attractor property definitions
- Tight contraction factor (`κ`) bounds

Currently, Ξ-Formal exists as a standalone Lean module without:
- Integration into `Prime/lean/dynamics/` as a base dynamics component
- Formal proof that the discrete contraction framework matches continuous Banach theory
- ADR ratification of its production role
- Rust implementation for runtime contraction checking

Without formal integration into `dynamics/`, the stability dynamics risk:
- **Metric drift**: Different modules may define `dist` or `is_contraction` inconsistently.
- **Contraction violation**: Operators may claim to be contractive without proof.
- **Missing attractor guarantees**: The singular attractor property may be assumed without verification.

## Decision
We will integrate Ξ-Formal stability dynamics as a **foundational dynamics component** with the following mandates:

### 1. Dynamics Integration
- Move `XI_FORMAL/StabilityDynamics.lean` content into `Prime/lean/dynamics/XIFormal.lean` as the canonical base module for stability dynamics.
- All modules requiring contraction or attractor definitions must import `dynamics.XIFormal`.
- The `scale = 10000` convention aligns with `Core.ZMOD.scale` and `Core.PRMS.scale`.

### 2. Formal Proof Expansion
- Extend `dynamics/XIFormal.lean` with proofs:
  - `dist_symmetric`: `dist x y = dist y x`
  - `dist_nonneg`: `dist x y ≥ 0`
  - `dist_zero_iff`: `dist x y = 0 ↔ x = y`
  - `contraction_composition`: Composition of contractions is a contraction.
  - `stable_attractor_unique`: A stable attractor has a unique fixed point.

### 3. Rust Engine Parity
- Implement `crates/xi-formal/` or extend `crates/core/` with:
  - `XiFormalEngine::is_contraction(f: &dyn Fn(Nat) -> Nat, kappa: u64) -> bool`
  - `XiFormalEngine::is_stable_attractor(T: &dyn Fn(Nat) -> Nat) -> bool`
- The Rust implementation must:
  - Use exact `u64` arithmetic scaled by 10000
  - Return `false` if `kappa ≥ scale`
  - Emit `XiFormalWitness` to `Archivum` on every contraction check

### 4. Kani Verification
- Implement Kani harnesses in `crates/xi-formal/tests/kani/` proving:
  - `proof_contraction_bounded`: `is_contraction` rejects `kappa ≥ scale`.
  - `proof_attractor_has_fixed_point`: `is_stable_attractor` implies existence of fixed point.

### 5. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/dynamics/` and `cargo kani -p xi-formal` on every PR.
- The Guardian lock must verify the `XiFormalWitness` before approving dynamical system deployments.
- The Examiner lock must audit contraction proofs for tightness.
- The Publisher lock must sign stability configurations into `Archivum`.

## Formal Proof Obligations

### 1. Distance Metric Properties
```lean
namespace dynamics.XIFormal

/-- Scale for discrete integer math: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Absolute difference for Nat. -/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

@[proof]
theorem dist_symmetric (x y : Nat) : dist x y = dist y x := by
  unfold dist
  by_cases h : x ≥ y
  · simp [h]
    have : ¬y ≥ x := by
      intro hy
      have : x ≤ y := by omega
      exact h this
    simp [this]
  · simp [h]
    have : ¬y ≥ x := h
    simp [this]

@[proof]
theorem dist_nonneg (x y : Nat) : dist x y ≥ 0 := by
  unfold dist
  split <;> omega

end dynamics.XIFormal
```

### 2. Rust Runtime Contract
```rust
// crates/xi-formal/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XiFormalWitness {
    pub function_hash: [u8; 32],
    pub kappa: u64,
    pub is_contraction: bool,
    pub timestamp: i64,
}

const SCALE: u64 = 10000;

pub struct XiFormalEngine;

impl XiFormalEngine {
    pub fn is_contraction(
        &self,
        f: &dyn Fn(u64) -> u64,
        x: u64,
        y: u64,
        kappa: u64,
    ) -> bool {
        if kappa >= SCALE {
            return false;
        }
        let dx = if x >= y { x - y } else { y - x };
        let dy = if f(x) >= f(y) { f(x) - f(y) } else { f(y) - f(x) };
        dy * SCALE <= kappa * dx
    }
}
```

## Consequences

### Positive
- **Verified Dynamics**: Lean 4 + Kani guarantees that contraction and attractor properties are mathematically sound.
- **Discrete Metric Foundation**: The `Nat`-based `dist` replaces continuous `MetricSpace` axioms, enabling axiom-clean proofs.
- **Global Scale Consistency**: The `scale = 10000` convention aligns with `Core.ZMOD` and `Core.PRMS`.
- **Audit-Ready Stability**: Every contraction check emits a `XiFormalWitness` to `Archivum`.

### Negative
- **Discrete Approximation**: The `Nat`-based metric approximates continuous metrics; tightness proofs must account for discretization error.
- **Function Representation**: Representing arbitrary functions `Nat → Nat` in Rust requires trait objects or function pointers, limiting verification scope.
- **Performance**: Checking contraction for all `x, y` pairs is `O(n²)`; sampling strategies may be needed for large domains.

## Implementation Steps

1. **Refactor `XI_FORMAL/StabilityDynamics.lean`** into `dynamics/XIFormal.lean`.
2. **Prove metric properties and contraction theorems** in `dynamics/XIFormal.lean`.
3. **Create `crates/xi-formal/`** Rust crate with `XiFormalEngine`.
4. **Implement Kani harness** proving contraction boundedness and attractor fixed points.
5. **Wire Triple-Lock integration**: Guardian → contraction check → Examiner → `XiFormalWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p xi-formal`.
7. **Emit Archivum witness** `XiFormalProof` on every check.

## References
- `Prime/lean/XI_FORMAL/StabilityDynamics.lean` — Source module
- `Prime/lean/XI_FORMAL/TightCfBound.lean` — Contraction bound tightness
- `Prime/lean/dynamics/Lyapunov.lean` — Existing Lyapunov dynamics
- `Prime/lean/Core/Drift.lean` — Existing drift metrics
- ADR-063 (StratifiedGovernance) — Resource budget enforcement
