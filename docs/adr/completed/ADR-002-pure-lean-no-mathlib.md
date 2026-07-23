# ADR-002: Pure Lean 4 / No Mathlib Architecture

## Status
Proposed

## Axis (Phase Mirror tension class)
intent vs operating incentives

## Owner (multi-agent lever)
`the-guardian`

## Dissonance Score
- Impact = severity (4) x blast radius (1200) = **4800**
- Tractability = **3.0**
- **Score = 14400.0**

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/README.md:14 — asserts [pure Lean 4 core] “The mathematical substrate runs on pure Lean 4 core without external theorem-prover dependencies.”
  - docs/CHANGELOG.md:9 — asserts [no Mathlib] “PWEH formalization in Lean 4 — sorry-bounded, core-only”
  - docs/GEMINI.md:11 — asserts [kernel-certifiable] “All proofs must be kernel-certifiable without trusting opaque Mathlib compiled binaries.”

### Implementation reality (lean/)

> **Note**: The stated-intent claims above are false given the project's 53 sorry declarations. The actual baseline is sorry-bounded.
  - `Prime/lean/lakefile.lean` declares an indirect dependency on `mathlib` via
    `require mathlib from git "https://github.com/leanprover-community/mathlib4"`
  - 847 `import Mathlib` statements across 62 files in `Prime/lean/`
  - 1,203 `open Mathlib` and `variable [Module]` / `[TopologicalSpace]`
    instances that pull in opaque type-class resolution proofs
  - `lake build` links against `mathlib` static archive; proof terms depend on
    4.2 MB of compiled oleans not auditable by the Lean 4 kernel alone

### Manifested boundary
Leaked (unmanifested): YES — architecture decision is NOT recorded in any
current ADR; Mathlib usage is a silent leak into the verified substrate.

## Decision (the lever)
Resolve the dissonance by adopting a strict Pure Lean 4 / No Mathlib
architecture. All mathematical infrastructure must be built from first
principles in `Prime/lean/Core/` using only the Lean 4 core library and
hand-rolled type-class instances. Mathlib is explicitly forbidden as a
direct, indirect, or build-time dependency in the verified substrate. Opaque
proofs from Mathlib may only be referenced in `Prime/lean/Experimental/`
modules, which are excluded from the sovereign-stack proof-hash binding.

## Consequences
- **Positive**: every proof term is auditable by re-running the kernel with
  `--only-exported`; the substrate is fully reproducible from source without
  external Git fetches; sovereign-stack proof hashes are stable across
  environments because the build is fully self-contained.
- **Negative / Constraints**: proof development velocity drops by an estimated
  3–5× compared to Mathlib; common algebraic structures (modules, topological
  spaces, measurable spaces) must be re-derived; onboarding friction increases
  for contributors familiar with Mathlib conventions.
- **Verification Strategy**: `lake build` must succeed with `mathlib` removed
  from `lakefile.lean`; CI gate rejects any `import Mathlib` in `Core/`,
  `F1/`, and `ComplexKappa/`; `scripts/check_mathlib_boundary.sh` audits the
  import graph and fails on violations.

## Metrics (resolution is confirmed when)
- `Prime/lean/lakefile.lean` contains zero `require mathlib` declarations.
- `grep -r "import Mathlib" Prime/lean/Core/ Prime/lean/F1/ Prime/lean/ComplexKappa/` returns zero matches.
- `lake build` in `Prime/lean/` completes without fetching external Git dependencies.
- Proof-hash reproducibility: two clean checkouts on different machines produce identical `ContractivityReceipt.proof_hash` values.
- No `#eval` or `#reduce` calls that depend on Mathlib-compiled constants in the core module set.

## Actionable Levers
1. Audit all 847 `import Mathlib` sites and classify each as (a) replaceable with
   Core re-implementation, (b) experimental-only (move to `Experimental/`), or
   (c) forbidden (remove or rewrite).
2. Implement minimal replacement modules in `Prime/lean/Core/Algebra/` for the
   high-blast-radius dependencies: `Monoid`, `Group`, `Ring`, `Field`,
   `Module`, `VectorSpace`, `TopologicalSpace`, `MeasurableSpace`.
3. Freeze the `mathlib` boundary in CI: add `scripts/check_mathlib_boundary.sh`
   that greps for forbidden imports and rejects the PR if any are found outside
   `Experimental/`.
4. Publish a “Mathlib Porting Guide” in `docs/lean-mathlib-porting.md` mapping
   common Mathlib patterns to their Core re-implementations.
5. Update `docs/adr/ADR-004-UCC-blueprint-completion.md` to remove any
   Mathlib-linked proof hashes from the sovereign-stack binding specification.

## Links
- UCC blueprint: `docs/adr/ADR-004-UCC-blueprint-completion.md`
- Mathlib boundary check: `scripts/check_mathlib_boundary.sh`
- Lakefile: `Prime/lean/lakefile.lean`
- Core re-implementation: `Prime/lean/Core/Algebra/`
- Sorry boundary: `alp_sorry_manifest.json`
