/-
  Foundations/Topology.lean
  Topological spaces, open sets, continuity, homeomorphisms.
  No mathlib dependency.
-/

import Foundations.Basic

namespace Foundations.Topology

-- ═══════════════════════════════════════════════════════════════
-- Topological Space
-- ═══════════════════════════════════════════════════════════════

structure TopologicalSpace (α : Type) where
  IsOpen : Set α → Prop
  open_univ : IsOpen Set.univ
  open_union : ∀ (ι : Type) (f : ι → Set α),
    (∀ i, IsOpen (f i)) → IsOpen (Set.unionFamily f)
  open_inter : ∀ s t, IsOpen s → IsOpen t → IsOpen (s ∩ t)

-- ═══════════════════════════════════════════════════════════════
-- Closed sets
-- ═══════════════════════════════════════════════════════════════

def IsClosed {α : Type} (τ : TopologicalSpace α) (s : Set α) : Prop :=
  τ.IsOpen (sᶜ)

-- ═══════════════════════════════════════════════════════════════
-- Continuity
-- ═══════════════════════════════════════════════════════════════

def Continuous {α β : Type}
    (τα : TopologicalSpace α) (τβ : TopologicalSpace β)
    (f : α → β) : Prop :=
  ∀ s, τβ.IsOpen s → τα.IsOpen (f⁻¹' s)

-- ═══════════════════════════════════════════════════════════════
-- Homeomorphism
-- ═══════════════════════════════════════════════════════════════

structure Homeomorphism {α β : Type}
    (τα : TopologicalSpace α) (τβ : TopologicalSpace β) where
  toFun : α → β
  invFun : β → α
  left_inv : ∀ a, invFun (toFun a) = a
  right_inv : ∀ b, toFun (invFun b) = b
  continuous_toFun : Continuous τα τβ toFun
  continuous_invFun : Continuous τβ τα invFun

-- ═══════════════════════════════════════════════════════════════
-- Compactness (open cover definition)
-- ═══════════════════════════════════════════════════════════════

def IsCompact {α : Type} (τ : TopologicalSpace α) (s : Set α) : Prop :=
  ∀ (ι : Type) (f : ι → Set α),
    (∀ i, τ.IsOpen (f i)) →
    s ⊆ Set.unionFamily f →
    ∃ (t : Finset ι), s ⊆ Set.unionFamily (fun i => f i.val)

-- ═══════════════════════════════════════════════════════════════
-- Hausdorff
-- ═══════════════════════════════════════════════════════════════

def IsHausdorff {α : Type} (τ : TopologicalSpace α) : Prop :=
  ∀ a b : α, a ≠ b →
    ∃ s t, τ.IsOpen s ∧ τ.IsOpen t ∧ a ∈ s ∧ b ∈ t ∧ s ∩ t = ∅

end Foundations.Topology
