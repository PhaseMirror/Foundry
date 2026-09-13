with open("ADR/Examples.lean", "r") as f:
    text = f.read()

import re

# Find the ADR0027 block
pattern = r"def prop_0027_main.*?def prop_0028_main"

detailed_0027 = """
def prop_0027_context := PropToken.atom "A null experimental outcome is not a statement of physical absence; a latent state passes through multiple stages before recorded data exist"
def prop_layered_factorization := PropToken.atom "Total map is factored as M = T ∘ A ∘ P ∘ R ∘ S; measurement fibers define observational equivalence"
def prop_null_witness_filtration := PropToken.atom "Cumulative nulls form a filtration K₀ ⊆ K₁ ⊆ ... and dual witness spaces shrink in the opposite direction"
def prop_target_specific_closure := PropToken.atom "Target C is identifiable iff K_j ⊆ ker C; target-obstruction dimension counts unresolved directions"
def prop_common_state_closure := PropToken.atom "Probes combine by kernel intersection only when they refer to a common latent state"
def prop_walsh_hadamard_coding := PropToken.atom "Reversal experiments act as group characters only when reversals are commuting involutions"
def prop_0027_consequences := PropToken.and (PropToken.atom "Every null is attributed to a specific stage of a declared factorization") (PropToken.atom "Upstream contradiction differs logically from a downstream projection null")

def ADR0027 : ADR := {
  id := "0027"
  title := "When Null Does Not Mean Absent — Measurement-Map Geometry and Null–Witness Duality"
  status := .Accepted
  context := [prop_0027_context]
  decision := [prop_layered_factorization, prop_null_witness_filtration, prop_target_specific_closure, prop_common_state_closure, prop_walsh_hadamard_coding, prop_0027_consequences]
  consequences := [prop_0027_consequences]
  supersedes := none
  links := [
    { relation := "Source File", target := "docs/adr/accepted/0027-When Null Does Not Mean Absent Measurement Map Geometry.md" },
    { relation := "Related ADR", target := "ADR-0022" },
    { relation := "Related ADR", target := "ADR-0024" },
    { relation := "Related ADR", target := "ADR-0026" },
    { relation := "Related ADR", target := "ADR-0028" },
    { relation := "Delivered Kernel", target := "packages/rust/observ" }
  ]
  entailment_proof := by
    intro c hc
    apply Or.inr
    exact List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ hc))))
}

def prop_0028_main"""

text = re.sub(pattern, detailed_0027, text, flags=re.DOTALL)

with open("ADR/Examples.lean", "w") as f:
    f.write(text)
