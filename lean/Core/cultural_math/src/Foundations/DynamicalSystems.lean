/-
  Foundations/DynamicalSystems.lean
  Flows, stability (Lyapunov), chaos.
  No mathlib dependency.
-/

import Foundations.Basic

namespace Foundations.Dynamics

-- ═══════════════════════════════════════════════════════════════
-- Discrete Dynamical System
-- ═══════════════════════════════════════════════════════════════

structure DiscreteSystem (α : Type) where
  map : α → α
  state : α

def iterate {α : Type} (f : α → α) : Nat → α → α
  | 0, a => a
  | n + 1, a => iterate f n (f a)

def trajectory {α : Type} (f : α → α) (x₀ : α) : Nat → α :=
  fun n => iterate f n x₀

-- ═══════════════════════════════════════════════════════════════
-- Fixed Points
-- ═══════════════════════════════════════════════════════════════

def IsFixedPoint {α : Type} (f : α → α) (x : α) : Prop :=
  f x = x

def fixedPointOfIterate {α : Type} (f : α → α) (x : α) (n : Nat) :
    IsFixedPoint f (iterate f n x) → ∀ m, iterate f (n + m) x = iterate f n x :=
  by
    intro h
    induction m with
    | zero => simp [iterate]
    | succ m ih =>
      simp [iterate]
      rw [ih]
      exact h

-- ═══════════════════════════════════════════════════════════════
-- Lyapunov Stability
-- ═══════════════════════════════════════════════════════════════

def LyapunovFunction {α : Type} (f : α → α) (V : α → Nat) (x* : α) : Prop :=
  V x* = 0 ∧
  (∀ x, x ≠ x* → V x > 0) ∧
  (∀ x, V (f x) ≤ V x)

def IsStable {α : Type} (f : α → α) (x* : α) : Prop :=
  ∃ V, LyapunovFunction f V x*

-- ═══════════════════════════════════════════════════════════════
-- Asymptotic Stability
-- ═══════════════════════════════════════════════════════════════

def IsAsymptoticallyStable {α : Type} (f : α → α) (x* : α) : Prop :=
  IsStable f x* ∧
  ∀ x₀, ∃ N, ∀ n ≥ N, iterate f n x₀ = x*

-- ═══════════════════════════════════════════════════════════════
-- Chaos (Devaney definition)
-- ═══════════════════════════════════════════════════════════════

def SensitiveInitialConditions {α : Type} [DecidableEq α]
    (f : α → α) (d : α → α → Nat) : Prop :=
  ∃ ε > 0, ∀ x, ∃ y, ∃ n, d (iterate f n x) (iterate f n y) > ε

def TopologicallyTransitive {α : Type} [DecidableEq α]
    (f : α → α) : Prop :=
  ∀ U V, (∃ x, x ∈ U) → (∃ y, y ∈ V) →
    ∃ n, ∃ x ∈ U, iterate f n x ∈ V

def DensePeriodicOrbits {α : Type} [DecidableEq α]
    (f : α → α) : Prop :=
  ∀ x, ∃ n, ∃ y, IsFixedPoint (iterate f n) y ∧ d x y < 1

-- ═══════════════════════════════════════════════════════════════
-- Continuous Flows
-- ═══════════════════════════════════════════════════════════════

structure Flow (α : Type) where
  phi : Nat → α → α
  phi_zero : ∀ x, phi 0 x = x
  phi_add : ∀ s t x, phi (s + t) x = phi s (phi t x)

def EquilibriumPoint {α : Type} (φ : Flow α) (x : α) : Prop :=
  ∀ t, φ.phi t x = x

def PeriodicOrbit {α : Type} (φ : Flow α) (x : α) (T : Nat) : Prop :=
  T > 0 ∧ φ.phi T x = x ∧ ∀ 0 < t < T, φ.phi t x ≠ x

end Foundations.Dynamics
