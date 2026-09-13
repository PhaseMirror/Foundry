# ADR-0028: Target-First Observability Calculus — Admissible Ambiguity and Dual Obstructions

**Status:** Accepted

## Context
Experimental design is often organized around an available instrument and only afterward around the claim the resulting data are meant to support. A detector records data; a paper makes a physical claim. Design decisions that maximize signal can select the wrong experiment: a high-amplitude measurement may have zero target design gain while a much smaller measurement exactly closes the target. The paper supplies a physics-specific observability workflow that reverses this ordering.

## Decision
Adopt the target-first observability calculus as the standard for designing altermagnetic (and general physics) experiments around a declared claim rather than an available instrument.

- **Target-first ordering.** target → state gate → forward map → target nulls / admissible set → dual obstruction → reversals / complementary probes → practical margin → attempted falsification. The 13-step explicit protocol (state the target; state the prerequisite state; build the state gate; factor the forward map; include nuisance and state variables; find target-changing fibers; quantify admissible ambiguity; construct a dual counterexample; encode controlled reversals; add complementary probes selectively; verify common-state compatibility; quantify practical margin; attempt falsification) is adopted.
- **Residual structural ambiguity.** For stacked exact common-state measurements A_E on a linear target C, the residual ambiguity is O_C(E) = C(ker A_E); structural closure holds exactly when O_C(E) = {0}. The structural design gain of a candidate probe is Δ_C(B|E) = d_C(E) − d_C(E∪B) ≥ 0. A probe with Δ_C = 0 may calibrate but does not improve exact identification; closure is discussed in residual ambiguity, not probe count.
- **Admissible-set contraction.** Exact closure and quantitative contraction are reported separately: O_C(E; y, Ω) = {Cx : x ∈ Ω, A_E x = y} with width/diameter w_C, recorded alongside d_C, because d_C is binary for scalar targets while the admissible interval can contract by orders of magnitude.
- **Dual obstructions.** Any v ∈ ker A_E with Cv ≠ 0 is a constructive counterexample; the most useful next experiment is maximally sensitive to such a counterexample, and a negative/forbidden channel is part of the identifying structure rather than quality assurance.
- **Worked counterexample.** For x = (θ, ν) with C = [1 0], a probe B_sig = [0 100] has Δ_C = 0 while B_tar = [1 0.01] has Δ_C = 1: maximum signal can be the wrong experiment.
- **State gate before downstream closure.** A downstream response cannot repair a contradicted upstream source-state attribution; H_S must survive an independent state gate before downstream response closure.
- **Practical margin.** Structural identifiability is necessary but not sufficient; after structural viability, optimize with nuisance-projected Jacobians J_eff and the target practical margin μ_C(J_eff), where c-optimal / goal-oriented OED enters downstream. Priors and regularizers stabilize or select but cannot create a witness direction absent from the data.

## Consequences
* Experiment selection is justified by target design gain (Δ_C > 0) or admissible-set contraction, not by raw response amplitude.
* Every claim carries a declared target, state gate, forward map, nuisance variables, an explicit target-changing ambiguity (or proof none remains), reversal/complementary probe, conditioning diagnostic, and an attempted falsification — a publication reporting standard.
* The three shortcuts forbidden for MnF₂ are named: magnon splitting alone does not identify the signed exchange; a polarized inelastic chiral signal does not by symmetry determine static multipole rank; a static multipole reconstruction does not prove the dynamical response of another probe.
* Equivalence classes, prior-conditional inference, and model inconsistency are reported explicitly rather than resolved by preference.

## Traceability & Artifact Links
* **[Source File]** `docs/adr/proposed/Paper7 From Hidden Order to Identifiable Physics- A Target First Observability Calculus with Admissible Ambiguity and Dual Obstructions - JHaines 2026.pdf` — "From Hidden Order to Identifiable Physics: A Target-First Observability Calculus with Admissible Ambiguity and Dual Obstructions" (John Haines, Sept 12, 2026).
* **[Related ADR]** ADR-0027 — the forward measurement-map geometry this calculus runs in reverse.
* **[Related ADR]** ADR-0024 — reversal-space coding as the concrete implementation of dual witness/obstruction channels.
* **[Related ADR]** ADR-0026 — the state gate formalized with the same upstream-first logic at benchmark scale.
* **[Related ADR]** ADR-0025 — the claim-separation discipline (C₁ signed exchange, C₂ dynamical chiral response, C₃ static multipole rank) governing MnF₂ targets.

* **[Delivered — spec]** `docs/specs/observ_calculus_v1.md` (+ `observ_calculus_v1.schema.json`) — the measurement-map program wire and gate semantics.
* **[Delivered — kernel]** `packages/rust/observ` — exact-rational observability kernel: null/witness filtrations, obstruction dimension with dual counterexamples, design gain, Walsh–Hadamard reversal coding, admissible-reference sector gate, six-component claim gate, receipts bound into the CRMF PWEH chain (no WORM); sample programs under `packages/rust/observ/programs/`, verified by 4 Kani harnesses and 50 unit/integration tests on `cargo test -p observ`.