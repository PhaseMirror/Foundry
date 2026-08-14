/-
F1 square — **the multiplicative Haar-measure integral over a bounded interval** (`HaarInterval.lean`):
the first certified integral against the invariant measure `dx/x` of the multiplicative group — the
measure the Mellin transform and the multiplicative convolution theorem integrate against.

The construction reuses the step-3 L² product machinery (`IntegralInner`) with one new integrand:
the clamped reciprocal (`ClampedInv`) packaged as an `L2Test`.

- `innerIonI φ ψ lo w = ∫_lo^{lo+w} φ·ψ` — the L² pairing over a general bounded interval `[lo, lo+w]`
  (the `[0,1]`-fixed `innerI` lifted to a rational interval through the affine gateway
  `riemannIntegralI`), reusing the very same product certificate `l2lip`/`l2fc`.
- `recipTest a` — the clamped reciprocal `1/max(x,a)` as a bounded-Lipschitz test: modulus `(1/a)²`,
  bound `1/a`, both rational; inert (`= 1/x`) on `[a,∞)` and exactly `1/q` at every rational point
  `q ≥ a` (`haarDensity_at_rational`). This is the integrand-ready Haar density.
- `haarIntegral φ a lo w = ∫_lo^{lo+w} φ(x)·(1/max(x,a)) dx` — the multiplicative Haar-measure
  integral. When `a ≤ lo` the density is inert on the whole window, so this is genuinely
  `∫_lo^{lo+w} φ(x) dx/x`. Non-negative for a non-negative test (`haarIntegral_nonneg`).

HONEST SCOPE. This constructs the `dx/x` integral over a bounded interval bounded away from `0`, as
a certified real. What is NOT here: **Haar invariance** — that `∫ φ(x) dx/x = ∫ φ(ax) dx/x` — which
is the defining property of the measure and needs the affine change-of-variables carried through the
`1/x` weight; the exp/log change of variables tying this to the additive line; the multiplicative
convolution `⋆`; and the Mellin convolution theorem. Those are the transform-bridge walls that would
make `weilPrimeGram (vFrom g)` the genuine autocorrelation Gram — step 4, which is RH. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.IntegralInner
import Multiplicity.F1Square.Analysis.ClampedInv
import Multiplicity.F1Square.Analysis.IntervalIntegral

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The L² pairing over a general bounded interval** `⟨φ,ψ⟩_[lo,lo+w] = ∫_lo^{lo+w} φ·ψ` — the
    `[0,1]`-fixed `innerI` lifted to a rational interval through the affine gateway, reusing the
    identical product certificate (`l2lip`, `l2fc`) that `innerI` consumes. -/
def innerIonI (φ ψ : L2Test) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Real :=
  riemannIntegralI (l2L_den φ ψ) (l2L_num φ ψ) (l2lip φ ψ) (l2fc φ ψ) lo w hlo hw hwn

/-- **The interval L² squared norm is non-negative**: `∫_lo^{lo+w} φ² ≥ 0` — the integrand is a
    pointwise square and the certified interval integral preserves non-negativity. -/
theorem innerIonI_self_nonneg (φ : L2Test) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) : Rnonneg (innerIonI φ φ lo w hlo hw hwn) :=
  riemannIntegralI_nonneg (l2L_den φ φ) (l2L_num φ φ) (l2lip φ φ) (l2fc φ φ)
    (fun x => Rnonneg_Rmul_self (φ.f x)) lo w hlo hw hwn

/-- **The clamped reciprocal as a bounded-Lipschitz test** — `recipTest a . f x = 1/max(x,a)`, with
    rational Lipschitz modulus `(1/a)²` and rational bound `1/a`. The integrand-ready Haar density. -/
def recipTest (a : Q) (han : 0 < a.num) (had : 0 < a.den) : L2Test where
  f := clampedInv a han had
  L := mul (Qinv a) (Qinv a)
  M := Qinv a
  hLd := Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han)
  hLn := Int.mul_nonneg (Int.le_of_lt (Qinv_num_pos had)) (Int.le_of_lt (Qinv_num_pos had))
  hMd := Qinv_den_pos han
  hMn := Int.le_of_lt (Qinv_num_pos had)
  hlip := clampedInv_lipschitz a han had
  hfc := fun _ _ h => clampedInv_congr a han had h
  hbd := fun x => Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_clampedInv a han had x)))
    (Rinv_le_ofQ_inv han had (qClampQ_witness a han had x) (Rle_ofQ_qClampQ a had x))

/-- **The Haar density is `1/q` at every rational point `q ≥ a`** — `recipTest a` evaluates to the
    genuine reciprocal on the window, so the integrand is the multiplicative Haar density there, not
    an artefact of the floor clamp. -/
theorem haarDensity_at_rational (a q : Q) (han : 0 < a.num) (had : 0 < a.den) (hqd : 0 < q.den)
    (hqn : 0 < q.num) (haq : Qle a q) :
    Req ((recipTest a han had).f (ofQ q hqd)) (ofQ (Qinv q) (Qinv_den_pos hqn)) :=
  clampedInv_ofQ han had hqd hqn haq

/-- **The multiplicative Haar-measure integral** `∫_lo^{lo+w} φ(x)·(1/max(x,a)) dx` — the certified
    integral of a test against the invariant density `dx/x` over the bounded interval `[lo, lo+w]`.
    For `a ≤ lo` the clamp is inert on the whole window (`haarDensity_at_rational`), so this is the
    genuine `∫ φ dx/x`. -/
def haarIntegral (φ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : Real :=
  innerIonI φ (recipTest a han had) lo w hlo hw hwn

/-- **The Haar integral of a non-negative test is non-negative** — the integrand `φ(x)·(1/max(x,a))`
    is a product of two non-negatives (the density is always `≥ 0`). -/
theorem haarIntegral_nonneg (φ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hφ : ∀ x, Rnonneg (φ.f x)) :
    Rnonneg (haarIntegral φ a han had lo w hlo hw hwn) :=
  riemannIntegralI_nonneg (l2L_den φ (recipTest a han had)) (l2L_num φ (recipTest a han had))
    (l2lip φ (recipTest a han had)) (l2fc φ (recipTest a han had))
    (fun x => Rnonneg_Rmul (hφ x) (Rnonneg_clampedInv a han had x)) lo w hlo hw hwn

end Multiplicity.UOR.Bridge.F1Square.Analysis
