# ADR-PML-069: Two-Track Verification Ghost — Rust/Kani track has no harnesses in workspace

## Status
Accepted
Proposed

## Axis
control desired vs available

## Owner
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (2) = **8**
- Tractability = **3.0**
- **Score = 24.0**

## Context
`Prime/lean/formal/ADR.md:48–70` defines an extensive Rust/Kani verification
track:

- `kani/harnesses/graph_properties.rs`
- `kani/harnesses/operator_correctness.rs`
- `kani/harnesses/convergence_proofs.rs`
- `src/graph.rs`, `src/operators.rs`, `src/convergence.rs`, `src/spectral.rs`

None of these directories or files exist in the workspace. The
`alp_sorry_manifest.json` references "paired Rust/Kani witnesses" (e.g.
`verify_non_parallelism_distinct_primes` in `resolution` fields), but the
workspace contains no `kani/` directories and no `crates/multiplicity/rust/`
structure.

### Manifested boundary
Leaked (unmanifested): YES — the Rust/Kani track is a written specification
with no executable implementation. Cross-track consistency between Lean and Rust
cannot be verified because the Rust side does not exist.

## Decision
Acknowledge the ghost track and either (a) implement the Rust/Kani harnesses
under `Prime/rust/kani/` with paired Lean-Rust proof obligations, or (b)
formally withdraw the Rust/Kani track from `formal/ADR.md` and replace it with
a Lean-only verification strategy.

Option (b) is the cheaper and more honest choice given current resource
constraints. The Rust verification strategy is then restructured as a future
`ADR.PML.NNN` lever rather than a current mandate.

## Consequences
- **Positive**: eliminates a phantom promise; Lean-only verification is still
  machine-checked.
- **Negative / Constraints**: loses the implementation-level guarantee that
  Rust code matches Lean specs.
- **Verification Strategy**: `formal/ADR.md` no longer lists Rust/Kani
  directories that do not exist; `phase_mirror_loop.py` no longer flags them
  as missing.

## Metrics (resolution is confirmed when)
- `formal/ADR.md` Rust/Kani sections are either implemented or removed.
- No `kani/`-related claims remain in documents without matching files.
- `phase_mirror_loop.py` score for "missing Rust/Kani harnesses" reaches 0.

## Actionable Levers
1. If implementing Rust/Kani: create `Prime/rust/` with the directory tree from
   `formal/ADR.md` and add a CMake or cargo integration to `lakefile.lean`.
2. If withdrawing: edit `formal/ADR.md` to replace sections 3.2 and 3.3 with
   a scoped Lean-only pipeline, and update all `ADRs` that claim Rust/Kani
   pairings.
3. Re-run `scripts/phase_mirror_loop.py`; confirm score reaches 0.

## Links
- Ghost track: `Prime/lean/formal/ADR.md:48–70`
- Stub references: `Prime/lean/alp_sorry_manifest.json:13`
- Loop evidence: `Phase_Mirror_Loop_Goal.md`
