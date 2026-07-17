# ADR-065: ACE Runtime Production Hardening

## Status
**Adopted**

## Context
The existing `Prime/docs/adr/0005-ace-runtime.md` defines the Attested Convergence Envelope (ACE) as a standalone enforcement layer, but it is **20 lines of prose** with no formal proof obligations, no Rust crate specification, and no Kani verification requirements. 

ACE is the **budget and invariant enforcement layer** of the Multiplicity Sovereign Core. It guarantees:
- Computation budget limits are never exceeded
- Invariant preservation (contraction bounds, resonance functional stability) is continuously monitored
- The `CompilationResult` is verifiable and auditable

Currently, ACE logic is embedded in various Rust crates (`ace-zk`, `ace-scn-csc`, `pirtm-invariants`) without a unified, formally verified interface. The `Prime/lean/adr-governance/` package does not reference ACE at all. This means:
- **No unified ACE specification**: Different crates enforce different subsets of the ACE contract.
- **No formal proof that ACE preserves invariants**: The Rust assertions are not backed by Lean 4 theorems.
- **No Kani verification**: The `ace-zk` crate uses `pyo3` for Python bindings but lacks Rust-level model checking.

## Decision
We will harden ACE into a **unified, formally verified, production-grade enforcement layer** with the following mandates:

### 1. Unified ACE Specification in Lean 4
- Define `ACE.lean` in `Prime/lean/adr-governance/ADR/ACE.lean` with:
  - `ComputationBudget` — struct capturing compute, memory, and time bounds
  - `InvariantSet` — set of predicates that must hold throughout computation
  - `ACEEnvelope` — dependent pair of `(initial_budget, invariant_set, witness_trace)`
- Prove:
  - `ace_preserves_invariants`: Any computation running within an `ACEEnvelope` never violates its `InvariantSet`.
  - `budget_exhaustion_detected`: If computation exceeds `ComputationBudget`, the ACE envelope flags a `BudgetViolation`.
  - `witness_trace_complete`: Every state transition within the envelope produces a cryptographically bound witness.

### 2. Rust Unification
- Consolidate ACE logic from `crates/ace-zk/`, `crates/ace-scn-csc/`, and `crates/pirtm-invariants/` into a single `crates/ace/` crate.
- The `crates/ace/` crate must expose:
  - `ACEEnvelope::new(budget, invariants) -> Result<ACEEnvelope, ACEInitError>`
  - `ACEEnvelope::check_transition(&mut self, state: &State) -> Result<ACEWitness, ACEViolation>`
  - `ACEEnvelope::finalize(self) -> Result<ACEProof, ACEBudgetExceeded>`
- All other crates must depend on `crates/ace/` rather than reimplementing ACE logic.

### 3. Kani Verification
- Implement Kani proof harnesses in `crates/ace/tests/kani/` proving:
  - `proof_ace_preserves_invariants`: For any public `ACEEnvelope` and valid state transition, `check_transition` returns `Ok` iff invariants hold.
  - `proof_budget_is_exhaustive`: Any state consuming more than `ComputationBudget` triggers `ACEBudgetExceeded`.
  - `proof_witness_is_bound`: `ACEWitness` contains a Blake3 hash of the state transition, preventing witness tampering.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/adr-governance/ADR/ACE.lean` and `cargo kani -p ace` on every PR.
- The Guardian lock must verify the `ACEProof` before approving any state transition.
- The Examiner lock must audit the `ACEWitness` trace for completeness.
- The Publisher lock must sign the final `ACEProof` into the `Archivum` ledger.

## Formal Proof Obligations

### 1. ACE Preserves Invariants
```lean
namespace ADR.ACE

structure ComputationBudget where
  max_cycles : Nat
  max_memory : Nat
  max_latency_ns : Nat
  deriving Repr

structure InvariantSet where
  invariants : List (String × (State → Bool))
  -- In full formalization, invariants are typed predicates from MOC/CRMF

structure ACEEnvelope where
  budget : ComputationBudget
  invariants : InvariantSet
  witness_trace : List String
  deriving Repr

inductive ACEViolation
  | BudgetExceeded {used : Nat} {limit : Nat}
  | InvariantBreach {inv_name : String}
  | WitnessTampered {witness_hash : String}

@[proof]
theorem ace_preserves_invariants (env : ACEEnvelope) (s₁ s₂ : State)
  (h_trans : check_transition env s₁ = some s₂) :
  ∀ inv ∈ env.invariants.invariants, inv.2 s₂ := by
  -- Proof by induction on the transition check
  -- Each invariant is evaluated in the Rust engine and proven in Lean 4
  sorry

@[proof]
theorem budget_exhaustion_detected (env : ACEEnvelope) (s : State)
  (h_over : compute_cycles s > env.budget.max_cycles) :
  check_transition env s = none := by
  -- Proof that the Rust engine rejects over-budget states
  sorry

end ADR.ACE
```

### 2. Rust Runtime Contract
```rust
// crates/ace/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComputationBudget {
    pub max_cycles: u64,
    pub max_memory: u64,
    pub max_latency_ns: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InvariantSet {
    pub invariants: Vec<(String, fn(&State) -> bool)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ACEWitness {
    pub state_hash: [u8; 32],
    pub invariant_checks: Vec<(String, bool)>,
    pub budget_used: u64,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum ACEViolation {
    #[error("budget exceeded: {used} > {limit}")]
    BudgetExceeded { used: u64, limit: u64 },
    #[error("invariant breached: {inv_name}")]
    InvariantBreach { inv_name: String },
}

pub struct ACEEnvelope {
    budget: ComputationBudget,
    invariants: InvariantSet,
    cycles_used: u64,
    witness_trace: Vec<ACEWitness>,
}

impl ACEEnvelope {
    pub fn new(budget: ComputationBudget, invariants: InvariantSet) -> Result<Self, ACEViolation> {
        Ok(Self { budget, invariants, cycles_used: 0, witness_trace: Vec::new() })
    }

    pub fn check_transition(&mut self, state: &State) -> Result<State, ACEViolation> {
        self.cycles_used += 1;
        if self.cycles_used > self.budget.max_cycles {
            return Err(ACEViolation::BudgetExceeded {
                used: self.cycles_used,
                limit: self.budget.max_cycles,
            });
        }
        for (name, check) in &self.invariants.invariants {
            if !check(state) {
                return Err(ACEViolation::InvariantBreach { inv_name: name.clone() });
            }
        }
        let witness = ACEWitness {
            state_hash: blake3::hash(&serde_json::to_vec(state).unwrap()).into(),
            invariant_checks: self.invariants.invariants.iter().map(|(n, c)| (n.clone(), c(state))).collect(),
            budget_used: self.cycles_used,
            timestamp: chrono::Utc::now().timestamp(),
        };
        self.witness_trace.push(witness);
        Ok(state.clone())
    }
}
```

## Consequences

### Positive
- **Unified Enforcement**: All ACE logic lives in one place, eliminating drift between crates.
- **Formal Guarantees**: Lean 4 proofs back every Rust assertion, making ACE violations structurally impossible within verified bounds.
- **Kani-Verified**: Model checking guarantees no edge-case bypass in the Rust implementation.
- **Audit-Ready**: Complete witness trace emitted to `Archivum` for every computation.

### Negative
- **Consolidation Effort**: Merging `ace-zk`, `ace-scn-csc`, and `pirtm-invariants` into `crates/ace/` requires careful dependency management and may break downstream consumers.
- **Performance Overhead**: Per-transition invariant checks add latency. The `cycles_used` counter must be atomic in concurrent contexts.
- **Formalization Gap**: The `InvariantSet` predicates must be lifted from informal Rust closures to formal Lean predicates, requiring significant metaprogramming or DSL design.

## Implementation Steps

1. **Define `ACE.lean`** in `Prime/lean/adr-governance/ADR/ACE.lean`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/ACEProofs.lean`.
3. **Create `crates/ace/`** Rust crate, consolidating logic from `ace-zk`, `ace-scn-csc`, and `pirtm-invariants`.
4. **Implement Kani harness** proving `check_transition` soundness.
5. **Wire Triple-Lock integration**: Guardian → `ACEEnvelope::check_transition` → Examiner → `ACEWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p ace` + `cargo test -p ace`.
7. **Emit Archivum witness** `ACEProof` on every finalized envelope.
8. **Deprecate legacy crates** (`ace-zk`, `ace-scn-csc`, `pirtm-invariants`) via follow-up ADRs.

## References
- `Prime/docs/adr/0005-ace-runtime.md` — Legacy ACE ADR (to be superseded)
- `Prime/crates/ace-zk/` — Existing ACE zero-knowledge crate
- `Prime/crates/ace-scn-csc/` — Existing ACE SCN/CSC crate
- `Prime/crates/pirtm-invariants/` — Existing PIRTM invariant crate
- `Prime/lean/adr-governance/` — Lean ADR governance package
- ADR-002 (Sedona Spine) — Path of Integrity
- ADR-008 (Recursive Proof Aggregation) — Batch ZK proofs
- `publications/ACE Runtime Certification Stack/` — ACE publication
- ADR-006 (Phase Mirror Governance) — Deployment gates
