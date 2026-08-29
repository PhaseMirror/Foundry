/-
F1 square — **the pre-Hilbert layer, brick 8** (`IntegralCS.lean`): the **per-level
Cauchy–Schwarz** for Riemann sums and the **effective dyadic error bound** for the certified
integral — the two load-bearing halves of the integral Cauchy–Schwarz.

- `riemannSum_cauchy_schwarz` — at every partition level, `R_N(fg)² ≤ R_N(f²)·R_N(g²)`: the
  `RsumN` core of a product Riemann sum IS (definitionally) the truncated inner product
  `innerN (f ∘ sample) (g ∘ sample)` of brick 1, so the discrete sqrt-free Cauchy–Schwarz
  applies, and the UNIFORM weight `1/(N+1)` squares out with no square root:
  `(wA)² ≈ w²·A² ≤ w²·BC ≈ (wB)(wC)` (monomial reassociation via the `RprodL` engine).
- `riemannSum_abs_le` — a globally bounded integrand gives `|R_N(h)| ≤ M` (the constant sum
  collapses by `riemannSum_const`).
- `riemannIntegral_dyadic_dist` — the effective error bound: `|∫₀¹f − D_m| ≤ (⌈L⌉+2)/m` for
  every level `m ≥ 1` — the telescoping Cauchy modulus (`genSum_gap`) plus the
  distance-to-limit (`Rabs_dist_Rlim`), through the shared `D₀` anchor. Every certified
  integral now carries an explicit rational error at every dyadic level.

WHY. The integral Cauchy–Schwarz `(∫fg)² ≤ ∫f²·∫g²` follows from these by the ε-collapse
(`a² − bc` telescopes through the level-`k` sums, each within `O(1/k)` of its integral, the
per-level CS killing the middle term) — that assembly is the banked next brick; this one
delivers the two analytic inputs, each independently reusable.

HONEST SCOPE. Per-level inequalities and an effective error bound; the limit-level
Cauchy–Schwarz is NOT yet stated. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.PreHilbert
import Foundations.F1.Analysis.IntegralCertIrrel

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Per-level Cauchy–Schwarz for Riemann sums.
-- ===========================================================================

/-- **CAUCHY–SCHWARZ AT EVERY PARTITION LEVEL**: `R_N(fg)² ≤ R_N(f²)·R_N(g²)`. The sum core is
    the truncated inner product of the sampled families (definitionally), brick 1's sqrt-free
    Cauchy–Schwarz bounds it, and the uniform weight squares out. -/
theorem riemannSum_cauchy_schwarz (f g : Real → Real) (N : Nat) :
    Rle (Rmul (riemannSum (fun x => Rmul (f x) (g x)) N)
              (riemannSum (fun x => Rmul (f x) (g x)) N))
        (Rmul (riemannSum (fun x => Rmul (f x) (f x)) N)
              (riemannSum (fun x => Rmul (g x) (g x)) N)) := by
  have hCS := cauchy_schwarz (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
    (fun i => g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1)
  have hw : Rnonneg (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
      (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (Nat.succ_pos N) (by show (0:Int) ≤ 1; decide))
      (Rnonneg_ofQ (Nat.succ_pos N) (by show (0:Int) ≤ 1; decide))
  have hBC : Rnonneg (Rmul
      (innerN (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
              (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))
      (innerN (fun i => g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
              (fun i => g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) :=
    Rnonneg_Rmul (innerN_self_nonneg _ _) (innerN_self_nonneg _ _)
  refine Rle_trans (Rle_of_Req (prod_sq_reassoc (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (innerN (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
            (fun i => g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1)))) ?_
  refine Rle_trans (Rmul_le_Rmul_both hw hBC (Rle_refl _) hCS) ?_
  -- `(w·w)·(B·C) ≈ (w·B)·(w·C)` — multiset `{w,w,B,C}` reassociation
  refine Rle_of_Req ?_
  refine Req_trans (Rmul_pair_eq_RprodL4 _ _ _ _) ?_
  refine Req_trans (RprodL_perm (List.Perm.cons _ (List.Perm.swap _ _ _))) ?_
  exact Req_symm (Rmul_pair_eq_RprodL4 _ _ _ _)

-- ===========================================================================
-- The uniform bound on Riemann sums of a bounded integrand.
-- ===========================================================================

/-- A globally bounded integrand has uniformly bounded Riemann sums: `|R_N(h)| ≤ M`. -/
theorem riemannSum_abs_le {h : Real → Real} {M : Q} (hMd : 0 < M.den) (hMn : 0 ≤ M.num)
    (hbd : ∀ x, Rle (Rabs (h x)) (ofQ M hMd)) (N : Nat) :
    Rle (Rabs (riemannSum h N)) (ofQ M hMd) := by
  have hw : Rnonneg (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) :=
    Rnonneg_ofQ (Nat.succ_pos N) (by show (0:Int) ≤ 1; decide)
  refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr
    (Rabs_ofQ_nonneg (Nat.succ_pos N) (by show (0:Int) ≤ 1; decide)) (Req_refl _))) ?_
  refine Rle_trans (Rmul_le_Rmul_both hw
    (Rnonneg_RsumN (N + 1) (fun i _ => Rnonneg_ofQ hMd hMn)) (Rle_refl _)
    (Rle_trans (RsumN_Rabs_le _ (N + 1)) (RsumN_le (N + 1) (fun i _ => hbd _)))) ?_
  exact Rle_of_Req (riemannSum_const (ofQ M hMd) N)

-- ===========================================================================
-- The effective dyadic error bound of the certified integral.
-- ===========================================================================

/-- **THE EFFECTIVE DYADIC ERROR BOUND**: `|∫₀¹f − D_m| ≤ (⌈L⌉+2)/m` at every level `m ≥ 1` —
    the certified integral is effectively computable with an explicit rational error at every
    dyadic Riemann sum. Telescoping Cauchy modulus to the schedule, distance-to-limit past it. -/
theorem riemannIntegral_dyadic_dist {f : Real → Real} {L : Q} (hLd : 0 < L.den)
    (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) {m : Nat} (hm : 1 ≤ m) :
    Rle (Rabs (Rsub (riemannIntegral hLd hLn hlip hfc) (dyadicR f m)))
        (ofQ (⟨((L.num.toNat + 2 : Nat) : Int), m⟩ : Q) hm) := by
  have hT := fun k hk => dyadicTerm_abs_bound hLd hLn hlip hfc k hk
  -- `D_m ≈ D₀ + genSum m`
  have h1 : Req (dyadicR f m) (Radd (dyadicR f 0) (genSum (dyadicTerm f) m)) :=
    Req_symm (Req_trans (Radd_congr (Req_refl _) (genSum_telescope f m))
      (Radd_Rsub_cancel (dyadicR f m) (dyadicR f 0)))
  -- `∫ − D_m ≈ lim S − genSum m`
  have h2 : Req (Rsub (riemannIntegral hLd hLn hlip hfc) (dyadicR f m))
      (Rsub (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc)) (genSum (dyadicTerm f) m)) := by
    refine Req_trans (Rsub_congr (Req_refl _) h1) ?_
    refine Req_trans (Rsub_Radd_Radd (dyadicR f 0)
      (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc)) (dyadicR f 0)
      (genSum (dyadicTerm f) m)) ?_
    refine Req_trans (Radd_congr (Radd_neg _) (Req_refl _)) ?_
    exact Req_trans (Radd_comm _ _) (Radd_zero _)
  -- telescope through the scheduled sum `S_m = genSum (digammaMidx L m)`
  have htele : Req (Radd
      (Rsub (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc))
            (genSum (dyadicTerm f) (digammaMidx L m)))
      (Rsub (genSum (dyadicTerm f) (digammaMidx L m)) (genSum (dyadicTerm f) m)))
      (Rsub (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc)) (genSum (dyadicTerm f) m)) :=
    Req_trans (Radd_comm _ _) (Radd_Rsub_Rsub _ _ _)
  -- the two pieces
  have hdist : Rle (Rabs (Rsub (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc))
      (genSum (dyadicTerm f) (digammaMidx L m)))) (ofQ (⟨2, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _))
      (Rabs_dist_Rlim (dyadicSum_RReg hLd hLn hlip hfc) m)
  obtain ⟨d, hd⟩ : ∃ d, digammaMidx L m = m + d :=
    ⟨digammaMidx L m - m, by have := digammaMidx_ge L m; omega⟩
  have hgap : Rle (Rabs (Rsub (genSum (dyadicTerm f) (digammaMidx L m))
      (genSum (dyadicTerm f) m))) (ofQ (mul L (⟨1, m⟩ : Q)) (Qmul_den_pos hLd hm)) := by
    rw [hd]
    exact genSum_gap hLd hLn hT hm d
  -- assemble
  refine Rle_trans (Rle_of_Req (Rabs_congr h2)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm htele))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hdist hgap) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ _ _)) ?_
  refine Rle_ofQ_ofQ _ _ ?_
  -- `2/(m+1) + L/m ≤ (⌈L⌉+2)/m`
  show ((2 * (L.den * m : Nat) : Int) + (L.num * 1) * ((m + 1 : Nat) : Int))
        * ((m : Nat) : Int)
      ≤ ((L.num.toNat + 2 : Nat) : Int) * (((m + 1) * (L.den * m) : Nat) : Int)
  push_cast
  have hnum_eq : L.num = (L.num.toNat : Int) := (Int.toNat_of_nonneg hLn).symm
  have hden1 : (1 : Int) ≤ (L.den : Int) := by exact_mod_cast hLd
  have ht : (L.num.toNat : Int) ≤ (L.num.toNat : Int) * (L.den : Int) := by
    have h := Int.mul_le_mul_of_nonneg_left hden1 (Int.ofNat_nonneg L.num.toNat)
    rwa [Int.mul_one] at h
  have hmm : ((m : Int)) * ((m : Int)) ≤ ((m : Int)) * ((m : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_left (by omega) (Int.ofNat_nonneg m)
  have e1 : (2 * ((L.den : Int) * (m : Int)) + L.num * 1 * ((m : Int) + 1)) * (m : Int)
      = (2 * (L.den : Int)) * ((m : Int) * (m : Int))
        + L.num * ((m : Int) * ((m : Int) + 1)) := by ring_uor
  have e2 : ((L.num.toNat : Int) + 2) * (((m : Int) + 1) * ((L.den : Int) * (m : Int)))
      = (2 * (L.den : Int)) * ((m : Int) * ((m : Int) + 1))
        + ((L.num.toNat : Int) * (L.den : Int)) * ((m : Int) * ((m : Int) + 1)) := by ring_uor
  rw [e1, e2]
  refine Int.add_le_add ?_ ?_
  · exact Int.mul_le_mul_of_nonneg_left hmm (by omega)
  · rw [hnum_eq]
    exact Int.mul_le_mul_of_nonneg_right ht
      (Int.mul_nonneg (Int.ofNat_nonneg m) (by omega))

end Multiplicity.UOR.Bridge.F1Square.Square
