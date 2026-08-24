/-
F1 square — **the pre-Hilbert layer** (`RationalWindowPower.lean`): **the window power
substrate on an ARBITRARY rational window** — the band-clamped identity on a general
rational band `[lo, hi]` and its iterated powers, as members of the test algebra.

`WindowPower.lean` builds the same object clamped to the *integer* window `[m+1, m+2]`
(`powWinTest`). But dilating that integer window by a rational scale `s` carries it to the
rational window `[s·(m+1), s·(m+2)]`, on which the integer-indexed `powWinTest` is WRONG
(it is clamped to `[m+1, m+2]`). This brick generalizes the endpoints `m+1, m+2` to arbitrary
rationals `lo, hi` with `0 ≤ lo ≤ hi`, producing exactly the weight object the per-window
Mellin dilation covariance consumes:

- `bandGen lo hi …` — the identity clamped to `[lo, hi]` (the `qBandQ` band): a genuine
  `L2Test` (1-Lipschitz, bounded by `hi`), INERT on its window
  (`bandGen_inert`: `≈ t` where `lo ≤ t ≤ hi`).
- `powBandGen lo hi …` — its `n`-th power by iterated `L2Test.mul`: certificates compose
  automatically through the algebra, and `powBandGen_succ_inert` shows it is `tⁿ` on the
  window (recursively `≈ (previous)·t`, base `≡ 1`). The accumulated bound field is at most
  `hiⁿ` (`powBandGen_M_le`, the `qpow` of the upper endpoint).

HONEST SCOPE. The windowed power `tⁿ` generalized from integer windows to an arbitrary
rational window `[lo, hi]` (`powBandGen`), clamped/inert on its window exactly like
`powWinTest`, with the `hiⁿ` bound. It builds NO integral, NO dilation covariance, NO
factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is
RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.WindowPower

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The upper endpoint of a non-negative rational band has a non-negative numerator:
    `0 ≤ lo.num` and `lo ≤ hi` force `0 ≤ hi.num`. -/
private theorem qhi_num_nonneg {lo hi : Q} (hlod : 0 < lo.den) (hle : Qle lo hi)
    (hlon : 0 ≤ lo.num) : 0 ≤ hi.num := by
  simp only [Qle] at hle
  have h1 : (0 : Int) ≤ lo.num * (hi.den : Int) := Int.mul_nonneg hlon (Int.ofNat_nonneg _)
  have h2 : (0 : Int) ≤ hi.num * (lo.den : Int) := Int.le_trans h1 hle
  have hd : (0 : Int) < (lo.den : Int) := by exact_mod_cast hlod
  rcases (by omega : hi.num < 0 ∨ 0 ≤ hi.num) with h | h
  · exact absurd h2 (by have := Int.mul_neg_of_neg_of_pos h hd; omega)
  · exact h

/-- **The band-clamped identity on `[lo, hi]`** — the general-window copy of the identity as a
    genuine test: 1-Lipschitz, bounded by `hi`, inert on the window. -/
def bandGen (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi)
    (hlon : 0 ≤ lo.num) : L2Test where
  f := qBandQ lo hi hlod hhid
  L := ⟨1, 1⟩
  M := hi
  hLd := by decide
  hLn := by decide
  hMd := hhid
  hMn := qhi_num_nonneg hlod hle hlon
  hlip := fun x y =>
    Rle_trans (qBandQ_lipschitz lo hi hlod hhid x y)
      (Rle_of_Req (Req_symm (Req_trans (Rmul_comm _ _) (Rmul_one (Rabs (Rsub x y))))))
  hfc := fun _ _ h => qBandQ_congr lo hi hlod hhid h
  hbd := fun x => by
    have hnn : Rnonneg (qBandQ lo hi hlod hhid x) := by
      intro n
      refine Qle_trans hlod ?_ (qBandQ_ge lo hi hlod hhid hle x n)
      show Qle (neg (Qbound n)) lo
      simp only [Qle, neg, Qbound]
      push_cast
      have hp : (0 : Int) ≤ lo.num * ((n : Int) + 1) :=
        Int.mul_nonneg hlon (by omega)
      have hd : (0 : Int) ≤ (lo.den : Int) := Int.ofNat_nonneg _
      omega
    have hle' : Rle (qBandQ lo hi hlod hhid x) (ofQ hi hhid) := by
      intro n
      refine Qle_trans hhid (qBandQ_le lo hi hlod hhid x n) ?_
      show Qle hi (add hi (⟨2, n + 1⟩ : Q))
      simp only [Qle, add]
      push_cast
      have key : (hi.num * ((n : Int) + 1) + 2 * (hi.den : Int)) * (hi.den : Int)
          = hi.num * ((hi.den : Int) * ((n : Int) + 1)) + 2 * ((hi.den : Int) * (hi.den : Int)) := by
        ring_uor
      rw [key]
      have hc : (0 : Int) ≤ 2 * ((hi.den : Int) * (hi.den : Int)) :=
        Int.mul_nonneg (by decide) (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
      omega
    exact Rle_trans (Rle_of_Req (Rabs_of_nonneg hnn)) hle'

/-- **The band is inert on its window**: `bandGen lo hi ≈ t` for `lo ≤ t ≤ hi`. -/
theorem bandGen_inert (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi)
    (hlon : 0 ≤ lo.num) {x : Real}
    (hlo : Rle (ofQ lo hlod) x) (hhi : Rle x (ofQ hi hhid)) :
    Req ((bandGen lo hi hlod hhid hle hlon).f x) x :=
  qBandQ_eq_of_band hlo hhi

/-- **The rational-window power** `tⁿ` on `[lo, hi]` — iterated product in the test algebra:
    certificates compose automatically. -/
def powBandGen (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi)
    (hlon : 0 ≤ lo.num) : Nat → L2Test
  | 0 => oneTest
  | n + 1 => L2Test.mul (powBandGen lo hi hlod hhid hle hlon n) (bandGen lo hi hlod hhid hle hlon)

/-- The zeroth window power is the constant `1` (definitional). -/
theorem powBandGen_zero (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi)
    (hlon : 0 ≤ lo.num) (x : Real) :
    (powBandGen lo hi hlod hhid hle hlon 0).f x = one := rfl

/-- **The window power is inert on its window, recursively**: for `lo ≤ t ≤ hi`,
    `(powBandGen … (n+1)) t ≈ (powBandGen … n) t · t` — with the base `≡ 1`, the window power
    IS `tⁿ` on the window. -/
theorem powBandGen_succ_inert (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den)
    (hle : Qle lo hi) (hlon : 0 ≤ lo.num) (n : Nat) {x : Real}
    (hlo : Rle (ofQ lo hlod) x) (hhi : Rle x (ofQ hi hhid)) :
    Req ((powBandGen lo hi hlod hhid hle hlon (n + 1)).f x)
      (Rmul ((powBandGen lo hi hlod hhid hle hlon n).f x) x) :=
  Rmul_congr (Req_refl _) (bandGen_inert lo hi hlod hhid hle hlon hlo hhi)

/-- **The accumulated bound of the rational-window power is at most `hiⁿ`** — the datum the
    twisted tail's convergence estimate consumes. -/
theorem powBandGen_M_le (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi)
    (hlon : 0 ≤ lo.num) :
    ∀ n, Qle ((powBandGen lo hi hlod hhid hle hlon n).M) (qpow hi n)
  | 0 => by
    show Qle (⟨1, 1⟩ : Q) (qpow hi 0)
    show (1 : Int) * ((qpow hi 0).den : Int) ≤ (qpow hi 0).num * (1 : Int)
    rw [show qpow hi 0 = (⟨1, 1⟩ : Q) from rfl]
    decide
  | n + 1 => by
    have ih := powBandGen_M_le lo hi hlod hhid hle hlon n
    have hhin : 0 ≤ hi.num := qhi_num_nonneg hlod hle hlon
    show Qle (mul ((powBandGen lo hi hlod hhid hle hlon n).M) hi) (qpow hi (n + 1))
    have h1 : Qle (mul ((powBandGen lo hi hlod hhid hle hlon n).M) hi)
        (mul (qpow hi n) hi) :=
      qmul_le_right_mono ih hhin
    refine Qle_trans (Qmul_den_pos (qpow_den_pos hhid n) hhid) h1 (Qeq_le ?_)
    rw [qpow_succ]
    show ((qpow hi n).num * hi.num) * ((mul hi (qpow hi n)).den : Int)
        = (mul hi (qpow hi n)).num * ((mul (qpow hi n) hi).den : Int)
    simp only [mul]
    push_cast
    ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
