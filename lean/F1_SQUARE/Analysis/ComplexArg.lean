/-
F1 square — v0.22.0 Track 1, brick (complex lift): **the complex argument `arg(z)` on the principal
sector** — `arg(z) = arctan(Im z / Re z)` for `Re z > 0` and `|Im z / Re z| ≤ ρ < 1`.

The next brick after real-argument arctan (`RArctan.lean`) toward the complex logarithm `Clog`
(`Clog z = ½·log|z|² + i·arg(z)`), which `log ξ` and `ζ′/ζ` need. Built directly on `RarctanR`
(brick 1) and the constructive real division `Rdiv` (`Inv.lean`). The first property is the
value on a positive real: `arg(x) = 0` for `x > 0` (`Im = 0`, so the ratio has numerator `0` and
`RarctanR_of_num_zero` gives `0`).

(Principal sector only — `|arg| < π/4`; the full-range argument via the `|t| ≥ 1` reduction
`arctan t = ±π/2 − arctan(1/t)` and quadrant adjustments is a later brick.)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.RArctan
import F1Square.Analysis.Inv
import F1Square.Analysis.Complex

namespace UOR.Bridge.F1Square.Analysis

/-- **The complex argument on the principal sector**: `arg(z) = arctan(Im z / Re z)` for `Re z > 0`
    (witness `k`) and `|Im z / Re z| ≤ ρ < 1`. -/
def Carg (z : Complex) (k : Nat) (hk : Qlt (Qbound k) (z.re.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.im z.re k hk).seq n)) ρ) : Real :=
  RarctanR (Rdiv z.im z.re k hk) ρ hρ0 hρd hρlt hb

/-- **`arg(x) = 0` for a positive real `x`**: a point on the positive real axis (`Im = 0`) has
    argument `0`. The ratio `Im/Re = 0/x` has vanishing numerators, so `RarctanR_of_num_zero` applies.
    The principal-branch anchor for `Clog` of a positive real. -/
theorem Carg_ofReal_pos (x : Real) (k : Nat) (hk : Qlt (Qbound k) ((ofReal x).re.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (ofReal x).im (ofReal x).re k hk).seq n)) ρ) :
    Req (Carg (ofReal x) k hk ρ hρ0 hρd hρlt hb) zero := by
  unfold Carg
  refine RarctanR_of_num_zero (Rdiv (ofReal x).im (ofReal x).re k hk) ?_ ρ hρ0 hρd hρlt hb
  intro n
  show ((Rmul zero (Rinv x k hk)).seq n).num = 0
  show (mul (zero.seq (Ridx zero (Rinv x k hk) n))
        ((Rinv x k hk).seq (Ridx zero (Rinv x k hk) n))).num = 0
  rw [zero_seq]; simp [mul]

end UOR.Bridge.F1Square.Analysis
