# AUDIT.md — Canonical Verification Record

Single source of truth for artifact status. Every claim below is backed by
command output captured at the timestamp shown. Status documents must cite
this file instead of re-asserting state from memory.

- **Last audit run:** 2026-08-22T10:59:53Z (UTC)
- **Toolchain:** `leanprover/lean4:v4.33.0-rc1` (`lean-toolchain`)
- **Environment note:** box has no C linker (`cc`/`gcc`/`clang`/`ld` absent);
  see Blocked Items.

## Artifacts on disk

| Path | Lines | Purpose |
|---|---|---|
| `Care.lean` | 197 | Option B: patient-nurse bonds, exact fixed-point arithmetic |
| `ADR/Theorems/CareViability.lean` | 292 | Option A: thresholds v1+v2, governance theorems (ADR-038) |
| `.github/workflows/build.yml` | 72 | CI: build + sorry-scan + axiom audit |
| `packages/rust/materia_commons/src/care_viability.rs` | 211 | Integer port, audit v2 semantics (ADR-038) |
| `whitepaper/arXiv_draft.md` | 187 | Draft paper; scope-limited claims |
| `docs/adr/ADR-038-Circle-Audit-v2-PerTriad-Floors.md` | — | Proposed: per-triad resonance floors (audit v2) |

Module registration: `lakefile.lean` roots are
`#[PhaseMirror, Care, ADR.Theorems.CareViability]`. There are **no**
`lean_exe` targets in this project.

## Build status (fresh transcript)

```
$ lake build
Build completed successfully (33 jobs).
```

## Axiom audit (fresh transcript)

Mechanism: `#print axioms` commands inside a file executed with
`lake env lean`. The CLI flag `--print-axioms` does **not** exist:

```
$ lake env lean --print-axioms ADR/Theorems/CareViability.lean
lean: unrecognized option '--print-axioms'
```

Actual audit output — thirteen declarations, all clean of `sorryAx`:

```
'PhaseMirror.Care.multiplicity_bounded' depends on axioms: [propext, Quot.sound]
'PhaseMirror.Care.affinity_le_scale' depends on axioms: [propext]
'PhaseMirror.CareViability.rMeanPass_iff_avg' depends on axioms: [propext]
'PhaseMirror.CareViability.viableE_iff_some_pos' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.cap_of_sixths' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.viable_circle_prevents_burnout' depends on axioms: [propext]
'PhaseMirror.CareViability.averaging_blind_spot' does not depend on any axioms
'PhaseMirror.CareViability.circle_multiplicity_bounded' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.cap_violation_possible' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.each_implies_mean' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.mean_does_not_imply_each' does not depend on any axioms
'PhaseMirror.CareViability.viable_circle_prevents_burnout_v2' depends on axioms: [propext]
'PhaseMirror.CareViability.audit_v2_sound_wrt_v1' depends on axioms: [propext, Quot.sound]
```

Sorry-tactic scan over governed modules (`Care.lean`, `ADR/`),
anchored regex so docstring prose does not trigger:

```
SORRY-SCAN CLEAN
```

## Kernel-decided instances (inside `CareViability.lean`)

| Declaration | R (raw) | E (raw) | Audit |
|---|---|---|---|
| `healthyCircle` | 900/880/910 | 700/640/760 | pass |
| `strainedCircle` | 800/790/810 | 400/380/420 | fail (resonance) |
| `depletedCircle` | 900/880/910 | 0/0/0 | fail (viability) |

## Known-blocked items (with reasons)

1. **Rust unit tests never executed.** `cargo test -p materia_commons`
   fails with `error: linker 'cc' not found`; no linker exists on the box.
   The module type-checks as an rlib. Test execution deferred to CI or a
   toolchain-complete machine.
2. **Lean FFI bridge not built.** No Lean staticlib, no exported symbol;
   the extern seam in `care_viability.rs` is commented out by design.
3. **ADR-038 status:** Implemented and command-verified (this file,
   10:59:53Z). Document Status remains **Proposed** pending explicit human
   acceptance.
4. **Pre-existing upstream sorries** in `Prime/*` and
   `lean/Multiplicity/dynamics/*` are outside governed scope and excluded
   from scans.

## Reproduction commands

```bash
lake build
cat > /tmp/axaudit.lean <<'EOF'
import Care
import ADR.Theorems.CareViability
#print axioms PhaseMirror.Care.multiplicity_bounded
#print axioms PhaseMirror.Care.affinity_le_scale
#print axioms PhaseMirror.CareViability.rMeanPass_iff_avg
#print axioms PhaseMirror.CareViability.viableE_iff_some_pos
#print axioms PhaseMirror.CareViability.cap_of_sixths
#print axioms PhaseMirror.CareViability.viable_circle_prevents_burnout
#print axioms PhaseMirror.CareViability.averaging_blind_spot
#print axioms PhaseMirror.CareViability.circle_multiplicity_bounded
#print axioms PhaseMirror.CareViability.cap_violation_possible
#print axioms PhaseMirror.CareViability.each_implies_mean
#print axioms PhaseMirror.CareViability.mean_does_not_imply_each
#print axioms PhaseMirror.CareViability.viable_circle_prevents_burnout_v2
#print axioms PhaseMirror.CareViability.audit_v2_sound_wrt_v1
EOF
lake env lean /tmp/axaudit.lean
grep -rnE '^[[:space:]]*(sorry|first[[:space:]]+\|[[:space:]]*sorry)' Care.lean ADR/
```

Rule: a status claim without matching command output is unverified by
default. Update this file whenever artifacts change.
