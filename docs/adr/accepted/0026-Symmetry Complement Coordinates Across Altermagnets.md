# ADR-0026: Symmetry-Complement Coordinates Across Altermagnets — Cross-Material Falsification

**Status:** Proposed

## Context
A portable symmetry argument must survive materials in which the microscopic hierarchy, probe physics, and even the proposed magnetic state differ, and it must not be made true by choosing its reference model after seeing the target response. The Altermagnetic literature has accumulated strong positive signatures and sharply constraining nulls across MnF₂, FeF₂, α-MnTe, CrSb, α-Fe₂O₃, and bulk RuO₂. Whether the δJ7-style source-sector construction generalizes, and how far, cannot be judged by favorable examples alone.

## Decision
Adopt the hardened cross-material falsification benchmark with a six-component claim vector as the standard for source-sector attribution across altermagnets.

- **Six-component claim vector.** c = (M, S, E, χ, R, K): static magnetic order M; identification of a response-specific Hamiltonian/operator source sector S; nonrelativistic electronic spin splitting E; chiral collective dynamics χ; signed reversal/control relation R; static multipolar content K. Components are not collapsed into a scalar; each is closed or left open independently.
- **Predeclared-reference admissibility.** Source-sector attribution is accepted only relative to a predeclared or independently anchored reference (H₀, G₀) for which the target channel is absent or symmetry-degenerate, with a certificate A_m,j = A_ind ∧ A_state ∧ A_null ∧ A_no-retune. A post-hoc reference is insufficient even if it reproduces the data.
- **Adversarial controls.** FeF₂ tests separation of a weak altermagnetic contribution from a dominant long-range dipolar splitting; MnSi is a non-altermagnetic specificity control showing χ ≠ 0 ⇏ altermagnetic source (Dzyaloshinskii–Moriya physics).
- **Verdicts.** Per-material verdicts are label sets (Closed / Supported / Provisional / Open / Contradicted / Disfavored / Blocked / State-dependent) and framework verdicts are Pass / Partial / Blocked / Specificity; they are not evidence scores ranking materials.
- **Source-state gating.** A downstream signal can be physically real while its attribution to an altermagnetic bulk state fails because the upstream state is absent or contradicted (bulk RuO₂: M Contradicted ⇒ S Blocked).

## Consequences
* The restricted generalization survives — response-specific symmetry-complement *sectors* — while the universal weak one-dimensional coordinate, universal smallness ratio, and the inference χ ≠ 0 ⇒ altermagnetic source are rejected.
* Attribution is killed by the source-state gate before downstream observables can be counted.
* MnF₂ is benchmarked as a near-scalar (d_S ≃ 1) inside a bounded range-seven model; MnTe and CrSb require broader exchange sectors (d_S > 1); hematite a response-specific long-range exchange family.
* Identifies decisive missing experiments per material (e.g., independent signed δJ7 readout for MnF₂; peer-reviewed replication of the CrSb g-wave multipole preprint).

## Traceability & Artifact Links
* **[Source File]** `docs/adr/proposed/Paper5 Symmetry Complement Coordinates Across Altermagnets- Predeclared References and Cross Material Falsification - JHaines 2026.pdf` — "Symmetry-Complement Coordinates Across Altermagnets: Predeclared References and Cross-Material Falsification" (John Haines, Sept 12, 2026).
* **[Related ADR]** ADR-0023 — MnF₂'s d_S ≃ 1 calibration case in the δJ7 convention.
* **[Related ADR]** ADR-0025 — the K component and its conditional identifiability feeding the matrix.
* **[Related ADR]** ADR-0027 — the layered null taxonomy that makes cross-probe agreement meaningful.
* **[Related ADR]** ADR-0028 — target-first protocol that operationalizes the same state-gate logic.

* **[Delivered — spec]** `docs/specs/observ_calculus_v1.md` (+ `observ_calculus_v1.schema.json`) — the measurement-map program wire and gate semantics.
* **[Delivered — kernel]** `packages/rust/observ` — exact-rational observability kernel: null/witness filtrations, obstruction dimension with dual counterexamples, design gain, Walsh–Hadamard reversal coding, admissible-reference sector gate, six-component claim gate, receipts bound into the CRMF PWEH chain (no WORM); sample programs under `packages/rust/observ/programs/`, verified by 4 Kani harnesses and 50 unit/integration tests on `cargo test -p observ`.