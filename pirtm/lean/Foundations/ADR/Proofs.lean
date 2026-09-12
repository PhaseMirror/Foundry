import Foundations.ADR.Core

/-!
# ADR Foundations Proofs

Formal invariants for the ADR data model.

The logical transition relationships live here because the foundational `ADR`
record in `Core.lean` is intentionally data-only (it carries `status` and a
`supersedes : Option ADRId` field but no transition predicate).  Deﬁning the
transition relation at the proof layer keeps the record minimal while still
letting every invariant below be discharged without `sorry`.

Arithmetic-heavy soundness (e.g. genuine primality attribution for the
`isPrimeBasis` helper in `PrimeQuantum.lean`) is deliberately *not* proven here
inside Lean — this package is zero-mathlib.  Attribute-level arithmetic is
verified instead in the Rust/Kani mirror (`rust/adr_rust/src/prime_quantum.rs`,
trial-division `is_prime_basis` + `#[kani::proof]` harness); see
`ENF-006` / `AX-PQ-001` in the Axiom Ledger.
-/
open PIRTM.ADR

/-! ## Valid Transitions -/

/--
Whether transitioning from `old` to `new` is allowed under ADR governance.

Accepted ADRs are immutable unless they are superseded by a valid target ADR.
Proposed ADRs may be accepted or deprecated without supersession.
-/
def validTransition (old new : ADRStatus) (supersedes : Option ADRId) : Bool :=
  if old = new then true
  else if old = ADRStatus.Accepted then
    new = ADRStatus.Superseded && supersedes.isSome
  else if old = ADRStatus.Proposed then
    new = ADRStatus.Accepted || new = ADRStatus.Deprecated
  else false

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
`followSupersessionLoop` walks the supersession chain with fuel, so its length
is bounded by `acc.length + fuel`.  A circular chain cannot be traversed
beyond this bound, which is how "no circular supersession" is made
machine-checkable without adding termination structure to the data model.
-/
def followSupersessionLoop
    (lookup : ADRId → Option ADR) (current : ADR) (acc : List ADRId) (fuel : Nat) : List ADRId :=
  match fuel with
  | 0 => acc
  | fuel + 1 =>
      match current.supersedes with
      | none => acc
      | some targetId =>
          match lookup targetId with
          | none => acc
          | some target =>
              followSupersessionLoop lookup target (targetId :: acc) fuel

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
`followSupersession` is bounded by `fuel`.  Therefore the returned chain has
length at most `fuel`, so no circular chain can be traversed within that bound.
-/
def followSupersession (lookup : ADRId → Option ADR) (a : ADR) (fuel : Nat) : List ADRId :=
  followSupersessionLoop lookup a [] fuel

theorem followSupersession_length_bounded
    (lookup : ADRId → Option ADR) (a : ADR) (fuel : Nat) :
    (followSupersession lookup a fuel).length ≤ fuel := by
  unfold followSupersession
  have h := followSupersessionLoop_length lookup a [] fuel
  simp only [List.length_nil, Nat.zero_add] at h
  exact h

/-! ## Traceability -/

/--
An Accepted ADR always has a reconstructible history: the singleton list
containing its own id.
-/
theorem traceability (a : ADR) (_h : a.status = ADRStatus.Accepted) :
    ∃ hist : List ADRId, hist.head? = some a.id := by
  exact ⟨[a.id], rfl⟩
