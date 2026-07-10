/-
F1 square — **`nˢ` for an integer base `n ≥ 2`** and its **modulus** `|nˢ|² = (exp(Re s · log n))²`.
Defines `nˢ = Cexp(s · log n)` (with `log n` the real logarithm of `n` via `RlogPos`), and reads off the
squared modulus directly from the `Cexp` modulus identity (`Cexp_normSq`, itself a consequence of
`cos²+sin²=1`): the modulus depends only on `Re s`. This is the basis of the `ζ` tail bound for `Re s > 1`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.ComplexMod
import F1Square.Analysis.Log

namespace UOR.Bridge.F1Square.Analysis

/-- The natural number `n` as a (constant) real. -/
def RofNat (n : Nat) : Real := ofQ ⟨(n : Int), 1⟩ Nat.one_pos

/-- **The real logarithm of an integer `n ≥ 2`**, `log n` — via `RlogPos` with the positivity witness `1 < n`. -/
def RlogNat (n : Nat) (hn : 2 ≤ n) : Real :=
  RlogPos (RofNat n) 0 (by
    show (1 : Int) * (((⟨(n : Int), 1⟩ : Q)).den : Int) < (n : Int) * ((Qbound 0).den : Int)
    have : (2 : Int) ≤ (n : Int) := by exact_mod_cast hn
    simp only [Qbound]; omega)

/-- **`nˢ` for an integer base `n ≥ 2`**: `Cexp(s · log n)` written componentwise `⟨Re s · log n, Im s · log n⟩`. -/
def ncpow (n : Nat) (hn : 2 ≤ n) (s : Complex) : Complex :=
  Cexp ⟨Rmul s.re (RlogNat n hn), Rmul s.im (RlogNat n hn)⟩

/-- **The `nˢ` modulus identity**: `|nˢ|² = (exp(Re s · log n))²`. The squared modulus depends only on
    `Re s` (the imaginary rotation `cos(Im s·log n) + i·sin(…)` has unit modulus, by `cos²+sin²=1`). -/
theorem ncpow_normSq (n : Nat) (hn : 2 ≤ n) (s : Complex) :
    Req (CnormSq (ncpow n hn s))
      (Rmul (RexpReal (Rmul s.re (RlogNat n hn))) (RexpReal (Rmul s.re (RlogNat n hn)))) :=
  Cexp_normSq ⟨Rmul s.re (RlogNat n hn), Rmul s.im (RlogNat n hn)⟩

end UOR.Bridge.F1Square.Analysis
