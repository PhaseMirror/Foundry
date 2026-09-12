import DCA.Core

/-!
# DCA Proofs

## Constructor argument order for `DcaTransition.step`

`cases h with | step a1 a2 a3 a4 a5 a6 a7 =>` binds:
  1. hw : s2.was = s1.did
  2. hd : s2.did = s1.is_
  3. hi : s2.is_ = s1.is_ + s1.epsilon_g
  4. hr : s2.root_pointer = s1.root_pointer
  5. he : s2.epsilon_g = s1.epsilon_g
  6. hv1 : s1.is_valid = true
  7. hv2 : s2.is_valid = true

## UInt64 limitation

`omega` does not operate on `UInt64`. Theorems requiring arithmetic on
`UInt64` fields are stated with `sorry` proofs and documented extension
points. A production extension would add a `DCA/UInt64Arith.lean` module.
-/

namespace DCA.Proofs

open DCA

/-! ## Core Invariant Theorems -/

@[dca_proof]
theorem preserve_invariants (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.is_valid = true := by
  cases h <;> assumption

@[dca_proof]
theorem source_valid (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s1.is_valid = true := by
  cases h <;> assumption

@[dca_proof]
theorem transition_preserves_root (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.root_pointer = s1.root_pointer := by
  cases h <;> assumption

@[dca_proof]
theorem transition_preserves_epsilon (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.epsilon_g = s1.epsilon_g := by
  cases h <;> assumption

@[dca_proof]
theorem transition_was_eq_did (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.was = s1.did := by
  cases h <;> assumption

@[dca_proof]
theorem transition_did_eq_is (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.did = s1.is_ := by
  cases h <;> assumption

@[dca_proof]
theorem transition_is_eq_add (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.is_ = s1.is_ + s1.epsilon_g := by
  cases h <;> assumption

/-! ## Determinism -/

@[dca_proof]
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

/-! ## FIR Reversibility -/

@[dca_proof]
theorem fir_path_reconstructible (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    (DcaState.firPath s2).current = s1.is_ + s1.epsilon_g ∧
    (DcaState.firPath s2).previous = s1.is_ ∧
    (DcaState.firPath s2).oldest = s1.did := by
  unfold DcaState.firPath
  cases h with
  | step hw hd hi _ _ _ _ =>
    exact ⟨hi, hd, hw⟩

@[dca_proof]
theorem fir_path_self_match (s : DcaState) :
    FirPath.matches (DcaState.firPath s) s = true := by
  unfold FirPath.matches DcaState.firPath
  simp [BEq.beq]

/-! ## Execution Safety -/

@[dca_proof]
theorem memory_topology_sound : fitsInFrame (6 * 8) = true := by
  native_decide

@[dca_proof]
theorem overflow_gate_trivial_invalid (s : DcaState) (h : s.is_valid = false) :
    OverflowGate.check s = true := by
  unfold OverflowGate.check
  simp [h]

@[dca_proof]
theorem execution_gate_sound (s : DcaState) (h : ExecutionGate.check s = true) :
    fitsInFrame (6 * 8) = true ∧ OverflowGate.check s = true := by
  unfold ExecutionGate.check at h
  simp only [Bool.and_eq_true] at h
  exact h

/-! ## Registry -/

@[dca_proof]
theorem registry_valid_count_nonneg (reg : DcaRegistry) :
    reg.validCount ≥ 0 := by
  omega

private theorem registry_add_preserves_existing_aux (s : DcaState) :
    ∀ (l : List DcaState) (j : Nat), j < l.length →
      listGet? l j = listGet? (l ++ [s]) j := by
  intro l
  induction l with
  | nil => intro j hj; simp [List.length] at hj
  | cons a as ih =>
    intro j hj
    cases j with
    | zero => rfl
    | succ n =>
      simp only [listGet?]
      apply ih
      simp only [List.length_cons] at hj
      omega

@[dca_proof]
theorem registry_add_preserves_existing (reg : DcaRegistry) (s : DcaState)
    (i : Nat) (hi : i < reg.states.length) :
    listGet? reg.states i = listGet? (reg.add s).states i := by
  unfold DcaRegistry.add
  exact registry_add_preserves_existing_aux s reg.states i hi

@[dca_proof]
theorem registry_valid_subset (reg : DcaRegistry) (s : DcaState)
    (hs : s ∈ reg.valid) :
    s ∈ reg.states := by
  unfold DcaRegistry.valid at hs
  rw [List.mem_filter] at hs
  exact hs.1

/-! ## Traceability -/

@[dca_proof]
theorem history_reconstructible (s1 s2 : DcaState) (h : DcaTransition s1 s2) :
    s2.was = s1.did ∧ s2.did = s1.is_ ∧ s2.is_ = s1.is_ + s1.epsilon_g := by
  cases h with
  | step hw hd hi _ _ _ _ =>
    exact ⟨hw, hd, hi⟩

/-! ## State Identity -/

/-- Transition always changes the isolated value (when epsilon_g > 0).

**Extension point:** The proof requires `UInt64` arithmetic reasoning that
is beyond `omega`. A production extension would add:
  - `UInt64.toNat_inj : a.toNat = b.toNat → a = b`
  - `UInt64.add_ne_of_pos : a.toNat + b.toNat < UInt64.size → b > 0 → a + b ≠ a` -/
@[dca_proof]
theorem transition_changes_is (s1 s2 : DcaState) (h : DcaTransition s1 s2)
    (hpos : s1.epsilon_g > 0) :
    s2.is_ ≠ s1.is_ := by
  intro heq
  cases h with
  | step _ _ hi _ _ _ _ =>
    sorry

/-! ## Consequence Entailment -/

def wordsOf (s : String) : List String :=
  let rec go (cs : List Char) (current : List Char) (acc : List String) : List String :=
    match cs with
    | [] => (String.ofList current.reverse :: acc).reverse
    | c :: rest =>
      if c = ' ' then
        go rest [] (if current.length = 0 then acc else String.ofList current.reverse :: acc)
      else
        go rest (c :: current) acc
  go s.toList [] []

def entails (context decision consequence : String) : Bool :=
  let words := wordsOf context ++ wordsOf decision
  let cwords := wordsOf consequence
  cwords.all (fun w => List.elem w words) && consequence != ""

def entails_prop (context decision consequence : String) : Prop :=
  entails context decision consequence = true

@[dca_proof]
theorem entails_implies_nonempty {c d x : String} (h : entails c d x = true) : x ≠ "" := by
  intro hx
  subst hx
  unfold entails at h
  simp [wordsOf] at h

end DCA.Proofs
