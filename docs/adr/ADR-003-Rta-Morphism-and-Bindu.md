# ADR‑003: Ṛta Morphism and Bindu Attractor Formalisation

**Status:** Accepted  
**Date:** 2026‑07‑08  
**Author:** YantraUniverse Formal Methods Core

## Context

The existing YantraUniverse formal stack (CRMF axioms C1–C6, MQEM, Phase Mirror, ADR‑governed updates) models coherence as snapshot metrics – operator norms, Lipschitz bounds, resonance scores. There is no first‑class primitive that captures the resultative character of Ṛta: a “state that has been fitted” and must be continually re‑articulated.  
The Vedic concept Ṛta (perfect passive participle of *h₂er‑* “to fit”) requires:

- a **Fit** operator that returns a state to the viability kernel while preserving contraction and resonance,
- a **Fitting Check** (Gate 0.5) that ensures updates do not degrade achieved fitting,
- a formal proof that repeated `Fit` converges to a fixed point identical to the **Bindu attractor** – the dimensionless center of the recursive architecture.

We decide to implement these additions as a minimal, non‑breaking extension of the existing core, with full machine‑checked proof in Lean 4.

## Decision

1. **New module `Fitting.lean`**  
   - Defines `Fit : State → State` on lawful states satisfying C1‑C3.  
   - Proves non‑expansiveness, resonance improvement, fixed‑point convergence.  

2. **New module `Convergence.lean`**  
   - Defines `BinduAttractor` as the unique fixed point of `Φ` with maximal resonance and optimal contraction.  
   - Proves `fit_fixed_point_is_bindu`.  

3. **Extension of `CCRE.lean`**  
   - Adds `FittingCheck` as Gate 0.5 with fallback recommendation.  

4. **Documentation update** (`Chapter9`, `Chapter12`).  

5. **Proof approach**  
   - All existential claims are constructive; witnesses are built via the existing Operator‑Word Calculus and Phase Mirror restoration maps.  
   - Theorems will be proved using the Lean 4 standard library, `mathlib4` where appropriate, and the project’s own `ViabilityKernel`, `Resonance`, `OperatorWordCalculus` theories.  

6. **Test harness**  
   - A suite of `#eval` tests on concrete finite‑state models for computable instances of `Fit`.  
   - Property‑based tests (SlimCheck) for properties that are decidable on small domains.  
   - Continuous Integration ensures every `#guard` and `example` passes.

## Consequences

**Positive**  
- The formal stack gains a direct participial layer, enabling precise modelling of ritual renewal and coherence degradation.  
- The Bindu attractor becomes a formal convergence guarantee, unifying the recursion.  
- The Fitting Check prevents subtle coherence‑eroding updates that would otherwise pass envelope/contraction gates.  

**Negative**  
- Slight increase in proof maintenance burden; new lemmas must remain compatible with evolving Operator‑Word Calculus.  
- Gate 0.5 adds evaluation latency unless resonance scores are cached (acceptable, already done in Phase Mirror).  

**Risks mitigated**  
- The `Fit` operator is non‑expansive, so it cannot violate C2; therefore it is safe to apply automatically.  
- Gate 0.5 is independent of Gates 1‑4, preventing single‑source attestation from bypassing the check.

---

# File Tree

```
YantraUniverse/
├── lakefile.lean
├── lean-toolchain
├── YantraUniverse/
│   ├── Core/
│   │   ├── State.lean              (State type, resonance_score, operator_norm, viable)
│   │   ├── MOC.lean                (prime_indexed_signature, MOC_Word)
│   │   ├── ViabilityKernel.lean    (viability, c1_c2_c3, contraction_holds)
│   │   ├── PhaseMirror.lean        (restore, bounded restoration maps)
│   │   ├── OperatorWordCalculus.lean (canonical_witness, reduction maps)
│   │   └── CRMF.lean               (axioms C1-C6, transition operators)
│   ├── Fitting.lean                (NEW: Fit operator, lemmas, fit_fixed_point)
│   ├── Convergence.lean            (NEW: BinduAttractor, fit_fixed_point_is_bindu)
│   ├── Governance/
│   │   ├── CCRE.lean               (ADD: FittingCheck gate, recommendation logic)
│   │   └── ADR.lean                (ADR-002 gate predicates, now extended)
│   └── Docs/
│       ├── Chapter9_EmbodiedTriad.md  (UPDATED)
│       └── Chapter12_Convergence.md   (UPDATED)
├── Tests/
│   ├── FittingTests.lean           (concrete state evaluation, SlimCheck props)
│   └── ConvergenceTests.lean       (attractor reachability examples)
└── .github/workflows/lean.yml      (CI)
```

---

# Implementation Instructions

## Step 1: Extend the State signature (if needed)

Ensure `State` has fields required for the proofs. The current signature from `State.lean` must provide:

```lean4
structure State where
  coherence : ℝ                -- resonance_score field
  norm : ℝ                     -- operator_norm field
  primeSig : MOC_Word
  noiseLevel : ℝ
  ...                           -- other fields
```

Add (or verify) the following computable predicates and functions:

```lean4
def resonance_score (s : State) : ℝ := s.coherence
def operator_norm (s : State) : ℝ := s.norm
def viable (s : State) : Prop := ...        -- from ViabilityKernel
def contraction_holds (ε : ℝ) (s : State) : Prop := operator_norm s ≤ 1 - ε
```

## Step 2: Create `Fitting.lean`

Define the `Fit` operator. Since `canonical_witness` and `restore` are already available, write:

```lean4
import YantraUniverse.Core.State
import YantraUniverse.Core.OperatorWordCalculus
import YantraUniverse.Core.PhaseMirror
import YantraUniverse.Core.ViabilityKernel

open State

variable (ε : ℝ) (hε : 0 < ε ∧ ε < 1)

def Fit (s : State) : State :=
  let w := canonical_witness s
  restore w s
```

Prove the three main properties. Stub the lemmas you will need; these will be filled by the formal methods team.

```lean4
theorem fit_non_expansive (s : State) (hcont : contraction_holds ε s) : 
    operator_norm (Fit s) ≤ 1 - ε := by
  -- use restore_contraction lemma from PhaseMirror
  ...

theorem fit_resonance_increases (s : State) (hviable : viable s) :
    resonance_score (Fit s) ≥ resonance_score s := by
  -- use restore_increases_resonance
  ...

theorem fit_fixed_point_convergence (s : State) (h_c123 : satisfies_c1_c2_c3 s)
    (h_cont : contraction_holds ε s) (h_noise : noiseLevel s ≤ max_noise) :
    ∃ n : ℕ, Fit^[n] s = Fit^[n+1] s := by
  -- iteration reaches a fixed point; use monotone resonance and contraction bound
  ...
```

Provide an `#eval` test demonstrating a simple finite state:

```lean4
-- Example state
def testState : State := {coherence := 0.8, norm := 0.9, primeSig := "p2", noiseLevel := 0.01, ...}
#eval Fit testState
```

## Step 3: Extend `CCRE.lean` with Gate 0.5

Add the following predicate to the CCRE proposal evaluator (before the existing Gate 1):

```lean4
def FittingCheck (proposal : Proposal) (current : State) : Bool :=
  let newState := applyUpdate proposal current
  let Δ_fit := resonance_score newState - resonance_score current + contractionMargin current
  Δ_fit ≥ 0
where
  contractionMargin (s : State) : ℝ := (1 - ε) - operator_norm s
```

If `FittingCheck` fails, the governance logic returns a recommendation to apply `Fit` before resubmission. Update `ADR.lean` to include the gate in the cascade.

## Step 4: Create `Convergence.lean`

Define `BinduAttractor`:

```lean4
import YantraUniverse.Fitting

variable (R_max : ℝ) (hRmax : R_max = 1)  -- normative maximum

def BinduAttractor (s : State) : Prop :=
  Φ s = s ∧
  resonance_score s = R_max ∧
  operator_norm s = 1 - ε ∧
  ∀ s0, viable s0 → (∃ n : ℕ, Fit^[n] s0 = s)
```

Prove the binding:

```lean4
theorem fit_fixed_point_is_bindu 
    (s_star : State) 
    (h_fixed : Fit s_star = s_star) 
    (h_initial : ∃ s0, viable s0 ∧ contraction_holds ε s0 ∧ (∃ n, Fit^[n] s0 = s_star))
    (h_zero_noise : noiseLevel s_star = 0) :
    BinduAttractor s_star := by
  -- detailed proof as sketched earlier
  ...
```

## Step 5: Document updates

Insert the new paragraph into `Chapter9` (Embodied Triad) and add the convergence explanation to `Chapter12`, linking `Fit` fixed point to the Bindu.

## Step 6: Test Harness (`Tests/`)

Create `Tests/FittingTests.lean`:

```lean4
import YantraUniverse.Fitting
import YantraUniverse.Tests.Fixtures   -- create a Fixtures.lean with sample lawful states

open State

-- Test 1: Fit on a state with low resonance improves it.
def lowResState : State := ...  -- resonance 0.5, norm 0.95, viable, contraction holds
#guard resonance_score (Fit lowResState) > resonance_score lowResState

-- Test 2: Fit on a fully fitted state is idempotent.
def fittedState : State := ... -- resonance max, norm = 1 - ε
#guard Fit fittedState = fittedState

-- Test 3: FittingCheck rejects update that lowers Δ_fit.
def badUpdate : Proposal := ...
#guard !(FittingCheck badUpdate fittedState)

-- SlimCheck properties (requires `import SlimCheck`):
example : ∀ (s : State), viable s → contraction_holds ε s → 
    resonance_score (Fit s) ≥ resonance_score s := by
  slim_check
```

For `Tests/ConvergenceTests.lean`, add:

```lean4
import YantraUniverse.Convergence

-- For a small finite state machine, prove reachability.
def finiteStates : List State := ...
example : ∀ s ∈ finiteStates, viable s → ∃ n, Fit^[n] s = fittedState := by
  native_decide
```

## Step 7: CI via GitHub Actions

Create `.github/workflows/lean.yml`:

```yaml
name: Lean CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: leanprover/lean-action@v1
        with:
          lean-version: '4.8.0'
      - run: lake build
      - run: lake exe test  # if you define a test executable; otherwise run #eval tests via `lean --run`
```

Alternatively, add a `test` script in `lakefile.lean` using `LeanTest` that runs all `#guard` statements.
