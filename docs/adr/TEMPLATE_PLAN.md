# Phase Mirror Loop ADR Plan Template

Used by `scripts/phase_mirror_loop.py` to emit per-tension plan ADRs
(`ADR-PML-###.md`). Every plan ADR is an **actionable lever**: it states the
dissonance, scores it, and lists concrete steps to close the gap between stated
intent (documents) and the mathematical Lean 4 implementation.

```markdown
# ADR-PML-NNN: <tension title>

## Status
Proposed

## Axis (Phase Mirror tension class)
<intent vs operating incentives | urgency vs capacity |
 risk claimed vs risk owned | control desired vs available>

## Owner (multi-agent lever)
`<the-guardian | the-examiner | the-publisher>`

## Dissonance Score
- Impact = severity x blast radius = <n>
- Tractability = <n>
- **Score = <n>**  (rank <k> of <m>)

## Context (stated intent vs implementation)
### Stated intent (documents)
  - <doc:line — claim>
### Implementation reality (lean/)
  - <file:line — evidence>
### Manifested boundary
Leaked (unmanifested): <YES | no>

## Decision (the lever)
<one-paragraph decision: manifest the gap + close it with a verified artifact>

## Consequences
- **Positive**: ...
- **Negative / Constraints**: ...
- **Verification Strategy**: re-run the loop; tension must exit the ranked list.

## Metrics (resolution is confirmed when)
- <the cited theorem/invariant exists in lean/ and compiles free of unmanifested sorry>
- <OR the gap is in alp_sorry_manifest.json with a paired Rust stub + governance test>
- <dissonance score for this axis trends to 0>

## Actionable Levers
1. <concrete step with file path + command>
2. <concrete step>
3. <re-run loop to confirm score decrease>

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
```

## Loop contract
1. ANALYZE documents + Lean 4 corpus; extract claims and implementation evidence.
2. DETECT gaps; classify each into one of the four tension axes.
3. RANK by impact x tractability (impact = severity x blast radius).
4. PLAN: emit per-tension ADRs + master index into `docs/adr/`.
5. RESOLVE: manifest gaps as Lean stubs (`--scaffold-proofs`) and close them;
   re-run to confirm the tension leaves the ranked list (score -> 0).
