/-
Copyright (c) 2026 Citizen Gardens / Multiplicity Foundation.
Released under Apache 2.0 license.

! ADR-0034-F1-Geometry Scaffolding — governance tag attributes
-/
import Lean

/-!
# ComplexKappa.SpectralAttractor.Tags

Inert governance attributes mandated by the ADR contract:

* `@[adr]` — the declaration belongs to an ADR's locked public surface;
* `@[proof]` — the declaration is a machine-checked supporting lemma.

Both are tags only: they alter no elaboration, no linter, no codegen.
They exist so that tooling (sorry-manifest auditors, export generators)
can select the ADR surface mechanically.
-/

namespace ComplexKappa.SpectralAttractor.Tags

open Lean in
initialize
  registerBuiltinAttribute {
    name := `adr
    descr := "marks a declaration belonging to an ADR's public surface"
    applicationTime := .afterTypeChecking
    add := fun _ _ _ => pure ()
  }

open Lean in
initialize
  registerBuiltinAttribute {
    name := `proof
    descr := "marks a machine-checked supporting lemma"
    applicationTime := .afterTypeChecking
    add := fun _ _ _ => pure ()
  }

end ComplexKappa.SpectralAttractor.Tags
