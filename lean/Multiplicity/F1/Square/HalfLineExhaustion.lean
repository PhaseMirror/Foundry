/-
F1 square — **certified integration: the EXHAUSTION CHARACTERIZATION of the half-line integral**
(`HalfLineExhaustion.lean`), exhaustion rung 4. The window-`genSum`-defined improper integral
`∫₀^∞ f` is re-expressed as the Bishop limit of a sequence of **interval integrals** over the caps
`[0, 1 + digammaMidx K j]`:

    `∫₀^∞ f  ≈  limⱼ ∫_0^{1 + digammaMidx K j} f`   (`halfLineIntegral_eq_Rlim`).

The reduction is a pure reindexing/telescoping identity. STEP A collapses the `genSum` of unit-window
tail increments into a single interval integral `∫_1^{N+1} f` via the committed finite telescoping
`riemannIntegralI_telescope` on the endpoint sequence `c k = k + 1` (reconciled to `integralTerm`
termwise by `riemannIntegralI_congr_Q`, `genSum` matched to `RsumN`). STEP B joins the `[0,1]`
gateway to that tail into a single cap `∫_0^{1+N} f` via `riemannIntegralI_split_at` at width `1`
(the `[0,1]` piece identified by `riemannIntegralI_unit`, the tail piece reconciled by
`riemannIntegralI_congr_Q`). STEP C pulls the fixed gateway constant inside the committed limit
(`Rlim_add_const`) and closes the two limits by `Rlim_congr`. The regularity of the interval-integral
sequence is carried as the explicit hypothesis `hReg`, so no fresh limit is minted.

HONEST SCOPE. The exhaustion characterization of `halfLineIntegral` as the `Rlim` of interval
integrals over the caps `[0, 1 + digammaMidx K j]`, via the committed telescope, split-at, unit
identity, and `Rlim` congruences. It builds NO dilation covariance, NO new limit, NO factorization,
NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.ImproperIntegral
import Multiplicity.F1.Analysis.RlimProps
import Multiplicity.F1.Square.IntervalTelescope
import Multiplicity.F1.Square.IntervalMinorant

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The exhaustion endpoint sequence `c k = k + 1` (all denominators `1`); adjacent windows
    `[c m, c (m+1)]` are the unit tail increments, and `[c 0, c N] = [1, N+1]`. -/
private def cSeq : Nat → Q := fun k => (⟨(k : Int) + 1, 1⟩ : Q)

/-- `genSum` and `RsumN` are the same left fold, so agree at every length. -/
private theorem genSum_RsumN (T : Nat → Real) : ∀ N, Req (genSum T N) (RsumN T N)
  | 0 => Req_refl zero
  | (N + 1) => Radd_congr (genSum_RsumN T N) (Req_refl _)

set_option maxHeartbeats 4000000 in
/-- **THE EXHAUSTION CHARACTERIZATION OF THE HALF-LINE INTEGRAL.** `∫₀^∞ f` equals the Bishop limit
    of the interval integrals over the caps `[0, 1 + digammaMidx K j]`:

      `∫₀^∞ f  ≈  limⱼ ∫_0^{1 + digammaMidx K j} f`.

    STEP A (`riemannIntegralI_telescope`) turns the tail `genSum` into `∫_1^{N+1} f`; STEP B
    (`riemannIntegralI_split_at` + `riemannIntegralI_unit`) joins the gateway `∫_0^1 f`; STEP C pulls
    the gateway constant through the committed limit (`Rlim_add_const`) and closes by `Rlim_congr`.
    The regularity `hReg` of the cap sequence is the carried hypothesis, so no new limit is minted. -/
theorem halfLineIntegral_eq_Rlim {f : Real → Real} {L K : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hKd : 0 < K.den) (hK0 : 0 ≤ K.num)
    (hb : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
          (integralTerm hLd hLn hlip hfc m)
      ∧ Rle (integralTerm hLd hLn hlip hfc m)
          (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
    (hReg : RReg (fun j => riemannIntegralI hLd hLn hlip hfc (⟨(0 : Int), 1⟩ : Q)
        (⟨((1 + digammaMidx K j : Nat) : Int), 1⟩ : Q) (by decide) Nat.one_pos
        (Int.ofNat_nonneg _))) :
    Req (halfLineIntegral hLd hLn hlip hfc hKd hK0 hb)
        (Rlim (fun j => riemannIntegralI hLd hLn hlip hfc (⟨(0 : Int), 1⟩ : Q)
            (⟨((1 + digammaMidx K j : Nat) : Int), 1⟩ : Q) (by decide) Nat.one_pos
            (Int.ofNat_nonneg _)) hReg) := by
  -- telescope hypotheses for `cSeq k = k + 1`
  have hc_den : ∀ m, 0 < (cSeq m).den := fun _ => Nat.one_pos
  have hwin : ∀ m, 0 ≤ (Qsub (cSeq (m + 1)) (cSeq m)).num := by
    intro m; simp only [cSeq, Qsub, add, neg]; push_cast; omega
  have hWn : ∀ N, 0 ≤ (Qsub (cSeq N) (cSeq 0)).num := by
    intro N; simp only [cSeq, Qsub, add, neg]; push_cast; omega
  have hWpos : ∀ N, 0 < (Qsub (cSeq (N + 1)) (cSeq 0)).num := by
    intro N; simp only [cSeq, Qsub, add, neg]; push_cast; omega
  have hWle : ∀ N, Qle (Qsub (cSeq N) (cSeq 0)) (Qsub (cSeq (N + 1)) (cSeq 0)) := by
    intro N; simp only [cSeq, Qle, Qsub, add, neg]; push_cast; omega
  have hrem : ∀ N, 0 ≤ (Qsub (Qsub (cSeq (N + 1)) (cSeq 0)) (Qsub (cSeq N) (cSeq 0))).num := by
    intro N; simp only [cSeq, Qsub, add, neg]; push_cast; omega
  -- the committed finite telescoping specialized to `cSeq`
  have tel := riemannIntegralI_telescope hLd hLn hlip hfc cSeq hc_den hwin hWn hWpos hWle hrem
  -- STEP A: `genSum (integralTerm) N = ∫_1^{N+1} f` = `∫_{cSeq 0}^{cSeq N} f`
  have termeq : ∀ m, Req (integralTerm hLd hLn hlip hfc m)
      (riemannIntegralI hLd hLn hlip hfc (cSeq m) (Qsub (cSeq (m + 1)) (cSeq m))
        (hc_den m) (Qsub_den_pos (hc_den (m + 1)) (hc_den m)) (hwin m)) := by
    intro m
    exact riemannIntegralI_congr_Q hLd hLn hlip hfc
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) (cSeq m) (Qsub (cSeq (m + 1)) (cSeq m))
      Nat.one_pos (by decide) (by decide)
      (hc_den m) (Qsub_den_pos (hc_den (m + 1)) (hc_den m)) (hwin m)
      (Qeq_refl _)
      (by simp only [cSeq, Qeq, Qsub, add, neg]; push_cast; ring_uor)
  have mideq : ∀ N, Req (RsumN (integralTerm hLd hLn hlip hfc) N)
      (RsumN (fun m => riemannIntegralI hLd hLn hlip hfc (cSeq m) (Qsub (cSeq (m + 1)) (cSeq m))
        (hc_den m) (Qsub_den_pos (hc_den (m + 1)) (hc_den m)) (hwin m)) N) :=
    fun N => RsumN_congr N (fun m _ => termeq m)
  have stepA : ∀ N, Req (genSum (integralTerm hLd hLn hlip hfc) N)
      (riemannIntegralI hLd hLn hlip hfc (cSeq 0) (Qsub (cSeq N) (cSeq 0))
        (hc_den 0) (Qsub_den_pos (hc_den N) (hc_den 0)) (hWn N)) :=
    fun N => Req_trans (genSum_RsumN (integralTerm hLd hLn hlip hfc) N)
      (Req_trans (mideq N) (tel N))
  -- the per-index identity: gateway + telescoped tail = the cap integral
  have perj : ∀ j, Req (Radd (riemannIntegral hLd hLn hlip hfc)
        (genSum (integralTerm hLd hLn hlip hfc) (digammaMidx K j)))
      (riemannIntegralI hLd hLn hlip hfc (⟨(0 : Int), 1⟩ : Q)
        (⟨((1 + digammaMidx K j : Nat) : Int), 1⟩ : Q) (by decide) Nat.one_pos
        (Int.ofNat_nonneg _)) := by
    intro j
    -- STEP B: split the cap `[0, 1 + N]` at width `1`
    have hle : Qle (⟨1, 1⟩ : Q) (⟨((1 + digammaMidx K j : Nat) : Int), 1⟩ : Q) := by
      simp only [Qle]; push_cast; omega
    have hw2n : (0 : Int) ≤
        (Qsub (⟨((1 + digammaMidx K j : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q)).num := by
      simp only [Qsub, add, neg]; push_cast; omega
    have split := riemannIntegralI_split_at hLd hLn hlip hfc (⟨(0 : Int), 1⟩ : Q)
      (⟨((1 + digammaMidx K j : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) Nat.one_pos
      (Int.ofNat_nonneg _) (by decide) (by decide) hle hw2n
    -- the tail piece of the split matches the telescoped tail
    have rightEq := riemannIntegralI_congr_Q hLd hLn hlip hfc
      (add (⟨(0 : Int), 1⟩ : Q) (⟨1, 1⟩ : Q))
      (Qsub (⟨((1 + digammaMidx K j : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q))
      (cSeq 0) (Qsub (cSeq (digammaMidx K j)) (cSeq 0))
      (add_den_pos (by decide) (by decide)) (Qsub_den_pos Nat.one_pos (by decide)) hw2n
      (hc_den 0) (Qsub_den_pos (hc_den (digammaMidx K j)) (hc_den 0)) (hWn (digammaMidx K j))
      (by decide)
      (by simp only [cSeq, Qeq, Qsub, add, neg]; push_cast; ring_uor)
    have stepB := Req_symm (Req_trans split
      (Radd_congr (riemannIntegralI_unit hLd hLn hlip hfc) rightEq))
    exact Req_trans (Radd_congr (Req_refl _) (stepA (digammaMidx K j))) stepB
  -- STEP C: pull the gateway constant inside the committed limit, then close by congruence
  have hG : RReg (fun j => genSum (integralTerm hLd hLn hlip hfc) (digammaMidx K j)) :=
    genSum_RReg (integralTerm hLd hLn hlip hfc) hKd hK0 hb
  have hcX : RReg (fun j => Radd (riemannIntegral hLd hLn hlip hfc)
      (genSum (integralTerm hLd hLn hlip hfc) (digammaMidx K j))) :=
    RReg_add_const (riemannIntegral hLd hLn hlip hfc) _ hG
  exact Req_trans
    (Req_symm (Rlim_add_const (riemannIntegral hLd hLn hlip hfc) _ hG hcX))
    (Rlim_congr _ _ hcX hReg perj)

end Multiplicity.UOR.Bridge.F1Square.Square
