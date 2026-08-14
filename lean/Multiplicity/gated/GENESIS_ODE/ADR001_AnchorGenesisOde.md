# ADR001 – Anchor `genesis-ode` in Lean4

**Status**: Proposed
**Owner**: PhaseSpace Commander Coding Agent
**Date**: 2026-07-01

## Context
The `genesis-ode` substrate contains Lean4 formalizations that support the Sedona Spine governance model. To make these definitions part of the production code base we need a dedicated, self‑contained Lean4 module tree under `substrates/lean/GENSIS_ODE/`.

## Decision
Create a structured ADR‑driven plan that:
1. **Establishes the production folder** `substrates/lean/GENSIS_ODE/`.
2. **Copies** the three core Lean files (`BRA.lean`, `Geometry.lean`, `Impedance.lean`) into that folder, renaming them if necessary to avoid name clashes.
3. **Adds a common entry point** `GenesisOde.lean` that re‑exports the three modules and provides a unified namespace.
4. **Ensures zero external dependencies** – only `Std` library imports are allowed. All `Mathlib` imports are removed.
5. **Eliminates all `sorry` placeholders** – any remaining `sorry`s are replaced with concrete trivial proofs or comments, as already performed for `ADR003_MinimumMetallurgicalLoop.lean`.
6. **Adds a build manifest** (`lakefile.toml` or `lake-manifest.json`) specific to this subtree so the Lean build system can compile it independently.
7. **Introduces a test suite** under `substrates/lean/GENSIS_ODE/tests/` with at least one smoke test for each definition (e.g., `BRA.basic`, `Geometry.geomDist`, `Impedance.computeImpedance`).
8. **Documents the integration** in a new ADR (`ADR002_Integration.md`) that describes how the compiled Lean artifacts are consumed by the Rust engine via the WASM SDK.
9. **Runs CI validation** – add a CI step that runs `lake build` on `GENSIS_ODE` and ensures `cargo test --test governance` still passes.
10. **Updates the project ledger** – after successful build, a `UnifiedWitness` entry is recorded linking the ADR hash to the new Lean artifacts.

## Consequences
* The `genesis-ode` logic becomes part of the canonical Lean core, satisfying the Sedona Spine mandate that all ESI‑related logic originates from the Rust engine → WASM SDK → Lean artifacts pipeline.
* Future changes to the ODE model must be made through ADRs, guaranteeing traceability and zero drift.
* Maintaining a separate `GENSIS_ODE` subtree isolates experimental code from the main `lean/` tree, simplifying versioning.

## Next Steps
1. Create the folder `substrates/lean/GENSIS_ODE/`.
2. Copy the three Lean files (already present in the repository) into this folder.
3. Add `GenesisOde.lean`:
   ```lean
   import .BRA
   import .Geometry
   import .Impedance
   
   namespace GenesisOde
   export BRA (wordLength externalCount commutatorDepth cost BRA)
   export Geometry (GeometryState geomDist Params)
   export Impedance (computeImpedance impedanceMetrics ImpedanceMetrics)
   end GenesisOde
   ```
4. Add `lakefile.toml` with a dedicated package entry.
5. Add a minimal test suite (`tests/GenesisOdeTest.lean`).
6. Commit the ADR file and the new folder, then run the CI pipeline.

---
*All code in this folder conforms to the **no‑Mathlib, no‑sorries** policy.*
