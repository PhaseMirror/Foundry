# ADR-006: Phase Mirror Governance and Deployment Gates

## Status
**Planned**

## Context
The 7-phase implementation roadmap detailed in `MSP_3.md` (Foundation, Validation, Embodied Layer, Atomic Layer, Crypto-Economic Layer, Operational Deployment, and Scaling) establishes the sequence required to safely deploy the Multiplicity Social Physics ecosystem. 

In traditional software rollouts, roadmap phases are often bypassed, abbreviated, or prematurely triggered by business pressure or manual overrides. Given that our system involves verified constraints, human nervous system regulation (Embodied Layer), and economic valuation (Crypto-Economic Layer), premature phase advancement can cause catastrophic systemic collapse or legal invalidation. We must programmatically enforce roadmap integrity so that human governance cannot violate the mathematical prerequisites for scaling.

## Decision
We will build a strict, formally verified state-machine into the Sedona Spine (Rust Kernel) governed by the **Phase Mirror** protocol. 

1. **State-Machine Gates:** Progression from one phase to the next is structurally gated. The system cannot progress unless specific internal conditions (e.g., benchmark accuracy, node density, embodied scores) are mathematically verified by the kernel.
2. **Monotonicity:** Deployment phases are strictly monotonic. The system cannot skip a phase, nor can it rollback to an earlier phase once the higher-level invariant guarantees are instantiated.
3. **Rust Engine Enforcement:** No UI button or admin command can forcefully mutate the current phase. Progression requires submitting a formal cryptographically signed Event Log demonstrating that all conditions of the current gate have been achieved.

## Formal Proof Obligations

To guarantee this governance constraint, we must construct Lean 4 proofs that prevent invalid progression logic in the state machine.

### 1. Monotonicity and No Bypassing
We must prove that for any phase transition $N \to M$, it must hold that $M = N + 1$.

**Lean 4 Formalization Sketch:**
```lean
import ADR.Core

namespace ADR.PhaseMirror

inductive RoadmapPhase
| Foundation             -- Phase 1
| Validation             -- Phase 2
| EmbodiedLayer          -- Phase 3
| AtomicLayer            -- Phase 4
| CryptoEconomic         -- Phase 5
| OperationalDeployment  -- Phase 6
| Scaling                -- Phase 7
deriving Repr, DecidableEq

/-- The step relation defining the single allowable subsequent phase -/
def next_phase : RoadmapPhase → Option RoadmapPhase
| RoadmapPhase.Foundation            => some RoadmapPhase.Validation
| RoadmapPhase.Validation            => some RoadmapPhase.EmbodiedLayer
| RoadmapPhase.EmbodiedLayer         => some RoadmapPhase.AtomicLayer
| RoadmapPhase.AtomicLayer           => some RoadmapPhase.CryptoEconomic
| RoadmapPhase.CryptoEconomic        => some RoadmapPhase.OperationalDeployment
| RoadmapPhase.OperationalDeployment => some RoadmapPhase.Scaling
| RoadmapPhase.Scaling               => none

/-- Valid state transitions must follow exactly one step -/
inductive ValidPhaseTransition : RoadmapPhase → RoadmapPhase → Prop
| step {p1 p2 : RoadmapPhase} (h : next_phase p1 = some p2) : ValidPhaseTransition p1 p2

/-- Theorem: A transition from Foundation to CryptoEconomic is strictly prohibited -/
@[proof]
theorem no_bypass_validation (h : ValidPhaseTransition RoadmapPhase.Foundation RoadmapPhase.CryptoEconomic) : False := by
  -- Proof that the inductively defined ValidPhaseTransition relation 
  -- mathematically forbids skipping phases.
  cases h
  contradiction
```

## Consequences

### Positive
- **Absolute Deployment Safety**: By embedding the roadmap directly into the computational kernel, we prevent catastrophic failures associated with deploying economic incentives before the underlying social validation (Embodied Layer) is ready.
- **Trustless Governance**: External stakeholders, auditors, and participants can mathematically verify that the Phase Mirror will not allow arbitrary rule changes or rushed implementations.
- **Enforced Discipline**: Forces the community and developers to rigorously satisfy the constraints of the current phase rather than kicking technical debt down the road.

### Negative
- **Inflexibility**: If a critical, unforeseen operational reality requires adjusting the phase order (e.g., pivoting), the system cannot accommodate it without rewriting the verified Lean proofs and compiling a new rust kernel iteration—a deliberately slow process.
- **Strict Verification Burden**: Writing the specific gating logic (e.g., determining exactly when Phase 2 is "complete" mathematically) requires translating subjective real-world milestones into objective structural metrics.

## Implementation Steps
1. Formalize the `RoadmapPhase` types and transition proofs in Lean 4 (`ADR/PhaseMirror.lean`).
2. Translate the phase definitions and gating logic into the Sedona Spine (`src/roadmap.rs`).
3. Define the precise numeric or structural thresholds required to satisfy each gate (e.g., `if simulator_accuracy > 0.95 && ...`).
4. Implement the `try_advance()` function in Rust that evaluates the thresholds, returning a strict `Result<(), PhaseError>`.
5. Expose the current Phase and the progress-towards-next-gate metrics through the WASM SDK so the frontend can transparently display the system's operational maturity.
