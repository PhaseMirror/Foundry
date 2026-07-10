/-
F1 square — the **complex reciprocal** `1/z = z̄/|z|²` (the `v0.16.0` substrate for `1/(s−1)` in the
Euler–Maclaurin continuation of `ζ`, and the `Γ`-factor place — goals A and B). Built on the real
inverse law `Rmul_Rinv_self` (`RealDiv`): with `N = |z|² = (Re z)² + (Im z)²` and `I = 1/N` (positivity
via a witness `k`), `1/z := (Re z)·I − i·(Im z)·I`, and the defining identity `z·(1/z) = 1` reduces
componentwise to `Re = ((Re z)² + (Im z)²)·I = N·I = 1` and `Im = (Re z)(Im z)I − (Im z)(Re z)I = 0`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.ComplexMod
import F1Square.Analysis.RealDiv

namespace UOR.Bridge.F1Square.Analysis

/-- `−(−x) ≈ x` (`Rneg` is pointwise, so this is a seq-level identity). -/
private theorem cinv_dneg (x : Real) : Req (Rneg (Rneg x)) x :=
  Req_of_seq_Qeq (fun _ => by simp only [Rneg, Qeq, neg]; push_cast; ring_uor)

/-- **The complex reciprocal** `1/z = z̄/|z|²` (with a positivity witness `k` for `|z|²`). -/
def Cinv (z : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq z).seq k)) : Complex :=
  ⟨Rmul z.re (Rinv (CnormSq z) k hk), Rneg (Rmul z.im (Rinv (CnormSq z) k hk))⟩

/-- **The complex inverse law** `z · (1/z) = 1` (for `z` with `|z|²` positive via the witness `k`). -/
theorem Cmul_Cinv (z : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq z).seq k)) :
    Ceq (Cmul z (Cinv z k hk)) Cone := by
  refine ⟨?_, ?_⟩
  · -- real part: `(Re z)²·I − (Im z)·(−(Im z)·I) = N·I ≈ 1`
    show Req (Rsub (Rmul z.re (Rmul z.re (Rinv (CnormSq z) k hk)))
        (Rmul z.im (Rneg (Rmul z.im (Rinv (CnormSq z) k hk))))) one
    refine Req_trans (Rsub_congr (Req_refl _)
      (Rmul_neg_right z.im (Rmul z.im (Rinv (CnormSq z) k hk)))) ?_
    refine Req_trans (Radd_congr (Req_refl _)
      (cinv_dneg (Rmul z.im (Rmul z.im (Rinv (CnormSq z) k hk))))) ?_
    refine Req_trans (Radd_congr (Req_symm (Rmul_assoc z.re z.re (Rinv (CnormSq z) k hk)))
      (Req_symm (Rmul_assoc z.im z.im (Rinv (CnormSq z) k hk)))) ?_
    refine Req_trans (Req_symm (Rmul_distrib_right (Rmul z.re z.re) (Rmul z.im z.im)
      (Rinv (CnormSq z) k hk))) ?_
    exact Rmul_Rinv_self hk
  · -- imaginary part: `(Re z)·(−(Im z)·I) + (Im z)·(Re z)·I = −X + X ≈ 0`
    show Req (Radd (Rmul z.re (Rneg (Rmul z.im (Rinv (CnormSq z) k hk))))
        (Rmul z.im (Rmul z.re (Rinv (CnormSq z) k hk)))) zero
    have hsecond : Req (Rmul z.im (Rmul z.re (Rinv (CnormSq z) k hk)))
        (Rmul z.re (Rmul z.im (Rinv (CnormSq z) k hk))) :=
      Req_trans (Req_symm (Rmul_assoc z.im z.re (Rinv (CnormSq z) k hk)))
        (Req_trans (Rmul_congr (Rmul_comm z.im z.re) (Req_refl _))
          (Rmul_assoc z.re z.im (Rinv (CnormSq z) k hk)))
    refine Req_trans (Radd_congr (Rmul_neg_right z.re (Rmul z.im (Rinv (CnormSq z) k hk))) hsecond) ?_
    exact Req_trans (Radd_comm (Rneg _) _) (Radd_neg _)

end UOR.Bridge.F1Square.Analysis
