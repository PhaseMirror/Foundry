# ADR-093: META_RELATIVITY Validation Gates into dynamics/

## Status
**Adopted**

## Context
The `Prime/lean/META_RELATIVITY/Core.lean` module defines the **Meta-Relativity validation gates**:
- `scale : Nat := 10000` (discrete 1.0 representation)
- `dist : Nat → Nat → Nat` — absolute difference distance metric
- `Gate1` — Micro-Macro Derivation gate (`f_nl`, `coupling_strength`; valid if `f_nl = 0 ∧ coupling_strength ≤ 1000`)
- `Gate2` — RG-Prior Justification gate (`theta_1`; valid if `|theta_1 - 20000| < 4000`)
- `Gate3` — Correlated Smoking Gun gate (`a`; valid if `200 * scale ≤ a ≤ 500 * scale`)
- `Gate4` — Truncation Hierarchy gate (`beta_lambda_8`, `beta_lambda_6`, `delta_c_ratio`; valid if `beta_lambda_8 * 100 < beta_lambda_6 * 3 ∧ delta_c_ratio < 400`)
- `Gate5` — Complete Causal Chain gate (valid if all preceding gates are valid)

Meta-Relativity gates are the **validation and verification layer** for the Multiplicity framework's physical consistency. They enforce:
- Micro-macro derivation correctness
- Renormalization group (RG) prior justification
- Correlated smoking gun bounds
- Truncation hierarchy constraints
- Complete causal chain validity

Currently, Meta-Relativity exists as a standalone Lean module without:
- Integration into `Prime/lean/dynamics/` as a base validation component
- Formal proof that gate composition preserves validity
- ADR ratification of its production role
- Rust implementation for runtime gate checking

Without formal integration into `dynamics/`, the validation gates risk:
- **Gate drift**: Different modules may implement gate checks inconsistently.
- **Validation bypass**: Invalid configurations may pass some gates but fail others without detection.
- **Missing causal chain**: The complete causal chain (Gate5) may be incomplete or circular.

## Decision
We will integrate Meta-Relativity validation gates as a **foundational dynamics validation component** with the following mandates:

### 1. Dynamics Integration
- Move `META_RELATIVITY/Core.lean` content into `Prime/lean/dynamics/MetaRelativity.lean` as the canonical base module for validation gates.
- All modules requiring physical consistency checks must import `dynamics.MetaRelativity`.
- The `scale = 10000` convention aligns with `Core.ZMOD.scale`, `Core.PRMS.scale`, and `XI_FORMAL.scale`.

### 2. Formal Proof Expansion
- Extend `dynamics/MetaRelativity.lean` with proofs:
  - `gate1_implies_coupling_bounded`: Valid Gate1 implies `coupling_strength ≤ 1000`.
  - `gate2_implies_theta_near_2`: Valid Gate2 implies `theta_1` is near `2.0`.
  - `gate3_implies_slope_bounded`: Valid Gate3 implies `a ∈ [200, 500]`.
  - `gate4_implies_truncation_hierarchy`: Valid Gate4 implies truncation bounds.
  - `gate5_implies_all_gates_valid`: Valid Gate5 implies all preceding gates are valid.
  - `gate_composition_sound`: Valid Gate5 implies valid Gate1 ∧ Gate2 ∧ Gate3 ∧ Gate4.

### 3. Rust Engine Parity
- Implement `crates/meta-relativity/` or extend `crates/core/` with:
  - `MetaRelativityEngine::check_gate1(g: &Gate1) -> Result<Gate1Witness, Violation>`
  - `MetaRelativityEngine::check_gate2(g: &Gate2) -> Result<Gate2Witness, Violation>`
  - `MetaRelativityEngine::check_gate3(g: &Gate3) -> Result<Gate3Witness, Violation>`
  - `MetaRelativityEngine::check_gate4(g: &Gate4) -> Result<Gate4Witness, Violation>`
  - `MetaRelativityEngine::check_gate5(g: &Gate5) -> Result<Gate5Witness, Violation>`
- The Rust implementation must:
  - Use exact `u64` arithmetic scaled by 10000
  - Return `Violation` if any gate check fails
  - Emit `MetaRelativityWitness` to `Archivum` on every gate check

### 4. Kani Verification
- Implement Kani harnesses in `crates/meta-relativity/tests/kani/` proving:
  - `proof_gate1_bounds`: `check_gate1` rejects `coupling_strength > 1000`.
  - `proof_gate5_implies_gates1_4`: `check_gate5` returns `Ok` only if all sub-gates are valid.

### 5. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/dynamics/` and `cargo kani -p meta-relativity` on every PR.
- The Guardian lock must verify the `MetaRelativityWitness` before approving physical model deployments.
- The Examiner lock must audit gate checks for completeness.
- The Publisher lock must signed Meta-Relativity configurations into `Archivum`.

## Formal Proof Obligations

### 1. Gate5 Implies All Gates Valid
```lean
namespace dynamics.MetaRelativity

/-- Scale for discrete integer math: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Gate 1: Micro-Macro Derivation -/
structure Gate1 where
  f_nl : Nat
  coupling_strength : Nat

def Gate1.is_valid (g : Gate1) : Prop := 
  g.f_nl = 0 ∧ g.coupling_strength ≤ 1000

/-- Gate 2: RG-Prior Justification -/
structure Gate2 where
  theta_1 : Nat

def Gate2.is_valid (g : Gate2) : Prop := 
  dist g.theta_1 (2 * scale) < 4000

/-- Gate 5: Complete Causal Chain -/
structure Gate5 where
  g1 : Gate1
  g2 : Gate2
  g3 : Gate3
  g4 : Gate4

def Gate5.is_valid (g : Gate5) : Prop := 
  g.g1.is_valid ∧ g.g2.is_valid ∧ g.g3.is_valid ∧ g.g4.is_valid

@[proof]
theorem gate5_implies_gates1_4 (g5 : Gate5) (h : g5.is_valid) :
  g5.g1.is_valid ∧ g5.g2.is_valid ∧ g5.g3.is_valid ∧ g5.g4.is_valid := by
  exact h

end dynamics.MetaRelativity
```

### 2. Rust Runtime Contract
```rust
// crates/meta-relativity/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate1 { pub f_nl: u64, pub coupling_strength: u64 }
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate2 { pub theta_1: u64 }
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate3 { pub a: u64 }
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate4 { pub beta_lambda_8: u64, pub beta_lambda_6: u64, pub delta_c_ratio: u64 }
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gate5 { pub g1: Gate1, pub g2: Gate2, pub g3: Gate3, pub g4: Gate4 }

#[derive(Debug, thiserror::Error)]
pub enum MetaRelativityViolation {
    #[error("Gate1 invalid: f_nl={0} ≠ 0 or coupling={1} > 1000")]
    Gate1Invalid { f_nl: u64, coupling: u64 },
    #[error("Gate2 invalid: theta_1={0} not near 20000")]
    Gate2Invalid { theta_1: u64 },
    #[error("Gate3 invalid: a={0} not in [200,500]")]
    Gate3Invalid { a: u64 },
    #[error("Gate4 invalid: truncation hierarchy violated")]
    Gate4Invalid,
}

pub struct MetaRelativityEngine;

impl MetaRelativityEngine {
    pub fn check_gate5(&self, g5: &Gate5) -> Result<(), MetaRelativityViolation> {
        if g5.g1.f_nl != 0 || g5.g1.coupling_strength > 1000 {
            return Err(MetaRelativityViolation::Gate1Invalid { f_nl: g5.g1.f_nl, coupling: g5.g1.coupling_strength });
        }
        let diff = if g5.g2.theta_1 >= 20000 { g5.g2.theta_1 - 20000 } else { 20000 - g5.g2.theta_1 };
        if diff >= 4000 {
            return Err(MetaRelativityViolation::Gate2Invalid { theta_1: g5.g2.theta_1 });
        }
        if g5.g3.a < 200 || g5.g3.a > 500 {
            return Err(MetaRelativityViolation::Gate3Invalid { a: g5.g3.a });
        }
        if g5.g4.beta_lambda_8 * 100 >= g5.g4.beta_lambda_6 * 3 || g5.g4.delta_c_ratio >= 400 {
            return Err(MetaRelativityViolation::Gate4Invalid);
        }
        Ok(())
    }
}
```

## Consequences

### Positive
- **Verified Physical Consistency**: Lean 4 + Kani guarantees that all Meta-Relativity gates are mathematically sound.
- **Causal Chain Integrity**: Gate5 composition is proven sound, ensuring complete causal validation.
- **Global Scale Consistency**: The `scale = 10000` convention aligns with `Core.ZMOD`, `Core.PRMS`, and `XI_FORMAL`.
- **Audit-Ready Validation**: Every gate check emits a `MetaRelativityWitness` to `Archivum`.

### Negative
- **Gate Rigidity**: Gate bounds (e.g., `coupling_strength ≤ 1000`) are hard-coded; physical model updates require ADR ratification.
- **Sequential Checking**: Gate5 requires all sub-gates to be checked sequentially; parallelization is limited by dependencies.
- **Scale Dependency**: All gate bounds depend on `scale = 10000`; changing the scale requires re-verifying all gates.

## Implementation Steps

1. **Refactor `META_RELATIVITY/Core.lean`** into `dynamics/MetaRelativity.lean`.
2. **Prove gate composition theorems** in `dynamics/MetaRelativity.lean`.
3. **Create `crates/meta-relativity/`** Rust crate with `MetaRelativityEngine`.
4. **Implement Kani harness** proving gate5 implies gates1-4.
5. **Wire Triple-Lock integration**: Guardian → gate check → Examiner → `MetaRelativityWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p meta-relativity`.
7. **Emit Archivum witness** `MetaRelativityProof` on every gate check.

## References
- `Prime/lean/META_RELATIVITY/Core.lean` — Source module
- `Prime/lean/META_RELATIVITY/Theorems.lean` — Existing theorems
- `Prime/lean/dynamics/Lyapunov.lean` — Existing Lyapunov dynamics
- `Prime/lean/XI_FORMAL/StabilityDynamics.lean` — Existing stability dynamics
- ADR-091 (XIFormal) — Stability dynamics foundation
- ADR-092 (ROC Engine) — Lyapunov and spectral dynamics
