# ADR-001: Lean 4 Formalization Mandate

## Status
Proposed

## Axis (Phase Mirror tension class)
urgency vs capacity

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (5) x blast radius (388) = **1940**
- Tractability = **2.0**
- **Score = 3880.0**

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - docs/README.md:12 — asserts [100% theorem formalization] “All core mathematical theorems are fully formalized in Lean 4 with zero admitted axioms.”
  - docs/Phase_Mirror_Loop_Goal.md:45 — asserts [sorry-free core] “The verified substrate contains no `sorry` placeholders, `axiom` declarations, or `native_decide` escapes in the mathematical core.”
  - docs/adr/ADR-004-UCC-blueprint-completion.md:16 — asserts [zero-sorry baseline] “Every definition is zero-sorry except the `closure` placeholder.”

### Implementation reality (lean/)

> **Note**: The stated-intent claims above are false given the project's 53 sorry declarations. The actual baseline is sorry-bounded.
  - 388 `sorry` placeholders present across 47 `.lean` files in `Prime/lean/`
  - 12 `axiom` declarations in `Prime/lean/Core/f1_square/Analysis/Real.lean`
  - 3 `native_decide` escapes in `Prime/lean/Core/f1_square/Arithmetic/`
  - `lake build` in `Prime/lean/` compiles successfully but emits 388 sorry warnings

### Manifested boundary
Leaked (unmanifested): YES — gap is NOT manifested in `alp_sorry_manifest.json` (silent leak risk)

## Decision (the lever)
Resolve the dissonance by mandating that all core mathematical theorems in
`Prime/lean/` must be formalized in pure Lean 4 with zero `sorry` placeholders,
zero `axiom` declarations, and zero `native_decide` escapes. Every proof term
must be kernel-certifiable by the Lean 4 kernel without trusting external
tactics or compiled libraries. The mandate applies to all `.lean` files under
`Prime/lean/Core/`, `Prime/lean/F1/`, and `Prime/lean/ComplexKappa/`.

## Consequences
- **Positive**: proof terms become fully auditable and kernel-checkable; the
  mathematical core achieves the documented sorry-bounded guarantee; downstream
  sovereign-stack components can trust proof certificates without ad-hoc
  validation.
- **Negative / Constraints**: proof-engineering effort scales superlinearly with
  theorem depth; the 388-placeholder backlog blocks UCC sorry-bounded status
  (per ADR-004); need for custom constructive real-number library increases
  initial scaffolding time.
- **Verification Strategy**: CI gate enforces `lake build` with
  `--warning-as-error` on `sorry`, `axiom`, and `native_decide`; `scripts/
  phase_mirror_loop.py` must report zero sorrys in the ranked tension list;
  `alp_sorry_manifest.json` must be empty or contain only deprecated entries.

## Metrics (resolution is confirmed when)
- `grep -r "sorry" Prime/lean/` returns zero matches in `.lean` source files.
- `grep -r "axiom" Prime/lean/` returns zero matches in `.lean` source files.
- `grep -r "native_decide" Prime/lean/` returns zero matches in `.lean` source files.
- `lake build` in `Prime/lean/` exits with code 0 and emits no sorry/axiom/native_decide warnings.
- `scripts/phase_mirror_loop.py` reports zero sorrys in the `Prime/lean/` subsystem.
- All 388 current sorrys are either closed with full proofs or formally deprecated in `alp_sorry_manifest.json` with paired Rust/Kani witnesses.

## Actionable Levers
1. Inventory every `sorry`, `axiom`, and `native_decide` in `Prime/lean/` and register each in `alp_sorry_manifest.json` with file path, line number, and proof-effort estimate.
2. Prioritize sorry closure by blast radius: start with theorems in `Core/f1_square/` that other modules depend on, then cascade outward to `F1/` and `ComplexKappa/`.
3. Build a custom constructive real library in `Prime/lean/Core/f1_square/Analysis/ConstructiveReal.lean` to replace the 12 `axiom` declarations in `Real.lean`.
4. Replace all `native_decide` escapes with explicit `decide`-based proofs bounded by `NormNum` or custom reflection tactics.
5. Add a CI check (`scripts/check_sorry_boundary.sh`) that fails the build if any new `sorry`/`axiom`/`native_decide` is introduced without a manifest entry.

## Links
- Sorry boundary: `alp_sorry_manifest.json`
- Zero-sorry goal: `Phase_Mirror_Loop_Goal.md`
- CI gate: `scripts/check_sorry_boundary.sh`
- Dissonance loop: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
