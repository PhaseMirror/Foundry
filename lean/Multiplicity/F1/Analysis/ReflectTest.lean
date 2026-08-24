/-
F1 square — **the multiplicative inversion of a test** (`ReflectTest.lean`): the reflection
`g^τ(x) = g(1/x)` of the multiplicative group, the second symmetry (after `dilateTest`) the
autocorrelation `g ⋆ g^τ` of the Weil prime side is built from.

`reflectTest a g` sends `x ↦ g(1/max(x,a))` — the clamped reciprocal (`ClampedInv`) precomposed with
`g`. On the window `[a, ∞)` the clamp is inert, so `(reflectTest a g).f x = g(1/x)` there; the floor
`a > 0` is what makes it a total, globally-Lipschitz `L2Test` (the reciprocal is `(1/a)²`-Lipschitz
above the floor, so the composite is `(L_g·(1/a)²)`-Lipschitz, bound `M_g`).

HONEST SCOPE. The inversion group action on tests — NOT the convolution `⋆`, NOT the Mellin theorem;
those (Wall 2/3) are what would make `weilPrimeGram (vFrom g)` the genuine autocorrelation Gram, i.e.
step 4 = RH. Because of the floor clamp this is not a strict involution (double-clamping is not the
identity); it is the reflection operator on the class, inert on the window. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.IntegralInner
import Multiplicity.F1.Analysis.ClampedInv

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The multiplicative inversion of a test** `(reflectTest a g).f x = g(1/max(x,a))` — the
    reflection `g^τ(x) = g(1/x)` of the multiplicative group, totalized by the rational floor
    `a > 0`. A genuine `L2Test`: Lipschitz modulus `L_g·(1/a)²` (chain rule through the
    `(1/a)²`-Lipschitz clamped reciprocal), bound `M_g`. -/
def reflectTest (a : Q) (han : 0 < a.num) (had : 0 < a.den) (g : L2Test) : L2Test where
  f := fun x => g.f (clampedInv a han had x)
  L := mul g.L (mul (Qinv a) (Qinv a))
  M := g.M
  hLd := Qmul_den_pos g.hLd (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han))
  hLn := Int.mul_nonneg g.hLn
    (Int.mul_nonneg (Int.le_of_lt (Qinv_num_pos had)) (Int.le_of_lt (Qinv_num_pos had)))
  hMd := g.hMd
  hMn := g.hMn
  hlip := fun x y => Rle_trans (g.hlip (clampedInv a han had x) (clampedInv a han had y))
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ g.hLd g.hLn) (clampedInv_lipschitz a han had x y))
      (Rle_of_Req (Req_trans
        (Req_symm (Rmul_assoc (ofQ g.L g.hLd)
          (ofQ (mul (Qinv a) (Qinv a)) (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han)))
          (Rabs (Rsub x y))))
        (Rmul_congr (Rmul_ofQ_ofQ g.hLd (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han)))
          (Req_refl _)))))
  hfc := fun _ _ h => g.hfc _ _ (clampedInv_congr a han had h)
  hbd := fun x => g.hbd (clampedInv a han had x)

/-- **The reflection is inert on the window**: for `x ≥ a` (with a positivity witness `kx` for `x`),
    `(reflectTest a g).f x ≈ g(1/x)` — the clamp drops away and the operator is the genuine
    multiplicative inversion `g^τ(x) = g(1/x)`. -/
theorem reflectTest_eq_of_ge (a : Q) (han : 0 < a.num) (had : 0 < a.den) (g : L2Test)
    {x : Real} {kx : Nat} (hkx : Qlt (Qbound kx) (x.seq kx)) (hx : Rle (ofQ a had) x) :
    Req ((reflectTest a han had g).f x) (g.f (Rinv x kx hkx)) :=
  g.hfc _ _ (clampedInv_eq_of_ge hkx hx)

/-- **The reflection at a rational point `q ≥ a`**: `(reflectTest a g).f (ofQ q) ≈ g(1/q)` — the
    inversion evaluates exactly at rational arguments (the partition points the integral samples). -/
theorem reflectTest_ofQ (a q : Q) (han : 0 < a.num) (had : 0 < a.den) (hqd : 0 < q.den)
    (hqn : 0 < q.num) (haq : Qle a q) (g : L2Test) :
    Req ((reflectTest a han had g).f (ofQ q hqd)) (g.f (ofQ (Qinv q) (Qinv_den_pos hqn))) :=
  g.hfc _ _ (clampedInv_ofQ han had hqd hqn haq)

end Multiplicity.UOR.Bridge.F1Square.Analysis
