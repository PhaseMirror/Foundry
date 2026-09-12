# ADR-100: F1-Square Conditional Proof Scaffold

## Status
Accepted (v0.17.0 baseline)

## Context
The Multiplicity Sovereign Core requires a machine-checked bridge between the arithmetic surface `Spec ℤ ×_{𝔽₁} Spec ℤ` and the Riemann Hypothesis. The conditional theorem `F1Square_implies_RH` has been formalized in Lean 4 with zero `sorry` placeholders in the main implication, dependent on surface axioms (intersection form, ampleness, Hodge index, energy calibration). The surface itself remains unconstructed; RH is open.

This record formalizes the decision to treat the conditional scaffold as the **stable, auditable anchor** of the F1-Square production track — all subsequent surface probes, candidate tests, and Weil docking are validated against it.

## Decision
Adopt the **conditional proof scaffold** as the governing architecture for the F1-Square Prime track:

1. **Honesty boundary (bright line).** The fields `hodgeIndexHolds` and `liPositivityHolds` both stay `none` until a genuine, audited, axiom-clean proof (`{propext, Quot.sound}` only) exists. De-hedging removes false modesty about proven results; it never adds false confidence.
2. **Axiomatic surface specification.** `Surface.lean` declares the surface axioms (`F1Square`, `intersection_form`, `is_ample`, `hodge_index`, `pairing_relation`, `energy_calibration`). These are assumptions, not derived facts.
3. **Main implication is conditional.** `F1Square_implies_RH` is a theorem: if the axioms hold, then `∀ ρ, ρ.re = 1/2`. The proof is machine-checked; the axioms are the open content.
4. **Manuscript pipeline.** `docs/F1SQUARE_FORMALIZATION.md` (v1.0–v1.6+) documents the axiomatic basis, the conditional derivation, the T-ladder, and all disclaimers. Versioned releases map to ADR governance.
5. **Governance gate.** `scripts/honesty_audit.sh` and `scripts/audit_axioms.lean` enforce no-smuggling checks, axiom cleanliness, and disclaimer presence on every artifact.

## Consequences
- Every F1-Square artifact must carry the research-program disclaimer.
- Candidate surface constructions (Deitmar product, blueprint square) are tested against the scaffold, never presented as proof.
- Defensive publication (arXiv math.NT / cs.LO) describes the conditional theorem, never an unconditional RH proof.
- The scaffold is the **source of truth** for what is proven (implication), assumed (surface axioms), and open (positivity).

## References
- `Prime/F1Square Lean Formalization.md`
- `Prime/Prime Move_ Option 3 Confirmed.md`
- `docs/adr/ADR-001-Combined-Mandate.md`
- `docs/adr/ADR-013-F1-Square-Signature-Check.md`
