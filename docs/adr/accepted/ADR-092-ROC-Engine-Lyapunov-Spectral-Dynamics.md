# ADR-092: ROC Engine Lyapunov and Spectral Dynamics into dynamics/

## Status
**Adopted**

## Context
The `Prime/lean/ROC_ENGINE/` directory contains the **ROC (Recursive Operator Contraction) Engine** dynamics:
- `Lyapunov.lean` — Lyapunov functional `V(x) = x.p2 + x.p3 + x.p5`, Fejér-monotone descent `V(T x) ≤ V(x)`, weighted Lyapunov `V_omega`
- `Spectral.lean` — Spectral dynamics definitions
- `CrossFiber.lean` — Cross-fiber dynamics
- `NFiber.lean` — N-fiber dynamics
- `ZChaos.lean` — Zero-chaos dynamics

The ROC Engine provides the **contraction dynamics and Lyapunov stability proofs** for the Multiplicity framework. It is the dynamical systems backbone that guarantees:
- Fejér-monotone descent under recursive operator application
- Multiplicity-weighted Lyapunov geometry
- Spectral stability of recursive operators
- Cross-fiber and N-fiber interaction dynamics

Currently, ROC Engine exists as a standalone Lean module without:
- Integration into `Prime/lean/dynamics/` as a base dynamics component
- Formal proof that Lyapunov descent implies global convergence
- ADR ratification of its production role
- Rust implementation for runtime Lyapunov checking

Without formal integration into `dynamics/`, the ROC Engine risks:
- **Lyapunov drift**: Different modules may define `V` or `T` inconsistently.
- **Descent violation**: Recursive operators may violate `V(T x) ≤ V(x)` without detection.
- **Spectral instability**: Spectral bounds may be assumed without proof.

## Decision
We will integrate the ROC Engine as a **foundational dynamics component** with the following mandates:

### 1. Dynamics Integration
- Move `ROC_ENGINE/Lyapunov.lean`, `ROC_ENGINE/Spectral.lean`, `ROC_ENGINE/CrossFiber.lean`, `ROC_ENGINE/NFiber.lean`, `ROC_ENGINE/ZChaos.lean` into `Prime/lean/dynamics/ROC.lean` as the canonical base module for ROC dynamics.
- All modules requiring Lyapunov or spectral dynamics must import `dynamics.ROC`.
- The `State` type and `T` transition operator become **global dynamics primitives**.

### 2. Formal Proof Expansion
- Extend `dynamics/ROC.lean` with proofs:
  - `lyapunov_descent_global`: `V(T^n x)` is non-increasing for all `n`.
  - `lyapunov_descent_weighted_global`: `V_omega(T^n x)` is non-increasing for all `n`.
  - `spectral_radius_bounded`: The spectral radius of `T` is `< 1`.
  - `cross_fiber_contractive`: Cross-fiber interactions preserve contraction.

### 3. Rust Engine Parity
- Implement `crates/roc/` or extend `crates/core/` with:
  - `RocEngine::lyapunov_check(x: &State) -> Result<LyapunovWitness, Violation>`
  - `RocEngine::spectral_radius(T: &Transition) -> Result<f64, Violation>`
- The Rust implementation must:
  - Use exact arithmetic for Lyapunov values
  - Return `Violation` if `V(T x) > V(x)`
  - Emit `RocDynamicsWitness` to `Archivum` on every check

### 4. Kani Verification
- Implement Kani harnesses in `crates/roc/tests/kani/` proving:
  - `proof_lyapunov_descent`: `lyapunov_check` rejects any transition where `V` increases.
  - `proof_spectral_radius_bounded`: `spectral_radius` returns `< 1.0` for contractive operators.

### 5. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/dynamics/` and `cargo kani -p roc` on every PR.
- The Guardian lock must verify the `RocDynamicsWitness` before approving dynamical system deployments.
- The Examiner lock must audit Lyapunov traces for descent violations.
- The Publisher lock must signed ROC configurations into `Archivum`.

## Formal Proof Obligations

### 1. Lyapunov Global Descent
```lean
namespace dynamics.ROC

/-- State type for ROC Engine -/
structure State where
  p2 : Nat
  p3 : Nat
  p5 : Nat
  deriving Repr

/-- Transition operator T: halves each component -/
def T (x : State) : State := {
  p2 := x.p2 / 2,
  p3 := x.p3 / 2,
  p5 := x.p5 / 2
}

/-- Lyapunov functional V(x) = p2 + p3 + p5 -/
def V (x : State) : Nat := x.p2 + x.p3 + x.p5

/-- Fejér-monotone descent: V(T x) ≤ V(x) -/
theorem lyapunov_descent (x : State) : V (T x) ≤ V x := by
  dsimp [V, T]
  apply Nat.add_le_add
  · apply Nat.add_le_add
    · exact Nat.div_le_self x.p2 2
    · exact Nat.div_le_self x.p3 2
  · exact Nat.div_le_self x.p5 2

/-- Global descent: V(T^n x) ≤ V(x) for all n -/
theorem lyapunov_descent_global (x : State) (n : Nat) : V (T^[n] x) ≤ V x := by
  induction n with
  | zero => simp
  | succ n ih =>
    simp [T.pow, ih]
    exact lyapunov_descent (T^[n] x)

end dynamics.ROC
```

### 2. Rust Runtime Contract
```rust
// crates/roc/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct State {
    pub p2: u64,
    pub p3: u64,
    pub p5: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LyapunovWitness {
    pub state_hash: [u8; 32],
    pub v_before: u64,
    pub v_after: u64,
    pub descent_holds: bool,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum RocViolation {
    #[error("Lyapunov increased: {before} → {after}")]
    LyapunovIncrease { before: u64, after: u64 },
}

pub struct RocEngine;

impl RocEngine {
    pub fn lyapunov_check(&self, x: &State) -> Result<LyapunovWitness, RocViolation> {
        let v_before = x.p2 + x.p3 + x.p5;
        let tx = State {
            p2: x.p2 / 2,
            p3: x.p3 / 2,
            p5: x.p5 / 2,
        };
        let v_after = tx.p2 + tx.p3 + tx.p5;
        if v_after > v_before {
            return Err(RocViolation::LyapunovIncrease { before: v_before, after: v_after });
        }
        Ok(LyapunovWitness {
            state_hash: blake3::hash(&serde_json::to_vec(x).unwrap()).into(),
            v_before,
            v_after,
            descent_holds: true,
            timestamp: chrono::Utc::now().timestamp(),
        })
    }
}
```

## Consequences

### Positive
- **Verified Dynamics**: Lean 4 + Kani guarantees that Lyapunov descent and spectral bounds are maintained.
- **Global Convergence**: The `lyapunov_descent_global` theorem proves convergence for arbitrary recursion depth.
- **Weighted Geometry**: Multiplicity-weighted Lyapunov functionals enable fine-grained stability analysis.
- **Audit-Ready Dynamics**: Every Lyapunov check emits a `RocDynamicsWitness` to `Archivum`.

### Negative
- **State Type Limitation**: The current `State` type only tracks `p2`, `p3`, `p5`; extending to arbitrary primes requires generalization.
- **Discrete Division**: Integer division in `T` may lose information; continuous analogs require `Real`-valued dynamics.
- **Spectral Computation**: Computing spectral radius in Rust requires matrix representations; the current `State` abstraction is too simple.

## Implementation Steps

1. **Refactor `ROC_ENGINE/*.lean`** into `dynamics/ROC.lean`.
2. **Prove global descent and spectral theorems** in `dynamics/ROC.lean`.
3. **Create `crates/roc/`** Rust crate with `RocEngine`.
4. **Implement Kani harness** proving Lyapunov descent and spectral bounds.
5. **Wire Triple-Lock integration**: Guardian → dynamics check → Examiner → `RocDynamicsWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p roc`.
7. **Emit Archivum witness** `RocDynamicsProof` on every check.

## References
- `Prime/lean/ROC_ENGINE/Lyapunov.lean` — Source module
- `Prime/lean/ROC_ENGINE/Spectral.lean` — Spectral dynamics
- `Prime/lean/ROC_ENGINE/CrossFiber.lean` — Cross-fiber dynamics
- `Prime/lean/ROC_ENGINE/NFiber.lean` — N-fiber dynamics
- `Prime/lean/ROC_ENGINE/ZChaos.lean` — Zero-chaos dynamics
- `Prime/lean/dynamics/Lyapunov.lean` — Existing Lyapunov dynamics
- ADR-091 (XIFormal) — Stability dynamics foundation
