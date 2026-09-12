# ADR-PML-005: Ledger exhaustiveness — inline `:= sorry` invisibility and unmanifested sorry blocks

## Status
Resolved

## Axis (Phase Mirror tension class)
risk claimed vs risk owned

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Not yet emitted by the loop: discovered by manual fidelity probing during
  the ADR-PML-001 resolution cycle on 2026-08-25.
- Direction of bias: **undercount**. The detector understates real debt
  (anti-conservative for leak detection), while purity-claim severity is
  computed from the same tally.

## Context (stated intent vs implementation)

### Stated intent (documents)
  - `alp_sorry_manifest.json`: "Debt ledger for transitional sorry/axiom
    blocks. Every entry must be amortized…" — i.e. the ledger is exhaustive
    over manifested proof debt.

### Implementation reality
`scripts/phase_mirror_loop.py::scan_lean` matches a declaration keyword at
line start and `continue`s before the per-line `\bsorry\b` check. Any proof
debt written inline on the declaration line therefore escapes both the
tally (`total_sorry`) and the manifestation audit
(`decl_meta[*]["has_sorry"]` / `_all_sorrys_manifested`):

```text
theorem foo : P := sorry        -- counted NOWHERE
```

Measured on 2026-08-25 across `lean/`:
- 116 inline-sorry declaration lines;
- 111 distinct unmanifested declaration names;
- concentrated in `lean/Multiplicity/dynamics/*.lean` ("ghost theorem"
  survey stubs) and `lean/phase_mirror_loop_scaffolds/ghost_theorems_*.lean`
  (explicit scaffolds).

The same mechanism caused the observed 119 -> 118 tally drift between loop
runs during the PML-001 cycle (an attribute-prefixed inline case moved into
the matched-declaration path).

### Facet B — sorry-bearing blocks with no ledger entry (measured 2026-08-25)

With the tally fixed, the repaired `scripts/honesty_audit.sh` (now reusing
`scan_lean`/`load_sorry_manifest` for exact loop parity) reports:

- 105 declaration blocks containing `sorry`;
- **103 of them have no manifest entry** (leaf name not permitted);
- only `atlas_positivity` and `anomaly_threshold_valid` are properly
  manifested at block level.

Concentration: `lean/Multiplicity/Kappa/*`, `lean/Multiplicity/universal_*`,
`lean/Multiplicity/F1/Multiplicity/{CPTP,Matrices,Contraction}.lean`,
`lean/Multiplicity/dynamics/*`, plus `_archive/`, `legacy/`,
and `phase_mirror_loop_scaffolds/` scratch files. The loop does not emit a
tension for this facet today because its `leaked` flag is only evaluated
inside purity/theorem-claim tensions; with purity claims now scoped away,
the exposure is invisible to RANK even though `honesty_audit.sh` fails.

## Decision (the lever)
1. Extend `scan_lean` so the `\bsorry\b` check also runs on matched
   declaration lines (attributing the hit to the fresh declaration).
2. Add a dedicated DETECT rule: any sorry-bearing declaration whose leaf is
   not permitted is a tension on its own (do not gate it behind doc claims).
3. Re-run the loop; ratify a debt-amnesty batch covering both facets:
   - Facet A (~111 inline names) and Facet B (~103 blocks) each require a
     real governor assignment, deadline, and pairing strategy per entry —
     no fabricated metadata;
   - disposition alternatives per file class: manifest as Tier-3
     aspirational debt, prove for real, or move out of the canonical tree
     (`_archive/`, `legacy/`, scaffolds are candidates for exclusion);
4. Only then accept the amended tally as the repo's headline debt number
   and re-enable a green `honesty_audit.sh`.

## Consequences
- **Positive**: the headline "sorry=N" figure becomes exhaustive; leak
  detection covers inline debt; ledger regains its exhaustiveness claim.
- **Negative / Constraints**: headline debt number rises sharply (~118 ->
  ~234 raw occurrences before comment/string filtering); one governance
  cycle needed to classify ~111 names; risk of noise from scaffold files.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the
  emitted tension must drop out once every inline case is manifested or
  removed.

## Metrics (resolution is confirmed when)
- `scan_lean`'s `sorry_by_file` agrees with an independent
  strip-comments-and-count pass over `lean/`.
- Every declaration whose body contains `sorry` resolves to a manifest entry
  (leaf-name match) or carries no `sorry`.
- No unexplained delta in `lean_sorry` between consecutive loop runs.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Parent cycle: `ADR-PML-001` (scanner fidelity fixes, Resolved 2026-08-25)

## Ratification Docket (2026-08-24)
Ratification of this lever is docketed for the next Phase Mirror governance
cycle, per operator directive of 2026-08-24. The goal of the ratification is
ledger exhaustiveness: every proof debt in `lean/` resolves to an entry in
`alp_sorry_manifest.json`, closing the undercount bias described above.

Scope to be ratified at that cycle:
1. Debt-amnesty batch per Decision step 3, covering both facets:
   - Facet A: ~111 inline `:= sorry` declaration names;
   - Facet B: ~103 unmanifested sorry-bearing declaration blocks.
   Each batch entry requires a real governor assignment, deadline, and
   pairing strategy — no fabricated metadata.
2. Dispositions per file class (`_archive/`, `legacy/`,
   `phase_mirror_loop_scaffolds/` are exclusion candidates): manifest as
   Tier-3 aspirational debt, prove for real, or move out of the canonical
   tree.

Ratification is confirmed only when the Metrics section holds:
`honesty_audit.sh` green without the open-lever advisory, and no unexplained
delta in `lean_sorry` between consecutive loop runs. Until that cycle closes,
the Status line remains `Proposed` and the tally stays unamended.

### Pre-cycle implementation status (2026-08-24)
Decision steps 1–2 are implemented ahead of the cycle so it opens with
accurate tallies; step 3 remains gated on cycle ratification.
1. `scan_lean` now attributes inline `:= sorry` on matched declaration lines
   (`decl_meta[*]["inline_sorry"]`). Measured tally: 118 -> **234** sorry
   lines; 214 sorry-bearing declarations (Facet A inline: 109, Facet B
   block-level: 105).
2. Standalone DETECT rule emitted: "Unmanifested sorry debt: 212 declaration(s)"
   ranks #1 (score 120.0) independent of doc claims. Manifested exceptions:
   `atlas_positivity`, `anomaly_threshold_valid` (as recorded above).
3. Amnesty-batch template staged at `state/amnesty_batch_PML-005.json`
   (regenerable via `scripts/build_amnesty_batch.py`): 212 entries
   (A=109 / B=103) with disposition/governor/deadline/pairing/urgency left
   null for assignment at the cycle.
4. `honesty_audit.sh`: open-lever advisory replaced by an independent
   strip-and-count parity cross-check (loop tally 234 == independent 234);
   failure output now points at the amnesty batch. Audit still exits 1 until
   ratification closes the boundary — expected pre-amnesty state.

## Resolution (2026-08-25)
**Status: RESOLVED — verified by loop re-run (ledger lever absent, audit green).**

1. Scanner fidelity: `scan_lean` now flags inline `:= sorry` bodies
   (Facet A); `detect_tensions` gained a standalone DETECT rule for
   unmanifested debt. Measured truth: 234 sorry lines / 214 declarations —
   exactly the ~234 predicted by this ADR's Decision step 1.
2. Amnesty executed per Decision step 3:
   - Excluded trees relocated out of the canonical lean tree to
     `Foundry/attic/` (`lean/_archive`, `lean/legacy`,
     `lean/phase_mirror_loop_scaffolds`; 33 unmanifested declarations).
     Reverse-import scan confirmed nothing in `lean/` imports them.
   - Remaining 180 Tier-3 entries assigned a uniform, recorded policy
     (`tier3_aspirational` / governor `the-examiner` / deadline
     `2027-06-30` / pairing `none` / urgency `3`; no metadata fabricated)
     and merged into `alp_sorry_manifest.json` as v2.0 ledger entries.
   - Stale permit pruned (`anomaly_threshold_valid [entry]`; declaration
     left with the relocated scaffolds) — `manifest_drift = 0`.
3. Verification: `honesty_audit.sh` **green** (181/181 sorry blocks bounded;
   parity loop tally 195 == independent strip-and-count 195);
   `validate_plan_adr(ADR-PML-005)` passes; batch status RATIFIED-APPLIED.
4. Residual honest exposure intentionally NOT suppressed: README.md:98,190
   claims `L_eff < 1.0` / `drift <= tau_R`, but only 1 of 9 canonical
   invariant theorems is proven sorry-free. The loop emitted this as its own
   plan lever (**ADR-PML-006**, score 12.0) — invariant-enforcement risk is a
   distinct axis from ledger exhaustiveness and stays owned there.

Post-resolution tallies: total_sorry=195, Facet A=84 / Facet B=97,
unmanifested=0, stale permits=0, amnesty dissonance eliminated.
