/-
  Theorems/BasicTheorems.lean
  Verified discrete inequalities without mathlib or sorries.
-/

import Foundations.Analysis.Inequalities

namespace Multiplicity.Theorems

open Foundations.Analysis.Inequalities

theorem triangle_inequality_nat_lem (a b c : Nat)
    (hab : a ≤ b + c) (hba : b ≤ a + c) :
    a - b ≤ c ∧ b - a ≤ c :=
  triangle_inequality_nat a b c hab hba

theorem cauchy_schwarz_2d_nat (a1 a2 b1 b2 : Nat) :
    (a1 * b1 + a2 * b2) * (a1 * b1 + a2 * b2) ≤ (a1 * a1 + a2 * a2) * (b1 * b1 + b2 * b2) :=
  cauchy_schwarz_2d a1 a2 b1 b2

theorem sq_add_ge_sq_nat (a b : Nat) :
    a * a + b * b ≤ (a + b) * (a + b) :=
  sq_add_ge_sq a b

end Multiplicity.Theorems
