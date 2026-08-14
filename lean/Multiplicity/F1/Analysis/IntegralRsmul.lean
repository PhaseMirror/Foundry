/-
F1 square — **real-scalar linearity of the certified integral** (`IntegralRsmul.lean`). The existing
scalar law `riemannIntegral_smul` scales by a RATIONAL constant `q : ℚ`; this brick supplies the
missing REAL-scalar case:

    `∫₀¹ (c·f) = c·∫₀¹ f`   for any `c : Real`   (`riemannIntegral_Rsmul`),

the piece the "full linear-algebra API" (add/neg/smul/congr) was missing for real coefficients. The
one new analytic ingredient is that a real scalar commutes with the Bishop limit,

    `lim (c·X) = c·(lim X)`   (`Rmul_Rlim_of_approx`),

which the rational version got from `Rlim_ofQ_mul_of_approx` (tied to `ofQ q`). Here it is proved
directly from the two-sided convergence rate `|X m − lim X| ≤ 2/(m+1)` (`Rabs_dist_Rlim`) and the
rational bound `|c| ≤ xBound c` (`canon_bound`): the gap `|lim(c·X) − c·lim X|` telescopes through
`(c·X)_m` to `(2 + 2·xBound c)/(m+1)`, and the real-level squeeze (`Req_of_Rle_ofQ_all`) closes.

WHY. The Bernstein determinacy arc integrates `φ` against the operator `B_n(φ)(x) = Σ_k φ(k/n)·b_{n,k}(x)`,
whose coefficients `φ(k/n)` are REALS. Each single-basis integral already vanishes
(`innerI_bernBasis_zero`); pulling the real coefficient out of the integral, `∫φ·(c·b_{n,k}) =
c·∫φ·b_{n,k} = c·0 = 0`, needs exactly this real-scalar law.

HONEST SCOPE. Real-scalar linearity of the base integral over `[0,1]`, and the underlying limit law.
General real-analysis infrastructure; nothing here touches the Weil form, the moment problem, or
determinacy directly. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.DyadicIntegral
import Multiplicity.F1Square.Analysis.IntegralCertIrrel
import Multiplicity.F1Square.Analysis.ComplexZeta

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **A real is bounded in absolute value by its `xBound`**: `|c| ≤ xBound c` (as reals), directly
    from the canonical rational bound `canon_bound`. -/
theorem Rabs_le_ofQ_xBound (c : Real) :
    Rle (Rabs c) (ofQ (⟨(xBound c : Int), 1⟩ : Q) Nat.one_pos) := by
  intro n
  show Qle (Qabs (c.seq n)) (add (⟨(xBound c : Int), 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  exact Qle_trans Nat.one_pos (canon_bound c n) (Qle_self_add (by show (0:Int) ≤ 2; decide))

/-- `|a − c| ≤ |a − b| + |b − c|` at the real level (triangle through `b`). -/
private theorem Rabs_Rsub_triangle (a b d : Real) :
    Rle (Rabs (Rsub a d)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b d))) := by
  have htel : Req (Rsub a d) (Radd (Rsub a b) (Rsub b d)) := by
    show Req (Radd a (Rneg d)) (Radd (Radd a (Rneg b)) (Radd b (Rneg d)))
    refine Req_symm (Req_trans (Radd_assoc a (Rneg b) (Radd b (Rneg d))) ?_)
    refine Radd_congr (Req_refl a) ?_
    refine Req_trans (Req_symm (Radd_assoc (Rneg b) b (Rneg d))) ?_
    refine Req_trans (Radd_congr (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
      (Req_refl (Rneg d))) ?_
    exact Req_trans (Radd_comm zero (Rneg d)) (Radd_zero (Rneg d))
  exact Rle_trans (Rle_of_Req (Rabs_congr htel)) (Rabs_Radd (Rsub a b) (Rsub b d))

/-- `|a − b| ≈ |b − a|` (real level). -/
private theorem Rabs_Rsub_comm (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Rabs_congr (Req_symm (Rneg_Rsub_flip b a))) (Rabs_Rneg (Rsub b a))

/-- **A real scalar commutes with the Bishop limit** (approximate form): if `W j ≈ c·X j` and both
    are regular, then `lim W ≈ c·(lim X)`. The gap `|lim W − c·lim X| ≤ |lim W − W m| + |W m − c·lim X|`
    telescopes to `(2 + 2·xBound c)/(m+1)` for every `m` — the first summand is the limit rate, the
    second is `|c|·|X m − lim X| ≤ xBound c · 2/(m+1)` — and the real squeeze closes. -/
theorem Rmul_Rlim_of_approx (c : Real) (W X : Nat → Real) (hX : RReg X) (hW : RReg W)
    (happ : ∀ j, Req (W j) (Rmul c (X j))) :
    Req (Rlim W hW) (Rmul c (Rlim X hX)) := by
  have hB := Rabs_le_ofQ_xBound c
  -- per-`m` two-sided bound `|lim W − c·lim X| ≤ (2 + 2·xBound c)/(m+1)`
  have hrate : ∀ m, Rle (Rabs (Rsub (Rlim W hW) (Rmul c (Rlim X hX))))
      (ofQ (⟨((2 + 2 * xBound c : Nat) : Int), m + 1⟩ : Q) (Nat.succ_pos m)) := by
    intro m
    -- `|lim W − W m| ≤ 2/(m+1)`
    have hMW : Rle (Rabs (Rsub (Rlim W hW) (W m))) (ofQ (⟨2, m + 1⟩ : Q) (Nat.succ_pos m)) :=
      Rle_trans (Rle_of_Req (Rabs_Rsub_comm (Rlim W hW) (W m))) (Rabs_dist_Rlim hW m)
    -- `|W m − c·lim X| ≤ 2·xBound c/(m+1)`
    have hWcL : Rle (Rabs (Rsub (W m) (Rmul c (Rlim X hX))))
        (ofQ (⟨(2 * xBound c : Nat), m + 1⟩ : Q) (Nat.succ_pos m)) := by
      refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (happ m) (Req_refl _)))) ?_
      refine Rle_trans (Rle_of_Req (Rabs_congr
        (Req_symm (Rmul_sub_distrib c (X m) (Rlim X hX))))) ?_
      refine Rle_trans (Rle_of_Req (Rabs_Rmul c (Rsub (X m) (Rlim X hX)))) ?_
      refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs c) (Rabs_dist_Rlim hX m)) ?_
      refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos m) (by show (0:Int) ≤ 2; decide)) hB) ?_
      refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos (Nat.succ_pos m)) ?_)
      exact ofQ_congr (Qmul_den_pos Nat.one_pos (Nat.succ_pos m)) (Nat.succ_pos m)
        (by show Qeq (mul (⟨(xBound c : Int), 1⟩ : Q) (⟨2, m + 1⟩ : Q))
              (⟨(2 * xBound c : Nat), m + 1⟩ : Q); simp only [Qeq, mul]; push_cast; ring_uor)
    -- combine
    refine Rle_trans (Rabs_Rsub_triangle (Rlim W hW) (W m) (Rmul c (Rlim X hX)))
      (Rle_trans (Radd_le_add hMW hWcL) ?_)
    refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos m) (Nat.succ_pos m)) ?_)
    exact ofQ_congr (add_den_pos (Nat.succ_pos m) (Nat.succ_pos m)) (Nat.succ_pos m)
      (by show Qeq (add (⟨2, m + 1⟩ : Q) (⟨(2 * xBound c : Nat), m + 1⟩ : Q))
            (⟨((2 + 2 * xBound c : Nat) : Int), m + 1⟩ : Q); simp only [Qeq, add]; push_cast; ring_uor)
  refine Req_of_Rle_ofQ_all (C := 2 + 2 * xBound c) (fun k => Rle_of_Rabs_le (hrate k)) (fun k => ?_)
  exact Rle_of_Rabs_le (Rle_trans (Rle_of_Req
    (Rabs_Rsub_comm (Rmul c (Rlim X hX)) (Rlim W hW))) (hrate k))

/-- **REAL-SCALAR LINEARITY OF THE CERTIFIED INTEGRAL** `∫₀¹ (c·f) = c·∫₀¹ f` for `c : Real`. The
    dyadic sums scale at every finite level (`riemannSum_smul`, real scalar; `dyadicR` ⟹ `dyadicTerm`
    via `Rmul_sub_distrib` ⟹ `genSum` via `genSum_Rmul_of_termwise`), and `Rmul_Rlim_of_approx`
    carries the real scalar through the limit — the exact mirror of `riemannIntegral_smul` with
    `ofQ q ↦ c`. -/
theorem riemannIntegral_Rsmul {f : Real → Real} {L : Q} (c : Real) (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipcf : ∀ x y, Rle (Rabs (Rsub (Rmul c (f x)) (Rmul c (f y)))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfccf : ∀ x y, Req x y → Req (Rmul c (f x)) (Rmul c (f y))) :
    Req (riemannIntegral hLd hLn hlipcf hfccf) (Rmul c (riemannIntegral hLd hLn hlipf hfcf)) := by
  have hdR : ∀ m, Req (dyadicR (fun x => Rmul c (f x)) m) (Rmul c (dyadicR f m)) :=
    fun m => riemannSum_smul c f (2 ^ m - 1)
  have hdT : ∀ k, Req (dyadicTerm (fun x => Rmul c (f x)) k) (Rmul c (dyadicTerm f k)) := fun k =>
    Req_trans (Rsub_congr (hdR (k + 1)) (hdR k))
      (Req_symm (Rmul_sub_distrib c (dyadicR f (k + 1)) (dyadicR f k)))
  have hgS : ∀ j, Req (genSum (dyadicTerm (fun x => Rmul c (f x))) (digammaMidx L j))
      (Rmul c (genSum (dyadicTerm f) (digammaMidx L j))) := fun j =>
    genSum_Rmul_of_termwise hdT (digammaMidx L j)
  have hSf := dyadicSum_RReg hLd hLn hlipf hfcf
  have hScf := dyadicSum_RReg hLd hLn hlipcf hfccf
  refine Req_trans (Radd_congr (hdR 0)
    (Rmul_Rlim_of_approx c (fun j => genSum (dyadicTerm (fun x => Rmul c (f x))) (digammaMidx L j))
      (fun j => genSum (dyadicTerm f) (digammaMidx L j)) hSf hScf hgS)) ?_
  exact Req_symm (Rmul_distrib c (dyadicR f 0)
    (Rlim (fun j => genSum (dyadicTerm f) (digammaMidx L j)) hSf))

end Multiplicity.UOR.Bridge.F1Square.Analysis
