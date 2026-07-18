# ADR-108: Defensive Publication & Manuscript Pipeline

## Status
Accepted (30-day horizon; v1.0–v1.6 shipped)

## Context
The conditional theorem `F1Square_implies_RH` is a crisp, machine-checked result that deserves defensive publication: establishing priority for the axiomatic framework, providing a clear invitation to the `𝔽₁`-geometry community, and maintaining an honest record of what has and has not been proved. The manuscript pipeline governs how, when, and under what conditions artifacts are externalized.

## Decision
Operate a **versioned defensive-publication pipeline** for all F1-Square Prime artifacts:

1. **Manifesto (v1.0 — Option 3 Confirmed).**
   - Title: *A Formal Conditional Proof of the Riemann Hypothesis from the Existence of a Hypothetical `𝔽₁`-Square with Hodge Index Theorem*.
   - Subtitle: *Research Program Description*.
   - Structure: Abstract → Introduction → Hypothetical Surface Axioms → Conditional Theorem → Connection to Other Faces → Discussion → Acknowledgements → References → Mandatory Disclaimers.
   - Submission: arXiv math.NT (primary), cs.LO (secondary). Category: "research program description," not solution of RH.
   - Mandatory disclaimer: *"This document describes a research program and a formal conditional theorem. The Riemann Hypothesis remains open. The existence of the `𝔽₁`-square with Hodge index is not proved here. No claim of an unconditional proof is made."*

2. **Versioned updates (v1.1–v1.6+).**
   - v1.1: Bright Line of Honesty integrated (Li face computational limits documented).
   - v1.2: Surface probe (tropical Deitmar approximation; T1 verified, T3–T5 open).
   - v1.3: Accelerated Euler–Mascheroni (`Rgamma_h`) anchored.
   - v1.4: Positive `λ₁` anchor + pinned constants (Positive margin ~0.003).
   - v1.5: Formidable constants (Rpi, Rlogπ, Rlog4pi bounds).
   - v1.6: Candidate Surface Testing Harness (Deitmar monoid product + T3 mechanical falsifier).

3. **GitHub release → Zenodo DOI.**
   - Tagged releases (`v1.0-conditional-proof`, `v1.4-pos-lambda1`, `v1.6-surface-probe`) trigger Zenodo DOI minting (Lever 3 defensive publication).
   - `CITATION.cff` updated with DOI as preferred citation.

4. **Defensive publication suite.**
   - `unified_contraction_suite_v0.1.pdf`: reconstruction code + error tables + KS results + RH-neutral claims + provenance anchors (WORM, Aubrey, CVK).
   - `recursive_proof_integration_report.md`: Pallas/Vesta pipeline details.
   - `SOVEREIGN_POSTURE_AUDIT.md`: end-to-end alignment across recursive bridge, TEE hardware binding, Λ-Trace deep provenance.

5. **Honesty audit as release gate.**
   - Every release artifact must carry the research-program disclaimer.
   - `scripts/honesty_audit.sh` + `scripts/audit_axioms.lean` must pass (no-smuggling check, axiom cleanliness).
   - `RH_STATUS_LEDGER.md` must reflect true status: all faces `none` (open) except verified sub-results (`Pos λ₁`, Weil identity verified, etc.).

## Consequences
- External review is invited on the conditional scaffold without risk of overclaim.
- The conditional theorem serves as a **stable anchor** for future surface-construction attempts.
- Priority is established: any subsequent construction of `Spec ℤ ×_{𝔽₁} Spec ℤ` with Hodge index must cite this pipeline.
- No unconditional RH claim may appear in any published artifact under this governance.

## References
- `Prime/Prime Move_ Option 3 Confirmed.md`
- `Prime/F1Square Lean Formalization.md`
- `Prime/F1-Square T3 Harness Milestone.md`
- `Prime/RH-Neutral Weil Explicit Formula Reconstruction.md`
- `docs/adr/ADR-100-Conditional-Proof-Scaffold.md`
- `docs/adr/ADR-102-Missing-Object-Formalization.md`
- `docs/adr/ADR-103-T3-Intersection-Harness.md`
- `docs/adr/ADR-104-Weil-Explicit-Formula-Docking.md`
