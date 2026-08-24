/-
F1 square — **the real-scale covariance from φ's CLEAN decay, no per-approximant fine data**
(`MellinHatDilateCovarianceRealClean.lean`): the real-scale Mellin dilation covariance
`cⁿ⁺¹·mellinHat(dilateTestR c φ) = mellinHat φ`, discharged along the fast diagonal
`qk k = c.seq (covIdx k)` — but with the wall's two per-approximant obligations REMOVED. Where the
`_seq` capstone (`MellinHatDilateCovarianceRealSeq.lean`) routes through `_derived` and so demands the
per-approximant fine-`1/qk.den` window decay `hdec_fine_qk` (the covariance wall for `c ≥ 1`) and the
per-approximant twisted regularity `hReg_qk`, this file gets `hcov` from `covariance_at_qk_baseform`,
which discharges BOTH internally (the fine decay from φ's clean decay via `dilateTest_fine_window_decay`
at the enlarged constant `Cbig`, and the regularity from `scaledTwTerm_bound`). So the covariance now
rests only on φ's CLEAN order-`(n+2)` decay `hfdec` plus the standard window decays.

`mellinHat_dilate_covariance_real_clean`: no `hdec_fine_qk`, no `hReg_qk`. The remaining inputs are
`hdec_c`/`hdec_phi` (the `c`- and `φ`-window decays), `hfdec` (φ's clean decay — the SAME datum the
reconstruction already carries), and the per-approximant `hqk_pos`/`hqk_S`/`hdec_qk` at the diagonal.
This is the wall-break payoff: the `c ≥ 1` real-scale covariance needs no fine-window analytic input.

HONEST SCOPE. Object-grounding substrate — the real-scale covariance with the fine-decay wall removed.
The per-approximant `hqk_pos`/`hqk_S`/`hdec_qk` at the diagonal remain explicit and honest; discharging
them for the specific `c = clampedInv(a,t)` is the reconstruction's `hU` connect (separate). It builds
NO factorization theorem `M[f⋆g]=M[f]·M[g]`, NO grounding of `v = ĝ`, and — emphatically — NO step-4
band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinHatDilateCovarianceReal
import Multiplicity.F1.Square.CovarianceAtQk
import Multiplicity.F1.Square.CovCombHbound
import Multiplicity.F1.Analysis.RSeqApprox
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Real-scale covariance from φ's clean decay — the fine-decay wall removed.** Along the fast
    diagonal `qk k = c.seq (covIdx k)`, `hbound` is discharged by `covComb_hbound_of_fast` (free
    `Rabs_sub_seq_le`) and `hcov` by `covariance_at_qk_baseform` (which handles the fine-`1/qk.den`
    decay and the twisted regularity internally, from φ's clean decay `hfdec`). Compared to
    `mellinHat_dilate_covariance_real_seq` this DROPS the per-approximant fine decay `hdec_fine_qk` and
    the regularity `hReg_qk`, adding only φ's clean order-`(n+2)` decay `hfdec`. -/
theorem mellinHat_dilate_covariance_real_clean (φ : L2Test) (n : Nat)
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
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
       Rle (Rabs (φ.f y)) (ofQ (mul C (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
         (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (hqk_pos : ∀ k, 0 < (c.seq (covIdx φ S C n k)).num)
    (hqk_S : ∀ k, Rle (Rabs (ofQ (c.seq (covIdx φ S C n k)) (c.den_pos (covIdx φ S C n k))))
      (ofQ S hSd))
    (hdec_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR (ofQ (c.seq (covIdx φ S C n k)) (c.den_pos (covIdx φ S C n k)))
            S hSd hSn (hqk_S k) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (mellinHat φ n hCd hCn hdec_phi) :=
  mellinHat_dilate_covariance_real φ n S hSd hSn c hcS hCd hCn hdec_c hdec_phi
    (fun k => c.seq (covIdx φ S C n k)) (fun k => c.den_pos (covIdx φ S C n k)) hqk_S hdec_qk
    (fun k => covariance_at_qk_baseform φ n (c.seq (covIdx φ S C n k)) (hqk_pos k)
      (c.den_pos (covIdx φ S C n k)) S hSd hSn (hqk_S k) hCd hCn hfdec (hdec_qk k) hdec_phi)
    (C₀ := covC0 S n)
    (covComb_hbound_of_fast φ n S hSd hSn c hcS hCd hCn hdec_c
      (fun k => c.seq (covIdx φ S C n k)) (fun k => c.den_pos (covIdx φ S C n k)) hqk_S hdec_qk
      (fun k => Rabs_sub_seq_le c (covIdx φ S C n k)))

end Multiplicity.UOR.Bridge.F1Square.Square
