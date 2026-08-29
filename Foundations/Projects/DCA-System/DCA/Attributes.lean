import Lean

/-!
# DCA Attributes

Registers the project-wide attributes used by the DCA-System:

- `@[dca]`  — marks declarations that are formally registered Digital Control
  Act state definitions or transition specifications.
- `@[dca_proof]` — marks declarations that are formal proofs of DCA-System
  invariants or of the ADR-0030 operational safety properties.

Both are tag attributes with no elaboration-time behavior; they exist so that
tooling and humans can query the environment for all registered DCA artifacts
and proofs.

## Conventions

- One registration per attribute, at the top level of the module.
- Registration happens in its own module so that `@[dca]` / `@[dca_proof]`
  resolve in every importing file.
- Follows the exact pattern of `ADR.Attributes` in the ADR-System sub-project.
-/

/-- Tag attribute for formally registered DCA state definitions and transitions. -/
initialize dcaAttr : Lean.TagAttribute ← Lean.registerTagAttribute `dca "DCA registry tag" (fun _ => pure ())

/-- Tag attribute for formal proofs of DCA-System invariants. -/
initialize dcaProofAttr : Lean.TagAttribute ← Lean.registerTagAttribute `dca_proof "DCA invariant proof tag" (fun _ => pure ())
