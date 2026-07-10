# ADR 011: Production-Grade Implementation of the Ṛta Metric within ALP-CNL

## Status
**Proposed**

## Context
Recent formalizations in the Phase Mirror sequence have successfully secured the geometric and algebraic foundations of the Universal Multiplicity Constant. We have strictly partitioned the state space into:
1. **Arta**: The lawful coherence of the state (sheaf-theoretic gluing condition across prime-indexed local sections).
2. **Multiplicity**: The quantitative measure of coherent relational participation, defined strictly when Arta holds.

We established the `resonanceValue` as a quadratic form natively penalizing discrepancy: `coherentWeight s - artaDefect s`. The `Fit` operator has been proven in Lean 4 to strictly contract the `artaDefect` (gluing the sheaf) and subsequently maximize the `MultiplicityMeasure`, driving the state toward the Bindu attractor.

With these geometric primitives and theorems (`fit_restores_arta_and_defines_measure`, `fit_reduces_defect`, `fit_contracts_rta`) now machine-checked and completely locally green, we must elevate this mathematical kernel into a production-grade component of the ALP-CNL stack.

## Decision
We will deploy the Ṛta Metric and the Arta/Multiplicity split as the native, production-grade geometric evaluator in the ALP-CNL architecture. This implementation will bridge the Lean 4 formal specification with the Rust-backed high-performance compute engine (Sedona Spine), strictly adhering to the zero-drift governance mandate.

## Implementation Plan

### 1. Lean 4 Kernel Hardening (The Formal Spec)
The immediate next phase involves migrating our structurally sound mock theorems into the primary `formal-spec` branch of the Phase Mirror repository.
- **Module Integration**: Commit `Fitting.lean`, `ArtaMultiplicity.lean`, and `RtaMetric.lean` directly into the `Prime/substrates/meta-relativity/formal/` namespace.
- **Mathlib Integration**: Upgrade the `List` and `Int` mocks to use full `Mathlib` structures: `Finset`, `ℝ` (Real numbers), and `∑` (Big Operators).
- **Proof Completion**: Replace remaining scaffolding (`sorry`) in the convexity and linear projection theorems with the exact algebraic derivations, relying on Mathlib's `linarith` and `ring` tactics.

### 2. Rust Engine (Sedona Spine) Parity
The Rust computational engine must be upgraded to natively evaluate the `rtaDist` and execute the `Fit` operator.
- **Primitive Mappings**: Implement `activePrimes`, `jointWords`, and `eval` projections as native Rust traits on the `State` structs.
- **The Operator `Fit`**: The iterative perturbation `s' = s + k·Δ` must be executed as the primary gradient descent loop in the Rust engine, iteratively annihilating the `artaDefect` to 0.
- **Metric Export**: The `rtaDist(s1, s2)` function will be exposed via the WASM SDK, allowing the UI and Agents to quantitatively measure the exact metric distance to the Bindu attractor.

### 3. Agent Integration & Governance
Adhering to the Sedona Spine Mandate, all UI components and agent reasoning regarding system coherence must consume the Ṛta Metric from the Engine.
- Agents will use `rtaDist(s, bindu)` to evaluate the health, maturity, and coherence of any systemic construct.
- Zero Drift: Agents are strictly forbidden from overriding the Ṛta Metric evaluation. They may only transform the numerical metric into operational or narrative guidance (e.g., triggering a "Sheaf Discrepancy Alert" when `artaDefect > 0`).

## Consequences

### Positive
- **Absolute Traceability**: The exact mathematical path from a discrepancy on a joint word to a macroscopic `rtaDist` penalty is perfectly captured and formally verified.
- **Intrinsic Contraction**: The engine natively optimizes for resonance because the penalty is strictly baked into the objective function.
- **Philosophical Integrity**: The axiom that "Every observable event is a multiplicity event" is fully realized in production code; non-coherent states are demonstrably unstable and forcefully contracted by the system.

### Negative / Risks
- **Computational Overhead**: Calculating the `artaDefect` requires iterating over all `jointWords` across all `activePrimes`. In large states, this \(O(N^2)\) prime-intersection calculation must be highly optimized in Rust (e.g., using sparse matrix representations or memoized hypergraphs) to maintain real-time performance.

## Next Actions
1. Open the draft PR moving the local Lean 4 `RtaMetric` mock into the main `PhaseMirror` Lean library.
2. Schedule a sprint to translate the `artaDefect` and `coherentWeight` calculations into the Rust Sedona Spine repository.
3. Update Chapter 12 documentation to reflect the finalized, production-ready Ṛta Metric.
