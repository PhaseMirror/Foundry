-- Formal verification of the Language Mapping Protocol

/-- Represents the stability regime of a behavioral partition. -/
inductive BehavioralRegime where
  | Stable : BehavioralRegime
  | Artifact : BehavioralRegime
  deriving Repr, DecidableEq

/-- A prompt in the topology. -/
structure Prompt where
  value : String
  deriving Repr, DecidableEq

/-- An output mapping. -/
structure Output where
  value : String
  deriving Repr, DecidableEq

/-- A perturbation applied to a mapping. -/
structure Perturbation where
  structural_change : Bool
  isomorphic_change : Bool
  original_prompt : Prompt
  perturbed_prompt : Prompt
  deriving Repr

/-- Apply a perturbation evaluation based on original and new output. 
    This mirrors the topological constraints applied by the Rust execution engine. -/
def evaluate_perturbation (p : Perturbation) (original_output new_output : Output) : BehavioralRegime :=
  if p.structural_change ∧ ¬p.isomorphic_change ∧ original_output ≠ new_output then
    BehavioralRegime.Artifact
  else
    BehavioralRegime.Stable

/-- Theorem: A perturbation with no structural change where outputs change does NOT immediately flag as an artifact 
    within this strict definition space. -/
theorem stability_on_no_structural_change (p : Perturbation) (o1 o2 : Output) 
    (h : p.structural_change = false) :
  evaluate_perturbation p o1 o2 = BehavioralRegime.Stable := by
  dsimp [evaluate_perturbation]
  simp [h]

/-- Theorem: If the output perfectly matches the original output across the topological boundary, it is ALWAYS stable. -/
theorem stability_on_output_match (p : Perturbation) (o1 o2 : Output)
    (h : o1 = o2) :
  evaluate_perturbation p o1 o2 = BehavioralRegime.Stable := by
  dsimp [evaluate_perturbation]
  split
  · next h_if =>
    -- h_if contains o1 ≠ o2, but h says o1 = o2
    rcases h_if with ⟨_, _, h_neq⟩
    contradiction
  · rfl

/-- Theorem: Isomorphic changes are strictly required to maintain stability under structural shifts if the outputs diverge. -/
theorem artifact_on_divergence_and_structural (p : Perturbation) (o1 o2 : Output)
    (h_struct : p.structural_change = true)
    (h_iso : p.isomorphic_change = false)
    (h_div : o1 ≠ o2) :
  evaluate_perturbation p o1 o2 = BehavioralRegime.Artifact := by
  dsimp [evaluate_perturbation]
  simp [h_struct, h_iso, h_div]

/-- Theorem: If a perturbation has structural change but also isomorphic change, the regime remains Stable regardless of output divergence. -/
theorem stability_on_structural_isomorphic (p : Perturbation) (o1 o2 : Output)
    (h_struct : p.structural_change = true)
    (h_iso : p.isomorphic_change = true) :
  evaluate_perturbation p o1 o2 = BehavioralRegime.Stable := by
  dsimp [evaluate_perturbation]
  -- The conjunction requires ¬p.isomorphic_change, which is false here
  simp [h_struct, h_iso]
