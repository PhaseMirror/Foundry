/-
F1 square — **the real-scale covariance with `hbound` auto-discharged along the fast diagonal**
(`MellinHatDilateCovarianceRealSeq.lean`): the real-scale Mellin dilation covariance
`cⁿ⁺¹·mellinHat(dilateTestR c φ) = mellinHat φ`, with BOTH `hcov` (already derived) and `hbound` (the
continuity gap is a null family) now discharged — the approximant sequence is fixed to the real's own
fast diagonal `qk k = c.seq (covIdx k)`, so the fast-approximation input is free
(`Rabs_sub_seq_le`) and `hbound` is discharged internally by `covComb_hbound_of_fast`.

`mellinHat_dilate_covariance_real_seq`: no separate `hbound` hypothesis — the covariance now rests
only on the per-approximant decay/positivity/regularity data at the fixed diagonal `c.seq (covIdx k)`.
This is the natural capstone of the `hbound`-discharge arc: the "fast enough approximation" concern is
gone (the diagonal is *by construction* within `1/(covIdx k + 1)` of `c`, and `covIdx k` is chosen
exactly large enough to make the continuity gap a `covC0/(k+1)` null family).

HONEST SCOPE. Object-grounding substrate — the real-scale covariance with `hbound` discharged along
the fast diagonal. The remaining inputs (`hqk_pos`/`hqk_S`/`hdec_qk`/`hdec_fine_qk`/`hReg_qk` at the
diagonal) are the standard per-approximant decay/positivity data, explicit and honest; making THEM
uniform-in-scale (so the covariance needs only data on `φ` and `c`) is a separate hardening. It builds
NO factorization theorem `M[f⋆g]=M[f]·M[g]`, NO grounding of `v = ĝ`, and — emphatically — NO step-4
band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MellinHatDilateCovarianceRealDerived
import Multiplicity.F1Square.Square.CovCombHbound
import Multiplicity.F1Square.Analysis.RSeqApprox

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Real-scale covariance with `hbound` auto-discharged along the fast diagonal `c.seq (covIdx k)`.
    No separate fast-approximation input: `covComb_hbound_of_fast` discharges `hbound` from the free
    `Rabs_sub_seq_le`, and `mellinHat_dilate_covariance_real_derived` discharges `hcov` from the decay
    data. Only the per-approximant decay/positivity/regularity at the diagonal remain. -/
theorem mellinHat_dilate_covariance_real_seq (φ : L2Test) (n : Nat)
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
    (hqk_pos : ∀ k, 0 < (c.seq (covIdx φ S C n k)).num)
    (hqk_S : ∀ k, Rle (Rabs (ofQ (c.seq (covIdx φ S C n k)) (c.den_pos (covIdx φ S C n k))))
      (ofQ S hSd))
    (hdec_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR (ofQ (c.seq (covIdx φ S C n k)) (c.den_pos (covIdx φ S C n k)))
            S hSd hSn (hqk_S k) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_fine_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, (c.seq (covIdx φ S C n k)).den⟩ : Q) Int.zero_lt_one
            (c.den_pos (covIdx φ S C n k)) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg_qk : ∀ k, RReg (fun j => genSum (fun m => scaledTwTerm φ (c.seq (covIdx φ S C n k))
      (hqk_pos k) (c.den_pos (covIdx φ S C n k)) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) :
    Req (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (mellinHat φ n hCd hCn hdec_phi) :=
  mellinHat_dilate_covariance_real_derived φ n S hSd hSn c hcS hCd hCn hdec_c hdec_phi
    (fun k => c.seq (covIdx φ S C n k)) hqk_pos (fun k => c.den_pos (covIdx φ S C n k)) hqk_S
    hdec_qk hdec_fine_qk hReg_qk
    (C₀ := covC0 S n)
    (covComb_hbound_of_fast φ n S hSd hSn c hcS hCd hCn hdec_c
      (fun k => c.seq (covIdx φ S C n k)) (fun k => c.den_pos (covIdx φ S C n k)) hqk_S hdec_qk
      (fun k => Rabs_sub_seq_le c (covIdx φ S C n k)))

end Multiplicity.UOR.Bridge.F1Square.Square
