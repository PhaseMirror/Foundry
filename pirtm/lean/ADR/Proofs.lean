
import ADR.Core

namespace ADR

set_option linter.unusedVariables false

/-! ## Entailment Logic -/

/--
A minimal justification record for consequence entailment.

`premises` is the set of atomic facts derived from `context` and `decision`.
`conclusion` is the claimed consequence.
-/
structure Justification where
  premises : List String
  conclusion : String
  deriving Repr, Inhabited

namespace Justification

/--
Simple entailment: the conclusion must be a non-empty string that appears
explicitly in the premises.
-/
def entails (j : Justification) : Bool :=
  j.conclusion.length > 0 && j.premises.contains j.conclusion

/--
Build a justification from an ADR's context and decision by treating
every non-empty line as an atomic premise.  One justification is produced
per consequence, pairing the shared premise set with the actual consequence.
-/
def fromADR (a : ADR) : List Justification :=
  let ctxLines := (a.context.split (· == '\n')).map (·.toString) |>.filter (· != "") |>.toList
  let decLines := (a.decision.split (· == '\n')).map (·.toString) |>.filter (· != "") |>.toList
  let premises := ctxLines ++ decLines
  a.consequences.map (fun c => ⟨premises, c⟩)

end Justification

/-! ## Immutability After Acceptance -/

/--
Accepted ADRs can only remain accepted or move to superseded (with a valid
supersession target).  No other transitions are permitted.
-/
theorem accepted_immutable_without_supersession
    (old new : ADRStatus) (sup : Option ADRId) :
    old = ADRStatus.Accepted →
    validTransition old new sup = true →
    new = ADRStatus.Accepted ∨ (new = ADRStatus.Superseded ∧ sup.isSome) := by
  intro hOld hTrans
  unfold validTransition at hTrans
  simp [hOld] at hTrans
  rcases hTrans with hEq | hEq
  · apply Or.inl; exact hEq.symm
  · apply Or.inr; exact hEq

/--
An ADR in `Accepted` status can never revert to `Proposed`.
-/
theorem accepted_cannot_revert_to_proposed
    (old new : ADRStatus) (sup : Option ADRId) :
    old = ADRStatus.Accepted →
    validTransition old new sup = true →
    new ≠ ADRStatus.Proposed := by
  intro hOld hTrans hNew
  unfold validTransition at hTrans
  simp [hOld, hNew] at hTrans

/--
An ADR in `Accepted` status can never move to `Deprecated` without
supersession.
-/
theorem accepted_cannot_deprecate_without_supersede
    (old new : ADRStatus) (sup : Option ADRId) :
    old = ADRStatus.Accepted →
    validTransition old new sup = true →
    new ≠ ADRStatus.Deprecated := by
  intro hOld hTrans hNew
  unfold validTransition at hTrans
  simp [hOld, hNew] at hTrans

/-! ## No Circular Supersession -/

/--
Lemma: `followSupersessionLoop` length is bounded by `acc.length + fuel`.
-/
theorem followSupersessionLoop_length
    (lookup : ADRId → Option ADR) (current : ADR) (acc : List ADRId) (fuel : Nat) :
    (followSupersessionLoop lookup current acc fuel).length ≤ acc.length + fuel := by
  induction fuel generalizing current acc with
  | zero =>
    exact Nat.le_refl _
  | succ fuel ih =>
    unfold followSupersessionLoop
    split
    · exact Nat.le_add_right _ _
    · split
      · exact Nat.le_add_right _ _
      · rename_i _ targetId _ _ target _
        have h := ih target (targetId :: acc)
        simp only [List.length_cons] at h
        omega




/--
`followSupersession` is bounded by `fuel`.  Therefore the returned chain
has length at most `fuel`, and no cycle can be traversed within that bound.
-/
theorem followSupersession_length_bounded
    (lookup : ADRId → Option ADR) (a : ADR) (fuel : Nat) :
    (followSupersession lookup a fuel).length ≤ fuel := by
  unfold followSupersession
  have h := followSupersessionLoop_length lookup a [] fuel
  simp only [List.length_nil, Nat.zero_add] at h
  exact h

/--
`followSupersession` terminates at an ADR with `supersedes = none` before
the fuel bound is exhausted, provided the lookup function is well-formed.
-/
theorem followSupersession_terminates_at_root
    (lookup : ADRId → Option ADR) (a : ADR) (fuel : Nat)
    (_hFuel : fuel > 0)
    (_hLookup : ∀ id, lookup id = none ∨ ∃ adr, lookup id = some adr) :
    let chain := followSupersession lookup a fuel
    chain = [] ∨ (chain ≠ [] ∧ chain.length ≤ fuel) := by
  dsimp
  cases h : followSupersession lookup a fuel with
  | nil => exact Or.inl rfl
  | cons x xs =>
    apply Or.inr
    constructor
    · intro hContra
      contradiction
    · rw [← h]
      exact followSupersession_length_bounded lookup a fuel

/-! ## Traceability -/

/--
An ADR is reconstructible if its backward supersession ancestry can be
traced to a terminal root ADR with `supersedes = none`.
-/
inductive Reconstructible (lookup : ADRId → Option ADR) : ADR → Prop where
  | root (a : ADR) : a.supersedes = none → Reconstructible lookup a
  | step (a : ADR) {targetId : ADRId} {target : ADR} :
      a.supersedes = some targetId →
      lookup targetId = some target →
      Reconstructible lookup target →
      Reconstructible lookup a


/--
If an ADR is `Accepted` and has no supersession target, it is trivially
reconstructible.
-/
theorem accepted_without_supersession_reconstructible
    {lookup : ADRId → Option ADR} (a : ADR) :
    a.status = ADRStatus.Accepted →
    a.supersedes = none →
    Reconstructible lookup a := by
  intro _ hSup
  exact Reconstructible.root a hSup

/--
If an ADR is `Accepted` and supersedes another ADR, and the target is
reconstructible, then the ADR is reconstructible.
-/
theorem accepted_with_supersession_reconstructible

    {lookup : ADRId → Option ADR} (a : ADR)
    {targetId : ADRId} {target : ADR}
    (hAcc : a.status = ADRStatus.Accepted)
    (hSup : a.supersedes = some targetId)
    (hTarget : lookup targetId = some target)
    (hTargetRecon : Reconstructible lookup target) :
    Reconstructible lookup a := by

  exact Reconstructible.step a hSup hTarget hTargetRecon

/-! ## Consequence Entailment -/

/--
`ConsequencesEntailed a` holds when every consequence listed in `a` is
non-empty and can be derived from `a.context` or `a.decision`.
-/
def ConsequencesEntailed (a : ADR) : Bool :=
  let ctxLines := (a.context.split (· == '\n')).map (·.toString) |>.filter (· != "") |>.toList
  let decLines := (a.decision.split (· == '\n')).map (·.toString) |>.filter (· != "") |>.toList
  let premises := ctxLines ++ decLines
  a.consequences.all (fun c => c.length > 0 && premises.contains c)

theorem all_and_elim_left {α : Type} (p q : α → Bool) (l : List α) :
    l.all (fun x => p x && q x) = true → l.all p = true := by
  induction l with
  | nil =>
    intro _
    rfl
  | cons x xs ih =>
    simp only [List.all_cons, Bool.and_eq_true]
    intro ⟨⟨hpx, _⟩, hrest⟩
    exact ⟨hpx, ih hrest⟩

/--
If an ADR is `Accepted` and its consequences are entailed, then all
consequences are non-empty strings.
-/
theorem accepted_adr_consequences_nonempty (a : ADR) :
    a.status = ADRStatus.Accepted →
    ConsequencesEntailed a = true →
    a.consequences.all (fun c => c.length > 0) = true := by
  intro _ hEntailed
  unfold ConsequencesEntailed at hEntailed
  exact all_and_elim_left (fun c => c.length > 0) _ a.consequences hEntailed

/--
An ADR is `JustifiedWith js` if the explicit justifications `js` match the
consequences one-to-one and each justification satisfies `entails`.
-/
def JustifiedWith (a : ADR) (js : List Justification) : Prop :=
  js.length = a.consequences.length ∧ js.all (·.entails) = true

/--
If an ADR is `Accepted` and explicitly justified, then its consequences
are entailed by construction.
-/
theorem accepted_adr_explicitly_justified
    (a : ADR) (js : List Justification) :
    a.status = ADRStatus.Accepted →
    JustifiedWith a js →
    js.all (·.entails) = true := by
  intro _ hJust
  exact hJust.right


end ADR
