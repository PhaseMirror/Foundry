/-
F1 square — the frontier brick: **the Riemann–Siegel angle is non-monotonic at the window center.**

THE OBSTRUCTION, FORMALIZED. The verified literature reconnaissance (the v0.21.0+ deep-research
survey) located the honest frontier precisely: the ONLY unconditional positivity in the Weil
explicit-formula program is Connes–Consani's single-archimedean-place positivity on the prime-free
Sonine window (*Selecta Math.* 27 (2021); formalized here as `archimedean_center_positive` /
`prime_window_maximal`), and its SEMI-LOCAL generalization is presented only as "a potential
conceptual reason" — with an OBSTRUCTION explicitly noted: the Riemann–Siegel angle is non-monotonic.

The Riemann–Siegel angle is
    `θ(t) = arg Γ(1/4 + i t/2) − (t/2)·log π`,
the phase of the completed zeta's functional equation `ξ(1/2 + it) = e^{−iθ(t)}·Z(t)` (`Z` real).
A monotonicity-based argument that would carry the single-place positivity across additional places
needs `θ` increasing; but `θ` is NOT monotone. Its center slope is
    `θ′(0) = (1/2)·(Re ψ(1/4 + i·0/2) − log π) = (1/2)·(ψ(1/4) − log π)`,
and at the window center `ψ(1/4) ≈ −4.2270 < log π ≈ 1.1447`, so `θ′(0) < 0` — `θ` DECREASES through
the symmetry point `t = 0` before rising for large `t` (`θ′(t) ∼ (1/2)·log(t/2π) → +∞`). The dip is
the obstruction: the phase is not monotone, so positivity does not propagate by monotonicity alone.

THIS FILE makes that an axiom-clean theorem. `rsCenterSlope := ψ(1/4) − log π` is the discriminant
`2·θ′(0)` (the positive factor `1/2` does not change its sign), and `rsCenterSlope_neg : Pos (Rneg
rsCenterSlope)` proves it strictly negative — `ψ(1/4) < log π` — from the two complementary brackets
`psiQuarter_upper` (`ψ(1/4) ≤ −3`, the value bounded ABOVE, opposite to the α(0) certificate) and
`Rnonneg_Rlog_pi` (`log π ≥ 0`, since `π ≥ 1`). Both inputs use only the genuine constructive reals
`psiQuarter` and `Rlog_pi` already built in this substrate.

THE HONEST BOUNDARY. This is the OBSTRUCTION, formalized faithfully — NOT a step toward closing it.
Proving `θ` non-monotone is precisely what blocks the naive monotonicity route from single-place to
semi-local positivity; it does not supply the route. The crux fields stay `none`: the unconditional
content remains confined to the archimedean window (`archimedean_center_positive`), and the
semi-local generalization is — by the survey's verified finding — equivalent to RH.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.PsiQuarter
import F1Square.Analysis.Gamma
import F1Square.Analysis.CosSinBound

namespace UOR.Bridge.F1Square.Analysis

/-- `(π−1)/(π+1) ≥ 0` lifts to a non-negative real (`π ≥ 1`). -/
theorem Rnonneg_RpiTmap : Rnonneg RpiTmap := by
  intro n
  have h1 : (0 : Int) ≤ (RpiTmap.seq n).num := RpiTmap_nonneg n
  have h4 : (0 : Int) ≤ (RpiTmap.seq n).num * ((n : Int) + 1) := Int.mul_nonneg h1 (by omega)
  simp only [Qle, neg, Qbound]
  push_cast
  omega

/-- **`log π ≥ 0`** (since `π ≥ 1`): `Rnonneg Rlogπc`. The repo's canonical constructive log π,
    `Rlogπc = 2·artanh((π−1)/(π+1))` (`GammaAccel`, the `log π` of α(0)/λ₁/λ₂), is non-negative —
    `artanh` of the non-negative argument `(π−1)/(π+1)` (`Rnonneg_Rartanh_of_nonneg`). -/
theorem Rnonneg_Rlogπc : Rnonneg Rlogπc := by
  unfold Rlogπc
  refine Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) ?_
  exact Rnonneg_Rartanh_of_nonneg RpiTmap (⟨15, 29⟩ : Q) (by decide) (by decide) (by decide)
    RpiTmap_abs_le Rnonneg_RpiTmap

/-- **The Riemann–Siegel center slope discriminant** `2·θ′(0) = ψ(1/4) − log π`, with `log π = Rlogπc`
    (the repo's canonical constructive log π). Its sign IS the sign of `θ′(0)` (the `1/2` factor is
    positive); proving it negative is proving `θ` decreasing at the window center. -/
def rsCenterSlope : Real := Rsub psiQuarter Rlogπc

/-- **THE OBSTRUCTION, FORMALIZED: `θ′(0) < 0` — the Riemann–Siegel angle decreases through the window
    center.** `ψ(1/4) − log π < 0`, i.e. `ψ(1/4) < log π`, from `ψ(1/4) ≤ −3` (`psiQuarter_upper`)
    and `log π ≥ 0` (`Rnonneg_Rlogπc`): the slope discriminant is `≤ −3 < 0`, so the center value
    `log π − ψ(1/4) ≥ 3 > 0`. This is the non-monotonicity that Connes–Consani name as the obstruction
    to extending the single-archimedean-place Weil positivity to the semi-local case — made an
    axiom-clean theorem, faithful to the obstruction. It does NOT close the crux (it is the barrier,
    not a route through it); the crux fields stay `none`. -/
theorem rsCenterSlope_neg : Pos (Rneg rsCenterSlope) := by
  refine Pos_congr (Req_symm (Rneg_Rsub psiQuarter Rlogπc)) ?_
  refine Pos_of_Rle_ofQ (c := (⟨3, 1⟩ : Q)) (by decide) (by decide) ?_
  have hconv3 : Rle (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rneg (ofQ (⟨-3, 1⟩ : Q) (by decide))) :=
    fun n => Qle_self_add (by show (0 : Int) ≤ 2; decide)
  have h1 : Rle (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rneg psiQuarter) :=
    Rle_trans hconv3 (Rneg_le psiQuarter_upper)
  have h2 : Rle (Rneg psiQuarter) (Rsub Rlogπc psiQuarter) :=
    Rle_self_Radd_left Rnonneg_Rlogπc
  exact Rle_trans h1 h2

end UOR.Bridge.F1Square.Analysis
