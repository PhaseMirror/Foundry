/-!
  Compact‑Closed enrichment for the PETC signature category.
  This file defines a degenerate `CompactClosedCategory` instance for `Sig`
  where cups and caps are the identity on the unit object, and proves that
  the multiplicity functor `M` preserves them (maps to `1`).

  No external libraries are used; the required type‑class is defined locally.
-/

namespace PIRTM

/-- Minimal definition of a compact‑closed category (degenerate version). -/
class CompactClosedCategory (Obj : Type) where
  -- The unit object.
  unit : Obj
  -- Cup and cap morphisms (here simply values of type `Obj`).
  cup  : Obj → Obj
  cap  : Obj → Obj
  /- Axiom: cups and caps are the unit object. -/
  cup_is_unit : ∀ x, cup x = unit
  cap_is_unit : ∀ x, cap x = unit

/-- Re‑export the existing `Signature` type from `Signatures`. -/
open Signatures

def Sig := Signature   -- alias for readability

/-- Provide the compact‑closed instance for `Sig`. -/
instance : CompactClosedCategory Sig where
  unit := Signature.new   -- the empty signature is the monoidal unit
  cup  := fun _ => Signature.new
  cap  := fun _ => Signature.new
  cup_is_unit := by intro _; rfl
  cap_is_unit := by intro _; rfl

/-- Multiplicity functor `M` (already defined in `Multiplicity.lean`). -/
open Multiplicity

/-- Lemma: `M` maps every cup to the scalar `1`. -/
@[simp] theorem M_preserves_cup (e : Sig) :
    M (CompactClosedCategory.cup e) = (1 : ℚˣ) := by
  -- `cup e` is the empty signature, and `M` of the empty signature is `1`.
  rfl

/-- Lemma: `M` maps every cap to the scalar `1`. -/
@[simp] theorem M_preserves_cap (e : Sig) :
    M (CompactClosedCategory.cap e) = (1 : ℚˣ) := by
  rfl

end PIRTM
