/-
  Specifications/DynamicsSpec.lean
  Predicates for recursive updates and dynamical systems.
  Shared with Rust verification.
  No mathlib dependency.
-/

import Foundations.Basic
import Foundations.DynamicalSystems

namespace Specifications.Dynamics

-- ═══════════════════════════════════════════════════════════════
-- Valid Iteration
-- ═══════════════════════════════════════════════════════════════

def ValidIteration {α : Type} (f : α → α) (x₀ : α) (n : Nat) (result : α) : Prop :=
  result = Foundations.Dynamics.iterate f n x₀

-- ═══════════════════════════════════════════════════════════════
-- Halving Convergence Spec
-- ═══════════════════════════════════════════════════════════════

def HalvingConverges (n : Nat) : Prop :=
  ∃ k, Nat.repeat (· / 2) k n = 0

-- ═══════════════════════════════════════════════════════════════
-- Lyapunov Decrease Spec
-- ═══════════════════════════════════════════════════════════════

def LyapunovDecrease {α : Type} (f : α → α) (V : α → Nat) (x : α) : Prop :=
  V (f x) ≤ V x

-- ═══════════════════════════════════════════════════════════════
-- Fixed Point Spec
-- ═══════════════════════════════════════════════════════════════

def FixedPointSpec {α : Type} (f : α → α) (x : α) : Prop :=
  f x = x

-- ═══════════════════════════════════════════════════════════════
-- Periodicity Spec
-- ═══════════════════════════════════════════════════════════════

def PeriodicSpec {α : Type} [DecidableEq α] (f : α → α) (x : α) (period : Nat) : Prop :=
  period > 0 ∧
  (∀ t, Foundations.Dynamics.iterate f (t + period) x = Foundations.Dynamics.iterate f t x) ∧
  (∀ 0 < p < period, Foundations.Dynamics.iterate f p x ≠ x)

-- ═══════════════════════════════════════════════════════════════
-- Cultural Algorithm Specs
-- ═══════════════════════════════════════════════════════════════

-- Babylonian square root convergence
def BabylonianSqrtSpec (S x result : Nat) : Prop :=
  x ≤ S → x ≥ 1 → result = (x + S / x) / 2 ∧ result ≤ S

-- Egyptian doubling/halving
def EgyptianMulSpec (a b result : Nat) : Prop :=
  result = a * b

-- Chinese CRT
def ChineseCRTSpec (n₁ n₂ a₁ a₂ result : Nat) : Prop :=
  n₁ ≥ 2 → n₂ ≥ 2 →
  result % n₁ = a₁ % n₁ ∧ result % n₂ = a₂ % n₂

-- Vedic multiplication
def VedicMulSpec (a b base result : Nat) : Prop :=
  result = (base + a) * (base + b)

end Specifications.Dynamics
