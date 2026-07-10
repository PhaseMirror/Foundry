import ADR.Core
/-!
# ADR Examples
Demonstrates instantiation of the ADR structures.
-/

namespace ADR.Examples
open ADR

def adr001 : ADR := {
  id := "ADR-001",
  title := "Use Lean 4 for Formal ADRs",
  status := ADRStatus.Accepted,
  context := "We need rigorous verification of architectural decisions.",
  decision := "Implement ADRs as dependent types in Lean 4.",
  consequences := ["High initial learning curve", "Machine-checked proofs of architecture"],
  supersedes := none,
  links := []
}

def adr002 : ADR := {
  id := "ADR-002",
  title := "Sedona Spine as Sole Source of Truth",
  status := ADRStatus.Proposed,
  context := "Multiple agents and UI components risk implementing divergent logic.",
  decision := "Designate the Rust-based Sedona Spine as the sole mandatory source of truth.",
  consequences := ["Transformation only for Agents"],
  supersedes := none,
  links := []
}

end ADR.Examples
