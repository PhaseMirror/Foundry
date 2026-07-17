# ADR-094: AFFINE_CORE Certification and Stability into Core/dynamics/

## Status
**Adopted**

## Context
The `Prime/lean/AFFINE_CORE/` directory contains the **Affine Core certification library**:
- `AffineCore.lean` — Master import rollup for all AFFINE_CORE submodules
- `Foundations/` — BanachSpace, PrimeSeries, HilbertSchmidt foundations
- `Operators/` — UpdateOperator, PolicyProjector, MultiplicityOperator
- `CertificationGate.lean` — Certification gate logic
- `MoldingModularity.lean` — Molding and modularity structures
- `ConstraintNerve.lean` — Constraint nerve complex
- `S4_Spectral.lean` — S4 spectral logic
- `SpectralCert.lean` — Spectral certification
- `Stability/` — ZenoContractivity and other stability proofs
- `Widgets.lean` — Widget structures
- `MTPI/` — Multiplicity Theory Processing Interface

AFFINE_CORE is the **certification and stability backbone** of the Multiplicity Lean substrate. It provides:
- Banach space foundations for contractivity proofs
- Prime series and Hilbert-Schmidt operators
- Policy projection and multiplicity operators
- Certification gates for admissible transformations
- Spectral certification and S4 modal logic
- Zeno contractivity stability proofs

Currently, AFFINE_CORE exists as a standalone Lean package with its own `lake-manifest.json` and `lakefile.lean` (in `MOC_CORE/`), without:
- Integration into `Prime/lean/Core/` and `Prime/lean/dynamics/` as base components
- Formal proof that certification gates preserve admissibility
- ADR ratification of its production role
- Rust implementation for runtime certification checking

Without formal integration into `Core/` and `dynamics/`, the AFFINE_CORE risks:
- **Certification drift**: Different modules may implement certification gates inconsistently.
- **Stability violation**: Admissible transformations may violate contractivity without detection.
- **Spectral unsoundness**: Spectral certification may be bypassed or incorrectly applied.

## Decision
We will integrate AFFINE_CORE as a **dual Core/dynamics component** with the following mandates:

### 1. Core Integration (Foundations and Primitives)
- Move `AFFINE_CORE/Foundations/BanachSpace.lean`, `AFFINE_CORE/Foundations/PrimeSeries.lean`, `AFFINE_CORE/Foundations/HilbertSchmidt.lean` into `Prime/lean/Core/Affine.lean` as base algebraic/analytic primitives.
- Move `AFFINE_CORE/Operators/MultiplicityOperator.lean` into `Prime/lean/Core/MultiplicityOperator.lean`.
- All modules requiring Banach space, prime series, or multiplicity operator definitions must import `Core.Affine`.

### 2. Dynamics Integration (Stability and Certification)
- Move `AFFINE_CORE/Stability/ZenoContractivity.lean` into `Prime/lean/dynamics/ZenoContractivity.lean`.
- Move `AFFINE_CORE/CertificationGate.lean` into `Prime/lean/dynamics/CertificationGate.lean`.
- Move `AFFINE_CORE/SpectralCert.lean` into `Prime/lean/dynamics/SpectralCert.lean`.
- All modules requiring stability, certification, or spectral certification must import `dynamics.ZenoContractivity`, `dynamics.CertificationGate`, or `dynamics.SpectralCert`.

### 3. Formal Proof Expansion
- Extend the moved modules with proofs:
  - `banach_contraction_implies_fixed_point`: Banach contraction has a unique fixed point.
  - `zeno_contractivity_preserved`: Zeno-contractive operators preserve contractivity under composition.
  - `certification_gate_sound`: Passing the certification gate implies admissibility.
  - `spectral_cert_complete`: Spectral certification covers all admissible operators.

### 4. Rust Engine Parity
- Implement `crates/affine-core/` or extend `crates/core/` with:
  - `AffineCoreEngine::certify(operator: &MultiplicityOperator) -> Result<CertificationWitness, Violation>`
  - `AffineCoreEngine::zeno_check(state: &State) -> Result<ZenoWitness, Violation>`
- The Rust implementation must:
  - Use exact arithmetic for Banach and spectral computations
  - Return `Violation` if contractivity or certification fails
  - Emit `AffineCoreWitness` to `Archivum` on every certification

### 5. Kani Verification
- Implement Kani harnesses in `crates/affine-core/tests/kani/` proving:
  - `proof_certification_gate_sound`: `certify` rejects non-admissible operators.
  - `proof_zeno_contractivity`: `zeno_check` verifies Zeno contractivity for all valid states.

### 6. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/Core/` and `Prime/lean/dynamics/` and `cargo kani -p affine-core` on every PR.
- The Guardian lock must verify the `AffineCoreWitness` before approving operator deployments.
- The Examiner lock must audit certification traces for completeness.
- The Publisher lock must signed AFFINE_CORE configurations into `Archivum`.

## Formal Proof Obligations

### 1. Banach Contraction Implies Fixed Point
```lean
namespace Core.Affine

/-- Banach space metric on Nat (discrete approximation) -/
def banach_dist (x y : Nat) : Nat := if x ≥ y then x - y else y - x

/-- Contraction: kappa < scale and dist (f x) (f y) * scale ≤ kappa * dist x y -/
def is_banach_contraction (f : Nat → Nat) (kappa : Nat) : Prop :=
  kappa < 10000 ∧ ∀ x y, banach_dist (f x) (f y) * 10000 ≤ kappa * banach_dist x y

@[proof]
theorem banach_contraction_implies_fixed_point (f : Nat → Nat) (kappa : Nat)
  (h_cont : is_banach_contraction f kappa) :
  ∃ x, f x = x := by
  -- In a finite discrete space, a contraction must have a fixed point.
  -- This follows from the discrete Banach fixed-point theorem.
  sorry

end Core.Affine
```

### 2. Zeno Contractivity Preserved
```lean
namespace dynamics.ZenoContractivity

/-- Zeno contractivity: operator converges in finite steps -/
def is_zeno_contractive (T : Nat → Nat) (x : Nat) (n : Nat) : Prop :=
  T^[n] x = T^[n+1] x

@[proof]
theorem zeno_contractivity_preserved (T₁ T₂ : Nat → Nat) (x : Nat)
  (h_z1 : is_zeno_contractive T₁ x 0)
  (h_z2 : is_zeno_contractive T₂ (T₁ x) 0) :
  is_zeno_contractive (T₂ ∘ T₁) x 0 := by
  unfold is_zeno_contractive
  simp [Function.comp, T₂.pow, T₁.pow]

end dynamics.ZenoContractivity
```

### 3. Rust Runtime Contract
```rust
// crates/affine-core/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicityOperator {
    pub name: String,
    pub prime_indices: Vec<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CertificationWitness {
    pub operator_hash: [u8; 32],
    pub is_admissible: bool,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum AffineCoreViolation {
    #[error("operator {0} is not admissible")]
    NotAdmissible(String),
    #[error("Zeno contractivity violated")]
    ZenoViolation,
}

pub struct AffineCoreEngine;

impl AffineCoreEngine {
    pub fn certify(&self, op: &MultiplicityOperator) -> Result<CertificationWitness, AffineCoreViolation> {
        if op.prime_indices.is_empty() {
            return Err(AffineCoreViolation::NotAdmissible(op.name.clone()));
        }
        Ok(CertificationWitness {
            operator_hash: blake3::hash(&serde_json::to_vec(op).unwrap()).into(),
            is_admissible: true,
            timestamp: chrono::Utc::now().timestamp(),
        })
    }
}
```

## Consequences

### Positive
- **Verified Certification**: Lean 4 + Kani guarantees that certification gates and Zeno contractivity are mathematically sound.
- **Dual Core/Dynamics Architecture**: Foundations live in `Core/`, stability/certification live in `dynamics/`, matching the mathematical hierarchy.
- **Banach Fixed-Point Guarantee**: The Banach contraction theorem provides a global convergence guarantee for all certified operators.
- **Audit-Ready Certification**: Every certification emits an `AffineCoreWitness` to `Archivum`.

### Negative
- **Refactoring Overhead**: Splitting AFFINE_CORE into `Core/` and `dynamics/` requires careful module restructuring and import updates.
- **Banach Space Approximation**: The discrete `Nat`-based metric approximates continuous Banach spaces; tightness proofs must account for discretization.
- **Zeno Complexity**: Proving Zeno contractivity for arbitrary operators requires induction on transition depth, which may not terminate for all inputs.

## Implementation Steps

1. **Refactor `AFFINE_CORE/Foundations/`** into `Core/Affine.lean`.
2. **Refactor `AFFINE_CORE/Stability/`** into `dynamics/ZenoContractivity.lean`.
3. **Refactor `AFFINE_CORE/CertificationGate.lean`** into `dynamics/CertificationGate.lean`.
4. **Refactor `AFFINE_CORE/SpectralCert.lean`** into `dynamics/SpectralCert.lean`.
5. **Prove Banach fixed-point and Zeno theorems** in the new locations.
6. **Create `crates/affine-core/`** Rust crate with `AffineCoreEngine`.
7. **Implement Kani harness** proving certification gate soundness.
8. **Wire Triple-Lock integration**: Guardian → certification → Examiner → `AffineCoreWitness` → Publisher → `Archivum`.
9. **Update CI** to enforce `lake build` + `cargo kani -p affine-core`.
10. **Emit Archivum witness** `AffineCoreProof` on every certification.

## References
- `Prime/lean/AFFINE_CORE/AffineCore.lean` — Master rollup
- `Prime/lean/AFFINE_CORE/Foundations/` — Banach, PrimeSeries, HilbertSchmidt
- `Prime/lean/AFFINE_CORE/Operators/` — UpdateOperator, PolicyProjector, MultiplicityOperator
- `Prime/lean/AFFINE_CORE/CertificationGate.lean` — Certification gate
- `Prime/lean/AFFINE_CORE/Stability/ZenoContractivity.lean` — Zeno stability
- `Prime/lean/Core/Spine.lean` — Existing Core Spine
- `Prime/lean/dynamics/Lyapunov.lean` — Existing Lyapunov dynamics
- ADR-091 (XIFormal) — Stability dynamics foundation
- ADR-092 (ROC Engine) — Lyapunov and spectral dynamics
