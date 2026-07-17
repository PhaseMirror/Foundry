import ADR.Core
import ADR.Proofs

/-! 
# Verified ADR Examples
-/

namespace ADR.Examples

def adr001 : ADRRecord := {
  id := "ADR-001"
  title := "Adopt Lean 4 for Governance"
  status := ADRStatus.Accepted
  context := "We require machine-checked architectural decisions."
  decision := "Formalize ADRs in Lean 4."
  consequences := ["High rigor", "Zero drift"]
  supersedes := none
  links := [{ url := "https://github.com/leanprover/lean4" }]
}

-- Note: In a real project you might use a macro @[proof] or similar.
theorem adr001_valid : ValidADR adr001 := {
  accepted_immutable := fun _ _ => trivial
  consequences_entailed := fun _ _ => trivial
  no_circular_supersession := by decide
  traceability := by decide
}

end ADR.Examples
