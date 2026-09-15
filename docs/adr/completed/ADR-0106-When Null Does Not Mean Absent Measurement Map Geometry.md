# ADR-0027: When Null Does Not Mean Absent — Measurement-Map Geometry and Null–Witness Duality

**Status:** Completed

## Context
A null experimental outcome is not, by itself, a statement of physical absence. A latent state passes through source physics, response formation, probe selection, ensemble averaging, instrument transfer, and nuisance structure before recorded data exist. Physics practice frequently assigns a stage label to a null ("response null", "projection null") without a rigorous basis for where distinguishability was lost, conflating raw signal with identification. The Altermagnetic program (this series) motivated the four-null distinction; the paper generalizes it into a compositional calculus.

## Decision
Adopt the layered measurement-map geometry with null–witness duality as the canonical discipline for interpreting nulls and combining probes.

- **Layered factorization.** A total map is written M = T ∘ A ∘ P ∘ R ∘ S over source/state preparation, response, probe projection, ensemble/domain averaging, and transfer/resolution, with nuisance parameters entering any stage; measurement fibers M⁻¹(M(x)) define observational equivalence.
- **Null-then-witness filtration.** In a layered linear experiment with cumulative maps F_j, the cumulative nulls K_j = ker F_j form a filtration K₀ ⊆ K₁ ⊆ … ⊆ K_n and the dual witness spaces W_j = Ann(K_j) = im F_j* shrink in the opposite direction; K_j/K_{j−1} records directions first erased at stage j.
- **Boundaries.** The total observational quotient is factorization-independent, but stage-local null attribution is invariant only under invertible reparameterizations of declared intermediate spaces, not under arbitrary refactorization. Passive post-processing cannot restore an erased distinction; active intervention (field reversal, domain retraining, re-preparation) creates a new measurement map and can shrink the joint kernel.
- **Target-specific closure.** A linear target C is identifiable after stage j iff K_j ⊆ ker C; the target-obstruction dimension d_C(A) = dim C(ker A) counts exact unresolved target directions and is not an evidence score.
- **Common-state closure.** Independent probes combine by kernel intersection, ker A_stack = ∩ ker A_i, only when they refer to a common latent state; otherwise the ζᵢ must be promoted into the latent model or closure is spurious.
- **Generalization scope.** Nonlinear/noisy experiments use nuisance-projected Jacobians and Fisher information; stochastic experiments use outcome-distribution maps; quantum measurements enter via POVM probability maps with the quantum instrument included when backaction matters.
- **Walsh–Hadamard coding.** Reversal experiments are characters of (ℤ₂)^N only when the reversals behave as commuting involutions; otherwise they remain exact factorial contrasts but not group characters.

## Consequences
* Every null is attributed to a specific stage of a declared factorization, or its stage label is withheld; the taxonomy now includes source/state failure, response, projection, averaging/domain, transfer/resolution, nuisance confounding, practical near-null, and model inconsistency.
* A large raw signal can be non-identifying and a nominally null channel can coexist with a nonzero orthogonal-sector signal.
* Upstream contradiction (source-state absence) has a different logical status from a downstream projection null, mirroring ADR-0026's source-state gate.
* Reversal channels double as obstruction testbeds: forbidden sectors expose leakage or missing physics.

## Traceability & Artifact Links
* **[Source File]** `docs/adr/proposed/Paper6 When Null Does Not Mean Absent- Measurement Map Geometry, Factorization Boundaries, and Null Witness Duality - JHaines 2026.pdf` — "When Null Does Not Mean Absent: Measurement-Map Geometry, Factorization Boundaries, and Null–Witness Duality" (John Haines, Sept 12, 2026).
* **[Related ADR]** ADR-0022 — the four-null taxonomy this ADR generalizes to the layered taxonomy.
* **[Related ADR]** ADR-0024 — Walsh–Hadamard reversal coding as the symmetry-coded specialization.
* **[Related ADR]** ADR-0026 — cross-probe closure conditioned on common latent state.
* **[Related ADR]** ADR-0028 — the target-first calculus built as the time-reversed use of this geometry.

* **[Delivered — spec]** `docs/specs/observ_calculus_v1.md` (+ `observ_calculus_v1.schema.json`) — the measurement-map program wire and gate semantics.
* **[Delivered — kernel]** `packages/rust/observ` — exact-rational observability kernel: null/witness filtrations, obstruction dimension with dual counterexamples, design gain, Walsh–Hadamard reversal coding, admissible-reference sector gate, six-component claim gate, receipts bound into the CRMF PWEH chain (no WORM); sample programs under `packages/rust/observ/programs/`, verified by 4 Kani harnesses and 50 unit/integration tests on `cargo test -p observ`.