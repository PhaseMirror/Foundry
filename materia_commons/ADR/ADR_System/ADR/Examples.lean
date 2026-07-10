/-!
# ADR Examples
-/
import ADR.Core

namespace ADRSystem.Examples
open ADRSystem

def exampleADR1 : ADR := {
  id := 1,
  title := "Use Lean 4 for ADRs",
  status := .Accepted,
  context := "We need formal verification for our architecture.",
  decision := "Implement ADRs in Lean 4.",
  consequences := ["High rigor", "Steep learning curve"],
  supersedes := none,
  links := []
}

def exampleADR2 : ADR := {
  id := 2,
  title := "Deprecate Markdown ADRs",
  status := .Proposed,
  context := "Markdown lacks formal semantics.",
  decision := "Stop using plain markdown.",
  consequences := ["Require Lean 4 toolchain"],
  supersedes := some 1,
  links := []
}

end ADRSystem.Examples
