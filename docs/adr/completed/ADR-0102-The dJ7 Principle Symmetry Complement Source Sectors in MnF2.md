# ADR-0023: The δJ7 Principle — Symmetry-Complement Source Sectors in Altermagnetic MnF₂

**Status:** Completed

## Context
A recurring theoretical idea in correlated-matter physics is that an observable can be controlled by a Hamiltonian term that is small in the total energy yet leading in a selected symmetry channel. In MnF₂ a small imbalance between the two symmetry-distinct seventh-neighbor Heisenberg exchange bonds (J7a and J7b) has emerged as a candidate source coordinate for the altermagnetic chiral response. Whether that construction is valid depends on a precise group-theoretic statement of what "symmetry complement" means relative to a declared reference model. The paper fixes that statement.

## Decision
Adopt the δJ7 principle as the canonical account of symmetry-complement source sectors in altermagnetic MnF₂.

- **Group-averaged decomposition.** Given a reference Hamiltonian H₀ with enhanced symmetry group G₀, group averaging defines a projector P onto the invariant subspace; the operator space V = im P ⊕ ker P splits into the invariant sector and the symmetry-complement (source) sector. The physically relevant part of ker P for a target response is the symmetry-complement source sector Vₘ = span{λₘ,a}.
- **Covariance law.** A coefficient λ in the complement transforms as F_O(ρ_s λ) = χ_O(s) F_O(λ); if the reference symmetry maps λ → −λ, analyticity forces an odd expansion F_−(λ) = k·λ + O(‖λ‖³). A small coefficient dominates a selected channel because lower-order invariant contributions are forbidden, not because the coefficient has become large — a selection statement, not an amplification law.
- **δJ7 convention.** The altermagnetic source is the inequivalence δJ7 ≡ J7b − J7a of the two symmetry-distinct seventh-neighbor bonds in the range-seven spin-wave model, with the bond-label convention declared explicitly (the sign is meaningful only after that declaration).
- **No universal scalar.** δJ7 is a bounded-model near-scalar, not a theorem of a full material Hamiltonian; the generality is a source *sector*, not universal one-dimensionality.

## Consequences
* Source attribution in MnF₂ is tied to a declared reference model and bond convention, preventing tautological "complement" definitions.
* The odd-channel expansion fixes the expected scaling of the chiral response with the small coefficient, enabling falsifiability.
* Establishes the mathematical substrate on which reversal-space tomography (ADR-0024) and probe–tensor correspondence (ADR-0025) are built.
* Explicitly warns against exporting δJ7 as a universal weak coordinate to other altermagnets (see cross-material benchmark, ADR-0026).

## Traceability & Artifact Links
* **[Source File]** `docs/adr/proposed/Paper2 The δJ7 Principle- Symmetry Complement Source Sectors in Altermagnetic MnF2 - JHaines 2026.pdf` — "The δJ7 Principle: Symmetry-Complement Source Sectors in Altermagnetic MnF₂" (John Haines, Sept 12, 2026).
* **[Related ADR]** ADR-0022 — polarization-odd channel whose chiral response this source sector drives.
* **[Related ADR]** ADR-0024 — signed field/partner-momentum readout that measures δJ7.
* **[Related ADR]** ADR-0026 — cross-material falsification benchmark that limits δJ7's generality.

* **[Delivered — spec]** `docs/specs/observ_calculus_v1.md` (+ `observ_calculus_v1.schema.json`) — the measurement-map program wire and gate semantics.
* **[Delivered — kernel]** `packages/rust/observ` — exact-rational observability kernel: null/witness filtrations, obstruction dimension with dual counterexamples, design gain, Walsh–Hadamard reversal coding, admissible-reference sector gate, six-component claim gate, receipts bound into the CRMF PWEH chain (no WORM); sample programs under `packages/rust/observ/programs/`, verified by 4 Kani harnesses and 50 unit/integration tests on `cargo test -p observ`.