# ADR-003: Sorry Manifest and Governance

## Status
Proposed

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (4) x blast radius (388) = **1552**
- Tractability = **4.0**
- **Score = 6208.0**

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/Phase_Mirror_Loop_Goal.md:52 — asserts [manifest completeness] “Every
    `sorry` in the verified substrate is paired with a Rust/Kani witness and a
    governance test until the Lean proof lands.”
  - docs/adr/ADR-054-Rust-Kani-Stub-Governance.md:18 — asserts [dual-track
    verification] “Each manifested `sorry` must have a corresponding Rust stub
    exercised by Kani model checking.”
  - alp_sorry_manifest.json — asserts [canonical sorry registry] “This file is
    the single source of truth for all admitted proof obligations.”

### Implementation reality (lean/)
  - 388 `sorry` placeholders present across 47 `.lean` files in `Prime/lean/`
  - `alp_sorry_manifest.json` exists but contains only 13 entries (stale permits
    from ADR-PML-003)
  - Zero `sorry` entries have paired Rust/Kani witnesses in `crates/`
  - Zero governance tests exist that validate sorry-to-witness correspondence
  - CI does not gate new `sorry` introductions against the manifest

### Manifested boundary
Leaked (unmanifested): YES — 375 of 388 sorrys are NOT manifested in
`alp_sorry_manifest.json` (silent leak risk)

## Decision (the lever)
Resolve the dissonance by mandating a strict Sorry Manifest and Governance
protocol. Every `sorry` placeholder in `Prime/lean/` must be registered in
`alp_sorry_manifest.json` with a unique ID, file path, line number, theorem
signature, proof-effort estimate, and a paired Rust/Kani witness path. No
`sorry` may be introduced without a manifest entry and a corresponding
governance test stub. The manifest is the single source of truth; stale
entries are pruned weekly by `scripts/reconcile_sorry_manifest.py`.

## Consequences
- **Positive**: the verified substrate achieves auditable proof-obligation
  tracking; governance tests catch orphaned sorrys before they leak into
  production; the dual-verification track (Lean proof + Rust witness) provides
  defense-in-depth for critical theorems.
- **Negative / Constraints**: manifest maintenance adds a recurring tax on every
  PR that touches `.lean` files; 388 initial entries must be back-filled;
  Rust/Kani witness development requires expertise in both Lean and verified
  Rust; stale-manifest pruning is a weekly operational cost.
- **Verification Strategy**: `scripts/reconcile_sorry_manifest.py` must report
  zero orphaned sorrys and zero stale manifest entries on every CI run; the
  manifest must contain exactly 388 entries (or fewer as proofs land); each
  entry must have a non-empty `rust_witness_path` and `governance_test_path`.

## Metrics (resolution is confirmed when)
- `alp_sorry_manifest.json` contains exactly one entry for every `sorry` in
  `Prime/lean/` and zero stale permits.
- Every manifest entry has non-null `rust_witness_path` and
  `governance_test_path` fields pointing to existing files.
- `crates/` contains a Kani test for each sorry in `Core/f1_square/` and
  `F1/UCC/`.
- `scripts/reconcile_sorry_manifest.py --check` exits with code 0.
- CI fails if any PR introduces a `sorry` without a corresponding manifest entry
  added in the same commit.

## Actionable Levers
1. Run `scripts/scaffold_sorry_manifest.py --full` to generate the initial 388
   entries from the current sorry inventory and write them to
   `alp_sorry_manifest.json`.
2. For each sorry, generate a paired Rust stub in `crates/verification-witnesses/`
   and a Kani proof harness in `crates/verification-witnesses/kani/`.
3. Add `scripts/reconcile_sorry_manifest.py` as a pre-merge CI check that
   cross-references `grep -r "sorry"` output against manifest JSON keys and
   fails on mismatch.
4. Create a governance ticket template that requires every new sorry PR to
   include: (a) manifest entry, (b) Rust witness stub, (c) Kani test, and
   (d) proof-effort estimate.
5. Enforce weekly manifest reconciliation: the guardian agent runs
   `scripts/reconcile_sorry_manifest.py --prune` and closes entries whose Lean
   proofs have landed.

## Links
- Sorry boundary: `alp_sorry_manifest.json`
- Rust/Kani governance: `docs/adr/ADR-054-Rust-Kani-Stub-Governance.md`
- Reconciliation script: `scripts/reconcile_sorry_manifest.py`
- Scaffold script: `scripts/scaffold_sorry_manifest.py`
- Dissonance loop: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
