/-
F1 square — **the Sonine co-support recovers coupled positivity** (`CoupledWeilSonine.lean`): the
POSITIVE companion of the indefinite-arch obstruction. The obstruction shows raw whole-space dominance
is false for an indefinite arch; this shows the coupled kernel IS positive on the Sonine co-support
subspace — the discrete `f, f̂` co-support condition — realizing, at the coupled-kernel level, the doc's
central mechanism: the coupling cancels the arch-negative band.

TWO restrictions, together the discrete Sonine co-support:
  • `PrimeNull v M c N` — the transform side: `Σ_i c_i·v(m,i) = 0` at every prime-power place `m`
    (`f̂` vanishes on the prime band). Under it the prime energy is exactly zero
    (`weilQuad_primeGram_prime_null`).
  • the archimedean complement — `c` vanishes on the arch-negative band (`arch(i) ≥ 0 ∨ c(i) = 0`),
    on which the arch form is `≥ 0` unconditionally (`multForm_psd_on_complement`).
On the intersection the coupled form is `arch − 0 = arch ≥ 0`: `coupledWeil_psd_on_sonine_restriction`.

HONEST SCOPE. This is positivity on a STRICT subspace — it does NOT force full Weil positivity (the doc's
SECOND dichotomy branch: it sharpens the localization, it does not close the crux). `PrimeNull` sets the
prime energy to zero by the co-support constraint (not by any dominance), and the arch complement is the
built unconditional skeleton; neither asserts the genuine coupling. Extending this from the co-support
subspace to the WHOLE space (via the genuine `f, f̂` transform coupling, unbuilt) is step 4 = RH. Crux
stays `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.CoupledWeilKernel

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The transform-side co-support condition**: `Σ_{i<N} c_i·v(m,i) = 0` at every prime-power place
    `m < M` — the discrete `f̂`-vanishes-on-the-prime-band constraint. -/
def PrimeNull (v : Nat → Nat → Real) (M : Nat) (c : Nat → Real) (N : Nat) : Prop :=
  ∀ m, m < M → Req (RsumN (fun i => Rmul (c i) (v m i)) N) zero

/-- **Under co-support the prime energy vanishes**: `weilQuad (primeGram w v M) c N = 0`. -/
theorem weilQuad_primeGram_prime_null (w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat) (hnull : PrimeNull v M c N) :
    Req (weilQuad (primeGram w v M) c N) zero := by
  refine Req_trans (weilQuad_primeGram_split w v c N M) ?_
  refine RsumN_zero M (fun m hm => ?_)
  -- w(m)·(S m)² = w(m)·(0·0) = 0
  refine Req_trans (Rmul_congr (Req_refl (w m))
    (Rmul_congr (hnull m hm) (hnull m hm))) ?_
  exact Req_trans (Rmul_congr (Req_refl (w m)) (Rmul_zero zero)) (Rmul_zero (w m))

/-- **★ THE SONINE CO-SUPPORT RECOVERS COUPLED POSITIVITY**: on the intersection of the transform-side
    co-support (`PrimeNull`, prime energy `= 0`) and the archimedean complement (arch form `≥ 0`), the
    coupled Weil form is `≥ 0` — `coupledWeil = arch − 0 = arch`. The doc's central cancellation, at the
    coupled-kernel level; positivity on a strict subspace, never forcing full positivity. -/
theorem coupledWeil_psd_on_sonine_restriction (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat) (hnull : PrimeNull v M c N)
    (hc : ∀ i, i < N → Rnonneg (arch i) ∨ Req (c i) zero) :
    Rnonneg (weilQuad (coupledWeil arch w v M) c N) := by
  have harch : Rnonneg (weilQuad (multForm arch) c N) := multForm_psd_on_complement arch c N hc
  refine Rnonneg_congr (Req_symm ?_) harch
  -- weilQuad coupledWeil = weilQuad multForm − weilQuad primeGram = arch − 0 = arch
  refine Req_trans (weilQuad_sub (multForm arch) (primeGram w v M) c N) ?_
  refine Req_trans (Rsub_congr (Req_refl _) (weilQuad_primeGram_prime_null w v M c N hnull)) ?_
  exact Req_trans (Radd_congr (Req_refl _) Rneg_zero) (Radd_zero _)


/-- **★ THE BURNOL-CORRECTED COUPLED KERNEL IS POSITIVE ON THE CO-SUPPORT** (no complement needed): if a
    correction lifts the arch multiplier nonnegative everywhere (`arch(i) + corr(i) ≥ 0 ∀i` — Burnol's
    `burnol_corrected_nonneg`, the bounded negative band lifted), then the corrected coupled kernel
    `coupledWeil (arch + corr) w v M` is `≥ 0` on the whole `PrimeNull` co-support subspace. This is the
    coupled-kernel analog of Burnol's sharpest unconditional positivity — the correction removes the arch
    indefiniteness, the co-support kills the prime, leaving a manifestly PSD diagonal form. The corrected
    kernel differs from the genuine one by the window-supported defect `multForm corr`; it is NOT the
    genuine coupled kernel, and this does not close the crux. -/
theorem coupledWeilCorrected_psd_on_primeNull (arch corr w : Nat → Real) (v : Nat → Nat → Real)
    (M : Nat) (c : Nat → Real) (N : Nat) (hcorr : ∀ i, Rnonneg (Radd (arch i) (corr i)))
    (hnull : PrimeNull v M c N) :
    Rnonneg (weilQuad (coupledWeil (fun k => Radd (arch k) (corr k)) w v M) c N) := by
  have harch : Rnonneg (weilQuad (multForm (fun k => Radd (arch k) (corr k))) c N) :=
    (multForm_psd_iff (fun k => Radd (arch k) (corr k))).mpr hcorr N c
  refine Rnonneg_congr (Req_symm ?_) harch
  refine Req_trans (weilQuad_sub (multForm (fun k => Radd (arch k) (corr k))) (primeGram w v M) c N) ?_
  refine Req_trans (Rsub_congr (Req_refl _) (weilQuad_primeGram_prime_null w v M c N hnull)) ?_
  exact Req_trans (Radd_congr (Req_refl _) Rneg_zero) (Radd_zero _)


/-- **The genuine Burnol instance**: the Burnol-corrected coupled kernel (`burnolMult + burnolCorr`, the
    2-sample Burnol multiplier with its bounded-band correction) is positive on the `PrimeNull` co-support
    subspace, UNCONDITIONALLY — `burnol_corrected_nonneg` discharges the correction hypothesis. The
    sharpest unconditional coupled positivity in the repo, on genuine archimedean data. -/
theorem coupledWeilBurnol_psd_on_primeNull (w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat) (hnull : PrimeNull v M c N) :
    Rnonneg (weilQuad (coupledWeil (fun k => Radd (burnolMult k) (burnolCorr k)) w v M) c N) :=
  coupledWeilCorrected_psd_on_primeNull burnolMult burnolCorr w v M c N burnol_corrected_nonneg hnull

end Multiplicity.UOR.Bridge.F1Square.Square
