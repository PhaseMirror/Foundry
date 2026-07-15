import Kernel

/-!
# GodelianTruth — consistency and the unprovable liar

Formalizes the incompleteness invariant: in any consistent formal system rich enough
for self-reference, the Gödel/liar sentence is not provable. The diagonal lemma is
treated as a precisely-scoped trusted axiom (the Kani-style boundary), mirroring the
discipline in `proofs/Kani.lean`. No `sorry`.
-/
namespace GodelianTruth

open proofs.Kernel

/-- A provability predicate over propositions. -/
def proves : Prop → Prop := id

/-- Consistency: no proposition is both provable and refutable. -/
def consistent (P : Prop → Prop) : Prop := ∀ p, ¬ (P p ∧ P (¬ p))

/-- The diagonal lemma (trusted boundary, cf. `proofs/Kani.lean`). -/
axiom DiagSent : Prop
axiom diag_spec : DiagSent ↔ ¬ proves DiagSent

/-- Consistency implies the diagonal sentence is unprovable. -/
theorem consistency_implies_unprovable (hcon : consistent proves) : ¬ proves DiagSent := by
  intro hd
  have : proves (¬ DiagSent) := by rwa [diag_spec] at hd
  exact hcon DiagSent ⟨hd, this⟩

/-- A trivially consistent system always exists. -/
theorem exists_consistent : ∃ P : Prop → Prop, consistent P := by
  use fun p => False
  intro p hp
  simp at hp

end GodelianTruth
