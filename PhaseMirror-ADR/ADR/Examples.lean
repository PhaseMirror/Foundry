/-!
# Example ADRs
Instances of ADRs representing real architectural decisions.
-/
import ADR.Core
import ADR.Proofs

namespace ADR.Examples

open ADR

def adr1 : ADR := {
  id := 1,
  title := "Use Lean 4 for ADR Governance",
  status := .Accepted,
  context := "We need formal verification of architectural decisions.",
  decision := "Implement the Phase Mirror scaffolding.",
  consequences := ["Steeper learning curve", "Mathematically sound governance"],
  supersedes := none,
  links := []
}

def adr2 : ADR := {
  id := 2,
  title := "Migrate from Markdown to Lean",
  status := .Superseded,
  context := "Markdown lacks formal verification.",
  decision := "Store ADRs as `.lean` files.",
  consequences := ["Better CI/CD checks"],
  supersedes := some 1,
  links := []
}

def adr3 : ADR := {
  id := 3,
  title := "Implement Property-Based Testing",
  status := .Proposed,
  context := "We need to ensure transition rules are exhaustively checked.",
  decision := "Add test harness using Lean theorems.",
  consequences := ["More robust pipeline"],
  supersedes := none,
  links := []
}

def adr4 : ADR := {
  id := 4,
  title := "Host foundry-web via GitHub Pages",
  status := .Proposed,
  context := "We need a public-facing documentation and landing page for the Foundry project. The foundry-web package already contains the necessary web assets.",
  decision := "Configure GitHub Actions to build and deploy foundry-web to GitHub Pages.",
  consequences := ["Free hosting via GitHub", "Public visibility of the project", "Requires setting up a gh-pages branch or Pages deployment workflow"],
  supersedes := none,
  links := [{ title := "foundry-web", url := "./foundry-web" }]
}

end ADR.Examples
