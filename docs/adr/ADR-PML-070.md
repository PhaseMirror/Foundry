# ADR-PML-070: Status Re-entrancy Violation — Accepted ADRs reopened by Dissonance Loop

## Status
Proposed

## Axis
intent vs operating incentives

## Owner
`the-guardian`

## Dissonance Score
- Impact = severity (5) x blast radius (1) = **5**
- Tractability = **2.0**
- **Score = 10.0**

## Context
The formal ADR model in `AGENTS.md` defines `ADRStatus` as
`Proposed | Accepted | Deprecated | Superseded` and mandates:

> "Once `Accepted`, status is immutable without a superseding ADR"

However, the Phase Mirror Dissonance Loop flags accepted decisions as gaps and
requires action on them:

- `ADR-PML-064` documents that `FockTrunc` does not exist in `lean/`, yet
  `docs/adr/completed/ADR-077-PIRTM-Fock-Space-Constitutional-Contractivity.md`
  asserts it exists and is verified (the loop treats this Accepted ADR as
  effectively Proposed for resolution).
- The loop's decision in `ADR-PML-064:34` says: "Treat the unproven claim as
  `Proposed` until a Lean proof backs it."

This creates a governance hole: any accepted ADR can be silently downgraded to
`Proposed` by the loop without a superseding ADR, violating the immutability
theorem.

### Manifested boundary
Leaked (unmanifested): YES — the loop operates as an ungoverned tunnel that
can retroactively change accepted decisions without triggering the
`Superseded` transition.

## Decision
Strengthen the governance layer by requiring that the Phase Mirror Loop never
directly mutate an `Accepted` ADR's status. Instead, when the loop detects a
gap in an accepted decision, it must:

1. Emit a new `ADR.PML.NNN` plan ADR that references the accepted ADR.
2. Require the author of the accepted ADR to either:
   - Discharge the gap with a proof (no status change), OR
   - Issue a new ADR that explicitly `Supersedes` the accepted one.

This preserves the immutability invariant while allowing the loop to surface
gaps via new artifacts rather than mutating old ones.

## Consequences
- **Positive**: `Accepted` status remains machine-enforced as immutable.
- **Negative / Constraints**: resolving a gap requires more ceremony than a
  single plan ADR; accepted ADRs cannot be silently reopened.
- **Verification Strategy**: `ADR.Proofs` adds `no_reentrant_acceptance` which
  proves that `Accepted` implies no transition back to `Proposed` without
  `Superseded`.

## Metrics (resolution is confirmed when)
- `ADR.Proofs` defines `no_reentrant_acceptance` and the theorem compiles.
- `ADR.Governance` enforces that any `accepted_immutable` proof fails if
  `supersedes = none` and the new status is `Proposed`.
- The dissonance loop's `--reopen` behavior is formally disallowed.

## Actionable Levers
1. Add `Transition` inductive to `ADR.Core` with a proof that `Accepted`s only
   transition to `Deprecated` or `Superseded`.
2. Update `adal_loop.py` to emit "gap plan ADRs" rather than mutating status.
3. Add CI check: run `lake test` and fail if any plan ADR claims to reopen an
   accepted decision without a supersession.

## Links
- Formal model: `AGENTS.md:28` (immutability theorem)
- Triggering gap: `docs/adr/ADR-PML-064.md`
- Immutability proof sketch: `Prime/lean/adr-governance/ADR/FolderLoop/ADR0001.lean:84–90`
