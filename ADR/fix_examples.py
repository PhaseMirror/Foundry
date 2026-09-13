with open("ADR/Examples.lean", "r") as f:
    text = f.read()

import re

# Fix ADR0024
text = re.sub(r"def ADR0024.*?exact List\.Mem\.tail _ <\|.*?hc\n}", 
"""def ADR0024 : ADR := {
  id := "0024"
  title := "Reversal-Space Tomography of Weak Altermagnetic Exchange in MnF₂"
  status := .Accepted
  context := [prop_readout_multiplication]
  decision := [prop_walsh_hadamard_contrast, prop_path_consistency_gate, prop_0024_consequences]
  consequences := [prop_0024_consequences]
  supersedes := none
  links := [
    { relation := "Source File", target := "docs/adr/accepted/0024-Reversal Space Tomography of Weak Altermagnetic Exchange in MnF2.md" },
    { relation := "Related ADR", target := "ADR-0022" },
    { relation := "Related ADR", target := "ADR-0023" },
    { relation := "Related ADR", target := "ADR-0027" },
    { relation := "Related ADR", target := "ADR-0028" },
    { relation := "Delivered Kernel", target := "packages/rust/observ" }
  ]
  entailment_proof := by
    intro c hc
    apply Or.inr
    exact List.Mem.tail _ (List.Mem.tail _ hc)
}""", text, flags=re.DOTALL)

# Fix ADR0025
text = re.sub(r"def ADR0025.*?exact List\.Mem\.tail _ <\|.*?hc\n}", 
"""def ADR0025 : ADR := {
  id := "0025"
  title := "Static Multipolar Order and Dynamical Chiral Response — Probe–Tensor Correspondence in MnF₂"
  status := .Accepted
  context := [prop_0025_context]
  decision := [prop_separated_objects, prop_no_automatic_substitution, prop_conditional_rank_identifiability, prop_0025_consequences]
  consequences := [prop_0025_consequences]
  supersedes := none
  links := [
    { relation := "Source File", target := "docs/adr/accepted/0025-Static Multipolar Order and Dynamical Chiral Response in MnF2.md" },
    { relation := "Related ADR", target := "ADR-0023" },
    { relation := "Related ADR", target := "ADR-0026" },
    { relation := "Related ADR", target := "ADR-0027" },
    { relation := "Delivered Kernel", target := "packages/rust/observ" }
  ]
  entailment_proof := by
    intro c hc
    apply Or.inr
    exact List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ hc))
}""", text, flags=re.DOTALL)

# Fix ADR0026
text = re.sub(r"def ADR0026.*?exact List\.Mem\.tail _ <\|.*?hc\n}", 
"""def ADR0026 : ADR := {
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
}""", text, flags=re.DOTALL)

# Fix ADR0027
text = re.sub(r"def ADR0027.*?exact List\.Mem\.tail _ <\|.*?hc\n}", 
"""def ADR0027 : ADR := {
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
}""", text, flags=re.DOTALL)

# Fix ADR0028
text = re.sub(r"def ADR0028.*?exact List\.Mem\.tail _ <\|.*?hc\n}", 
"""def ADR0028 : ADR := {
  id := "0028"
  title := "Target-First Observability Calculus — Admissible Ambiguity and Dual Obstructions"
  status := .Accepted
  context := [prop_0028_context]
  decision := [prop_target_first_ordering, prop_residual_structural_ambiguity, prop_admissible_set_contraction, prop_dual_obstructions, prop_worked_counterexample, prop_state_gate_before_closure, prop_practical_margin, prop_0028_consequences]
  consequences := [prop_0028_consequences]
  supersedes := none
  links := [
    { relation := "Source File", target := "docs/adr/accepted/0028-Target First Observability Calculus with Admissible Ambiguity.md" },
    { relation := "Related ADR", target := "ADR-0024" },
    { relation := "Related ADR", target := "ADR-0025" },
    { relation := "Related ADR", target := "ADR-0026" },
    { relation := "Related ADR", target := "ADR-0027" },
    { relation := "Delivered Kernel", target := "packages/rust/observ" }
  ]
  entailment_proof := by
    intro c hc
    apply Or.inr
    exact List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ hc)))))))
}""", text, flags=re.DOTALL)

with open("ADR/Examples.lean", "w") as f:
    f.write(text)
