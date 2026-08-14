/-!
# Multiplicity Kernel — Finite Sets (ADR-0001 Phase 1 scope)

`Finset` is not available outside Mathlib, so a finite set is modelled by a
`List` together with the `Nodup` (no-duplicates) proof.  The kernel certifies
the cardinality laws needed by the rest of the stack.
-/

namespace Multiplicity.Kernel

/-- A finite set: a list with no duplicates. -/
structure FinSet where
  elements : List Nat
  nodup : elements.Nodup

/-- Cardinality of a finite set. -/
def card (s : FinSet) : Nat := s.elements.length

/-- Membership. -/
def mem (x : Nat) (s : FinSet) : Prop := x ∈ s.elements

/-- Subset relation. -/
def subset (s t : FinSet) : Prop := ∀ x, mem x s → mem x t

/-- The empty set. -/
def emptySet : FinSet :=
  { elements := [], nodup := List.nodup_nil }

/-- Cardinality of the empty set is zero. -/
theorem card_empty : card emptySet = 0 := rfl

/-- Singleton set. -/
def singletonSet (x : Nat) : FinSet :=
  { elements := [x], nodup := by simp }

/-- Cardinality of a singleton is one. -/
theorem card_singleton (x : Nat) : card (singletonSet x) = 1 := rfl

/-- A non-empty finite set has an element. -/
theorem card_pos_mem {s : FinSet} (h : 0 < card s) : ∃ x, mem x s := by
  cases hEq : s.elements with
  | nil =>
      rw [card] at h
      rw [hEq] at h
      simp at h
  | cons a l =>
      simp [mem, hEq]

/-- Filtering a set cannot increase its cardinality. -/
theorem card_filter_le (p : Nat → Bool) (l : List Nat) :
    (l.filter p).length ≤ l.length :=
  List.length_filter_le p l

/-- The subset of a set induced by a membership filter has cardinality at
most the set itself. -/
theorem card_filter_mem_le (t : FinSet) (s : FinSet) :
    (s.elements.filter (fun x => x ∈ t.elements)).length ≤ s.elements.length :=
  List.length_filter_le (fun x => x ∈ t.elements) s.elements

/-- Subset is reflexive. -/
theorem subset_refl (s : FinSet) : subset s s := by
  intro x hx
  exact hx

/-- Subset is transitive. -/
theorem subset_trans {s t u : FinSet} (hst : subset s t) (htu : subset t u) : subset s u := by
  intro x hx
  exact htu x (hst x hx)

/-! ## Cardinality of subsets (`subset_card_le`) -/

/-- `(a == b) = true` implies `a = b`. -/
theorem beq_eq_of_true {a b : Nat} (h : (a == b) = true) : a = b :=
  Nat.beq_eq.mp (by simpa using h)

/-- `a ≠ b` implies `(a == b) = false`. -/
theorem beq_false_of_ne {a b : Nat} (h : a ≠ b) : (a == b) = false := by
  cases hb : (a == b) with
  | true =>
      have : a = b := beq_eq_of_true hb
      exact (h this).elim
  | false => simp

/-- An element different from `a` that lies in `m` stays in `m.erase a`. -/
theorem mem_erase_of_mem_ne (a b : Nat) {m : List Nat} (hb : b ∈ m) (hne : b ≠ a) :
    b ∈ m.erase a := by
  induction m with
  | nil => cases hb
  | cons x ms ih =>
      cases hb with
      | head =>
          simp [List.erase]
          by_cases hba : b == a
          · have : b = a := beq_eq_of_true hba
            exact (hne this).elim
          · simp [hba]
      | tail =>
          rename_i hbm
          simp [List.erase]
          by_cases hx : x == a
          · simp [hx]
            exact hbm
          · have hxne : x ≠ a := by
              intro heq
              apply hx
              simp [heq]
            have hxf : (x == a) = false := beq_false_of_ne hxne
            simp [hxf]
            right
            exact ih hbm

/-- Membership in an erased list implies membership in the original. -/
theorem mem_of_mem_erase {a b : Nat} {l : List Nat} (h : b ∈ l.erase a) : b ∈ l := by
  induction l with
  | nil => cases h
  | cons x ms ih =>
      simp [List.erase] at h
      by_cases hx : x == a
      · simp [hx] at h
        exact List.Mem.tail x h
      · have hxne : x ≠ a := by
          intro heq
          apply hx
          simp [heq]
        have hxf : (x == a) = false := beq_false_of_ne hxne
        simp [hxf] at h
        cases h with
        | inl hb =>
            rw [hb]
            exact List.Mem.head ms
        | inr hbm => exact List.Mem.tail x (ih hbm)

/-- Erasing preserves the no-duplicates invariant. -/
theorem nodup_erase {a : Nat} {m : List Nat} (hm : m.Nodup) : (m.erase a).Nodup := by
  induction m with
  | nil => simp
  | cons x ms ih =>
      rw [List.nodup_cons] at hm
      rcases hm with ⟨hx, hms⟩
      simp [List.erase]
      by_cases hxeq : x == a
      · simp [hxeq]
        exact hms
      · have hxne : x ≠ a := by
          intro heq
          apply hxeq
          simp [heq]
        have hxf : (x == a) = false := beq_false_of_ne hxne
        rw [hxf]
        rw [List.nodup_cons]
        constructor
        · intro hxe
          have hxin : x ∈ ms := mem_of_mem_erase hxe
          exact hx hxin
        · exact ih hms

/-- Erasing a present element decrements the length by one. -/
theorem erase_length {a : Nat} {m : List Nat} (hmem : a ∈ m) :
    (m.erase a).length = m.length - 1 := by
  simp [hmem]

/-- A list with a member has positive length. -/
theorem length_pos_of_mem {a : Nat} {m : List Nat} (h : a ∈ m) : 0 < m.length := by
  induction m with
  | nil => cases h
  | cons x ms ih =>
      cases h with
      | head => simp
      | tail hm => simp

/-- Removing one element shrinks the size by at most one. -/
theorem erase_length_le {a : Nat} {m : List Nat} : (m.erase a).length ≤ m.length := by
  rw [List.length_erase]
  split <;> omega

/-- Cardinality of a subset: `s ⊆ t ⟹ |s| ≤ |t|`.  Proven at the list level
against two `Nodup` proofs to avoid dependent elimination on the structure. -/
theorem subset_length_le (l m : List Nat) : l.Nodup → m.Nodup →
    (∀ x, x ∈ l → x ∈ m) → l.length ≤ m.length := by
  induction l generalizing m with
  | nil => intro _ _ _; simp
  | cons x l' ih =>
      intro hl hm hsub
      rw [List.nodup_cons] at hl
      rcases hl with ⟨hxnot, hl'nodup⟩
      have hxm : x ∈ m := hsub x (List.Mem.head l')
      have hsub' : ∀ y, y ∈ l' → y ∈ m.erase x := by
        intro y hy
        have hym : y ∈ m := hsub y (List.Mem.tail x hy)
        have hyne : y ≠ x := by
          intro heq
          apply hxnot
          rw [← heq]
          exact hy
        exact mem_erase_of_mem_ne x y hym hyne
      have hih := ih (m.erase x) hl'nodup (nodup_erase hm) hsub'
      have hel : (m.erase x).length = m.length - 1 := erase_length hxm
      have hlen : (x :: l').length = l'.length + 1 := rfl
      rw [hlen]
      have hpos : 0 < m.length := length_pos_of_mem hxm
      omega

/-- Cardinality of a subset: `s ⊆ t ⟹ |s| ≤ |t|`. -/
theorem subset_card_le {s t : FinSet} (h : subset s t) : card s ≤ card t := by
  exact subset_length_le s.elements t.elements s.nodup t.nodup
    (by intro x hx; exact h x hx)

/-- The whole set is a subset of itself and the inequality is sharp. -/
theorem subset_card_eq_self (s : FinSet) : card s ≤ card s := Nat.le_refl _

end Multiplicity.Kernel
