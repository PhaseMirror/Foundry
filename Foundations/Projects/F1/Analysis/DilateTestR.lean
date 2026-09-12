/-
F1 square — **real-scale dilation of a test** (`DilateTestR.lean`): the dilation `x ↦ φ(s·x)` by a
REAL scale `s` (with `|s|` bounded by a rational `S`), generalizing the rational-scale `dilateTest`.

The Mellin transform of a convolution `M[f⋆g](σ) = ∫ (f⋆g)(x) x^{σ-1} dx` integrates over the REAL
output variable `x` of the convolution — so `(f⋆g)(x)` must be evaluated at real `x`, i.e. the
dilation-by-`x` inside `mulConv` must accept a real scale. `dilateTestR s S φ` is that: a genuine
`L2Test` with Lipschitz modulus `φ.L·S` (the rational bound `S ≥ |s|` supplies the rational constant
the integral gateway needs) and bound `φ.M`.

HONEST SCOPE. The real-scale group action only — the foundation for a real-parametrized convolution
and the Mellin integral over the real output variable. It is NOT the Mellin transform, NOT the Mellin
convolution theorem (Wall 3); those are what would identify `mulConv` values at prime powers with
`weilPrimeGram (vFrom g)`, i.e. step 4 = RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.IntegralInner

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Real-scale dilation** `(dilateTestR s S φ).f x = φ(s·x)` for a real scale `s` with `|s| ≤ S`
    (`S` rational) — a genuine `L2Test`: Lipschitz modulus `φ.L·S` (the slope-`s` chain rule,
    `|s·(x−y)| = |s|·|x−y| ≤ S·|x−y|`), bound `φ.M`. Generalizes `dilateTest` to a real scale, as the
    Mellin integral over the convolution's real output variable requires. -/
def dilateTestR (s : Real) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hS : Rle (Rabs s) (ofQ S hSd)) (φ : L2Test) : L2Test where
  f := fun x => φ.f (Rmul s x)
  L := mul φ.L S
  M := φ.M
  hLd := Qmul_den_pos φ.hLd hSd
  hLn := Int.mul_nonneg φ.hLn hSn
  hMd := φ.hMd
  hMn := φ.hMn
  hlip := fun x y => Rle_trans (φ.hlip (Rmul s x) (Rmul s y))
    (Rle_trans
      (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn)
        (Rle_trans
          (Rle_of_Req (Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib s x y)))
            (Rabs_Rmul s (Rsub x y))))
          (Rmul_le_Rmul_right (Rnonneg_Rabs (Rsub x y)) hS)))
      (Rle_of_Req (Req_trans
        (Req_symm (Rmul_assoc (ofQ φ.L φ.hLd) (ofQ S hSd) (Rabs (Rsub x y))))
        (Rmul_congr (Rmul_ofQ_ofQ φ.hLd hSd) (Req_refl _)))))
  hfc := fun _ _ h => φ.hfc _ _ (Rmul_congr (Req_refl s) h)
  hbd := fun x => φ.hbd (Rmul s x)

/-- The real-scale dilation's value — the defining computation. -/
theorem dilateTestR_f (s : Real) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hS : Rle (Rabs s) (ofQ S hSd)) (φ : L2Test) (x : Real) :
    (dilateTestR s S hSd hSn hS φ).f x = φ.f (Rmul s x) := rfl

/-- **Agreement with the rational-scale `dilateTest` value**: at a rational scale `s = ofQ q`, the
    real-scale dilation evaluates as `φ(q·x)` — the same argument the rational `dilateTest q φ` uses,
    so the two agree pointwise (the real-scale action extends the rational one). -/
theorem dilateTestR_ofQ_f (q S : Q) (hqd : 0 < q.den) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hS : Rle (Rabs (ofQ q hqd)) (ofQ S hSd)) (φ : L2Test) (x : Real) :
    Req ((dilateTestR (ofQ q hqd) S hSd hSn hS φ).f x) (φ.f (Rmul (ofQ q hqd) x)) :=
  Req_refl _

end Multiplicity.UOR.Bridge.F1Square.Analysis
