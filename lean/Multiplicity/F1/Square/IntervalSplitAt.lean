/-
F1 square — certified integration: the **analytic foundation for general split-point additivity**
(`IntervalSplitAt.lean`) — the two ingredients the arbitrary-rational split needs and that the
dyadic-only substrate does not yet provide, delivered and verified here:

  • `riemannSum_multiple_refine` — the **block refinement bound** `|R_{cP-1}(g) − R_{P-1}(g)| ≤ L/P`
    (subdividing each of `P` equal subintervals into `c` pieces; per-block Lipschitz), generalizing
    the dyadic doubling `riemannSum_refine` to an arbitrary integer factor (via `RsumN_flatten`).
  • `riemannSum_conv_dist` — the **general Riemann-sum convergence rate** `|∫₀¹ g − R_N(g)| ≤ L/(N+1)`
    for EVERY `N`, not only the dyadic `2^m`. Coarse and integral are compared through a common
    refinement, the two `k`-dependent tails killed by the Archimedean collapse. This is the piece
    exhaustion-independence rests on: every Riemann sum, at every resolution, carries an explicit
    rational error.
  • `riemannSum_split_at_gen` — the **exact finite split at a general node** (subtraction-free): with
    `t₀ = (a+1)/(a+b+2)`, the fine `(a+b+2)`-point sum is exactly the `t₀ / (1−t₀)`-weighted sum of the
    two affine block sums, generalizing `riemannSum_halves` (`a=b=0`) to any rational node.

Together these are the substrate for `riemannIntegralI_split_at` (`∫_a^{a+w} = ∫_a^{a+w1} + ∫_{a+w1}^{a+w}`),
whose remaining assembly is the Archimedean limit of `riemannSum_split_at_gen` (scaled resolution)
closed by `riemannSum_conv_dist`, then the affine composition of the block pullbacks; that capstone is
NOT performed in this file.

HONEST SCOPE. The analytic foundation for general split-point additivity — a block refinement bound,
a general Riemann-sum convergence rate, and the exact finite split at a general node — via change of
variables. It builds NO improper integral, NO limit beyond the Riemann integral itself, NO dilation
covariance, NO factorization, NO positivity, NO determinacy, and it does NOT itself state the interval
split `riemannIntegralI_split_at`, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.IntegralSplit
import Multiplicity.F1.Square.IntegralCS

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Block flattening of a finite sum.
-- ===========================================================================

/-- **Block flattening**: `Σ_{j<c·P} F j = Σ_{i<P} Σ_{r<c} F (c·i + r)`. -/
theorem RsumN_flatten (F : Nat → Real) (c : Nat) : ∀ P,
    Req (RsumN F (c * P)) (RsumN (fun i => RsumN (fun r => F (c * i + r)) c) P)
  | 0 => by
      show Req (RsumN F (c * 0)) (RsumN (fun i => RsumN (fun r => F (c * i + r)) c) 0)
      exact Req_refl _
  | P + 1 => by
      have hidx : c * (P + 1) = c * P + c := by rw [Nat.mul_succ]
      refine Req_trans (RsumN_idx F hidx) ?_
      refine Req_trans (RsumN_split_at F (c * P) c) ?_
      exact Radd_congr (RsumN_flatten F c P) (Req_refl _)

-- ===========================================================================
-- The block refinement bound: |R_{cP-1}(g) − R_{P-1}(g)| ≤ L/P.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- **BLOCK REFINEMENT BOUND**: subdividing each of the `N+1` equal subintervals into `e+1` equal
    pieces changes the Riemann sum by at most `L/(N+1)`. The fine sum `R_{(e+1)(N+1)-1}(g)` (index
    `(e+1)·N+e`) minus the coarse `R_N(g)`, regrouped block-by-block, is `L`-Lipschitz-bounded within
    each block of width `1/(N+1)`. Generalizes the dyadic doubling `riemannSum_refine` to an arbitrary
    integer refinement factor. -/
theorem riemannSum_multiple_refine {g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (g x) (g y)) (e N : Nat) :
    Rle (Rabs (Rsub (riemannSum g ((e + 1) * N + e)) (riemannSum g N)))
        (ofQ (mul L (⟨1, N + 1⟩ : Q)) (Qmul_den_pos hLd (Nat.succ_pos N))) := by
  let c := e + 1
  let M := (e + 1) * N + e
  have hMP : M + 1 = c * (N + 1) := by
    show (e + 1) * N + e + 1 = (e + 1) * (N + 1)
    rw [Nat.mul_succ]; omega
  have hMpos : 0 < M + 1 := Nat.succ_pos M
  -- fine and coarse weights, the sampling points
  let Wf := ofQ (⟨1, M + 1⟩ : Q) hMpos
  let Wb := ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)
  let pt : Nat → Real := fun j => g (ofQ (⟨(j : Int), M + 1⟩ : Q) hMpos)
  let bpt : Nat → Real := fun i => g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))
  have hWfnn : Rnonneg Wf := Rnonneg_ofQ hMpos (by show (0 : Int) ≤ 1; decide)
  -- the coarse point equals the block-anchor fine point: `i/(N+1) = c·i/(M+1)`.
  have hpteq : ∀ i, Req (bpt i) (pt (c * i)) := by
    intro i
    refine hfc _ _ (ofQ_congr (Nat.succ_pos N) hMpos ?_)
    show Qeq (⟨(i : Int), N + 1⟩ : Q) (⟨((c * i : Nat) : Int), M + 1⟩ : Q)
    rw [hMP]; simp only [Qeq]; push_cast; ring_uor
  -- FINE sum in flattened block form.
  have hFine : Req (riemannSum g M)
      (Rmul Wf (RsumN (fun i => RsumN (fun r => pt (c * i + r)) c) (N + 1))) := by
    show Req (Rmul Wf (RsumN pt (M + 1))) _
    refine Rmul_congr (Req_refl _) ?_
    refine Req_trans (RsumN_idx pt hMP) ?_
    exact RsumN_flatten pt c (N + 1)
  -- COARSE sum in the same block shape (each block is `c` copies of the anchor value).
  -- `Wb ≈ Wf · c`  (both are `c/(M+1) = 1/(N+1)`).
  have hWbc : Req Wb (Rmul Wf (RofNat c)) :=
    Req_trans
      (ofQ_congr (Nat.succ_pos N) (Qmul_den_pos hMpos Nat.one_pos)
        (by rw [hMP]; simp only [Qeq, mul]; push_cast; ring_uor))
      (Req_symm (Rmul_ofQ_ofQ hMpos Nat.one_pos))
  have hCoarse : Req (riemannSum g N)
      (Rmul Wf (RsumN (fun i => RsumN (fun _ => pt (c * i)) c) (N + 1))) := by
    show Req (Rmul Wb (RsumN bpt (N + 1))) _
    -- per block `i`: `Wb · bpt i ≈ Wf · Σ_{r<c} pt(c·i)`.
    have hblk : ∀ i, Req (Rmul Wb (bpt i)) (Rmul Wf (RsumN (fun _ => pt (c * i)) c)) := by
      intro i
      refine Req_trans (Rmul_congr (Req_refl Wb) (hpteq i)) ?_
      refine Req_trans (Rmul_congr hWbc (Req_refl _)) ?_
      refine Req_trans (Rmul_assoc Wf (RofNat c) (pt (c * i))) ?_
      exact Rmul_congr (Req_refl Wf) (Req_symm (RsumN_const (pt (c * i)) c))
    -- assemble over `i`.
    refine Req_trans (Req_symm (RsumN_Rmul_const Wb bpt (N + 1))) ?_
    refine Req_trans (RsumN_congr (N + 1) (fun i _ => hblk i)) ?_
    exact RsumN_Rmul_const Wf (fun i => RsumN (fun _ => pt (c * i)) c) (N + 1)
  -- the difference regrouped as `Wf · Σ_i Σ_r (pt(c·i+r) − pt(c·i))`.
  have hDiff : Req (Rsub (riemannSum g M) (riemannSum g N))
      (Rmul Wf (RsumN (fun i =>
        RsumN (fun r => Rsub (pt (c * i + r)) (pt (c * i))) c) (N + 1))) := by
    refine Req_trans (Rsub_congr hFine hCoarse) ?_
    refine Req_trans (Req_symm (Rmul_sub_distrib Wf _ _)) ?_
    refine Rmul_congr (Req_refl _) ?_
    refine Req_trans (Req_symm (RsumN_Rsub _ _ (N + 1))) ?_
    refine RsumN_congr (N + 1) (fun i _ => ?_)
    exact Req_symm (RsumN_Rsub _ _ c)
  -- per-term Lipschitz bound `|pt(c·i+r) − pt(c·i)| ≤ L/(N+1)` (each block has width `1/(N+1)`).
  let tgt := ofQ (mul L (⟨1, N + 1⟩ : Q)) (Qmul_den_pos hLd (Nat.succ_pos N))
  have hterm : ∀ i r, r < c →
      Rle (Rabs (Rsub (pt (c * i + r)) (pt (c * i)))) tgt := by
    intro i r hr
    have hpd : Req (Rsub (ofQ (⟨((c * i + r : Nat) : Int), M + 1⟩ : Q) hMpos)
                        (ofQ (⟨((c * i : Nat) : Int), M + 1⟩ : Q) hMpos))
                   (ofQ (⟨(r : Int), M + 1⟩ : Q) hMpos) :=
      Req_trans (Rsub_ofQ_ofQ hMpos hMpos)
        (ofQ_congr _ hMpos (by simp only [Qeq, add, neg]; push_cast; ring_uor))
    refine Rle_trans (hlip _ _) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hLd hLn) ?_)
      (Rle_of_Req (Rmul_ofQ_ofQ hLd (Nat.succ_pos N)))
    -- `|(c·i+r)/(M+1) − (c·i)/(M+1)| = r/(M+1) ≤ 1/(N+1)`
    refine Rle_trans (Rle_of_Req (Rabs_congr hpd)) ?_
    refine Rle_trans (Rle_of_Req (Rabs_ofQ_nonneg hMpos (Int.ofNat_nonneg r))) ?_
    refine Rle_ofQ_ofQ hMpos (Nat.succ_pos N) ?_
    show ((r : Int)) * ((N + 1 : Nat) : Int) ≤ (1 : Int) * ((M + 1 : Nat) : Int)
    have hrle : r * (N + 1) ≤ 1 * (M + 1) := by
      rw [hMP, Nat.one_mul]; exact Nat.mul_le_mul (Nat.le_of_lt hr) (Nat.le_refl _)
    exact_mod_cast hrle
  -- `|ΣΣ Δ| ≤ Σ_i Σ_r tgt`.
  have hDS : Rle (Rabs (RsumN (fun i =>
        RsumN (fun r => Rsub (pt (c * i + r)) (pt (c * i))) c) (N + 1)))
      (RsumN (fun _ : Nat => RsumN (fun _ : Nat => tgt) c) (N + 1)) := by
    refine Rle_trans (RsumN_Rabs_le _ (N + 1)) ?_
    refine RsumN_le (N + 1) (fun i _ => ?_)
    refine Rle_trans (RsumN_Rabs_le _ c) ?_
    exact RsumN_le c (fun r hr => hterm i r hr)
  -- `Wf · (Σ_i Σ_r tgt) = L/(N+1)`.
  have hTB : Req (Rmul Wf (RsumN (fun _ : Nat => RsumN (fun _ : Nat => tgt) c) (N + 1))) tgt := by
    refine Req_trans (Rmul_congr (Req_refl _)
      (RsumN_congr (N + 1) (fun i _ => RsumN_const tgt c))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (RsumN_const (Rmul (RofNat c) tgt) (N + 1))) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_congr (Req_refl _) (Rmul_ofQ_ofQ Nat.one_pos (Qmul_den_pos hLd (Nat.succ_pos N))))) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_ofQ_ofQ Nat.one_pos (Qmul_den_pos Nat.one_pos (Qmul_den_pos hLd (Nat.succ_pos N))))) ?_
    refine Req_trans (Rmul_ofQ_ofQ hMpos
      (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos (Qmul_den_pos hLd (Nat.succ_pos N))))) ?_
    exact ofQ_congr _ (Qmul_den_pos hLd (Nat.succ_pos N))
      (by rw [hMP]; simp only [Qeq, mul]; push_cast; ring_uor)
  -- assemble: `|R_fine − R_coarse| = Wf·|ΣΣ Δ| ≤ Wf·(Σ_i Σ_r tgt) = L/(N+1)`.
  refine Rle_trans (Rle_of_Req (Rabs_congr hDiff)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg hMpos (by show (0 : Int) ≤ 1; decide) _)) ?_
  exact Rle_trans (Rmul_le_Rmul_left hWfnn hDS) (Rle_of_Req hTB)

-- ===========================================================================
-- The general convergence rate of the Riemann sums (all `N`, not only dyadic).
-- ===========================================================================

/-- The two symmetric block-refinement indices agree: `(P+1)·N + P = (N+1)·P + N`. -/
private theorem block_index_symm (P N : Nat) : (P + 1) * N + P = (N + 1) * P + N := by
  rw [Nat.succ_mul, Nat.succ_mul, Nat.mul_comm P N]; omega

/-- `|a| ≤ B` from the two one-sided bounds `a ≤ B` and `−B ≤ a`. -/
private theorem Rabs_le_of_both {x B : Real} (hu : Rle x B) (hl : Rle (Rneg B) x) : Rle (Rabs x) B := by
  have hxneg : Rle (Rneg x) B := Rle_trans (Rle_Rneg hl) (Rle_of_Req (Rneg_neg B))
  intro n
  exact Qabs_le_of_both (hu n) (hxneg n)

/-- `a − b ≤ c` from `a ≤ b + c`. -/
private theorem Rsub_le_of_le_add {a b c : Real} (h : Rle a (Radd b c)) : Rle (Rsub a b) c := by
  refine Rle_trans (Radd_le_add h (Rle_refl (Rneg b))) ?_
  refine Rle_of_Req (Req_trans (Radd_congr (Radd_comm b c) (Req_refl _)) ?_)
  refine Req_trans (Radd_assoc c b (Rneg b)) ?_
  exact Req_trans (Radd_congr (Req_refl c) (Radd_neg b)) (Radd_zero c)

/-- `|a − c| ≤ |a − b| + |b − c|` (local triangle inequality). -/
private theorem abs_sub_tri (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

set_option maxHeartbeats 4000000 in
/-- **GENERAL RIEMANN-SUM CONVERGENCE RATE**: `|∫₀¹ g − R_N(g)| ≤ L/(N+1)` for EVERY `N`, not only the
    dyadic levels `2^m`. The coarse `R_N` and the integral are compared through a common refinement
    `R_{2^{k+1}·(N+1)−1}`: `riemannSum_multiple_refine` bounds `R_N` against it (`≤ L/(N+1)`) and the
    dyadic sum `D_{k+1}` against it (`≤ L/2^{k+1}`), while `riemannIntegral_dyadic_dist` bounds `∫` vs
    `D_{k+1}` (`≤ (⌈L⌉+2)/(k+1)`); the two `k`-dependent tails vanish under the Archimedean collapse,
    leaving the clean `L/(N+1)`. The foundation for exhaustion-independence. -/
theorem riemannSum_conv_dist {g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (g x) (g y)) (N : Nat) :
    Rle (Rabs (Rsub (riemannIntegral hLd hLn hlip hfc) (riemannSum g N)))
        (ofQ (mul L (⟨1, N + 1⟩ : Q)) (Qmul_den_pos hLd (Nat.succ_pos N))) := by
  refine Rle_of_Rsub_le_eps (C := 2 * L.num.toNat + 2) (fun k => ?_)
  refine Rsub_le_of_le_add ?_
  -- the shared refinement level `2^{k+1}`
  have hpow : 1 ≤ 2 ^ (k + 1) := Nat.one_le_two_pow
  have hDeq : (2 ^ (k + 1) - 1) + 1 = 2 ^ (k + 1) := Nat.sub_add_cancel hpow
  -- the three estimates
  have c1 := riemannSum_multiple_refine hLd hLn hlip hfc (2 ^ (k + 1) - 1) N
  have c2 := riemannSum_multiple_refine hLd hLn hlip hfc N (2 ^ (k + 1) - 1)
  have ddist := riemannIntegral_dyadic_dist hLd hLn hlip hfc (m := k + 1) (by omega)
  have hbridge : Req (riemannSum g (((2 ^ (k + 1) - 1) + 1) * N + (2 ^ (k + 1) - 1)))
                     (riemannSum g ((N + 1) * (2 ^ (k + 1) - 1) + N)) :=
    riemannSum_idx g (block_index_symm (2 ^ (k + 1) - 1) N)
  -- `bnd2 = L/2^{k+1} ≤ ⌈L⌉/(k+1)`
  have hb2 : Rle (ofQ (mul L (⟨1, (2 ^ (k + 1) - 1) + 1⟩ : Q))
                    (Qmul_den_pos hLd (Nat.succ_pos (2 ^ (k + 1) - 1))))
                 (ofQ (⟨(L.num.toNat : Int), k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_
    show (L.num * 1) * ((k + 1 : Nat) : Int)
        ≤ ((L.num.toNat : Int)) * ((L.den * ((2 ^ (k + 1) - 1) + 1) : Nat) : Int)
    rw [Int.toNat_of_nonneg hLn, Int.mul_one]
    have hge : (k + 1 : Nat) ≤ L.den * ((2 ^ (k + 1) - 1) + 1) := by
      rw [hDeq]
      exact Nat.le_trans (Nat.le_of_lt Nat.lt_two_pow_self) (Nat.le_mul_of_pos_left _ hLd)
    exact Int.mul_le_mul_of_nonneg_left (by exact_mod_cast hge) hLn
  -- the triangle assembly
  refine Rle_trans (Rle_trans (abs_sub_tri _
      (riemannSum g (((2 ^ (k + 1) - 1) + 1) * N + (2 ^ (k + 1) - 1)))
      (riemannSum g N))
    (Radd_le_add
      (Rle_trans (abs_sub_tri _ (dyadicR g (k + 1)) _)
        (Radd_le_add ddist
          (Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_refl _) hbridge)))
            (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) c2))))
      c1)) ?_
  -- rearrange `(A + bnd2) + tgtN ≤ tgtN + C/(k+1)`
  refine Rle_trans (Rle_of_Req (Radd_comm _ _)) ?_
  refine Radd_le_add (Rle_refl _) ?_
  refine Rle_trans (Radd_le_add (Rle_refl _) hb2) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k)) ?_)
  exact ofQ_congr _ (Nat.succ_pos k) (by simp only [Qeq, add]; push_cast; ring_uor)

-- ===========================================================================
-- The exact finite split identity at a general node (subtraction-free).
-- ===========================================================================

/-- The left block's `j`-th partition point is the fine partition's `j`-th:
    `(a+1)/(a+b+2) · j/(a+1) = j/(a+b+2)`. -/
private theorem split_left_point (a b j : Nat) (hden : 0 < a + b + 2) :
    Req (affineMap (⟨0, 1⟩ : Q) (⟨(a + 1 : Int), a + b + 2⟩ : Q) (by decide) hden
          (ofQ (⟨(j : Int), a + 1⟩ : Q) (Nat.succ_pos a)))
        (ofQ (⟨(j : Int), a + b + 2⟩ : Q) hden) := by
  show Req (Radd (ofQ (⟨0, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨(a + 1 : Int), a + b + 2⟩ : Q) hden)
            (ofQ (⟨(j : Int), a + 1⟩ : Q) (Nat.succ_pos a)))) _
  refine Req_trans (Radd_congr (Req_refl _) (Rmul_ofQ_ofQ hden (Nat.succ_pos a))) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (Qmul_den_pos hden (Nat.succ_pos a))) ?_
  exact ofQ_congr _ hden (by simp only [Qeq, add, mul]; push_cast; ring_uor)

/-- The right block's `l`-th partition point is the fine partition's `(a+1+l)`-th:
    `(a+1)/(a+b+2) + (b+1)/(a+b+2) · l/(b+1) = (a+1+l)/(a+b+2)`. -/
private theorem split_right_point (a b l : Nat) (hden : 0 < a + b + 2) :
    Req (affineMap (⟨(a + 1 : Int), a + b + 2⟩ : Q) (⟨(b + 1 : Int), a + b + 2⟩ : Q) hden hden
          (ofQ (⟨(l : Int), b + 1⟩ : Q) (Nat.succ_pos b)))
        (ofQ (⟨((a + 1 + l : Nat) : Int), a + b + 2⟩ : Q) hden) := by
  show Req (Radd (ofQ (⟨(a + 1 : Int), a + b + 2⟩ : Q) hden)
      (Rmul (ofQ (⟨(b + 1 : Int), a + b + 2⟩ : Q) hden)
            (ofQ (⟨(l : Int), b + 1⟩ : Q) (Nat.succ_pos b)))) _
  refine Req_trans (Radd_congr (Req_refl _) (Rmul_ofQ_ofQ hden (Nat.succ_pos b))) ?_
  refine Req_trans (Radd_ofQ_ofQ hden (Qmul_den_pos hden (Nat.succ_pos b))) ?_
  exact ofQ_congr _ hden (by simp only [Qeq, add, mul]; push_cast; ring_uor)

set_option maxHeartbeats 4000000 in
/-- **EXACT FINITE SPLIT AT A GENERAL NODE** (subtraction-free): with the split ratio
    `t₀ = (a+1)/(a+b+2)`, the fine Riemann sum over `[0,1]` at `a+b+2` equal points is exactly the
    `t₀`/`(1−t₀)`-weighted sum of the two affine block sums (`a+1` and `b+1` points). Generalizes
    `riemannSum_halves` (`a = b = 0`) to any rational node; the two block partitions interleave into the
    fine partition (`split_left_point`, `split_right_point`) and `RsumN_split_at` flattens them. -/
theorem riemannSum_split_at_gen (g : Real → Real)
    (hfc : ∀ x y, Req x y → Req (g x) (g y)) (a b : Nat) :
    Req (riemannSum g (a + b + 1))
      (Radd
        (Rmul (ofQ (⟨(a + 1 : Int), a + b + 2⟩ : Q) (Nat.succ_pos (a + b + 1)))
          (riemannSum (fun x => g (affineMap (⟨0, 1⟩ : Q) (⟨(a + 1 : Int), a + b + 2⟩ : Q)
            (by decide) (Nat.succ_pos (a + b + 1)) x)) a))
        (Rmul (ofQ (⟨(b + 1 : Int), a + b + 2⟩ : Q) (Nat.succ_pos (a + b + 1)))
          (riemannSum (fun x => g (affineMap (⟨(a + 1 : Int), a + b + 2⟩ : Q)
            (⟨(b + 1 : Int), a + b + 2⟩ : Q) (Nat.succ_pos (a + b + 1)) (Nat.succ_pos (a + b + 1)) x)) b))) := by
  have hden : 0 < a + b + 2 := by omega
  -- the block-weight collapses: `t₀·(1/(a+1)) = 1/(a+b+2)`, `(1−t₀)·(1/(b+1)) = 1/(a+b+2)`.
  have hdL : Req (Rmul (ofQ (⟨(a + 1 : Int), a + b + 2⟩ : Q) hden)
        (ofQ (⟨1, a + 1⟩ : Q) (Nat.succ_pos a))) (ofQ (⟨1, a + b + 2⟩ : Q) hden) :=
    Req_trans (Rmul_ofQ_ofQ hden (Nat.succ_pos a))
      (ofQ_congr _ hden (by simp only [Qeq, mul]; push_cast; ring_uor))
  have hdR : Req (Rmul (ofQ (⟨(b + 1 : Int), a + b + 2⟩ : Q) hden)
        (ofQ (⟨1, b + 1⟩ : Q) (Nat.succ_pos b))) (ofQ (⟨1, a + b + 2⟩ : Q) hden) :=
    Req_trans (Rmul_ofQ_ofQ hden (Nat.succ_pos b))
      (ofQ_congr _ hden (by simp only [Qeq, mul]; push_cast; ring_uor))
  -- each weighted block sum, in fine-partition form.
  have hL : Req (Rmul (ofQ (⟨(a + 1 : Int), a + b + 2⟩ : Q) hden)
        (riemannSum (fun x => g (affineMap (⟨0, 1⟩ : Q) (⟨(a + 1 : Int), a + b + 2⟩ : Q)
          (by decide) hden x)) a))
      (Rmul (ofQ (⟨1, a + b + 2⟩ : Q) hden)
        (RsumN (fun j => g (ofQ (⟨(j : Int), a + b + 2⟩ : Q) hden)) (a + 1))) := by
    refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
    exact Rmul_congr hdL (RsumN_congr (a + 1) (fun j _ => hfc _ _ (split_left_point a b j hden)))
  have hR : Req (Rmul (ofQ (⟨(b + 1 : Int), a + b + 2⟩ : Q) hden)
        (riemannSum (fun x => g (affineMap (⟨(a + 1 : Int), a + b + 2⟩ : Q)
          (⟨(b + 1 : Int), a + b + 2⟩ : Q) hden hden x)) b))
      (Rmul (ofQ (⟨1, a + b + 2⟩ : Q) hden)
        (RsumN (fun l => g (ofQ (⟨((a + 1 + l : Nat) : Int), a + b + 2⟩ : Q) hden)) (b + 1))) := by
    refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
    exact Rmul_congr hdR (RsumN_congr (b + 1) (fun l _ => hfc _ _ (split_right_point a b l hden)))
  show Req (Rmul (ofQ (⟨1, a + b + 2⟩ : Q) hden)
      (RsumN (fun i => g (ofQ (⟨(i : Int), a + b + 2⟩ : Q) hden)) (a + b + 2))) _
  refine Req_trans ?_ (Req_symm (Radd_congr hL hR))
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_idx _ (show a + b + 2 = (a + 1) + (b + 1) by omega))
      (RsumN_split_at (fun i => g (ofQ (⟨(i : Int), a + b + 2⟩ : Q) hden)) (a + 1) (b + 1)))) ?_
  exact Rmul_distrib _ _ _

end Multiplicity.UOR.Bridge.F1Square.Square
