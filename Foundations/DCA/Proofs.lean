import Foundations.DCA.Core

/-!
# Foundations.DCA.Proofs — DCA Transition & Execution Safety Proofs

Formal verification of FIR state invariants, deterministic uniqueness, FIR path reversibility,
execution gate soundness, append-only registry preservation, and strict state identity progression.
-/

namespace Foundations.DCA.Proofs

open Foundations.DCA

/-- Theorem: DCA transition preserves validity of the successor state. -/
theorem preserve_invariants (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.is_valid = true := by
  cases h
  assumption

/-- Theorem: DCA transition requires source state validity. -/
theorem source_valid (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s1.is_valid = true := by
  cases h
  assumption

/-- Theorem: DCA transition preserves immutable root pointer. -/
theorem transition_preserves_root (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.root_pointer = s1.root_pointer := by
  cases h
  assumption

/-- Theorem: DCA transition preserves constant growth rate. -/
theorem transition_preserves_epsilon (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.epsilon_g = s1.epsilon_g := by
  cases h
  assumption

/-- Theorem: Shift history equality (s2.was = s1.did). -/
theorem transition_was_eq_did (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.was = s1.did := by
  cases h
  assumption

/-- Theorem: Filter completion equality (s2.did = s1.is_). -/
theorem transition_did_eq_is (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.did = s1.is_ := by
  cases h
  assumption

/-- Theorem: Isolation step equality (s2.is_ = s1.is_ + s1.epsilon_g). -/
theorem transition_is_eq_add (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.is_ = s1.is_ + s1.epsilon_g := by
  cases h
  assumption

/-- Theorem: Transition determinism — any two successors of s1 are identical. -/
theorem transition_deterministic (s1 s2a s2b : DcaState)
    (ha : DcaTransition s1 s2a) (hb : DcaTransition s1 s2b) :
    s2a.was = s2b.was ∧
    s2a.did = s2b.did ∧
    s2a.is_ = s2b.is_ ∧
    s2a.root_pointer = s2b.root_pointer ∧
    s2a.epsilon_g = s2b.epsilon_g ∧
    s2a.is_valid = s2b.is_valid := by
  cases ha with
  | step hw_a hd_a hi_a hr_a he_a hv1_a hv2_a =>
    cases hb with
    | step hw_b hd_b hi_b hr_b he_b hv1_b hv2_b =>
      exact ⟨by rw [hw_a, hw_b], by rw [hd_a, hd_b], by rw [hi_a, hi_b],
             by rw [hr_a, hr_b], by rw [he_a, he_b], by rw [hv2_a, hv2_b]⟩

/-- Theorem: FIR inverse path is fully reconstructible from the transition. -/
theorem fir_path_reconstructible (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    (DcaState.firPath s2).current = s1.is_ + s1.epsilon_g ∧
    (DcaState.firPath s2).previous = s1.is_ ∧
    (DcaState.firPath s2).oldest = s1.did := by
  dsimp [DcaState.firPath]
  cases h with
  | step hw hd hi _ _ _ _ =>
    exact ⟨hi, hd, hw⟩

/-- Theorem: FIR path matches its source state. -/
theorem fir_path_self_match (s : DcaState) :
    FirPath.matches (DcaState.firPath s) s = true := by
  dsimp [FirPath.matches, DcaState.firPath]
  simp [BEq.beq]

/-- Theorem: Fixed-width memory frame topology is sound (6 * 8 ≤ 48). -/
theorem memory_topology_sound : fitsInFrame (6 * 8) = true := by
  decide

/-- Theorem: Inactive state trivially passes overflow gate. -/
theorem overflow_gate_trivial_invalid (s : DcaState) (limit : Nat) (h : s.is_valid = false) :
    OverflowGate.check s limit = true := by
  dsimp [OverflowGate.check]
  simp [h]

/-- Theorem: Execution gate soundness. -/
theorem execution_gate_sound (s : DcaState) (limit : Nat) (h : ExecutionGate.check s limit = true) :
    fitsInFrame (6 * 8) = true ∧ OverflowGate.check s limit = true := by
  dsimp [ExecutionGate.check] at h
  simp only [Bool.and_eq_true] at h
  exact h

private theorem registry_add_preserves_existing_aux (s : DcaState) :
    ∀ (l : List DcaState) (j : Nat), j < l.length →
      listGet? l j = listGet? (l ++ [s]) j := by
  intro l
  induction l with
  | nil => intro j hj; contradiction
  | cons a as ih =>
    intro j hj
    cases j with
    | zero => rfl
    | succ n =>
      dsimp [listGet?]
      apply ih
      simp only [List.length_cons] at hj
      omega

/-- Theorem: Append-only registry addition preserves all existing historical entries. -/
theorem registry_add_preserves_existing (reg : DcaRegistry) (s : DcaState)
    (i : Nat) (hi : i < reg.states.length) :
    listGet? reg.states i = listGet? (reg.add s).states i := by
  dsimp [DcaRegistry.add]
  exact registry_add_preserves_existing_aux s reg.states i hi

/-- Theorem: Non-zero epsilon strictly advances the isolated state value. -/
theorem transition_changes_is (s1 s2 : DcaState) (h : DcaTransition s1 s2)
    (hpos : s1.epsilon_g > 0) :
    s2.is_ ≠ s1.is_ := by
  intro heq
  cases h with
  | step _ _ hi _ _ _ _ =>
    rw [heq] at hi
    omega

end Foundations.DCA.Proofs
