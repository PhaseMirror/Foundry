/-
F1 square — **the real-scale Mellin dilation covariance with the rational covariance DERIVED**
(`MellinHatDilateCovarianceRealDerived.lean`): the real-scale covariance
`cⁿ⁺¹·mellinHat(dilateTestR c φ) = mellinHat φ`, with the "covariance holds at each rational
approximant" hypothesis (`hcov` of `mellinHat_dilate_covariance_real`) now DERIVED rather than assumed.

The base capstone `mellinHat_dilate_covariance_real` takes two hypotheses: `hcov` (the rational-scale
covariance at the approximants) and `hbound` (the continuity gap is a null family). This refinement
discharges `hcov` from the more primitive, checkable decay data — the per-approximant decay bounds
`hdec_qk`/`hdec_fine_qk` and the schedule regularity `hReg_qk` — through the unconditional
`covariance_at_rational_dilateTestR` (whose scalar `ofQ (qpow q (n+1))` is bridged to the capstone's
`Rpow (ofQ q) (n+1)` by `Rpow_ofQ`). So the covariance is no longer *assumed* on the rationals; it is
*established* there from the tiling-based unconditional covariance, and only `hbound` (the
fast-approximation continuity rate) remains an explicit input.

HONEST SCOPE. Object-grounding substrate — the real-scale covariance with `hcov` discharged. `hbound`
(the fast-enough approximation) remains an explicit, dischargeable hypothesis (the diagonal
`q_k = c.seq(fast(k))` construction is deferred). It builds NO factorization theorem, NO grounding of
`v = ĝ`, and — emphatically — NO step-4 band-coupling positivity (`ArchDominatesPrime`), which is RH.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinHatDilateCovarianceReal
import Multiplicity.F1.Analysis.RealPow
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Real-scale covariance with the rational-scale covariance hcov DERIVED (not assumed): the primitive
    decay data (hdec_qk / hdec_fine_qk / hReg_qk) at each positive rational approximant discharge hcov
    through covariance_at_rational_dilateTestR + the Rpow_ofQ scalar bridge. Only hbound (the
    continuity gap is a null family) remains an explicit hypothesis. -/
theorem mellinHat_dilate_covariance_real_derived (φ : L2Test) (n : Nat)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_c : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR c S hSd hSn hcS φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (qk : Nat → Q) (hqk_pos : ∀ k, 0 < (qk k).num) (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_S : ∀ k, Rle (Rabs (ofQ (qk k) (hqk_den k))) (ofQ S hSd))
    (hdec_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_fine_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, (qk k).den⟩ : Q) Int.zero_lt_one (hqk_den k) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg_qk : ∀ k, RReg (fun j => genSum (fun m => scaledTwTerm φ (qk k) (hqk_pos k) (hqk_den k) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)))
    {C₀ : Nat}
    (hbound : ∀ k, Rle (Rabs (Rsub
        (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (Rmul (Rpow (ofQ (qk k) (hqk_den k)) (n + 1))
          (mellinHat (dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ) n hCd hCn (hdec_qk k)))))
        (ofQ (⟨(C₀ : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (mellinHat φ n hCd hCn hdec_phi) :=
  mellinHat_dilate_covariance_real φ n S hSd hSn c hcS hCd hCn hdec_c hdec_phi
    qk hqk_den hqk_S hdec_qk
    (fun k => Req_trans (Rmul_congr (Rpow_ofQ (hqk_den k) (n + 1)) (Req_refl _))
      (covariance_at_rational_dilateTestR φ n (qk k) (hqk_pos k) (hqk_den k) S hSd hSn (hqk_S k)
        hCd hCn (hdec_qk k) hdec_phi (hdec_fine_qk k) (hReg_qk k)))
    hbound

end Multiplicity.UOR.Bridge.F1Square.Square
