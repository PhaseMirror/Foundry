# ADR 043: Combined Sedona Spine and Phase Mirror Mandate for Multiplicity Lean Core

## Context
The Sedona Spine mandate enforces non-bypassable mathematical invariants (successor predicates, multiplicity conservation, exact Rational64 in $M(S)$) as first-class compilation errors on the multiplicity lean core. Conversely, the Phase Mirror methodology requires surfacing productive contradictions as levers with owners, metrics, and horizons rather than immediate rejection. 

The central tension is combining these requirements: we must preserve fail-closed L0 semantics (Sedona Spine) while routing near-miss tensions into governed lever generation (Phase Mirror) without softening gates.

## Decision
1. **Classification Matrix:**
   - **Immediate Violations (Sedona Spine):** Invalid stratum materializations, missing Rational64 exactness, or missing `ContractivityReceipt` linkage trigger immediate, hard compilation blocks.
   - **Lever-Eligible Tensions (Phase Mirror):** Productive dissonance, such as suboptimal $M(S)$ recursion depth within bounds, boundary case warnings, or proof structural tensions, generate diagnostic levers rather than outright failures, routed to respective owners (e.g., Lean Formalization Lead).

2. **Core Specification:** 
   - All core multiplicity operators in Lean 4 (successor predicates, multiplicity conservation, Multiplicity Functor) must carry dual formalization: Sedona Spine predicates plus Phase Mirror dissonance tags.

3. **Front-Matter & MLIR Bindings:**
   - `pirtm-parser` and `AdmissibilityValidator` apply this combined mandate at construction time.
   - Violations surface as ERROR; near-misses as lever-eligible diagnostics.
   - Binds to front-matter hardening requirements, ensuring zero paths emit or store invalid stratum without Rational64 exactness.

4. **CI/CD Integration (Dual-Gate):**
   - The CI workflow is extended: the hard Sedona Spine gate blocks builds on invariant violations, while the Phase Mirror MCP/agent integration extracts dissonance tags and emits structured levers with owners, metrics, and horizons.

## Status
Approved

## Consequences
- Requires dual instrumentation for all Lean core specs.
- Increases CI rigor but provides structural mechanisms for handling architectural tension without breaking builds for non-critical dissonance.
- Ensures all core changes produce a `ContractivityReceipt` linked to both invariant proofs and dissonance-resolution logs in the Archivum Ledger (Provenance completeness = 1.0).
