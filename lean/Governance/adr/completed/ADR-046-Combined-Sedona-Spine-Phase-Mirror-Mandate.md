# ADR: Combined Sedona-Spine & Phase Mirror Mandate for Multiplicity Lean Core

## Status
Draft

## Context
The Sedona Spine mandate enforces non-bypassable mathematical invariants (e.g., successor predicates, multiplicity conservation, exact Rational64 for \(M(S)\)) as first-class compilation errors on the multiplicity lean core. Conversely, the Phase Mirror methodology requires surfacing productive contradictions as levers (with owners, metrics, and horizons) rather than just outright rejecting them. We must preserve fail-closed L0 semantics while routing near-miss tensions into governed lever generation without softening gates. 

## Decision
We establish a classification matrix to differentiate between outright rejections and productive dissonance:
1. **Immediate Rejection (Sedona Spine):** Mathematical invariant violations. Examples include failed bounds checking on discrete spaces, loss of `ExactRat` precision for Rational64 conversions, and mathematically invalid successor predicate constructions where the logic fails to conserve multiplicity.
2. **Productive Dissonance / Lever Eligible (Phase Mirror):** Boundary near-misses, and heuristic deviations that do not break the discrete bounds but surface architectural tensions. Examples include \(M(S)\) recursion depths approaching defined threshold limits but not exceeding them, or unexpected but non-fatal phase state adjustments.

We will bind this to the front-matter hardening ADR and mandate the following:
- Require Rational64 exactness and full provenance (ContractivityReceipt) for all core paths.
- Lean 4 core specifications must be instrumented with dual formalization: Sedona Spine predicates plus Phase Mirror dissonance tags.
- The CI pipeline will be extended into a dual-gate system. Hard Sedona Spine errors will block the build. Near-miss Phase Mirror tensions will trigger the agent to emit structured levers for resolving these tensions.
- Phase Mirror agent tools will be extended to ingest these specs and emit structured levers.

## Consequences
1. **Owner: Lean Formalization Lead** -> All core multiplicity operators carry dual formalization (Sedona Spine + Phase Mirror) in Lean 4 specs. (Horizon: 14 days)
2. **Owner: DevOps** -> CI dual-gate pass rate reaches 100% on multiplicity lean core changes. (Horizon: 7 days)
3. **Owner: Governance** -> Every core change produces a ContractivityReceipt linked to both invariant proof and dissonance-resolution log in Archivum Ledger. (Horizon: 30 days)

## Precision Response
In the multiplicity lean core, hard mathematical failures (such as inexact Rational64 conversions, absolute stratum boundary violations, and broken multiplicity conservation) trigger immediate Sedona Spine rejection. Conversely, threshold warnings (like \(M(S)\) recursion depth approaching limits without overflow) or sub-optimal heuristic proofs are classified as productive dissonance. This generates structured levers instead of immediate build failures. This classification matrix is formally documented within this ADR and enforced via the dual-gate CI pipeline and dual-tagging within the Lean 4 specifications.

## Test Execution Review & Directive (Update)
**Confirmation of test execution review:** The dual gate test execution for the successor predicate passed successfully. However, the state-dependent AdmissibilityValidator still leaves a brief materialization window open during parser/AST construction. 
**Explicit Directive:** We must close the materialization window on the successor via its failable constructor (`try_successor`) before permitting expansion to any other operator. L0 invariant strictness remains non-negotiable.

## L0 Sign-Off & Expansion Authorization
**Successor Closure Sign-Off:** The `try_successor` failable constructor has been implemented and strictly enforced in CI. The construction-time materialization window for the successor predicate is officially closed and L0 integrity is audited and verified.
**Stratum Boundary Sign-Off:** The `try_stratum_boundary` failable constructor has similarly been implemented and enforced. Both operators' pre-validator materialization windows are formally closed under dual checks.
**Expansion Directive:** The failable constructor pattern must now be extracted as an explicit template. No third operator work will begin until this template is formalized and approved.

## Lever Mechanics Schema & L0 Guard
**Schema Definition:** All Phase Mirror levers must be emitted as strictly validated JSON objects comprising the following fields:
- `tension`: Description of the productive dissonance or near-miss.
- `evidence`: Citation of the exact file and line where the dissonance was flagged.
- `owner`: The designated owner resolving the tension.
- `metric`: The measurable goal.
- `horizon`: Timeframe for resolution.
- `actions`: Array of actionable steps.
**L0 Guard:** Levers are non-executable coordination artifacts. While they provide provenance and auditability, **no lever may propose or authorize the bypass of Sedona Spine hard invariants.** Acceptance of a lever creates an audit trail (linked to ContractivityReceipt) but does not soften gates. This ensures velocity while rigorously preserving L0.
