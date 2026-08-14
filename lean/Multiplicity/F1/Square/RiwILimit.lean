/-
F1 square — **the real-window integral is the limit of its partials** (`RiwILimit.lean`): if the
rational partials `riwSeq φ' qk … (m k)` approach a target `L` fast enough (`|riwSeq(m k) − L| ≤
C₀/(k+1)` along a sub-index `m` with `k ≤ m k`), then the real-window integral equals `L`:

    `riwI φ' qk … = L`.

Pure completeness: `riwI = Rlim (riwSeq …)`, so `|riwI − riwSeq(m k)| ≤ 2/(m k + 1) ≤ 2/(k+1)`
(`Rabs_dist_Rlim`, and `k ≤ m k`); the triangle with `hbound` gives `|riwI − L| ≤ (2+C₀)/(k+1)`, a
null family, and `Req_of_real_null_family` closes it.

WHY (the Rlim-interchange capstone). For `φ' = f·powBandGen_{[0,B]}` and `L = c^{n+1}·mellinMoment
(dilateTestR c f) n`, `hbound` is discharged from `riwSeq_term_eq_moment` (`riwSeq(m k) =
(qk (m k))^{n+1}·mellinMoment(dilate_{qk (m k)} f)`), `mellinMoment_bridge`/`Rpow_ofQ` (to the
`dilateTestR` form), and `moment_covComb_scale_lip` (`|H(qk (m k)) − H(c)| ≤ Lip·|qk (m k) − c|`) with a
fast diagonal `qk`. That yields the real-scale moment covariance `mellinMoment(dilateTestR c f) n =
c^{-(n+1)}·riwI …` — the factorization's inner integral at a real scale.

HONEST SCOPE. The completeness identity `riwI = Rlim = L` from a supplied approach rate. `hbound` is an
explicit, dischargeable input (exactly as in the half-line covariance `mellinHat_dilate_covariance_real`).
It builds NO factorization `M[f⋆g]=M[f]·M[g]`, NO half-line assembly, NO positivity, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.RealWindowIntegral
import Multiplicity.F1Square.Analysis.IntegralCertIrrel
import Multiplicity.F1Square.Analysis.RealNullFamily

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `(a − b) + (b − d) ≈ a − d` — through a midpoint (real-`Radd`/`Rneg` rearrangement). -/
private theorem Rsub_mid (a b d : Real) :
    Req (Radd (Rsub a b) (Rsub b d)) (Rsub a d) :=
  Req_trans (Radd_assoc a (Rneg b) (Radd b (Rneg d)))
    (Radd_congr (Req_refl a)
      (Req_trans (Req_symm (Radd_assoc (Rneg b) b (Rneg d)))
        (Req_trans
          (Radd_congr (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b)) (Req_refl (Rneg d)))
          (Req_trans (Radd_comm zero (Rneg d)) (Radd_zero (Rneg d))))))

/-- `|a − d| ≤ |a − b| + |b − d|` — the real-`Rabs` triangle through a midpoint. -/
private theorem Rabs_sub_tri (a b d : Real) :
    Rle (Rabs (Rsub a d)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b d))) :=
  Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rsub_mid a b d))))
    (Rabs_Radd (Rsub a b) (Rsub b d))

/-- **The real-window integral equals a target its fast partials approach.** -/
theorem riwI_eq_of_bound (φ' : L2Test) (qk : Nat → Q) (hqk_pos : ∀ k, 0 < (qk k).num)
    (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_fast : ∀ j k, Qle (mul (Qabs (Qsub (qk j) (qk k))) φ'.M)
      (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
    (L : Real) (m : Nat → Nat) (hm : ∀ k, k ≤ m k) {C₀ : Nat}
    (hbound : ∀ k, Rle (Rabs (Rsub (riwSeq φ' qk hqk_pos hqk_den (m k)) L))
      (ofQ (⟨(C₀ : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req (riwI φ' qk hqk_pos hqk_den hqk_fast) L := by
  refine Req_of_real_null_family (C := 2 + C₀) (fun k => ?_)
  have hdist : Rle (Rabs (Rsub (riwI φ' qk hqk_pos hqk_den hqk_fast)
        (riwSeq φ' qk hqk_pos hqk_den (m k))))
      (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) ?_
    refine Rle_trans (Rabs_dist_Rlim (riwSeq_RReg φ' qk hqk_pos hqk_den hqk_fast) (m k)) ?_
    refine Rle_ofQ_ofQ (Nat.succ_pos (m k)) (Nat.succ_pos k) ?_
    show Qle (⟨2, m k + 1⟩ : Q) (⟨2, k + 1⟩ : Q)
    simp only [Qle]; push_cast; have := hm k; omega
  refine Rle_trans (Rabs_sub_tri (riwI φ' qk hqk_pos hqk_den hqk_fast)
    (riwSeq φ' qk hqk_pos hqk_den (m k)) L) ?_
  refine Rle_trans (Radd_le_add hdist (hbound k)) ?_
  -- 2/(k+1) + C₀/(k+1) ≤ (2+C₀)/(k+1)  (an equality)
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k)
    (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))

end Multiplicity.UOR.Bridge.F1Square.Square
