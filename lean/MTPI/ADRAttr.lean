import Lean

/-!
# ADR-0013 attribute registrations

Lean requires registered tag attributes to be usable from a *different*
compiled module than the one that registers them. This tiny leaf module owns the
`@[adr]` and `@[proof]` attributes used throughout `MTPI.ADR0013`.

- `adr`   marks a formal ADR-0013 artifact (definition/structure).
- `proof` marks a machine-checked ADR-0013 theorem.
-/

namespace MTPI.ADRAttr

initialize adrAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `adr "marks a formal ADR-0013 artifact"

initialize proofAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `proof "marks a machine-checked ADR-0013 proof"

end MTPI.ADRAttr