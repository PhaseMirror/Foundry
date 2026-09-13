# ADR-PML-004: alp_sorry_manifest.json permits sorrys that are absent from the current lean tree (stale boundary)

## Status
Resolved

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (3) x blast radius (1) = **3**
- Tractability = **5.0**
- **Score = 15.0**  (cluster rank 1 of 1)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - alp_sorry_manifest.json permits 1 sorry(s) not present in lean

### Implementation reality (lean/)
  - stale permitted sorrys: atlas_positivity

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

Transient drift flagged while reconciling ADR-PML-001: the Atlas ledger
entries were renamed to their real declaration (`atlas_positivity`) but the
declaration itself was invisible to the scanner because it carries an
attribute decorator (`@[proof] theorem atlas_positivity`). Fixed in
`scripts/phase_mirror_loop.py::scan_lean` by allowing attribute decorators
(repo convention per AGENTS.md) before declaration keywords. Manifest and
tree are back in agreement: 0 stale permits.
