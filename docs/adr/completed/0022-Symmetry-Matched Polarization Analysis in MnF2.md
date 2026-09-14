# ADR-0022: Symmetry-Matched Polarization Analysis in MnF₂

**Status:** Completed

## Context
Unpolarized inelastic neutron scattering (INS) on MnF₂ reported no resolvable altermagnetic magnon band splitting within experimental resolution, while polarized INS later accessed an antisymmetric dynamical channel and reported a domain-dependent chiral response. These are not contradictions but different measurement operations: an unresolved positive spectral weight and a projection onto an antisymmetric polarization channel are different maps on the same spin-wave model. A "null" in one channel must not be treated as evidence of physical absence in another. The paper formalizes how to separate spectral resolution from chiral sensitivity in altermagnetic neutron scattering.

## Decision
Adopt symmetry-matched polarization analysis as the canonical interpretive discipline for altermagnetic neutron-scattering claims in MnF₂.

- **Blume–Maleev cross-section decomposition.** The transverse dynamical magnetic correlation tensor is decomposed into polarization-even and polarization-odd parts; reversing the incident neutron polarization isolates the antisymmetric (chiral) correlator.
- **Four-null taxonomy.** A null result is classified as one of: a *physical null* (response genuinely absent), a *resolution null* (response below transfer/resolution power), a *polarization-projection null* (probe is insensitive to the relevant component), or an *antiferromagnetic-domain cancellation* (opposite domains cancel in the measured average). These categories are deliberately contextual, not exhaustive.
- **Resolvability criterion.** A claim is resolvable only when source physics, probe projection, resolution transfer, and domain state are each identified; a falsifiable prediction must state which channel each null belongs to.
- **Domain-sensitive readout.** Chiral response is measured relative to a declared anti-ferromagnetic domain state; opposite-sign responses under domain control are part of the witness, not noise to be averaged away.

## Consequences
* Unpolarized null results no longer overrule polarized signatures: they are located in the taxonomy rather than treated as physical absence.
* Spectral resolution and chiral sensitivity are kept as separate design axes when planning and auditing neutron experiments.
* Every null claim now carries an explicit stage of loss, making cross-paper comparisons falsifiable rather than rhetorical.
* Supports the follow-on work items (source-sector δJ7 readout, reversal-space tomography, probe–tensor correspondence) that build on this channel separation.

## Traceability & Artifact Links
* **[Source File]** `docs/adr/proposed/Paper1 Symmetry Matched Polarization Analysis in MnF2- Separating Spectral Resolutionfrom Chiral Sensitivity in Altermagnetic Neutron Scattering - JHaines 2026.pdf` — "Symmetry-Matched Polarization Analysis in MnF₂: Separating Spectral Resolution from Chiral Sensitivity in Altermagnetic Neutron Scattering" (John Haines, Sept 12, 2026).
* **[Related ADR]** ADR-0023 — the δJ7 principle formalizes the source-sector basis for the antisymmetric channel this ADR isolates.
* **[Related ADR]** ADR-0024 — reversal-space tomography operationalizes the domain-signed readout introduced here.
* **[Related ADR]** ADR-0027 — null taxonomy generalized to a compositional measurement-map taxonomy (null–witness duality).

* **[Delivered — spec]** `docs/specs/observ_calculus_v1.md` (+ `observ_calculus_v1.schema.json`) — the measurement-map program wire and gate semantics.
* **[Delivered — kernel]** `packages/rust/observ` — exact-rational observability kernel: null/witness filtrations, obstruction dimension with dual counterexamples, design gain, Walsh–Hadamard reversal coding, admissible-reference sector gate, six-component claim gate, receipts bound into the CRMF PWEH chain (no WORM); sample programs under `packages/rust/observ/programs/`, verified by 4 Kani harnesses and 50 unit/integration tests on `cargo test -p observ`.