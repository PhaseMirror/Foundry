/-
F1 square — **the reflection covariance in log-coordinates** (`LogReflect.lean`): the multiplicative
inversion `x ↦ 1/x` becomes the additive negation `u ↦ −u` under `logPull` (the `φ ↦ φ∘exp` bridge),
the sibling of `logPull_dilate_shift` (dilation ↦ additive shift).

    `logPull (reflectTest a φ) u  ≈  logPull φ (−u)`     (on the window `exp u ≥ a`, clamp inert)

WHY (grounding `v = ĝ`, the self-dual arm). The autocorrelation `g ⋆ g^τ` uses the multiplicative
reflection `g^τ(x) = g(1/x) = reflectTest a g`. Its Mellin transform is the reflected transform
`M[g^τ](s) = M[g](−s)`; that reflection is exactly `u ↦ −u` in the additive log-coordinate. This
brick is the log-coordinate keystone of that reflection identity: it turns the multiplicative
inversion of a test into a negation of the log-argument, exact on the window where the floor clamp is
inert. The `M[g^τ](m) = M[g](−m)` step the autocorrelation recovery needs (matching
`weilPrimeGram (vHat g)` to the genuine autocorrelation prime side) rests on this covariance plus the
log-coordinate integral representation of `mellinHat` — the next bricks on top of it.

The proof: on `exp u ≥ a` the clamp drops (`clampedInv_eq_of_ge`), leaving `1/exp u`; and
`1/exp u = exp(−u)` because `exp(−u)·exp u = exp(−u+u) = exp 0 = 1` (`RexpReal_add`, the inverse
uniqueness `Rinv_eq_of_Rmul_left`). Then `φ.hfc` lifts the argument equality through `φ`.

HONEST SCOPE. The reflection→negation covariance of `logPull`, on the inert window. It is NOT the
reflection of the Mellin MOMENT/transform (`mellinHat (reflectTest a g)` — needs the log-coordinate
integral representation on top), NOT the autocorrelation identification
`weilPrimeGram (vHat g) = weilPrimePart(g_i ⋆ g_j^τ)`, and applies NO step-4 positivity
(`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MultShift
import Foundations.F1.Analysis.ReflectTest
import Foundations.F1.Analysis.RealDiv
import Foundations.F1.Analysis.ComplexExp

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Inverse uniqueness (left)**: if `y·x ≈ 1` then `1/x ≈ y` — the constructive reciprocal is the
    unique left inverse. `y ≈ y·1 ≈ y·(x·(1/x)) ≈ (y·x)·(1/x) ≈ 1·(1/x) ≈ 1/x`. -/
private theorem Rinv_eq_of_Rmul_left {x y : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k))
    (hmul : Req (Rmul y x) one) : Req (Rinv x k hk) y :=
  Req_symm
    (Req_trans (Req_symm (Rmul_one y))
      (Req_trans (Rmul_congr (Req_refl y) (Req_symm (Rmul_Rinv_self hk)))
        (Req_trans (Req_symm (Rmul_assoc y x (Rinv x k hk)))
          (Req_trans (Rmul_congr hmul (Req_refl (Rinv x k hk)))
            (Rone_mul (Rinv x k hk))))))

/-- **The reflection covariance in log-coordinates**: `logPull (reflectTest a φ) u ≈ logPull φ (−u)`
    on the window `exp u ≥ a` (positivity witness `kx` for `exp u`). The multiplicative inversion
    `x ↦ 1/x` of `reflectTest` is the additive negation `u ↦ −u` under `logPull`; the sibling of
    `logPull_dilate_shift`. This is the log-coordinate form of `M[g^τ](s) = M[g](−s)`. -/
theorem logPull_reflect_neg (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    (u : Real) {kx : Nat} (hkx : Qlt (Qbound kx) ((RexpReal u).seq kx))
    (hx : Rle (ofQ a had) (RexpReal u)) :
    Req (logPull (reflectTest a han had φ) u) (logPull φ (Rneg u)) := by
  -- exp(−u)·exp u = exp(−u+u) = exp 0 = 1
  have haddz : Req (Radd (Rneg u) u) zero := Req_trans (Radd_comm (Rneg u) u) (Radd_neg u)
  have hmul : Req (Rmul (RexpReal (Rneg u)) (RexpReal u)) one :=
    Req_trans (Req_symm (RexpReal_add (Rneg u) u))
      (Req_trans (RexpReal_congr haddz) RexpReal_zero)
  -- clampedInv(exp u) = 1/exp u = exp(−u), on the inert window
  have harg : Req (clampedInv a han had (RexpReal u)) (RexpReal (Rneg u)) :=
    Req_trans (clampedInv_eq_of_ge hkx hx) (Rinv_eq_of_Rmul_left hkx hmul)
  show Req (φ.f (clampedInv a han had (RexpReal u))) (φ.f (RexpReal (Rneg u)))
  exact φ.hfc _ _ harg

/-- **The reflection generator's interaction with dilation** (the second multiplicative-group law in
    log-coordinates, completing `MultShift`'s dilation laws): reflecting a dilated test negates the
    argument AND adds the dilation shift —
    `logPull (reflectTest a (dilateTest n φ)) u ≈ logPull φ (log n − u)`. The honest analog of
    `logPull_dilate_shift_comp` for the reflection generator (`reflect ∘ dilate`); composes
    `logPull_reflect_neg` (reflect ↦ negation) with `logPull_dilate_shift` (dilate ↦ shift), at the
    negated argument `−u`. On the window `exp u ≥ a`. -/
theorem logPull_reflect_dilate (a : Q) (han : 0 < a.num) (had : 0 < a.den) (n : Nat) (hn : 1 ≤ n)
    (φ : L2Test) (u : Real) {kx : Nat} (hkx : Qlt (Qbound kx) ((RexpReal u).seq kx))
    (hx : Rle (ofQ a had) (RexpReal u)) :
    Req (logPull (reflectTest a han had
            (dilateTest (⟨(n : Int), 1⟩ : Q) (by show (0:Int) < (n:Int); omega) Nat.one_pos φ)) u)
        (logPull φ (Radd (logN n hn) (Rneg u))) :=
  Req_trans
    (logPull_reflect_neg a han had
      (dilateTest (⟨(n : Int), 1⟩ : Q) (by show (0:Int) < (n:Int); omega) Nat.one_pos φ) u hkx hx)
    (logPull_dilate_shift n hn φ (Rneg u))

/-- **The reflection is an involution on the symmetric window** (the order-2 group law, completing the
    reflection generator's log-coordinate laws): applying `reflectTest` twice returns the original test —
    `logPull (reflectTest a (reflectTest a φ)) u ≈ logPull φ u` — on the reciprocal-symmetric window
    `a ≤ exp u ≤ 1/a` (i.e. both `exp u ≥ a` and `exp(−u) ≥ a`, the domain where both clamps are inert).
    Two applications of `logPull_reflect_neg` (`u ↦ −u ↦ −(−u) = u`) and `Rneg_neg`. This is the
    structural reason `g^τ` is self-inverse — the reflection generator of the multiplicative group. -/
theorem logPull_reflect_involutive (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test)
    (u : Real) {kx : Nat} (hkx : Qlt (Qbound kx) ((RexpReal u).seq kx))
    (hx : Rle (ofQ a had) (RexpReal u))
    {kx2 : Nat} (hkx2 : Qlt (Qbound kx2) ((RexpReal (Rneg u)).seq kx2))
    (hx2 : Rle (ofQ a had) (RexpReal (Rneg u))) :
    Req (logPull (reflectTest a han had (reflectTest a han had φ)) u) (logPull φ u) :=
  Req_trans (logPull_reflect_neg a han had (reflectTest a han had φ) u hkx hx)
    (Req_trans (logPull_reflect_neg a han had φ (Rneg u) hkx2 hx2)
      (φ.hfc _ _ (RexpReal_congr (Rneg_neg u))))

end Multiplicity.UOR.Bridge.F1Square.Square
