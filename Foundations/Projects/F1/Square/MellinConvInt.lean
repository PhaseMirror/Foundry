/-
F1 square — **the integer-exponent Mellin transform of the convolution** (`MellinConvInt.lean`): the
Mellin pairing of the convolution against the window power weight `tⁿ`, on the half-line window
`[m+1, m+2]`:

    `mellinConvInt f g m n = ∫_{m+1}^{m+2} (f ⋆ g)(x)·xⁿ dx`   (= `M[f⋆g]` at integer exponent `n`,
    window `m`, on the window where the clamps are inert).

`powWinTest m n` (`WindowPower`) is exactly `tⁿ` clamped to `[m+1, m+2]`, a genuine `L2Test`; the
transform is `mellinConv f g (powWinTest m n)` at that window. `mellinConvInt_nonneg`: for non-negative
`f, g` (e.g. the autocorrelation `g ⋆ g^τ`) the transform is `≥ 0` at every integer exponent — the
positivity of the transform of a non-negative convolution.

HONEST SCOPE. The transform evaluated at integer exponents, non-negative on non-negative data. It is
NOT the convolution theorem `M[f⋆g] = M[f]·M[g]` (Wall 3, the deep two-variable/Fubini step) — the
identity that would turn `mulConv` values at prime powers into `weilPrimeGram (vFrom g)`, i.e.
step 4 = RH. This file evaluates the transform; it proves no product identity about it. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinConv
import Foundations.F1.Square.WindowPower

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The window band-clamp `[m+1, m+2]` is non-negative (`≥ m+1 > 0`). -/
theorem bandTest_nonneg (m : Nat) (x : Real) : Rnonneg ((bandTest m).f x) := by
  intro n
  refine Qle_trans Nat.one_pos ?_ (qBandQ_ge (⟨(m : Int) + 1, 1⟩ : Q)
    (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos Nat.one_pos
    (by show Qle (⟨(m : Int) + 1, 1⟩ : Q) (⟨(m : Int) + 2, 1⟩ : Q)
        simp only [Qle]; push_cast; omega) x n)
  show Qle (neg (Qbound n)) (⟨(m : Int) + 1, 1⟩ : Q)
  simp only [Qle, neg, Qbound]; push_cast
  have hp : (0 : Int) ≤ ((m : Int) + 1) * ((n : Int) + 1) :=
    Int.mul_nonneg (by omega) (by omega)
  omega

/-- The window power `tⁿ`-clamp is non-negative (a product of non-negatives). -/
theorem powWinTest_nonneg (m n : Nat) (x : Real) : Rnonneg ((powWinTest m n).f x) := by
  induction n with
  | zero => rw [powWinTest_zero]; exact Rnonneg_one
  | succ k ih => exact Rnonneg_Rmul ih (bandTest_nonneg m x)

/-- **The integer-exponent Mellin transform of the convolution** `mellinConvInt f g m n =
    ∫_{m+1}^{m+2} (f⋆g)(x)·xⁿ dx` — the Mellin pairing against the window power `powWinTest m n`, on the
    half-line window `[m+1, m+2]`. -/
def mellinConvInt (f g : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (m n : Nat) : Real :=
  mellinConv f g (powWinTest m n) S hSd hSn a han had lo w hlo hw hwn
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)

/-- **The Mellin transform of a non-negative convolution is non-negative at every integer exponent**
    — `mulConvR_nonneg` for the convolution factor, `powWinTest_nonneg` for the power weight. This is
    the sign the autocorrelation `g ⋆ g^τ` carries into its transform. -/
theorem mellinConvInt_nonneg (f g : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (m n : Nat)
    (hf : ∀ y, Rnonneg (f.f y)) (hg : ∀ y, Rnonneg (g.f y)) :
    Rnonneg (mellinConvInt f g S hSd hSn a han had lo w hlo hw hwn m n) :=
  mellinConv_nonneg f g (powWinTest m n) S hSd hSn a han had lo w hlo hw hwn
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)
    hf hg (powWinTest_nonneg m n)

end Multiplicity.UOR.Bridge.F1Square.Square
