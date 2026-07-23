# ADR-PML-071: Sorry Manifest as Moral-Hazard Control — manifested sorrys are policy violations, not pass conditions

## Status
Accepted
Proposed

## Axis
urgency vs capacity

## Owner
`the-guardian`

## Dissonance Score
- Impact = severity (4) x blast radius (1) = **4**
- Tractability = **3.0**
- **Score = 12.0**

## Context
The project has a stated "zero sorry" purity policy enforced by both documents
and CI:

- `Prime/lean/formal/ADR.md:45` — "Zero `sorry` statements"
- `docs/MSP_1.md:128` — "zero Mathlib and zero `sorry`"
- `Prime/scripts/phase_mirror_loop.py:86-88` — detects purity claims like
  "zero sorry" and "sorry-free"

Yet the operational mechanism (`alp_sorry_manifest.json`) lists 27 *permitted*
`sorry` blocks. The manifest is consumed by CI as follows:

1. `load_sorry_manifest()` in `phase_mirror_loop.py:335` returns a **positive
   allow-list**.
2. `_all_sorrys_manifested()` checks that every current `sorry` is in the
   allow-list.
3. A `sorry` is therefore *passing* if it is in the manifest.

This creates a moral hazard: authors can add entries to the manifest to make
new `sorry`s "ok" rather than discharging them. The manifest operates as a
policy exception registry that acts like a permit-to-violate system.

### Manifested boundary
Leaked (unmanifested): YES — 27 permitted `sorry` blocks exist, but the
purity-policy claims in documents assert zero.

## Decision
Reformalize the sorry manifest as a **debt ledger** rather than a permit
system. Each entry must have:

1. A `deadline` (calendar date by which the `sorry` must be discharged).
2. A `governor` (the `ADR.PML.NNN` or `the-examiner` agent responsible).
3. A `pairing` (the Rust/Kani witness or alternate proof strategy).
4. An `urgency` score (severity x tractability, same as the dissonance loop).

CI should fail if any manifest entry is past its `deadline` without an
explicit `deadline_extended` field and a corresponding plan ADR.

## Consequences
- **Positive**: `sorry` debt is tracked like financial debt; aging-sorry
  detection becomes automated.
- **Negative / Constraints**: every permitted `sorry` must now be amortized
  with a deadline; the initial manifest migration requires effort.
- **Verification Strategy**: `lake test` runs a Python subprocess that checks
  manifest debt age and fails on overdue entries.

## Metrics (resolution is confirmed when)
- `alp_sorry_manifest.json` schema includes `deadline`, `governor`,
  `pairing`, `urgency` for every entry.
- `scripts/phase_mirror_loop.py` fails CI if any entry is overdue.
- Purity-policy documents in `docs/` no longer claim "zero sorry" without the
  qualifying scope "except as listed in `alp_sorry_manifest.json` with
  non-overdue deadlines."

## Actionable Levers
1. Schema-migrate `alp_sorry_manifest.json` to the debt-ledger format.
2. Add `sorry_debt_age` check to `scripts/run_phase_mirror_loop.sh`.
3. Update `formal/ADR.md` to reflect the new sorry-policy grammar.
4. Re-run `phase_mirror_loop.py`; this axis score should trend to 0 as
   overdue debt is discharged or extended with plan ADRs.

## Links
- Purity claims: `Prime/lean/formal/ADR.md:45`
- Manifest loader: `Prime/scripts/phase_mirror_loop.py:335`
- Debt schema: `docs/adr/ADR-PML-067.md` (consequence entailment vacuum)
