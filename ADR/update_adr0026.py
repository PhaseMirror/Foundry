with open("ADR/Examples.lean", "r") as f:
    text = f.read()

import re

# Find the ADR0026 block
pattern = r"def prop_0026_main.*?def prop_0027_main"

detailed_0026 = """
def prop_0026_context := PropToken.atom "A portable symmetry argument must survive differing materials and must not be made true by choosing its reference model post-hoc"
def prop_six_component_claim_vector := PropToken.atom "Six-component claim vector c=(M, S, E, χ, R, K) is used, components are closed independently"
def prop_predeclared_reference_admissibility := PropToken.atom "Source-sector attribution requires a predeclared or independently anchored reference model"
def prop_adversarial_controls := PropToken.atom "Adversarial controls like FeF₂ and MnSi test separation and non-altermagnetic specificity"
def prop_verdicts := PropToken.atom "Per-material and framework verdicts are categorical label sets, not numerical evidence scores"
def prop_source_state_gating := PropToken.atom "Source-state gating kills downstream attribution if the upstream state is absent or contradicted"
def prop_0026_consequences := PropToken.and (PropToken.atom "Universal weak one-dimensional coordinates are rejected") (PropToken.atom "Attribution is killed by source-state gate before observables are counted")

def ADR0026 : ADR := {
  id := "0026"
  title := "Symmetry-Complement Coordinates Across Altermagnets — Cross-Material Falsification"
  status := .Accepted
  context := [prop_0026_context]
  decision := [prop_six_component_claim_vector, prop_predeclared_reference_admissibility, prop_adversarial_controls, prop_verdicts, prop_source_state_gating, prop_0026_consequences]
  consequences := [prop_0026_consequences]
  supersedes := none
  links := [
    { relation := "Source File", target := "docs/adr/accepted/0026-Symmetry Complement Coordinates Across Altermagnets.md" },
    { relation := "Related ADR", target := "ADR-0023" },
    { relation := "Related ADR", target := "ADR-0025" },
    { relation := "Related ADR", target := "ADR-0027" },
    { relation := "Related ADR", target := "ADR-0028" },
    { relation := "Delivered Kernel", target := "packages/rust/observ" }
  ]
  entailment_proof := by
    intro c hc
    apply Or.inr
    exact List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ hc))))
}

def prop_0027_main"""

text = re.sub(pattern, detailed_0026, text, flags=re.DOTALL)

with open("ADR/Examples.lean", "w") as f:
    f.write(text)
