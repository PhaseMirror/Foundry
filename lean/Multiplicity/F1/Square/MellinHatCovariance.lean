/-
F1 square — **the half-line Mellin dilation covariance capstone** (`MellinHatCovariance.lean`):
naming the dilation covariance `s^(n+1) · mellinHat (dilate_s φ) n = mellinHat φ n` and isolating the
one remaining analytic step — tiling-independence — as an explicit, audit-visible hypothesis.

The committed `mellinHat_dilate_scaled` already delivers

    `s^(n+1) · mellinHat (dilate_s φ) n  =  ∫_{[0,s]} (φ · powBandGen_{[0,s+1]})  +  Rlim (scaled sums)`,

whose right-hand side is the improper Mellin integral of the ORIGINAL `φ` against `tⁿ`, exhausted by
the `s`-uniform tiling `{[0,s], [s,2s], [2s,3s], …}`. What remains is TILING-INDEPENDENCE: that this
`s`-uniform-tiling improper integral equals `mellinHat φ n` (the standard integer-tiling one,
`∫_{[0,1]}(φ·tⁿ)` plus the tail over `{[1,2],[2,3],…}`). Both tilings exhaust `[0,∞)` against the same
integrand `φ·tⁿ`, so this is a genuine real-analysis fact (comparison of two cofinal exhaustions),
NOT RH.

This brick assembles the covariance MODULO that fact, carried as the explicit hypothesis `htile`
(whose left-hand side is written to match `mellinHat_dilate_scaled`'s right-hand side verbatim). This
is the program's standard honest-hypothesis pattern — `mellinHat` itself carries its decay `hdec`, the
crux carries its `hmatch` — with `htile` a genuine non-RH analytic fact carried audit-visibly and
discharged by a later cap-`Rlim` / exhaustion-rung brick. Composing the two by `Req_trans` names the
covariance and pins the exact remaining gap.

HONEST SCOPE. The half-line Mellin dilation covariance
`s^(n+1)·mellinHat(dilate_s φ) = mellinHat(φ)`, assembled from the committed
`mellinHat_dilate_scaled` modulo an explicit tiling-independence hypothesis `htile` — a genuine
non-RH real-analysis fact (comparison of the `s`-uniform and integer exhaustions of `[0,∞)` against
the common integrand `φ·tⁿ`) carried audit-visibly in the honest-hypothesis pattern, NOT a smuggle.
It builds NO factorization (`M[f⋆g]=M[f]·M[g]`), NO positivity, NO determinacy, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinHatDilateScaled
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The wide band `[0, s+1]` low-end containment `0 ≤ s + 1` (own proof; `Qle` is a `Prop` over
    `Int ≤`, hence proof-irrelevant, so this coincides definitionally with the private
    `band01_le'` inside `MellinHatDilateScaled` and the two `powBandGen` weights are the same term). -/
private theorem band01_le'' {s : Q} (hsn : 0 < s.num) :
    Qle (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) := by
  simp only [Qle, add]; push_cast; omega

/-- **THE HALF-LINE MELLIN DILATION COVARIANCE.** With the dilated-test decay `hdec_dil`, the
    original-test decay `hdec_phi`, the regular witness `hReg` for the scaled twisted sums, and the
    explicit tiling-independence hypothesis `htile` — that the `s`-uniform-tiling improper Mellin
    integral `∫_{[0,s]}(φ·powBandGen) + Rlim(scaled sums)` equals the standard integer-tiling
    `mellinHat φ n` —

      `s^(n+1) · mellinHat (dilate_s φ) n  =  mellinHat φ n`.

    `Req_trans` composes the committed `mellinHat_dilate_scaled` (which rewrites the left-hand side as
    the `s`-uniform improper integral) with `htile` (which identifies that improper integral with
    `mellinHat φ n`). The hypothesis `htile` is a genuine non-RH real-analysis fact — both tilings
    exhaust `[0,∞)` against the common integrand `φ·tⁿ` — carried audit-visibly in the program's
    honest-hypothesis pattern, to be discharged by a later cap-`Rlim` / exhaustion-rung brick. -/
theorem mellinHat_dilate_covariance (φ : L2Test) (n : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_dil : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest s hsn hsd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg : RReg (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)))
    (htile : Req
      (Radd
        (riemannIntegralI
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le'' hsn) (by decide) n)).hLd
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le'' hsn) (by decide) n)).hLn
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le'' hsn) (by decide) n)).hlip
          (L2Test.mul φ (powBandGen (⟨0, 1⟩ : Q) (add s (⟨1, 1⟩ : Q)) (by decide)
            (add_den_pos hsd (by decide)) (band01_le'' hsn) (by decide) n)).hfc
          (mul s (⟨0, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
          (Qmul_den_pos hsd (by decide)) (Qmul_den_pos hsd (by decide))
          (Int.mul_nonneg (Int.le_of_lt hsn) (by decide)))
        (Rlim (fun j => genSum (fun m => scaledTwTerm φ s hsn hsd n m)
          (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) hReg))
      (mellinHat φ n hCd hCn hdec_phi)) :
    Req
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (mellinHat (dilateTest s hsn hsd φ) n hCd hCn hdec_dil))
      (mellinHat φ n hCd hCn hdec_phi) :=
  Req_trans (mellinHat_dilate_scaled φ n s hsn hsd hCd hCn hdec_dil hReg) htile

end Multiplicity.UOR.Bridge.F1Square.Square
