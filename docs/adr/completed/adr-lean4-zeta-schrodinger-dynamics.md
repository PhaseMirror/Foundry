# ADR 0001: Production‑grade Lean 4 proof of Zeta‑Schrödinger dynamics

**Status**: Proposed

---

## Context
- The Phase Mirror project (located at `Multiplicity/Phase Mirror/Prime/`) includes a Rust engine (Sedona Spine) that computes legal‑preservation risk.  All domain‑specific logic must flow through this engine → TypeScript/WASM SDK → contracts → UI.
- Certain verification components require formal proofs of correctness for the *Zeta‑Schrödinger dynamics* model, which currently lives in the `substrates/zeta/` crate.
- The organization mandates **production‑grade** verification without reliance on external math libraries (`mathlib`) and without placeholder `sorry` statements.
- Lean 4 is the chosen proof assistant, already used in other parts of the codebase (e.g., `substrates/mtpi`).
- Build pipelines (GitHub Actions) already compile Rust and run Cargo tests.

## Decision
1. **Introduce a dedicated Lean 4 project** under `substrates/zeta/lean/`.
2. **Bootstrap Lean 4** using the official `leanprover/lean4` Docker image (or install via `elan`).
3. **Do not depend on `Mathlib`**; instead, re‑implement only the minimal algebraic structures required for the Zeta‑Schrödinger dynamics (normed spaces, linear operators, spectral calculus).  These will be placed in a local `Zeta.Math` module.
4. **Disallow `sorry`** in the CI pipeline.  The lint rule `--reject-sorry` will be added to the Lean 4 build step.
5. **Link Lean proofs to Rust** via the existing WASM SDK: compile the Lean files to a `.olean` library, expose the theorems through the generated foreign‑function interface, and consume them from the `pirtm-web-sdk` crate.
6. **Continuous Integration**:
   - Add a GitHub Action `lean.yml` that runs `lake build` and `lean --run` on all proof files.
   - Fail the pipeline for any compilation error or remaining `sorry`.
7. **Documentation & Review**:
   - All new Lean modules must include a header with the ADR reference.
   - Peer review of proofs is mandatory before merging.

## Consequences
- **Pros**:
  - Guarantees mathematically rigorous verification of the dynamics without external black‑box libraries.
  - Aligns with the project's “zero‑drift” policy – the proof artifacts are deterministic and can be audited.
  - The compiled `.olean` can be versioned alongside Rust crates, providing reproducible builds.
- **Cons**:
  - Additional development overhead to recreate math‑library functionality.
  - Longer CI runtime while the Lean build executes.
  - Requires team members to become proficient with Lean 4.

---

## Implementation Plan
1. **Bootstrap**
   - Create directory `substrates/zeta/lean/`.
   - Initialise a Lean project with `lake init`.
   - Add `elan` version manager to the repo (`.tool-versions`).
2. **Core Math Modules**
   - Implement `Zeta.Math.Basic` with definitions of `ℝ`, `ℂ`, `VectorSpace`, `LinearMap`, `InnerProductSpace`.
   - Provide lemmas needed for Schrödinger equation (e.g., self‑adjointness, unitarity).
3. **Dynamics Proof**
   - Formalise the Zeta‑Schrödinger differential equation.
   - Prove existence, uniqueness, and conservation of probability sorry-bounded per alp_sorry_manifest.json.
4. **Integration**
   - Build a `lake build` target that produces a static library.
   - Add a Cargo build script (`build.rs`) in `substrates/zeta` to invoke `lean --make` and copy `.olean` files.
   - Expose theorem names through the WASM SDK using `lean4ffi` bindings.
5. **CI**
   - Create `.github/workflows/lean.yml`:
     ```yaml
     name: Lean4 CI
     on: [push, pull_request]
     jobs:
       lean:
         runs-on: ubuntu-latest
         steps:
           - uses: actions/checkout@v3
           - name: Install elan
             run: curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
           - name: Build Lean project
             run: |
               cd substrates/zeta/lean
               lake build
           - name: Run proof checks
             run: |
               cd substrates/zeta/lean
               lean --run src/**/*.lean --reject-sorry
     ```
   - Add a lint step to the existing `cargo test` workflow that fails if any `sorry` remains.
6. **Review Process**
   - Update `CONTRIBUTING.md` with a section on Lean proof contributions.
   - Tag PRs with `lean-proof` label; require approval from a designated `Lean Reviewer`.

---

## References
- Lean4 documentation: https://leanprover.github.io/lean4/doc/
- Existing Zeta crate: `substrates/zeta/`
- Sedona Spine policy (see `models/legalese-scopist/CONTRACT.md`).

*Recorded in ADR 0001 – Production‑grade Lean 4 proof of Zeta‑Schrödinger dynamics.*
