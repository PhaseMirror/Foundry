import Lean

/-!
# ADR Attributes

Registers the project-wide attributes used by the ADR-System:

- `@[adr]`  — marks declarations that are formally registered Architecture
  Decision Records (the full metadata lives in `ADR.Examples`).
- `@[proof]` — marks declarations that are formal proofs of ADR-System
  invariants or of the ADR-009 mathematical specification.

Both are tag attributes with no elaboration-time behavior; they exist so that
tooling and humans can query the environment for all registered ADRs and
proofs (`#eval adrAttr.ext ...` / the `Lean.EnvExtension`).

## Conventions

- One registration per attribute, at the top level of the module.
- Registration happens in its own module so that `@[adr]` / `@[proof]`
  resolve in every importing file.
-/

/-- Tag attribute for formally registered Architecture Decision Records. -/
initialize adrAttr : Lean.TagAttribute ← Lean.registerTagAttribute `adr "ADR registry tag" (fun _ => pure ())

/-- Tag attribute for formal proofs of ADR-System invariants. -/
initialize proofAttr : Lean.TagAttribute ← Lean.registerTagAttribute `proof "ADR invariant proof tag" (fun _ => pure ())
