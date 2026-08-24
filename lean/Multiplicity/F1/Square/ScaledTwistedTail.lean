/-
F1 square — **the `s`-scaled-window twisted tail** (`ScaledTwistedTail.lean`): the per-window-band
analog of the `mellinHat` twisted tail `twTail`, carried on the `s`-scaled windows
`[s·(m+1), s·(m+2)]`, and its proportionality to the dilated tail.

Unlike the committed finite `reschedule` (whose covering band depends on the truncation `N`), each
window here carries its OWN band `[0, (s+1)·(m+2)]` — a band covering BOTH the integer window
`[m+1, m+2]` and the scaled window `[s(m+1), s(m+2)]` — so the object is a genuine improper
half-line integral (a `Rlim` of window sums), not a finite reschedule.

- `scaledTwTerm φ s … n m` — the `m`-th scaled-window integral `∫_{s(m+1)}^{s(m+2)} (φ · powBandGen)`,
  the window integral of the algebra product against the wide-band power weight, over the `s`-scaled
  window. Its endpoints/weight match exactly the LHS of the committed per-window covariance.
- `scaledTwTerm_eq` — the KEY per-window bridge: `scaledTwTerm φ s … n m ≈ s^(n+1) · twTerm (dilate_s φ) n m`,
  i.e. `twTerm_dilate_window` instantiated at the concrete band `[0, (s+1)(m+2)]` (the four
  containments `hc1`–`hc4` discharged for that band).
- `genSum_scaled_eq` — the partial-sum proportionality `Σ_{m<N} scaledTwTerm ≈ s^(n+1) · Σ_{m<N} twTerm(dilate_s φ)`
  (`genSum_congr` on the per-window bridge, then the constant-pull `genSum_Rmul_const`).
- `scaledTwTail_eq_dilate` — the capstone: the `Rlim` of the scaled-window twisted sums equals
  `s^(n+1) · twTail (dilate_s φ)` (`Rlim_ofQ_mul_of_approx` on the partial-sum proportionality); the
  regular-witness `hReg` for the scaled sums and the dilated-test decay `hdec` are carried explicitly.

HONEST SCOPE. The `s`-scaled-window twisted tail (`scaledTwTerm`/`scaledTwTail_eq_dilate`, the
per-window-band analog of the `mellinHat` `twTail`) and its proportionality
`= s^(n+1) · twTail(dilate_s φ)`, via the committed per-window covariance `twTerm_dilate_window` and
the constant-pull. It builds NO boundary reconciliation (`[s,∞)` vs `[1,∞)`), NO compact
`mellinMoment` piece, NO full `mellinHat` covariance, NO factorization, NO positivity, NO
determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.TwTermDilateWindow
import Multiplicity.F1.Square.MellinHat
import Multiplicity.F1.Analysis.GenSumGeom
import Multiplicity.F1.Analysis.ComplexDigammaConj
import Multiplicity.F1.Analysis.RlimProps
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The concrete per-window upper endpoint `(s+1)·(m+2)` — dominates both `m+2` and `s·(m+2)`. -/
private def sbHi (s : Q) (m : Nat) : Q := mul (add s (⟨1, 1⟩ : Q)) (⟨(m : Int) + 2, 1⟩ : Q)

/-- The per-window band's upper endpoint has a positive denominator. -/
private theorem sbHi_den_pos (s : Q) (hsd : 0 < s.den) (m : Nat) : 0 < (sbHi s m).den :=
  Qmul_den_pos (add_den_pos hsd (Nat.one_pos)) (Nat.one_pos)

/-- `s ≤ s + 1`. -/
private theorem s_le_add_one (s : Q) : Qle s (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]
  push_cast
  have hd : (0 : Int) ≤ (s.den : Int) * (s.den : Int) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)
  have hexp : (s.num * 1 + 1 * (s.den : Int)) * (s.den : Int) - s.num * ((s.den : Int) * 1)
      = (s.den : Int) * (s.den : Int) := by ring_uor
  omega

/-- `1 ≤ s + 1` (from `0 ≤ s.num`). -/
private theorem one_le_add_one (s : Q) (hsn : 0 < s.num) : Qle (⟨1, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]
  push_cast
  have hsn' : (0 : Int) ≤ s.num := Int.le_of_lt hsn
  have hexp : (s.num * 1 + 1 * (s.den : Int)) * (1 : Int) - 1 * ((s.den : Int) * 1) = s.num * 1 := by
    ring_uor
  omega

/-- `m+2 ≤ (s+1)(m+2)`: the scaled window's right endpoint is covered (monotone right multiply). -/
private theorem sbHi_ge_mp2 (s : Q) (hsn : 0 < s.num) (m : Nat) :
    Qle (⟨(m : Int) + 2, 1⟩ : Q) (sbHi s m) := by
  have hmono : Qle (mul (⟨1, 1⟩ : Q) (⟨(m : Int) + 2, 1⟩ : Q)) (sbHi s m) :=
    qmul_le_right_mono (one_le_add_one s hsn) (by show (0 : Int) ≤ (m : Int) + 2; omega)
  refine Qle_congr_left (a := mul (⟨1, 1⟩ : Q) (⟨(m : Int) + 2, 1⟩ : Q))
    (Nat.mul_pos Nat.one_pos Nat.one_pos) ?_ hmono
  show Qeq (mul (⟨1, 1⟩ : Q) (⟨(m : Int) + 2, 1⟩ : Q)) (⟨(m : Int) + 2, 1⟩ : Q)
  simp only [Qeq, mul]
  push_cast
  ring_uor

/-- `s·(m+2) ≤ (s+1)(m+2)`: the scaled window's right endpoint is covered (monotone right multiply). -/
private theorem sbHi_cover_hi (s : Q) (m : Nat) :
    Qle (mul s (⟨(m : Int) + 2, 1⟩ : Q)) (sbHi s m) :=
  qmul_le_right_mono (s_le_add_one s) (by show (0 : Int) ≤ (m : Int) + 2; omega)

/-- `0 ≤ (s+1)(m+2)`: the zero lower endpoint lies below the band upper endpoint. -/
private theorem sbHi_ge_zero (s : Q) (hsn : 0 < s.num) (m : Nat) :
    Qle (⟨0, 1⟩ : Q) (sbHi s m) :=
  Qle_trans (b := (⟨(m : Int) + 2, 1⟩ : Q)) Nat.one_pos
    (by simp only [Qle]; push_cast; omega)
    (sbHi_ge_mp2 s hsn m)

/-- `0 ≤ s·(m+1)`: the scaled window's left endpoint is above the zero lower band endpoint. -/
private theorem sbLo_cover_scaled (s : Q) (hsn : 0 < s.num) (m : Nat) :
    Qle (⟨0, 1⟩ : Q) (mul s (⟨(m : Int) + 1, 1⟩ : Q)) := by
  simp only [Qle, mul]
  push_cast
  have hprod : (0 : Int) ≤ s.num * ((m : Int) + 1) * 1 :=
    Int.mul_nonneg (Int.mul_nonneg (Int.le_of_lt hsn) (by omega)) (by omega)
  omega

/-- **The `s`-scaled twisted window integral** `∫_{s(m+1)}^{s(m+2)} (φ · powBandGen_{[0,(s+1)(m+2)]})` —
    the `m`-th window integral of the algebra product against the wide-band power weight, over the
    `s`-scaled window `[s(m+1), s(m+2)]`. Endpoints/weight match the LHS of `twTerm_dilate_window`. -/
def scaledTwTerm (φ : L2Test) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) (n m : Nat) : Real :=
  riemannIntegralI
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (sbHi s m) (by decide) (sbHi_den_pos s hsd m)
        (sbHi_ge_zero s hsn m) (by decide) n)).hLd
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (sbHi s m) (by decide) (sbHi_den_pos s hsd m)
        (sbHi_ge_zero s hsn m) (by decide) n)).hLn
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (sbHi s m) (by decide) (sbHi_den_pos s hsd m)
        (sbHi_ge_zero s hsn m) (by decide) n)).hlip
    (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (sbHi s m) (by decide) (sbHi_den_pos s hsd m)
        (sbHi_ge_zero s hsn m) (by decide) n)).hfc
    (mul s (⟨(m : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
    (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
    (Int.mul_nonneg (Int.le_of_lt hsn) (by decide))

/-- **The per-window twisted dilation bridge**: the `s`-scaled twisted window integral equals
    `s^(n+1)` times the `mellinHat` tail term of the dilated test. Exactly `twTerm_dilate_window`
    at the concrete per-window band `[0, (s+1)(m+2)]` (its four containments discharged). -/
theorem scaledTwTerm_eq (φ : L2Test) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) (n m : Nat) :
    Req (scaledTwTerm φ s hsn hsd n m)
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (twTerm (dilateTest s hsn hsd φ) n m)) :=
  twTerm_dilate_window φ n m s hsn hsd (⟨0, 1⟩ : Q) (sbHi s m) (by decide)
    (sbHi_den_pos s hsd m) (sbHi_ge_zero s hsn m) (by decide)
    (by simp only [Qle]; push_cast; omega)
    (sbHi_ge_mp2 s hsn m)
    (sbLo_cover_scaled s hsn m)
    (sbHi_cover_hi s m)

/-- **The partial-sum proportionality**: the scaled twisted partial sums are `s^(n+1)` times the
    dilated-test twisted partial sums (`genSum_congr` on the per-window bridge, then the constant
    left-pull `genSum_Rmul_const`). -/
theorem genSum_scaled_eq (φ : L2Test) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) (n N : Nat) :
    Req (genSum (fun m => scaledTwTerm φ s hsn hsd n m) N)
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (genSum (fun m => twTerm (dilateTest s hsn hsd φ) n m) N)) :=
  Req_trans
    (genSum_congr _ _ (fun m => scaledTwTerm_eq φ s hsn hsd n m) N)
    (genSum_Rmul_const (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
      (fun m => twTerm (dilateTest s hsn hsd φ) n m) N)

/-- **The scaled twisted tail equals `s^(n+1) · (dilated twisted tail)`.** The `Rlim` of the
    scaled-window twisted sums (regular by the carried witness `hReg`) equals `s^(n+1)` times
    `twTail (dilate_s φ)`. `Rlim_ofQ_mul_of_approx` on the partial-sum proportionality
    `genSum_scaled_eq`; the dilated-test decay `hdec` supplies `twTail`. -/
theorem scaledTwTail_eq_dilate (φ : L2Test) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den) (n : Nat)
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest s hsn hsd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg : RReg (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) :
    Req (Rlim (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
          (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) hReg)
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (twTail (dilateTest s hsn hsd φ) n hCd hCn hdec)) :=
  Rlim_ofQ_mul_of_approx (qpow s (n + 1)) (qpow_den_pos hsd (n + 1))
    (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))
    (fun j => genSum (fun m => twTerm (dilateTest s hsn hsd φ) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))
    (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
      (Int.mul_nonneg hCn (Int.ofNat_nonneg _))
      (twTerm_bound (dilateTest s hsn hsd φ) n hCd hCn hdec))
    hReg
    (fun j => genSum_scaled_eq φ s hsn hsd n
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))

end Multiplicity.UOR.Bridge.F1Square.Square
