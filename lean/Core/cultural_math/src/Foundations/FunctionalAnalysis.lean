/-
  Foundations/FunctionalAnalysis.lean
  Normed spaces, Banach/Hilbert spaces, bounded linear operators.
  No mathlib dependency.
-/

import Foundations.Basic
import Foundations.Topology

namespace Foundations.FunAnalysis

-- ═══════════════════════════════════════════════════════════════
-- Normed Space
-- ═══════════════════════════════════════════════════════════════

structure NormedSpace (α : Type) where
  add : α → α → α
  smul : Nat → α → α
  norm : α → Real
  norm_nonneg : ∀ x, 0 ≤ norm x
  norm_eq_zero : ∀ x, norm x = 0 → x = 0
  norm_triangle : ∀ x y, norm (add x y) ≤ norm x + norm y
  norm_smul : ∀ c x, norm (smul c x) = c * norm x

-- ═══════════════════════════════════════════════════════════════
-- Banach Space (complete normed space)
-- ═══════════════════════════════════════════════════════════════

structure BanachSpace (α : Type) extends NormedSpace α where
  complete : ∀ (seq : Nat → α),
    (∀ ε > 0, ∃ N, ∀ m n ≥ N, norm (seq m - seq n) < ε) →
    ∃ limit, ∀ ε > 0, ∃ N, ∀ n ≥ N, norm (seq n - limit) < ε

-- ═══════════════════════════════════════════════════════════════
-- Hilbert Space (inner product space)
-- ═══════════════════════════════════════════════════════════════

structure HilbertSpace (α : Type) extends BanachSpace α where
  inner : α → α → Real
  inner_symm : ∀ x y, inner x y = inner y x
  inner_linear : ∀ x y z c, inner (add x y) z = inner x z + inner y z
  inner_pos : ∀ x, inner x x ≥ 0
  inner_eq_norm : ∀ x, inner x x = norm x * norm x

-- ═══════════════════════════════════════════════════════════════
-- Bounded Linear Operator
-- ═══════════════════════════════════════════════════════════════

structure BoundedLinearOp (α β : Type)
    (normα : NormedSpace α) (normβ : NormedSpace β) where
  toFun : α → β
  linear : ∀ x y c, toFun (normα.smul c x + y) = normβ.smul c (toFun x) + toFun y
  bounded : ∃ M, ∀ x, normβ.norm (toFun x) ≤ M * normα.norm x

-- ═══════════════════════════════════════════════════════════════
-- Operator Norm
-- ═══════════════════════════════════════════════════════════════

def operatorNorm {α β : Type}
    {normα : NormedSpace α} {normβ : NormedSpace β}
    (T : BoundedLinearOp α β normα normβ) : Real :=
  Inf { M : Real | ∀ x, normβ.norm (T.toFun x) ≤ M * normα.norm x }

end Foundations.FunAnalysis
