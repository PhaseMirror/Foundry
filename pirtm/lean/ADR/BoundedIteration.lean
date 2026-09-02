/-!
# Bounded Iteration & Control-Flow Contractivity Formalization

Formal proofs that bounded iterations, conditional branches, and function
compositions preserve the contractive envelope under the Universal Multiplicity
Governance Substrate.

Self-contained in Lean 4 Core (Zero-Mathlib, Zero-Sorry).
-/

namespace BoundedIteration

/-- Metric representation for state spaces with rational distance bounds. -/
structure MetricSpace (X : Type) where
  dist : X → X → Nat
  dist_self : ∀ x, dist x x = 0
  dist_symm : ∀ x y, dist x y = dist y x
  dist_triangle : ∀ x y z, dist x z ≤ dist x y + dist y z

/-- A transformation T : X → X is non-expansive if it does not increase distance. -/
structure NonExpansiveMap (X : Type) (M : MetricSpace X) where
  f : X → X
  bound : ∀ x y, M.dist (f x) (f y) ≤ M.dist x y

/-- Identity map on carrier X. -/
def idMap (X : Type) : X → X := fun x => x

/-- Iterated composition of an operator: f^N. -/
def iterate {X : Type} (f : X → X) : Nat → (X → X)
  | 0 => idMap X
  | n + 1 => fun x => f (iterate f n x)

/-- Composition of two non-expansive functions is non-expansive. -/
theorem compose_non_expansive {X : Type} (M : MetricSpace X)
    (f g : NonExpansiveMap X M) :
    ∀ x y, M.dist (f.f (g.f x)) (f.f (g.f y)) ≤ M.dist x y := by
  intro x y
  have h1 := f.bound (g.f x) (g.f y)
  have h2 := g.bound x y
  exact Nat.le_trans h1 h2

/-- Bounded loop iteration theorem:
    If loop body f is non-expansive, then f^N is non-expansive for any finite N. -/
theorem iterate_non_expansive {X : Type} (M : MetricSpace X)
    (f : NonExpansiveMap X M) (N : Nat) :
    ∀ x y, M.dist (iterate f.f N x) (iterate f.f N y) ≤ M.dist x y := by
  intro x y
  induction N with
  | zero =>
    dsimp [iterate, idMap]
    exact Nat.le_refl (M.dist x y)
  | succ n ih =>
    dsimp [iterate]
    have h1 := f.bound (iterate f.f n x) (iterate f.f n y)
    exact Nat.le_trans h1 ih

/-- Maximum bound helper for branch analysis. -/
def max_bound (b1 b2 : Nat) : Nat :=
  if b1 ≥ b2 then b1 else b2

/-- Conditional branch contractivity envelope theorem:
    Selecting between two bounded branches maintains the outer radius envelope. -/
theorem conditional_branch_safe (b1 b2 radius : Nat)
    (h1 : b1 ≤ radius) (h2 : b2 ≤ radius) :
    max_bound b1 b2 ≤ radius := by
  dsimp [max_bound]
  split
  · exact h1
  · exact h2

/-- Bounded iteration with static loop bound N_max preserves invariant envelope. -/
theorem bounded_while_envelope {X : Type} (M : MetricSpace X)
    (body : NonExpansiveMap X M) (N_max : Nat) (initial_radius : Nat)
    (h_init : ∀ x y, M.dist x y ≤ initial_radius) :
    ∀ x y, M.dist (iterate body.f N_max x) (iterate body.f N_max y) ≤ initial_radius := by
  intro x y
  have h_iter := iterate_non_expansive M body N_max x y
  have h_base := h_init x y
  exact Nat.le_trans h_iter h_base

end BoundedIteration
