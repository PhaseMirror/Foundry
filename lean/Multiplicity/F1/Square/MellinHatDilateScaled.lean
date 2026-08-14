/-
F1 square — **the scaled Mellin transform of a dilated test** (`MellinHatDilateScaled.lean`):
assembling the committed compact and tail dilation halves into a single identity for
`s^(n+1) · mellinHat (dilate_s φ)`.

`mellinHat` splits as `mellinMoment + twTail` (compact `[0,1]` piece plus twisted tail). The two
committed dilation halves scale each piece:

- `mellinMoment_dilate` : `∫_0^s (φ · powBandGen) = s^(n+1) · mellinMoment (dilate_s φ) n`;
- `scaledTwTail_eq_dilate` : `Rlim (scaled twisted sums) = s^(n+1) · twTail (dilate_s φ) n`.

Distributing `s^(n+1)` over the `mellinHat` split (`Rmul_distrib`) and rewriting each summand by its
half gives the scaled Mellin transform of the dilated test as the sum of the scaled compact integral
over `[0,s]` and the scaled twisted tail:

    `s^(n+1) · mellinHat (dilate_s φ) n  =  ∫_0^s (φ · powBandGen)  +  Rlim (scaled twisted sums)`.

The right-hand side is the improper Mellin integral of the ORIGINAL `φ` against `tⁿ`, exhausted by
the `s`-uniform tiling `{[0,s], [s,2s], [2s,3s], …}`. Identifying that `s`-tiling improper integral
with `mellinHat φ` (the standard integer-tiling one) is the split-point/tiling-independence step,
which is a LATER brick; this brick only assembles the two committed halves.

HONEST SCOPE. The scaled Mellin transform of a dilated test as the sum of the scaled compact
integral and the scaled twisted tail — `s^(n+1)·mellinHat(dilate_s φ) = ∫_0^s(φ·powBandGen) + Rlim`,
by `Rmul_distrib` over the `mellinHat` split and the committed `mellinMoment_dilate` /
`scaledTwTail_eq_dilate`. It builds NO split-point/tiling independence, NO identification with
`mellinHat φ`, NO factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CompactMomentDilate
import Multiplicity.F1Square.Square.ScaledTwistedTail

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The wide band `[0, s+1]` low-end containment `0 ≤ s + 1` (own proof; proof-irrelevant to the
    private one inside `CompactMomentDilate`, so the `powBandGen` terms coincide definitionally). -/
private theorem band01_le' {s : Q} (hsn : 0 < s.num) :
    Qle (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast; omega

/-- **The scaled Mellin transform of a dilated test.** With the dilated-test decay `hdec` (the
    hypothesis under which `twTail (dilate_s φ)` — hence `mellinHat (dilate_s φ)` — is defined) and
    the regular-witness `hReg` for the scaled twisted sums,

      `s^(n+1) · mellinHat (dilate_s φ) n = ∫_0^s (φ · powBandGen_{[0,s+1]}) + Rlim (scaled sums)`.

    Distributes `s^(n+1)` over `mellinHat = mellinMoment + twTail` (`Rmul_distrib`) and rewrites the
    compact summand by `mellinMoment_dilate` and the tail summand by `scaledTwTail_eq_dilate`. -/
theorem mellinHat_dilate_scaled (φ : L2Test) (n : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest s hsn hsd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg : RReg (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) :
    Req
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (mellinHat (dilateTest s hsn hsd φ) n hCd hCn hdec))
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le' hsn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le' hsn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le' hsn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le' hsn) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide))
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (Rlim (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
          (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) hReg)) := by
  refine Req_trans
    (Rmul_distrib (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
      (mellinMoment (dilateTest s hsn hsd φ) n)
      (twTail (dilateTest s hsn hsd φ) n hCd hCn hdec)) ?_
  exact Radd_congr
    (Req_symm (mellinMoment_dilate φ n s hsn hsd))
    (Req_symm (scaledTwTail_eq_dilate φ s hsn hsd n hCd hCn hdec hReg))

end Multiplicity.UOR.Bridge.F1Square.Square
