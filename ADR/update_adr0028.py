with open("ADR/Examples.lean", "r") as f:
    text = f.read()

import re

# Find the ADR0028 block
pattern = r"def prop_0028_main.*?(?=\n\ndef Registry)"

detailed_0028 = """
def prop_0028_context := PropToken.atom "Experimental design is often incorrectly organized around available instruments rather than declared claims"
def prop_target_first_ordering := PropToken.atom "13-step explicit protocol ordered target-first rather than instrument-first"
def prop_residual_structural_ambiguity := PropToken.atom "Residual ambiguity O_C(E) = C(ker A_E); probe selection requires target design gain Δ_C > 0"
def prop_admissible_set_contraction := PropToken.atom "Exact closure and quantitative contraction of the admissible set are reported separately"
def prop_dual_obstructions := PropToken.atom "A counterexample v ∈ ker A_E with Cv ≠ 0 identifies the most useful next experiment"
def prop_worked_counterexample := PropToken.atom "Maximum signal can be the wrong experiment (Δ_C = 0 vs Δ_C = 1)"
def prop_state_gate_before_closure := PropToken.atom "State gate must survive independently before downstream response closure"
def prop_practical_margin := PropToken.atom "Optimize structural viability with nuisance-projected Jacobians and target practical margins"
def prop_0028_consequences := PropToken.and (PropToken.atom "Experiment selection is justified by target design gain, not raw amplitude") (PropToken.atom "Claims require a declared target, state gate, forward map, and attempted falsification")

def ADR0028 : ADR := {
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
}"""

text = re.sub(pattern, detailed_0028, text, flags=re.DOTALL)

with open("ADR/Examples.lean", "w") as f:
    f.write(text)
