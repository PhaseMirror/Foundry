/-
F1 square — **the real-scale covariance at a scale `c ∈ [1, S]`, all approximant data discharged**
(`MellinHatDilateCovarianceRealGe1.lean`): for a REAL scale `c` with `1 ≤ c ≤ S`, the Mellin dilation
covariance `cⁿ⁺¹·mellinHat(dilateTestR c φ) = mellinHat φ`, needing only the `c`-window decay `hdec_c`,
the `φ`-window decay `hdec_phi`, and φ's CLEAN order-`(n+2)` decay `hfdec` — every per-approximant
obligation is discharged internally.

WHY (the `c ≥ 1` discharge). The base density capstone `mellinHat_dilate_covariance_real` takes an
arbitrary rational approximant sequence `qk → c` and the per-`qk` covariance/decay data. The natural
diagonal `c.seq (covIdx k)` dips below `1` at small `k` (breaking `dilateTestR_window_hdec`, which needs
scale `≥ 1`) and can exceed `S` (breaking the `≤ S` bound). The fix is the two-sided BAND clamp: run the
diagonal of `c' := qBandQ 1 S c` (`seqₙ = min(S, max(c.seqₙ, 1))`, in `[1, S]` at EVERY index by
construction). Since `c ∈ [1, S]`, the band is inert (`qBandQ_eq_of_band`: `c' ≈ c`), so
`|c − ofQ(c'.seq N)| = |c' − ofQ(c'.seq N)| ≤ 1/(N+1)` gives `hfast` for free — no clamp-nonexpansiveness
lemma. The band membership discharges `hqk_S` (`≤ S`), `hdec_qk` (scale `≥ 1`, from `hfdec` via
`dilateTestR_window_hdec`), and the numerator positivity `covariance_at_qk_baseform` needs; `hcov` comes
from `covariance_at_qk_baseform` (which itself removes the fine-decay wall), `hbound` from
`covComb_hbound_of_fast`.

HONEST SCOPE. Object-grounding substrate: the real-scale covariance usable directly at `c ≥ 1` (e.g.
`c = clampedInv(a,t)` on the reconstruction window), with all approximant data discharged. It builds NO
factorization theorem `M[f⋆g]=M[f]·M[g]`, NO grounding of `v = ĝ`, and — emphatically — NO step-4
band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinHatDilateCovarianceReal
import Foundations.F1.Square.CovarianceAtQk
import Foundations.F1.Square.CovCombHbound
import Foundations.F1.Square.DilateTestRDecay
import Foundations.F1.Analysis.BandClamp
import Foundations.F1.Analysis.RSeqApprox
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The real-scale covariance at `c ∈ [1, S]`.** For a real scale `c` with `1 ≤ c ≤ S`,
    `cⁿ⁺¹·mellinHat(dilateTestR c φ) n = mellinHat φ n`. All per-approximant data is discharged along the
    band diagonal `qk k = (qBandQ 1 S c).seq (covIdx k)` (in `[1, S]` by construction): `hcov` from
    `covariance_at_qk_baseform`, `hbound` from `covComb_hbound_of_fast` with `hfast` free (the band is
    inert since `c ∈ [1, S]`, so `c' ≈ c`). Remaining inputs: the `c`/`φ`-window decays and φ's clean
    decay `hfdec`. -/
theorem mellinHat_dilate_covariance_real_ge1 (φ : L2Test) (n : Nat)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hS1 : Qle (⟨1, 1⟩ : Q) S)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) (hc1 : Rle one c)
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
         (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos k))))) :
    Req (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (mellinHat φ n hCd hCn hdec_phi) := by
  -- the band-clamped copy of `c`: `c'.seqₙ = min(S, max(c.seqₙ, 1)) ∈ [1, S]` at every index.
  let c' : Real := qBandQ (⟨1, 1⟩ : Q) S (by decide) hSd c
  -- `c ∈ [1, S]` ⟹ the band is inert: `c ≈ c'`.
  have hzero_one : Rle zero one := Rle_ofQ_ofQ (by decide) (by decide) (by decide)
  have hzeroc : Rle zero c := Rle_trans hzero_one hc1
  have hnnc : Rnonneg c := Rnonneg_of_Rle_zero hzeroc
  have hcS' : Rle c (ofQ S hSd) := Rle_trans (Rle_of_Req (Req_symm (Rabs_of_nonneg hnnc))) hcS
  have hcc' : Req c c' := Req_symm (qBandQ_eq_of_band (a := (⟨1, 1⟩ : Q)) (b := S)
    (had := (by decide)) (hbd := hSd) hc1 hcS')
  -- the band diagonal as the approximant sequence.
  let qk : Nat → Q := fun k => c'.seq (covIdx φ S C n k)
  have hqk_den : ∀ k, 0 < (qk k).den := fun k => c'.den_pos (covIdx φ S C n k)
  have hge1 : ∀ k, Qle (⟨1, 1⟩ : Q) (qk k) := fun k =>
    qBandQ_ge (⟨1, 1⟩ : Q) S (by decide) hSd hS1 c (covIdx φ S C n k)
  have hleS : ∀ k, Qle (qk k) S := fun k =>
    qBandQ_le (⟨1, 1⟩ : Q) S (by decide) hSd c (covIdx φ S C n k)
  have hone_qk : ∀ k, Rle one (ofQ (qk k) (hqk_den k)) := fun k =>
    Rle_trans (Rle_of_Req (Req_refl one)) (Rle_ofQ_ofQ (by decide) (hqk_den k) (hge1 k))
  have hqk_S : ∀ k, Rle (Rabs (ofQ (qk k) (hqk_den k))) (ofQ S hSd) := fun k =>
    Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_of_Rle_zero
        (Rle_trans hzero_one (hone_qk k)))))
      (Rle_ofQ_ofQ (hqk_den k) hSd (hleS k))
  have hqk_num : ∀ k, 0 < (qk k).num := fun k => by
    have h := hge1 k; have hd := hqk_den k
    simp only [Qle] at h; push_cast at h; omega
  -- per-approximant dilate decay at `C`, from φ's clean decay (scale `≥ 1`).
  have hdec_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) := fun k =>
    dilateTestR_window_hdec φ n hCd hCn hfdec (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) (hone_qk k)
  -- `hcov` per approximant, at the uniform constant `C`.
  have hcov : ∀ k, Req
      (Rmul (Rpow (ofQ (qk k) (hqk_den k)) (n + 1))
        (mellinHat (dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ) n hCd hCn (hdec_qk k)))
      (mellinHat φ n hCd hCn hdec_phi) := fun k =>
    covariance_at_qk_baseform φ n (qk k) (hqk_num k) (hqk_den k) S hSd hSn (hqk_S k) hCd hCn
      hfdec (hdec_qk k) hdec_phi
  -- `hfast` free: the band is inert (`c ≈ c'`), so `|c − ofQ(qk k)| = |c' − ofQ(c'.seq …)| ≤ 1/(N+1)`.
  have hfast : ∀ k, Rle (Rabs (Rsub c (ofQ (qk k) (hqk_den k))))
      (ofQ (⟨1, covIdx φ S C n k + 1⟩ : Q) (Nat.succ_pos _)) := fun k =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hcc' (Req_refl _))))
      (Rabs_sub_seq_le c' (covIdx φ S C n k))
  -- assemble the base density capstone.
  exact mellinHat_dilate_covariance_real φ n S hSd hSn c hcS hCd hCn hdec_c hdec_phi
    qk hqk_den hqk_S hdec_qk hcov (C₀ := covC0 S n)
    (covComb_hbound_of_fast φ n S hSd hSn c hcS hCd hCn hdec_c qk hqk_den hqk_S hdec_qk hfast)

end Multiplicity.UOR.Bridge.F1Square.Square
