# ADR 038: Per-Triad Resonance Floors as Circle Audit v2

## Status
Proposed

## Context
The governed care-circle modules are formally verified
(`docs/AUDIT.md`, 2026-08-22T10:42:46Z):
`Care.lean` (patient-nurse bonds) and `ADR/Theorems/CareViability.lean`
(three-threshold viability audit) build clean with only `propext` and
`Quot.sound` in the axiom audit. The binary governance check is currently
aggregate:

```
phase_mirror_audit c := decide (rMeanPass c) && decide (viableE c)
rMeanPass c := 3 * ResFloor <= rSum c          -- mean resonance >= 0.85
viableE c := 0 < eSum c                        -- aggregate capacity > 0
```

This aggregate form contains a weakness that is not folklore but a
machine-checked theorem in the same module:

```
averaging_blind_spot :
  ∃ a b c : Nat, b < ResFloor ∧ 3 * ResFloor ≤ a + b + c ∧ …
```

A circle whose mean resonance passes can carry one triad below the
per-triad floor (witness profile 1024 / 869 / 1024). The Rust execution
port (`materia_commons::care_viability`) mirrors the aggregate semantics,
so it inherits the same blind spot. Runtime hardening items (git-hosted CI,
FFI linkage) are recorded in `AUDIT.md` as environment-blocked and cannot
proceed on the authoring box; strengthening the specification itself is not
blocked.

## Options Considered
1. **Adopt per-triad floors as audit v2 (chosen).** Each triad must meet
   the floor individually; the aggregate follows as a corollary.
   Directly discharges the proved gap; fully executable now.
2. **Keep v1, document the gap only.** Rejected: the gap is already a
   theorem; leaving governing behavior weaker than known-checkable policy
   contradicts the verification effort.
3. **Runtime-only mitigation in Rust.** Rejected: diverges execution from
   the proved model, recreating the drift this stack exists to prevent.
4. **Defer until FFI/CI unblock.** Rejected: ordering formal work behind
   blocked infrastructure inverts the dependency; v2 is prerequisite-free.

## Decision
Version the circle audit to require per-triad resonance floors, keeping
aggregate checks as derived properties. Work items, with target theorem
names fixed now so completion is mechanically checkable:

1. **Lean (`ADR/Theorems/CareViability.lean`):**
   - `rEachPass (c : CircleVital) : Prop :=`
     `ResFloor ≤ c.t0.r.val ∧ ResFloor ≤ c.t1.r.val ∧ ResFloor ≤ c.t2.r.val`
   - `each_implies_mean : rEachPass c → rMeanPass c`
   - `mean_does_not_imply_each : ∃ c, rMeanPass c ∧ ¬ rEachPass c`
     (kernel witness: R = 1024/869/1024, all E positive)
   - `phase_mirror_audit_v2 c := decide (rEachPass c) && decide (viableE c)`
   - `viable_circle_prevents_burnout_v2 : phase_mirror_audit_v2 c = true →
     viableE c ∧ rEachPass c`
   - `audit_v2_sound_wrt_v1 : phase_mirror_audit_v2 c = true →
     phase_mirror_audit c = true` (strict strengthening)
   - Kernel instance `mixedCircle` (R = 1024/869/1024, E = 700/640/760):
     passes v1, fails v2.
   - v1 definitions remain exported for provenance; v1-only reliance is
     deprecated for governance decisions.

2. **Rust (`materia_commons::care_viability`):** replace
   `CircleVital::r_mean_pass` body with per-triad comparison
   (`t0.r >= RES_FLOOR && t1.r >= RES_FLOOR && t2.r >= RES_FLOOR`);
   update the four unit tests to v2 expectations and add the `mixedCircle`
   parity test (v1 pass / v2 fail). Test execution remains deferred per
   `AUDIT.md` blocked item 1.

3. **Docs:** `whitepaper/arXiv_draft.md` §3.1 gains the v2 resolution;
   `docs/AUDIT.md` gains the new theorem list and refreshed transcripts.

## Consequences
- The averaging blind spot moves from "proved possible" to "prevented by
  construction": any v2-passing circle satisfies every triad floor.
- Strictness is provable both ways (`each_implies_mean`,
  `mean_does_not_imply_each`), so v2 ⊃ v1 with witnesses, not assertion.
- Execution parity becomes a concrete diff (one predicate, five tests),
   reviewable without toolchain access even while unrunnable locally.
- Aggregate-only consumers must migrate; v1 stays compiled for history but
  loses governance authority once this ADR is Accepted.
- Unchanged scope: Hundian cap arithmetic, Option B bond calculus, and
  environment-blocked runtime items are untouched by this decision.

## Verification (acceptance is command-backed)
```
lake build                                   # green, incl. all six new theorems
lake env lean /tmp/axaudit.lean              # extended: v2 names, no sorryAx
grep -n 'r_mean_pass' materia_commons/src/care_viability.rs   # per-triad body
grep -c '#\[test\]' materia_commons/src/care_viability.rs     # 5 tests present
```

On Acceptance, `docs/AUDIT.md` is regenerated with fresh transcripts and
this file's Status flips to Accepted.
