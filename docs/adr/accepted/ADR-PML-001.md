# ADR-PML-001: alp_sorry_manifest.json permits sorrys that are absent from the current lean tree (stale boundary)

## Status
Resolved

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (3) x blast radius (13) = **30**
- Tractability = **5.0**
- **Score = 150.0**  (cluster rank 1 of 3)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - alp_sorry_manifest.json permits 13 sorry(s) not present in lean

### Implementation reality (lean/)
  - stale permitted sorrys: Add, Div, Mul, Neg, OfNat, Sub ...

### Manifested boundary
Leaked (unmanifested): no

## Decision (the lever)
Resolve the dissonance by manifesting the gap and closing it with a verified
artifact rather than letting the claimed guarantee stand unbacked. Treat the
unproven claim as `Proposed` until a Lean proof (or a manifested `sorry` + Rust
stub, per `alp_sorry_manifest.json`) backs it.

## Consequences
- **Positive**: claimed guarantees become auditable; silent leaks into policy
  decisions are eliminated; the UAC-ALP boundary stays honest on every CI run.
- **Negative / Constraints**: temporary downgrade of the marketing-grade claim
  until the proof lands; added CI surface for the manifested stub.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension
  must drop out of the ranked list (score -> 0) once the backing proof exists
  and the manifest is reconciled.

## Metrics (resolution is confirmed when)
- The cited theorem/invariant exists in `lean/` and compiles free of unmanifested `sorry`.
- OR the gap is explicitly listed in `alp_sorry_manifest.json` with a paired Rust stub + governance test.
- Dissonance score for this axis trends to 0 on subsequent loop runs.

## Actionable Levers
1. Update the purity ADR (e.g. ADR-Prime-Move-Deployment-Readiness.md) to segregate the verified UAC math cores from the transitional `ALP` agentic contracts.
2. Run `scripts/honesty_audit.sh`; enforce that every `sorry` is in the manifest and every manifest entry resolves to a real declaration (no stale permits).
3. Downgrade absolute '100% verified / zero sorry' wording to scoped, accurate claims until the proof budget is spent.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`

## Resolution (2026-08-25)
**Status: RESOLVED — verified by loop re-run (tension absent, score 0).**

1. Purged the 6 legacy typeclass permits (`OfNat`, `Div`, `Add`, `Sub`,
   `Mul`, `Neg`) from `permitted_sorrys` — no corresponding declarations
   exist anywhere under `lean/`.
2. Removed the stale `Core/MultiplicityCore.lean` ledger entry: the file is
   absent from the tree and its cited declarations
   (`Nat.prime_mul_left_inj`, `interaction_product_injective`) do not exist;
   the surviving `Multiplicity/MultiplicityCore.lean` carries no debt.
3. Added explicit `name` fields to the two Quarternion axiom entries and
   normalized every entry's file path to its real location; renamed the two
   Atlas entries to their actual declaration (`atlas_positivity`, lines
   196/199).
4. Scanner fidelity fixes in    `scripts/phase_mirror_loop.py::scan_lean`
   (required so manifest `"type": "axiom"` entries resolve):
   `axiom` declarations are now indexed (the manifest schema tracks them),
   and attribute decorators (`@[proof]` etc.) no longer hide declarations.

Result: manifest drift 13 -> 0; every permit resolves to a real declaration.
