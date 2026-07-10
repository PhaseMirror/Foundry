/-
F1 square — v0.20.0 stage F: **the Li-term modulus growth law**, tying Lever 1 (`ZeroGeometry`) to
the Voros dichotomy (`Voros`) through the genuine multiplicativity `|zw|² = |z|²|w|²`.

The Li coefficient `λₙ = Σ_ρ (1 − (1−1/ρ)ⁿ)`; the per-zero term modulus is `|(1−1/ρ)ⁿ| = r(ρ)ⁿ` with
`r(ρ)² = |1−1/ρ|² = |ρ−1|²/|ρ|²` (`liRatio`). Lever 1 proved `r(ρ)² ≷ 1 ⟺ Re ρ ≶ ½`. This file makes
the GROWTH a theorem: `|zw|² = |z|²|w|²` (`cnormSq_mul`, the Brahmagupta–Fibonacci identity proved by
the `RAddNF`+`RMulNF` "ring" engine), hence `|zⁿ|² = (|z|²)ⁿ` (`cnormSq_npow`). So an off-line zero
(`liRatio > 1`) contributes a Li term whose squared modulus is `liRatioⁿ`, growing geometrically —
the constructive heart of the ¬RH (exponential) regime. The aggregation of the SUM `λₙ` (Voros's
saddle-point) stays [CLASSICAL] interface; WHERE the zeros sit is RH. Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.ZeroGeometry
import F1Square.Analysis.RAddNF
import F1Square.Analysis.RMulNF

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Generic 4-atom additive regroupings (the additive half of the `Real` ring engine, via `RAddNF`).
-- ===========================================================================

/-- Degree-4 additive flattening `(X+Y)+(Z+W) ≈ RsumL [X,Y,Z,W]`. -/
theorem Radd_pair_eq_RsumL4 (X Y Z W : Real) :
    Req (Radd (Radd X Y) (Radd Z W)) (RsumL [X, Y, Z, W]) :=
  Req_trans (Radd_congr (Radd_eq_RsumL X Y) (Radd_eq_RsumL Z W))
    (Req_symm (RsumL_append [X, Y] [Z, W]))

/-- `(X+Y)+(Z+W) ≈ (X+W)+(Y+Z)` (the `regroupX`/`regroupY` shuffle). -/
theorem add4_perm1 (X Y Z W : Real) :
    Req (Radd (Radd X Y) (Radd Z W)) (Radd (Radd X W) (Radd Y Z)) := by
  refine Req_trans (Radd_pair_eq_RsumL4 X Y Z W) ?_
  refine Req_trans (RsumL_perm (List.Perm.cons X
    ((List.Perm.cons Y (List.Perm.swap W Z [])).trans (List.Perm.swap W Y [Z])))) ?_
  exact Req_symm (Radd_pair_eq_RsumL4 X W Y Z)

/-- `(X+Y)+(Z+W) ≈ (X+Z)+(W+Y)` (the final monomial match). -/
theorem add4_perm2 (X Y Z W : Real) :
    Req (Radd (Radd X Y) (Radd Z W)) (Radd (Radd X Z) (Radd W Y)) := by
  refine Req_trans (Radd_pair_eq_RsumL4 X Y Z W) ?_
  refine Req_trans (RsumL_perm (List.Perm.cons X
    ((List.Perm.swap Z Y [W]).trans (List.Perm.cons Z (List.Perm.swap W Y []))))) ?_
  exact Req_symm (Radd_pair_eq_RsumL4 X Z W Y)

/-- `(A − C) + (B + C) ≈ A + B` — the single-pair cancellation (the cross term `C = abcd`). -/
theorem cancelC (A B C : Real) : Req (Radd (Rsub A C) (Radd B C)) (Radd A B) := by
  show Req (Radd (Radd A (Rneg C)) (Radd B C)) (Radd A B)
  refine Req_trans (Radd_assoc A (Rneg C) (Radd B C)) ?_
  refine Radd_congr (Req_refl A) ?_
  refine Req_trans (Radd_comm (Rneg C) (Radd B C)) ?_
  refine Req_trans (Radd_assoc B C (Rneg C)) ?_
  exact Req_trans (Radd_congr (Req_refl B) (Radd_neg C)) (Radd_zero B)

/-- `(e − f) − (g − h) ≈ (e + h) − (f + g)` — regroup the difference-of-squares cross terms. -/
theorem regroupX (e f g h : Real) :
    Req (Rsub (Rsub e f) (Rsub g h)) (Rsub (Radd e h) (Radd f g)) := by
  show Req (Radd (Radd e (Rneg f)) (Rneg (Radd g (Rneg h)))) (Radd (Radd e h) (Rneg (Radd f g)))
  have hL : Req (Rneg (Radd g (Rneg h))) (Radd (Rneg g) h) :=
    Req_trans (Rneg_Radd g (Rneg h)) (Radd_congr (Req_refl _) (Rneg_neg h))
  refine Req_trans (Radd_congr (Req_refl _) hL) ?_
  refine Req_trans (add4_perm1 e (Rneg f) (Rneg g) h) ?_
  exact Radd_congr (Req_refl (Radd e h)) (Req_symm (Rneg_Radd f g))

-- ===========================================================================
-- **`|zw|² = |z|²|w|²`** — the Brahmagupta–Fibonacci identity via the ring engine.
-- ===========================================================================

/-- **The modulus is multiplicative**: `|zw|² = |z|²·|w|²` (`cnormSq` of `Cmul`). Proved by the
    `RAddNF`+`RMulNF` engine: expand both squared real/imaginary parts into degree-4 monomials
    (`prod_sq_reassoc`, `prod_cross_reassoc`), the cross terms `±abcd` cancel (`cancelC`), and the
    four surviving squares match `(a²+b²)(c²+d²)` (`add4_perm2`). -/
theorem cnormSq_mul (z w : Complex) :
    Req (cnormSq (Cmul z w)) (Rmul (cnormSq z) (cnormSq w)) := by
  obtain ⟨a, b⟩ := z
  obtain ⟨c, d⟩ := w
  show Req
    (Radd (Rmul (Rsub (Rmul a c) (Rmul b d)) (Rsub (Rmul a c) (Rmul b d)))
          (Rmul (Radd (Rmul a d) (Rmul b c)) (Radd (Rmul a d) (Rmul b c))))
    (Rmul (Radd (Rmul a a) (Rmul b b)) (Radd (Rmul c c) (Rmul d d)))
  -- Step A: expand both squares (grouped form). Cross monomials are already `m = (ac)(bd)`,
  -- `m' = (bd)(ac)` on the X-side; `prod_cross` only rewrites the Y-side `(ad)(bc)`, `(bc)(ad)`.
  have hXX : Req (Rmul (Rsub (Rmul a c) (Rmul b d)) (Rsub (Rmul a c) (Rmul b d)))
      (Rsub (Rsub (Rmul (Rmul a c) (Rmul a c)) (Rmul (Rmul a c) (Rmul b d)))
            (Rsub (Rmul (Rmul b d) (Rmul a c)) (Rmul (Rmul b d) (Rmul b d)))) :=
    Req_trans (Rmul_sub_distrib_right (Rmul a c) (Rmul b d) (Rsub (Rmul a c) (Rmul b d)))
      (Rsub_congr (Rmul_sub_distrib (Rmul a c) (Rmul a c) (Rmul b d))
                  (Rmul_sub_distrib (Rmul b d) (Rmul a c) (Rmul b d)))
  have hYY : Req (Rmul (Radd (Rmul a d) (Rmul b c)) (Radd (Rmul a d) (Rmul b c)))
      (Radd (Radd (Rmul (Rmul a d) (Rmul a d)) (Rmul (Rmul a d) (Rmul b c)))
            (Radd (Rmul (Rmul b c) (Rmul a d)) (Rmul (Rmul b c) (Rmul b c)))) :=
    Req_trans (Rmul_distrib_right (Rmul a d) (Rmul b c) (Radd (Rmul a d) (Rmul b c)))
      (Radd_congr (Rmul_distrib (Rmul a d) (Rmul a d) (Rmul b c))
                  (Rmul_distrib (Rmul b c) (Rmul a d) (Rmul b c)))
  refine Req_trans (Radd_congr hXX hYY) ?_
  -- Step B: normalize each monomial.  Squares → a²c² etc (`prod_sq`); Y-cross → m, m' (`prod_cross`).
  refine Req_trans (Radd_congr
      (Rsub_congr (Rsub_congr (prod_sq_reassoc a c) (Req_refl (Rmul (Rmul a c) (Rmul b d))))
                  (Rsub_congr (Req_refl (Rmul (Rmul b d) (Rmul a c))) (prod_sq_reassoc b d)))
      (Radd_congr (Radd_congr (prod_sq_reassoc a d) (Req_symm (prod_cross_reassoc a b c d)))
                  (Radd_congr (Req_symm (prod_cross_reassoc b a d c)) (prod_sq_reassoc b c)))) ?_
  -- now: Radd (Rsub (Rsub u m)(Rsub m' v)) (Radd (Radd w₀ m)(Radd m' r))
  refine Req_trans (Radd_congr
      (regroupX (Rmul (Rmul a a) (Rmul c c)) (Rmul (Rmul a c) (Rmul b d))
        (Rmul (Rmul b d) (Rmul a c)) (Rmul (Rmul b b) (Rmul d d)))
      (add4_perm1 (Rmul (Rmul a a) (Rmul d d)) (Rmul (Rmul a c) (Rmul b d))
        (Rmul (Rmul b d) (Rmul a c)) (Rmul (Rmul b b) (Rmul c c)))) ?_
  -- cancel the cross term m+m'
  refine Req_trans (cancelC (Radd (Rmul (Rmul a a) (Rmul c c)) (Rmul (Rmul b b) (Rmul d d)))
      (Radd (Rmul (Rmul a a) (Rmul d d)) (Rmul (Rmul b b) (Rmul c c)))
      (Radd (Rmul (Rmul a c) (Rmul b d)) (Rmul (Rmul b d) (Rmul a c)))) ?_
  -- (u+v)+(w₀+r) ≈ (u+w₀)+(r+v) = RHS expansion
  refine Req_trans (add4_perm2 (Rmul (Rmul a a) (Rmul c c)) (Rmul (Rmul b b) (Rmul d d))
      (Rmul (Rmul a a) (Rmul d d)) (Rmul (Rmul b b) (Rmul c c))) ?_
  exact Req_symm (Req_trans (Rmul_distrib_right (Rmul a a) (Rmul b b) (Radd (Rmul c c) (Rmul d d)))
    (Radd_congr (Rmul_distrib (Rmul a a) (Rmul c c) (Rmul d d))
      (Rmul_distrib (Rmul b b) (Rmul c c) (Rmul d d))))

-- ===========================================================================
-- **The power law `|zⁿ|² = (|z|²)ⁿ`** and the geometric growth of an off-line Li term.
-- ===========================================================================

/-- Natural power on `Real`. -/
def Rnpow (x : Real) : Nat → Real
  | 0 => one
  | (k + 1) => Rmul x (Rnpow x k)

/-- Natural power of a complex number. -/
def Cnpow (z : Complex) : Nat → Complex
  | 0 => Cone
  | (k + 1) => Cmul z (Cnpow z k)

/-- `|1|² = 1`. -/
theorem cnormSq_one : Req (cnormSq Cone) one :=
  Req_trans (Radd_congr (Rmul_one one) (Rmul_zero zero)) (Radd_zero one)

/-- **THE MODULUS POWER LAW** `|zⁿ|² = (|z|²)ⁿ` — iterated `cnormSq_mul`. -/
theorem cnormSq_npow (z : Complex) : ∀ k, Req (cnormSq (Cnpow z k)) (Rnpow (cnormSq z) k)
  | 0 => cnormSq_one
  | (k + 1) =>
      Req_trans (cnormSq_mul z (Cnpow z k))
        (Rmul_congr (Req_refl (cnormSq z)) (cnormSq_npow z k))

/-- `xⁿ ≥ 0` for `x ≥ 0`. -/
theorem Rnpow_nonneg {x : Real} (hx : Rnonneg x) : ∀ k, Rnonneg (Rnpow x k)
  | 0 => Rnonneg_one
  | (k + 1) => Rnonneg_Rmul hx (Rnpow_nonneg hx k)

/-- **Monotonicity** `0 ≤ x ≤ y ⟹ xⁿ ≤ yⁿ`. -/
theorem Rnpow_le_Rnpow {x y : Real} (hx : Rnonneg x) (hxy : Rle x y) :
    ∀ k, Rle (Rnpow x k) (Rnpow y k)
  | 0 => Rle_refl one
  | (k + 1) => by
      have hy : Rnonneg y := Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg hx) hxy)
      exact Rle_trans (Rmul_le_Rmul_left hx (Rnpow_le_Rnpow hx hxy k))
        (Rmul_le_Rmul_right (Rnpow_nonneg hy k) hxy)

/-- `|z|² ≥ 0`. -/
theorem cnormSq_nonneg (z : Complex) : Rnonneg (cnormSq z) :=
  Rnonneg_Radd (Rnonneg_Rmul_self z.re) (Rnonneg_Rmul_self z.im)

/-- **THE LI-TERM GROWTH SEED**: a zero LEFT of the critical line (`Re ρ < ½`) makes its Li numerator
    `(ρ−1)ⁿ` dominate `ρⁿ` in modulus FOR EVERY `n` — `|ρ|²ⁿ ≤ |ρ−1|²ⁿ`, i.e. `(cnormSq ρ)ⁿ ≤
    (csubOneNormSq ρ)ⁿ`. So `|(1−1/ρ)ⁿ| = |(ρ−1)ⁿ|/|ρⁿ| ≥ 1` and grows geometrically: the
    constructive heart of Voros's exponential (¬RH) regime. The aggregation of the SUM `λₙ` (the
    saddle-point) stays [CLASSICAL] interface; the crux fields stay `none`. -/
theorem liTerm_dominates (ρ : Complex) (h : Pos (Rsub half ρ.re)) :
    ∀ n, Rle (Rnpow (cnormSq ρ) n) (Rnpow (csubOneNormSq ρ) n) :=
  fun n => Rnpow_le_Rnpow (cnormSq_nonneg ρ)
    (Rle_of_Rnonneg_Rsub (Rnonneg_of_Pos (liRatio_left_of_line ρ h))) n

end UOR.Bridge.F1Square.Analysis
