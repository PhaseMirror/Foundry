/-
F1 square — the **complex exponential** `Cexp z = exp(re z)·(cos(im z) + i·sin(im z))`, the first
brick of the v0.15.0 complex analytic engine (roadmap stage A).

Built directly on the real transcendentals `RexpReal` (ExpReal), `Rcos`/`Rsin` (CosSin) and the
complex ring `ℂ = ℝ×ℝ` (Complex): each component of `Cexp z` is a genuine constructive real, so `Cexp`
is a clean composition — no new regularity obligation. The argument-0 anchor (`Cexp 0 ≈ 1`), the `nˢ`
map, and `Czeta` build on this in subsequent bricks.

Pure Lean 4, no Mathlib, no `sorry`, choice-free.
-/

import F1Square.Analysis.Complex
import F1Square.Analysis.CosSin
import F1Square.Analysis.ExpReal
import F1Square.Analysis.ExpGen

namespace UOR.Bridge.F1Square.Analysis

/-- **The complex exponential** `e^z = e^{re z}·(cos(im z) + i·sin(im z))`. Each component is a genuine
    constructive real built from `RexpReal`, `Rcos`, `Rsin`, so this is a clean composition. -/
def Cexp (z : Complex) : Complex :=
  ⟨Rmul (RexpReal z.re) (Rcos z.im), Rmul (RexpReal z.re) (Rsin z.im)⟩

/-- `Re(e^z) = e^{re z}·cos(im z)`. -/
theorem Cexp_re (z : Complex) : (Cexp z).re = Rmul (RexpReal z.re) (Rcos z.im) := rfl

/-- `Im(e^z) = e^{re z}·sin(im z)`. -/
theorem Cexp_im (z : Complex) : (Cexp z).im = Rmul (RexpReal z.re) (Rsin z.im) := rfl

-- ===========================================================================
-- The argument-0 anchor `Cexp 0 ≈ 1` (the series collapse to their constant term).
-- ===========================================================================

/-- `qⁿ⁺¹` has zero numerator whenever the base does (cf. `qpow_zero_succ_num`, general base). -/
theorem qpow_num_zero {q : Q} (hq : q.num = 0) (n : Nat) : (qpow q (n + 1)).num = 0 := by
  show (mul q (qpow q n)).num = 0
  simp only [mul]; rw [hq]; simp

/-- Every cosine series term beyond the constant `1` vanishes at `0` (the `−q²` base has num `0`). -/
theorem altTerm_cos_zero_num (n : Nat) : (altTerm (⟨0, 1⟩ : Q) 0 (n + 1)).num = 0 := by
  show (qpow (neg (mul (⟨0, 1⟩ : Q) ⟨0, 1⟩)) (n + 1)).num * (1 : Int) = 0
  rw [qpow_num_zero (by decide) n]; simp

/-- `altSum 0 0 N ≈ 1` (the cosine series at `0`: only the `k = 0` term survives). -/
theorem altSum_cos_zero : ∀ N, Qeq (altSum (⟨0, 1⟩ : Q) 0 N) ⟨1, 1⟩
  | 0 => by decide
  | (n + 1) =>
      Qeq_trans (altSum_den_pos (by decide) 0 n)
        (Qeq_add_zero_num (altTerm_cos_zero_num n)) (altSum_cos_zero n)

/-- **`exp 0 ≈ 1`** on the everywhere-defined real exponential. -/
theorem RexpReal_zero : Req (RexpReal zero) one := fun n =>
  Qle_Qabs_Qsub_of_Qeq (expSum_zero_eq (RexpReal_R zero n)) (by show (0 : Int) ≤ 2; decide)

/-- **`cos 0 ≈ 1`**. -/
theorem Rcos_zero : Req (Rcos zero) one := fun n =>
  Qle_Qabs_Qsub_of_Qeq (altSum_cos_zero (RaltReal_R zero n)) (by show (0 : Int) ≤ 2; decide)

/-- **`sin 0 ≈ 0`** (`sin x = x · (sin x / x)`, and `0 · _ ≈ 0`). -/
theorem Rsin_zero : Req (Rsin zero) zero :=
  Req_trans (Rmul_comm zero (RsinAux zero)) (Rmul_zero (RsinAux zero))

/-- **`Cexp 0 ≈ 1`** — the complex exponential at the origin. -/
theorem Cexp_zero : Ceq (Cexp Czero) Cone :=
  ⟨Req_trans (Rmul_congr RexpReal_zero Rcos_zero) (Rmul_one one),
   Req_trans (Rmul_congr (Req_refl (RexpReal zero)) Rsin_zero) (Rmul_zero (RexpReal zero))⟩

end UOR.Bridge.F1Square.Analysis
