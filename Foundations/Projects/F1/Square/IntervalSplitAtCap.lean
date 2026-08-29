/-
F1 square — **certified integration: the INTERVAL-LEVEL general split-point additivity**
(`IntervalSplitAtCap.lean`): the capstone the `IntervalSplitAt.lean` substrate was built for —

    `∫_a^{a+w} f  ≈  ∫_a^{a+w1} f  +  ∫_{a+w1}^{a+w} f`   (`riemannIntegralI_split_at`),

for an arbitrary rational split width `0 < w1 ≤ w`. The midpoint law (`riemannIntegralI_split_half`)
handles only `w1 = w/2`; this is the general node, and it is assembled as the **Archimedean limit of
the committed exact finite split** `riemannSum_split_at_gen` closed by `riemannSum_conv_dist`.

The engine is the UNIT SPLIT (`riemannIntegral_split_at_unit`): for a globally-Lipschitz `g` and a
rational node `t₀ = p/q ∈ (0,1)`,

    `∫₀¹ g  ≈  t₀·∫₀¹ g(t₀·x)  +  (1−t₀)·∫₀¹ g(t₀ + (1−t₀)·x)`.

At resolution `(k+1)·q` the fine Riemann sum splits EXACTLY at the node `p/q` (choosing block sizes
`A = (k+1)p − 1`, `B = (k+1)(q−p) − 1`, so `(A+1)/(A+B+2) = p/q` and `A+B+2 = (k+1)q → ∞`); as
`k → ∞` the fine sum converges to `∫₀¹ g`, each block sum to its block integral (both by
`riemannSum_conv_dist`), and the exact finite identity passes to the limit. The `t₀`/`(1−t₀)` weights
are dropped by `t₀ ≤ 1`, so each error term is `O(1/(k+1))`; the two-sided vanishing bound is the
Bishop equality. The interval law then follows by the affine composition `affineMap_comp`
(`α_{a,w} ∘ α_{0,t₀} = α_{a,w1}`, `α_{a,w} ∘ α_{t₀,1−t₀} = α_{a+w1,w−w1}`) reconciled through
`riemannIntegral_congr_mod`.

HONEST SCOPE. The interval-level general split-point additivity `riemannIntegralI_split_at`
(∫ over `[a,a+w]` = ∫ over `[a,a+w1]` + ∫ over `[a+w1,a+w]`), assembled as the Archimedean limit of
the committed `riemannSum_split_at_gen` closed by `riemannSum_conv_dist`, plus affine composition. It
builds NO improper integral, NO dilation covariance, NO factorization, NO positivity, NO determinacy,
NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.IntervalSplitAt
import Foundations.F1.Square.Bern2DWindowSwap

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small reusable helpers.
-- ===========================================================================

/-- **Affine pullback respects `Qeq` of base and width.** -/
private theorem affineMap_qeq {a a' w w' : Q} (ha : 0 < a.den) (ha' : 0 < a'.den)
    (hw : 0 < w.den) (hw' : 0 < w'.den) (hba : Qeq a a') (hbw : Qeq w w') (x : Real) :
    Req (affineMap a w ha hw x) (affineMap a' w' ha' hw' x) := by
  show Req (Radd (ofQ a ha) (Rmul (ofQ w hw) x)) (Radd (ofQ a' ha') (Rmul (ofQ w' hw') x))
  exact Radd_congr (ofQ_congr ha ha' hba) (Rmul_congr (ofQ_congr hw hw' hbw) (Req_refl x))

/-- Distributing a scalar through a difference. -/
private theorem Rmul_Rsub (c a b : Real) :
    Req (Rmul c (Rsub a b)) (Rsub (Rmul c a) (Rmul c b)) :=
  Req_trans (Rmul_distrib c a (Rneg b)) (Radd_congr (Req_refl _) (Rmul_neg_right c b))

/-- `|a − c| ≤ |a − b| + |b − c|` (local triangle inequality). -/
private theorem abs_sub_tri (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- Turn a two-sided `|a − b| ≤ C/(k+1)` bound into `a ≈ b` (local copy). -/
private theorem Req_of_Rabs_sub_le {a b : Real} {C : Nat}
    (hk : ∀ k, Rle (Rabs (Rsub a b)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req a b :=
  Req_of_Rle_ofQ_all (fun k => Rle_of_Rabs_le (hk k))
    (fun k => Rle_trans (Rle_Rabs_self (Rsub b a))
      (Rle_trans (Rle_of_Req (Rabs_Rsub_symm b a)) (hk k)))

/-- **The convergence bound collapses to `M.num.toNat/(k+1)`** whenever the resolution denominator
    `D` is at least `k+1`: `M/D ≤ M.num.toNat/(k+1)` (drop the `≥ k+1` denominator and read the
    numerator as a `Nat`). The uniform way every Riemann-sum error term is bounded here. -/
private theorem conv_bound_le {M : Q} (hMd : 0 < M.den) (hMn : 0 ≤ M.num)
    {D k : Nat} (hD : 0 < D) (hDk : k + 1 ≤ D) :
    Rle (ofQ (mul M (⟨1, D⟩ : Q)) (Qmul_den_pos hMd hD))
        (ofQ (⟨(M.num.toNat : Int), k + 1⟩ : Q) (Nat.succ_pos k)) := by
  refine Rle_ofQ_ofQ (Qmul_den_pos hMd hD) (Nat.succ_pos k) ?_
  show (M.num * 1) * ((k + 1 : Nat) : Int) ≤ (M.num.toNat : Int) * ((M.den * D : Nat) : Int)
  have hcast : ((k + 1 : Nat) : Int) ≤ ((M.den * D : Nat) : Int) := by
    exact_mod_cast Nat.le_trans hDk (Nat.le_mul_of_pos_left D hMd)
  rw [Int.mul_one]
  calc M.num * ((k + 1 : Nat) : Int)
      ≤ M.num * ((M.den * D : Nat) : Int) := Int.mul_le_mul_of_nonneg_left hcast hMn
    _ = (M.num.toNat : Int) * ((M.den * D : Nat) : Int) := by rw [Int.toNat_of_nonneg hMn]

-- ===========================================================================
-- The per-`k` finite step of the unit split.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- **One finite level of the unit split.** With block sizes `A`, `B` chosen so that
    `A+1 = (k+1)p`, `B+1 = (k+1)(q−p)`, `A+B+2 = (k+1)q`, the distance between `∫₀¹ g` and the
    `t₀`/`(1−t₀)`-weighted block integrals is `≤ C/(k+1)` for the fixed `C` below. The exact finite
    split `riemannSum_split_at_gen` supplies the middle equality; `riemannSum_conv_dist` bounds the
    three sum-to-integral gaps; the weights are dropped by `t₀,(1−t₀) ≤ 1`. -/
private theorem split_unit_step {g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (g x) (g y))
    (p q : Nat) (hp : 0 < p) (hq : 0 < q) (hpq : p < q)
    (A B k : Nat) (hA1 : A + 1 = (k + 1) * p) (hB1 : B + 1 = (k + 1) * (q - p))
    (hsum2 : A + B + 2 = (k + 1) * q) :
    Rle (Rabs (Rsub (riemannIntegral hLd hLn hlip hfc)
      (Radd
        (Rmul (ofQ (⟨(p : Int), q⟩ : Q) hq)
          (riemannIntegral (f := fun x => g (affineMap (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q)
              (by decide) hq x)) (L := mul L (⟨(p : Int), q⟩ : Q))
            (Qmul_den_pos hLd hq) (Int.mul_nonneg hLn (Int.ofNat_nonneg p))
            (affine_lip hLd hLn hlip (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q) (by decide) hq
              (Int.ofNat_nonneg p))
            (fun x y h => hfc _ _ (affineMap_congr (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q)
              (by decide) hq h))))
        (Rmul (ofQ (⟨((q - p : Nat) : Int), q⟩ : Q) hq)
          (riemannIntegral (f := fun x => g (affineMap (⟨(p : Int), q⟩ : Q)
              (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq x)) (L := mul L (⟨((q - p : Nat) : Int), q⟩ : Q))
            (Qmul_den_pos hLd hq) (Int.mul_nonneg hLn (Int.ofNat_nonneg (q - p)))
            (affine_lip hLd hLn hlip (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq
              (Int.ofNat_nonneg (q - p)))
            (fun x y h => hfc _ _ (affineMap_congr (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q)
              hq hq h)))))))
      (ofQ (⟨((L.num.toNat + ((mul L (⟨(p : Int), q⟩ : Q)).num.toNat
        + (mul L (⟨((q - p : Nat) : Int), q⟩ : Q)).num.toNat) : Nat) : Int), k + 1⟩ : Q)
        (Nat.succ_pos k)) := by
  -- shorthands for the two block widths (as rationals)
  have hqp0 : 0 < q - p := Nat.sub_pos_of_lt hpq
  -- Lipschitz + congruence certificates for the two block integrands
  have hlipL := affine_lip hLd hLn hlip (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q) (by decide) hq
    (Int.ofNat_nonneg p)
  have hfcL : ∀ x y, Req x y →
      Req (g (affineMap (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q) (by decide) hq x))
          (g (affineMap (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q) (by decide) hq y)) :=
    fun x y h => hfc _ _ (affineMap_congr (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q) (by decide) hq h)
  have hlipR := affine_lip hLd hLn hlip (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq
    (Int.ofNat_nonneg (q - p))
  have hfcR : ∀ x y, Req x y →
      Req (g (affineMap (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq x))
          (g (affineMap (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq y)) :=
    fun x y h => hfc _ _ (affineMap_congr (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq h)
  -- the node Qeq facts
  have hqeqL : Qeq (⟨((A : Int) + 1), A + B + 2⟩ : Q) (⟨(p : Int), q⟩ : Q) := by
    show ((A : Int) + 1) * ((q : Nat) : Int) = (p : Int) * ((A + B + 2 : Nat) : Int)
    have e1 : ((A : Int) + 1) = ((k + 1 : Nat) : Int) * ((p : Nat) : Int) := by exact_mod_cast hA1
    have e2 : ((A + B + 2 : Nat) : Int) = ((k + 1 : Nat) : Int) * ((q : Nat) : Int) := by
      exact_mod_cast hsum2
    rw [e1, e2, Int.mul_comm ((k + 1 : Nat) : Int) ((p : Nat) : Int), Int.mul_assoc]
  have hqeqR : Qeq (⟨((B : Int) + 1), A + B + 2⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) := by
    show ((B : Int) + 1) * ((q : Nat) : Int) = ((q - p : Nat) : Int) * ((A + B + 2 : Nat) : Int)
    have e1 : ((B : Int) + 1) = ((k + 1 : Nat) : Int) * ((q - p : Nat) : Int) := by exact_mod_cast hB1
    have e2 : ((A + B + 2 : Nat) : Int) = ((k + 1 : Nat) : Int) * ((q : Nat) : Int) := by
      exact_mod_cast hsum2
    rw [e1, e2, Int.mul_comm ((k + 1 : Nat) : Int) ((q - p : Nat) : Int), Int.mul_assoc]
  -- resolution-bound side conditions (each block denominator ≥ k+1)
  have hDk0 : k + 1 ≤ (A + B + 1) + 1 := by
    show k + 1 ≤ A + B + 2; rw [hsum2]; exact Nat.le_mul_of_pos_right (k + 1) hq
  have hDkL : k + 1 ≤ A + 1 := by rw [hA1]; exact Nat.le_mul_of_pos_right (k + 1) hp
  have hDkR : k + 1 ≤ B + 1 := by rw [hB1]; exact Nat.le_mul_of_pos_right (k + 1) hqp0
  -- weights ≤ 1
  have hLWle1 : Rle (ofQ (⟨(p : Int), q⟩ : Q) hq) one :=
    Rle_ofQ_ofQ hq (by decide) (by simp only [Qle]; push_cast; omega)
  have hRWle1 : Rle (ofQ (⟨((q - p : Nat) : Int), q⟩ : Q) hq) one :=
    Rle_ofQ_ofQ hq (by decide) (by simp only [Qle]; push_cast; omega)
  -- the exact finite split (with block sums rewritten to the fixed block integrands)
  have hIdentity : Req (riemannSum g (A + B + 1))
      (Radd
        (Rmul (ofQ (⟨(p : Int), q⟩ : Q) hq)
          (riemannSum (fun x => g (affineMap (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q)
            (by decide) hq x)) A))
        (Rmul (ofQ (⟨((q - p : Nat) : Int), q⟩ : Q) hq)
          (riemannSum (fun x => g (affineMap (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q)
            hq hq x)) B))) := by
    refine Req_trans (riemannSum_split_at_gen g hfc A B) ?_
    refine Radd_congr (Rmul_congr ?_ ?_) (Rmul_congr ?_ ?_)
    · exact ofQ_congr _ hq hqeqL
    · exact riemannSum_congr A (fun i _ => hfc _ _
        (affineMap_qeq (by decide) (by decide) (Nat.succ_pos (A + B + 1)) hq (Qeq_refl _) hqeqL _))
    · exact ofQ_congr _ hq hqeqR
    · exact riemannSum_congr B (fun l _ => hfc _ _
        (affineMap_qeq (Nat.succ_pos (A + B + 1)) hq (Nat.succ_pos (A + B + 1)) hq hqeqL hqeqR _))
  -- the three convergence estimates
  have cd0 := riemannSum_conv_dist hLd hLn hlip hfc (A + B + 1)
  have cdL := riemannSum_conv_dist (L := mul L (⟨(p : Int), q⟩ : Q)) (Qmul_den_pos hLd hq)
    (Int.mul_nonneg hLn (Int.ofNat_nonneg p)) hlipL hfcL A
  have cdR := riemannSum_conv_dist (L := mul L (⟨((q - p : Nat) : Int), q⟩ : Q)) (Qmul_den_pos hLd hq)
    (Int.mul_nonneg hLn (Int.ofNat_nonneg (q - p))) hlipR hfcR B
  -- the three uniform numeric bounds
  have b0 := conv_bound_le hLd hLn (Nat.succ_pos (A + B + 1)) hDk0
  have bL := conv_bound_le (M := mul L (⟨(p : Int), q⟩ : Q)) (Qmul_den_pos hLd hq)
    (Int.mul_nonneg hLn (Int.ofNat_nonneg p)) (Nat.succ_pos A) hDkL
  have bR := conv_bound_le (M := mul L (⟨((q - p : Nat) : Int), q⟩ : Q)) (Qmul_den_pos hLd hq)
    (Int.mul_nonneg hLn (Int.ofNat_nonneg (q - p))) (Nat.succ_pos B) hDkR
  -- the per-block sum→integral bounds (forward terms; `t₀,(1−t₀) ≤ 1` drop the weights, then the
  -- block Riemann sum converges to the block integral). Types infer bottom-up, so the block integrals
  -- are never spelled out.
  have hBoundL :=
    Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rmul_Rsub _ _ _))))
      (Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg hq (Int.ofNat_nonneg p) _))
        (Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) hLWle1)
          (Rle_trans (Rle_of_Req (Rone_mul _))
            (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) (Rle_trans cdL bL)))))
  have hBoundR :=
    Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rmul_Rsub _ _ _))))
      (Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg hq (Int.ofNat_nonneg (q - p)) _))
        (Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) hRWle1)
          (Rle_trans (Rle_of_Req (Rone_mul _))
            (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) (Rle_trans cdR bR)))))
  -- the block half: |S − TARGET| ≤ t2 + t3
  have hblock :=
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hIdentity (Req_refl _))))
      (Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Radd_Radd _ _ _ _)))
        (Rle_trans (Rabs_Radd _ _) (Radd_le_add hBoundL hBoundR)))
  -- assemble: triangle, then combine `t1 + (t2 + t3)` into the single `C/(k+1)`
  refine Rle_trans (abs_sub_tri _ (riemannSum g (A + B + 1)) _)
    (Rle_trans (Radd_le_add (Rle_trans cd0 b0) hblock) (Rle_of_Req ?_))
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k))
      (ofQ_congr (b := (⟨(((mul L (⟨(p : Int), q⟩ : Q)).num.toNat
          + (mul L (⟨((q - p : Nat) : Int), q⟩ : Q)).num.toNat : Nat) : Int), k + 1⟩ : Q))
        _ (Nat.succ_pos k) (by simp only [Qeq, add]; push_cast; ring_uor)))) ?_
  refine Req_trans (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k)) ?_
  exact ofQ_congr _ (Nat.succ_pos k) (by simp only [Qeq, add]; push_cast; ring_uor)

-- ===========================================================================
-- The UNIT SPLIT.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- **THE UNIT SPLIT AT A GENERAL RATIONAL NODE** `t₀ = p/q ∈ (0,1)`:

      `∫₀¹ g  ≈  t₀ · ∫₀¹ g(t₀·x)  +  (1−t₀) · ∫₀¹ g(t₀ + (1−t₀)·x)`.

    The Archimedean limit of the exact finite split `riemannSum_split_at_gen` at the scaled
    resolutions `(k+1)·q`, closed by `riemannSum_conv_dist`. -/
theorem riemannIntegral_split_at_unit {g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (g x) (g y))
    (p q : Nat) (hp : 0 < p) (hq : 0 < q) (hpq : p < q) :
    Req (riemannIntegral hLd hLn hlip hfc)
      (Radd
        (Rmul (ofQ (⟨(p : Int), q⟩ : Q) hq)
          (riemannIntegral (f := fun x => g (affineMap (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q)
              (by decide) hq x)) (L := mul L (⟨(p : Int), q⟩ : Q))
            (Qmul_den_pos hLd hq) (Int.mul_nonneg hLn (Int.ofNat_nonneg p))
            (affine_lip hLd hLn hlip (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q) (by decide) hq
              (Int.ofNat_nonneg p))
            (fun x y h => hfc _ _ (affineMap_congr (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q)
              (by decide) hq h))))
        (Rmul (ofQ (⟨((q - p : Nat) : Int), q⟩ : Q) hq)
          (riemannIntegral (f := fun x => g (affineMap (⟨(p : Int), q⟩ : Q)
              (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq x)) (L := mul L (⟨((q - p : Nat) : Int), q⟩ : Q))
            (Qmul_den_pos hLd hq) (Int.mul_nonneg hLn (Int.ofNat_nonneg (q - p)))
            (affine_lip hLd hLn hlip (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) hq hq
              (Int.ofNat_nonneg (q - p)))
            (fun x y h => hfc _ _ (affineMap_congr (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q)
              hq hq h))))) := by
  refine Req_of_Rabs_sub_le
    (C := L.num.toNat + ((mul L (⟨(p : Int), q⟩ : Q)).num.toNat
      + (mul L (⟨((q - p : Nat) : Int), q⟩ : Q)).num.toNat)) (fun k => ?_)
  have hmp1 : 1 ≤ (k + 1) * p := Nat.mul_pos (Nat.succ_pos k) hp
  have hmqp1 : 1 ≤ (k + 1) * (q - p) := Nat.mul_pos (Nat.succ_pos k) (Nat.sub_pos_of_lt hpq)
  have hA1 : ((k + 1) * p - 1) + 1 = (k + 1) * p := Nat.sub_add_cancel hmp1
  have hB1 : ((k + 1) * (q - p) - 1) + 1 = (k + 1) * (q - p) := Nat.sub_add_cancel hmqp1
  have hsum2 : ((k + 1) * p - 1) + ((k + 1) * (q - p) - 1) + 2 = (k + 1) * q := by
    have h1 : ((k + 1) * p - 1) + ((k + 1) * (q - p) - 1) + 2
        = (k + 1) * p + (k + 1) * (q - p) := by omega
    rw [h1, ← Nat.mul_add]; congr 1; omega
  exact split_unit_step hLd hLn hlip hfc p q hp hq hpq
    ((k + 1) * p - 1) ((k + 1) * (q - p) - 1) k hA1 hB1 hsum2

-- ===========================================================================
-- The interval-level general split-point additivity.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- **THE INTERVAL SPLITS AT AN ARBITRARY RATIONAL NODE**:

      `∫_a^{a+w} f  ≈  ∫_a^{a+w1} f  +  ∫_{a+w1}^{a+w} f`,   `0 < w1 ≤ w`.

    The unit split of the pulled-back integrand `f ∘ α_{a,w}` at the node `t₀ = w1/w`, transported by
    the affine composition `α_{a,w} ∘ α_{0,t₀} = α_{a,w1}` and `α_{a,w} ∘ α_{t₀,1−t₀} = α_{a+w1,w−w1}`
    (`affineMap_comp`) and the certificate reconciliation `riemannIntegral_congr_mod`. The degenerate
    `w1 ≈ w` node (right piece of width `0`) is handled directly. -/
theorem riemannIntegralI_split_at {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (a w w1 : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : 0 < w1.den) (hw1n : 0 < w1.num) (hle : Qle w1 w)
    (hw2n : 0 ≤ (Qsub w w1).num) :
    Req (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)
      (Radd (riemannIntegralI hLd hLn hlip hfc a w1 ha hw1 (Int.le_of_lt hw1n))
            (riemannIntegralI hLd hLn hlip hfc (add a w1) (Qsub w w1)
              (add_den_pos ha hw1) (Qsub_den_pos hw hw1) hw2n)) := by
  -- the remainder numerator, once
  have hsubnum : (Qsub w w1).num = w.num * (w1.den : Int) - w1.num * (w.den : Int) := by
    simp only [Qsub, add, neg]; ring_uor
  rcases (show (Qsub w w1).num = 0 ∨ 0 < (Qsub w w1).num by omega) with hzero | hpos
  · -- degenerate: `w1 ≈ w`, the right piece has width 0
    have hw1eqw : Qeq w1 w := by
      show w1.num * (w.den : Int) = w.num * (w1.den : Int); omega
    have hofQ0 : Req (ofQ (Qsub w w1) (Qsub_den_pos hw hw1)) zero :=
      Req_trans (ofQ_congr (b := (⟨0, (Qsub w w1).den⟩ : Q)) (Qsub_den_pos hw hw1)
          (Qsub_den_pos hw hw1) (by simp only [Qeq]; rw [hzero]))
        (ofQ_zero_num (Qsub_den_pos hw hw1))
    have hRightZero : Req (riemannIntegralI hLd hLn hlip hfc (add a w1) (Qsub w w1)
        (add_den_pos ha hw1) (Qsub_den_pos hw hw1) hw2n) zero := by
      show Req (Rmul (ofQ (Qsub w w1) (Qsub_den_pos hw hw1)) _) zero
      exact Req_trans (Rmul_congr hofQ0 (Req_refl _))
        (Req_trans (Rmul_comm zero _) (Rmul_zero _))
    refine Req_trans
      (riemannIntegralI_congr_Q hLd hLn hlip hfc a w a w1 ha hw hwn ha hw1 (Int.le_of_lt hw1n)
        (Qeq_refl a) (Qeq_symm hw1eqw)) ?_
    exact Req_symm (Req_trans (Radd_congr (Req_refl _) hRightZero) (Radd_zero _))
  · -- generic node `t₀ = w1/w ∈ (0,1)`
    have hpI : (0 : Int) < w1.num * (w.den : Int) :=
      Int.mul_pos hw1n (by exact_mod_cast hw)
    have hleI : w1.num * (w.den : Int) ≤ w.num * (w1.den : Int) := hle
    have hqI : (0 : Int) < w.num * (w1.den : Int) := Int.lt_of_lt_of_le hpI hleI
    obtain ⟨p, hpval⟩ : ∃ p : Nat, (p : Int) = w1.num * (w.den : Int) :=
      ⟨_, Int.toNat_of_nonneg (Int.le_of_lt hpI)⟩
    obtain ⟨q, hqval⟩ : ∃ q : Nat, (q : Int) = w.num * (w1.den : Int) :=
      ⟨_, Int.toNat_of_nonneg (Int.le_of_lt hqI)⟩
    have hp : 0 < p := by omega
    have hq : 0 < q := by omega
    have hpq : p < q := by omega
    have hqp_cast : ((q - p : Nat) : Int) = (q : Int) - (p : Int) := by omega
    -- the transport `Qeq`s
    have Q1 : Qeq (mul w (⟨(p : Int), q⟩ : Q)) w1 := by
      simp only [Qeq, mul]; push_cast; rw [hpval, hqval]; ring_uor
    have Q2 : Qeq (mul w (⟨((q - p : Nat) : Int), q⟩ : Q)) (Qsub w w1) := by
      simp only [Qeq, mul, Qsub, add, neg]; rw [hqp_cast]; push_cast; rw [hpval, hqval]; ring_uor
    have Qbase0 : Qeq (add a (mul w (⟨(0 : Int), 1⟩ : Q))) a := by
      simp only [Qeq, mul, add]; push_cast; ring_uor
    have Qbase1 : Qeq (add a (mul w (⟨(p : Int), q⟩ : Q))) (add a w1) := by
      simp only [Qeq, mul, add]; push_cast; rw [hpval, hqval]; ring_uor
    have QM1 : Qeq (mul (mul L w) (⟨(p : Int), q⟩ : Q)) (mul L w1) := by
      simp only [Qeq, mul]; push_cast; rw [hpval, hqval]; ring_uor
    have QM2 : Qeq (mul (mul L w) (⟨((q - p : Nat) : Int), q⟩ : Q)) (mul L (Qsub w w1)) := by
      simp only [Qeq, mul, Qsub, add, neg]; rw [hqp_cast]; push_cast; rw [hpval, hqval]; ring_uor
    -- the unit split of the pulled-back integrand at `p/q`
    have US := riemannIntegral_split_at_unit (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
      (affine_lip hLd hLn hlip a w ha hw hwn)
      (fun x y h => hfc _ _ (affineMap_congr a w ha hw h)) p q hp hq hpq
    refine Req_trans (Rmul_congr (Req_refl _) US) ?_
    refine Req_trans (Rmul_distrib (ofQ w hw) _ _) (Radd_congr ?_ ?_)
    · -- left piece: `w · (t₀ · IL) = ∫_a^{a+w1} f`
      refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
      refine Req_trans (Rmul_congr (Rmul_ofQ_ofQ hw hq) (Req_refl _)) ?_
      refine Rmul_congr (ofQ_congr (Qmul_den_pos hw hq) hw1 Q1) ?_
      exact riemannIntegral_congr_mod _ _ _ _ (Qmul_den_pos hLd hw1)
        (Int.mul_nonneg hLn (Int.le_of_lt hw1n))
        (affine_lip hLd hLn hlip a w1 ha hw1 (Int.le_of_lt hw1n))
        (fun x y h => hfc _ _ (affineMap_congr a w1 ha hw1 h)) (Qeq_le QM1)
        (fun x => hfc _ _ (Req_trans
          (affineMap_comp a w (⟨(0 : Int), 1⟩ : Q) (⟨(p : Int), q⟩ : Q) ha hw (by decide) hq x)
          (affineMap_qeq (add_den_pos ha (Qmul_den_pos hw (by decide))) ha
            (Qmul_den_pos hw hq) hw1 Qbase0 Q1 x)))
    · -- right piece: `w · ((1−t₀) · IR) = ∫_{a+w1}^{a+w} f`
      refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
      refine Req_trans (Rmul_congr (Rmul_ofQ_ofQ hw hq) (Req_refl _)) ?_
      refine Rmul_congr (ofQ_congr (Qmul_den_pos hw hq) (Qsub_den_pos hw hw1) Q2) ?_
      exact riemannIntegral_congr_mod _ _ _ _ (Qmul_den_pos hLd (Qsub_den_pos hw hw1))
        (Int.mul_nonneg hLn hw2n)
        (affine_lip hLd hLn hlip (add a w1) (Qsub w w1) (add_den_pos ha hw1)
          (Qsub_den_pos hw hw1) hw2n)
        (fun x y h => hfc _ _ (affineMap_congr (add a w1) (Qsub w w1) (add_den_pos ha hw1)
          (Qsub_den_pos hw hw1) h)) (Qeq_le QM2)
        (fun x => hfc _ _ (Req_trans
          (affineMap_comp a w (⟨(p : Int), q⟩ : Q) (⟨((q - p : Nat) : Int), q⟩ : Q) ha hw hq hq x)
          (affineMap_qeq (add_den_pos ha (Qmul_den_pos hw hq)) (add_den_pos ha hw1)
            (Qmul_den_pos hw hq) (Qsub_den_pos hw hw1) Qbase1 Q2 x)))

end Multiplicity.UOR.Bridge.F1Square.Square
