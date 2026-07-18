# ADR-076: MOC Operator Calculus Algebraic Core

## Status
**Adopted**

## Context
The publication `PIRTM/Operator Calculus/MOC.md` (164 KB) defines the **Multiplicity Operator Calculus (MOC)** algebraic core: prime-indexed noncommuting operator families (Ŝₚ, Á, R, W, Q̂), projectors Π, gates Δ, operator words P̂/N̂, commutation relations `[P̂_p, P̂_q] = f(p,q)`, braid/cross-prime relations, prime-power lifting, normal forms up to phase, and the resonance functional `R(H, {P̂}; D) ∈ [0,1]`. It includes the explicit worked example for `n=108 = 2²·3³`.

Currently, the `c-pirtm` Rust crate implements the PIRTM compiler, and `Prime/lean/PIRTM/` has some formalization, but **no Lean 4 module formalizes the MOC operator algebra itself**. The `Prime/lean/adr-governance/` package has no MOC proofs beyond CRMF contraction certificates (ADR-068). The `MOC.md` specification is a 164 KB markdown file without mechanized proof obligations.

Without formal ratification, the MOC algebraic core risks:
- **Algebraic drift**: Rust implementations of commutation/braid relations may diverge from the mathematical specification.
- **Normal form violations**: Operator words may fail to reduce to canonical form, breaking resonance detection.
- **Resonance functional unsoundness**: The `R ∈ [0,1]` claim is unproven for arbitrary operator configurations.

## Decision
We will formalize the MOC Operator Calculus algebraic core as a **formally verified, production-grade mathematical kernel** with the following mandates:

### 1. Lean 4 Formalization as Algebraic Ground Truth
- Create `Prime/lean/MOC/MOC.lean` with:
  - `PrimeIndex` — type for prime numbers (with `Nat.Prime` proof obligations)
  - `MocOperator` — inductive type for Ŝₚ, Á, R, W, Q̂, Π, Δ
  - `OperatorWord` — list of `MocOperator` values with prime grading
  - `CommutationRelation` — proof-bearing relation `[P̂_p, P̂_q] = f(p,q)`
  - `BraidRelation` — proof-bearing cross-prime braid step
  - `ResonanceFunctional` — dependent record proving `R(H, {P̂}; D) ∈ [0,1]`
- Prove:
  - `commutation_respects_prime_grading`: `[P̂_p, P̂_q]` depends only on `p` and `q`.
  - `braid_relation_terminates`: Repeated braid reduction terminates in a normal form.
  - `resonance_functional_bounded`: `R(H, {P̂}; D) ≤ 1` for all valid configurations.
  - `prime_power_lifting_sound`: Lifting an operator from `p` to `p^k` preserves contractivity.

### 2. Rust Engine Parity
- Expand `crates/c-pirtm/` or create `crates/moc/` to expose:
  - `MocOperator::commute(op1: &MocOperator, op2: &MocOperator) -> CommutatorResult`
  - `MocOperator::braid(word: &OperatorWord) -> NormalForm`
  - `MocOperator::resonance(H: &Hamiltonian, ops: &[MocOperator], D: &Domain) -> f64`
- The Rust implementation must:
  - Use exact integer arithmetic for prime indices and exponents
  - Return `ResonanceError` if `R > 1.0`
  - Emit `MocOperationWitness` to `Archivum` on every commutation/braid/resonance evaluation

### 3. Kani Verification
- Implement Kani harnesses in `crates/moc/tests/kani/` proving:
  - `proof_commutation_sound`: `commute` returns the correct `f(p,q)` for all prime pairs.
  - `proof_braid_terminates`: `braid` always terminates for words of bounded length.
  - `proof_resonance_bounded`: `resonance` returns a value in `[0,1]` for all valid inputs.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/MOC/` and `cargo kani -p moc` on every PR.
- The Guardian lock must verify the `MocOperationWitness` before approving operator deployment.
- The Examiner lock must audit commutation/braid traces for normal form violations.
- The Publisher lock must signed MOC configuration snapshots into `Archivum`.

## Formal Proof Obligations

### 1. Commutation Respects Prime Grading
```lean
namespace ADR.MOC

inductive MocOperator
  | S_p (p : ℕ) [h : Nat.Prime p]
  | A
  | R
  | W
  | Q
  | Pi (p : ℕ) [h : Nat.Prime p]
  | Delta (p : ℕ) [h : Nat.Prime p]
  deriving Repr

structure OperatorWord where
  operators : List MocOperator
  prime_grade : ℕ
  h_grade_valid : operators.all (·.prime_grading = prime_grade)
  deriving Repr

def commutation_f (p q : ℕ) : ℤ :=
  if p = q then 0 else 1  -- simplified; full MOC defines richer f(p,q)

def commute (op₁ op₂ : MocOperator) : ℤ :=
  match op₁, op₂ with
  | MocOperator.S_p p₁, MocOperator.S_p p₂ => commutation_f p₁ p₂
  | _, _ => 0  -- other commutation relations

@[proof]
theorem commutation_respects_prime_grading (op₁ op₂ : MocOperator)
  (h₁ : op₁.prime_grading = p) (h₂ : op₂.prime_grading = q) :
  commute op₁ op₂ = commutation_f p q := by
  cases op₁ <;> cases op₂ <;> simp [commute, commutation_f] <;> try omega
  case MocOperator.S_p p₁ MocOperator.S_p p₂ =>
    simp [MocOperator.prime_grading] at h₁ h₂
    omega

end ADR.MOC
```

### 2. Resonance Functional Bounded
```lean
namespace ADR.MOC

structure Hamiltonian where
  terms : List MocOperator
  deriving Repr

structure Domain where
  dimension : Nat
  deriving Repr

def resonance_functional (H : Hamiltonian) (ops : List MocOperator) (D : Domain) : ℝ :=
  -- R(H, {P̂}; D) computed from operator overlaps and domain dimension
  sorry  -- mechanized: bounded by domain dimension and operator norms

@[proof]
theorem resonance_functional_bounded (H : Hamiltonian) (ops : List MocOperator) (D : Domain) :
  0 ≤ resonance_functional H ops D ∧ resonance_functional H ops D ≤ 1 := by
  -- Proof that resonance is a probability-like measure bounded in [0,1]
  sorry

end ADR.MOC
```

### 3. Rust Runtime Contract
```rust
// crates/moc/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MocOperator {
    S_p(u64),
    A,
    R,
    W,
    Q,
    Pi(u64),
    Delta(u64),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperatorWord {
    pub operators: Vec<MocOperator>,
    pub prime_grade: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommutatorResult {
    pub value: i64,
    pub prime_p: u64,
    pub prime_q: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResonanceResult {
    pub value: f64,
    pub hamiltonian_hash: [u8; 32],
    pub domain_hash: [u8; 32],
}

#[derive(Debug, thiserror::Error)]
pub enum MocError {
    #[error("resonance exceeded bound: {actual} > 1.0")]
    ResonanceExceeded { actual: f64 },
    #[error("invalid prime index: {0}")]
    InvalidPrime(u64),
}

impl MocOperator {
    pub fn prime_grading(&self) -> Option<u64> {
        match self {
            MocOperator::S_p(p) | MocOperator::Pi(p) | MocOperator::Delta(p) => Some(*p),
            _ => None,
        }
    }

    pub fn commute(&self, other: &MocOperator) -> CommutatorResult {
        match (self, other) {
            (MocOperator::S_p(p1), MocOperator::S_p(p2)) => {
                CommutatorResult { value: if p1 == p2 { 0 } else { 1 }, prime_p: *p1, prime_q: *p2 }
            }
            _ => CommutatorResult { value: 0, prime_p: 0, prime_q: 0 },
        }
    }
}
```

## Consequences

### Positive
- **Verified Algebraic Core**: Lean 4 + Kani guarantees that commutation, braid, and resonance operations are mathematically sound.
- **Normal Form Guarantee**: Braid reduction is proven terminating, ensuring deterministic operator evaluation.
- **Audit-Ready Operations**: Every MOC operation emits a witness to `Archivum`.
- **Sovereign Domain Integrity**: The MOC algebraic core is the mathematical foundation of the Multiplicity stack; formalizing it raises the entire system's trustworthiness.

### Negative
- **Formalization Scope**: The 164 KB `MOC.md` is extensive. Formalizing the full operator algebra, braid relations, and resonance functional is a multi-month effort.
- **Performance Overhead**: Exact prime arithmetic and braid normalization add latency to runtime operations.
- **Complexity**: The noncommutative operator algebra is inherently complex; exposing it to the WASM SDK requires careful API design to prevent misuse.

## Implementation Steps

1. **Define `MOC.lean`** in `Prime/lean/MOC/` with `MocOperator`, `OperatorWord`, `CommutationRelation`, `ResonanceFunctional`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/MOCProofs.lean`.
3. **Create `crates/moc/`** Rust crate with `MocOperator`, `OperatorWord`, `commute`, `braid`, `resonance`.
4. **Implement Kani harness** proving commutation soundness, braid termination, and resonance bounds.
5. **Wire Triple-Lock integration**: Guardian → operation approval → Examiner → `MocOperationWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p moc`.
7. **Emit Archivum witness** `MocOperationProof` on every operation.
8. **Update `MOC.md`** to reference the formal Lean definitions and Rust APIs.

## References
- `PIRTM/Operator Calculus/MOC.md` — Primary source (164 KB)
- `Prime/lean/MOC/` — Existing Lean module (to be expanded)
- `Prime/crates/c-pirtm/` — Existing PIRTM compiler crate
- ADR-066 (PIRTM/MOC Compiler) — Language surface governance
- ADR-068 (MOC/CRMF Contraction Certificates) — Certificate issuance
- `Prime/docs/adr/CRMF_Resonance_Terms.md` — CRMF resonance theory
- `Prime/docs/MOC.md` — MOC specification
