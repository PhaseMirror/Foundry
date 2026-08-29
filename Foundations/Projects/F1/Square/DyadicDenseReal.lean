/-
F1 square — **the pre-Hilbert layer, brick 79** (`DyadicDenseReal.lean`): **THE `L²` PAIRING IS
DEFINITE AT EVERY POINT OF `[0,1]`** — the density argument carried from the rationals (brick 78)
to all reals:

    `0 ≤ x ≤ 1`               ⟹   `DyadicApproximable x`        (`dyadicApproximable_of_unit`)
    `∫₀¹ φ² ≈ 0`,  `0 ≤ x ≤ 1` ⟹   `φ(x) ≈ 0`                    (`innerI_self_zero_imp_zero`)

and the polynomial-class capstone `polyPN_unit_zero`.

This discharges `DyadicApproximable` (brick 76) for an **arbitrary** unit-interval real, closing the
thread bricks 68–78 opened: brick 74 gave definiteness at dyadic points, brick 78 at rationals, and
this at every point. The mechanism is exactly the one the earlier bricks assembled — locate the
real's own rational approximant `x.seq N` to within `1/(N+1)` (`Rabs_sub_seq_le`, `RSeqApprox`),
floor it to a dyadic point (`dyadJ`, brick 75), clamp the index into range (`dyadJC`, brick 77),
and transport the vanishing value by the Lipschitz certificate (brick 76). The one genuinely new
ingredient is the **out-of-range case analysis** the approximant forces: `x.seq N` need not lie in
`[0,1)` (it can dip below `0` or reach `1` by the approximation error), so the clamped point sits at
the boundary and the distance is bounded there directly from `0 ≤ x ≤ 1`, not through the floor.
The three branches (`case_lo`, `case_mid`, `case_hi`) are the below-`0`, in-range, and at-or-above-`1`
positions of the approximant; only the middle one uses brick 75's floor bound, the other two use the
boundary geometry.

HONEST SCOPE. Point-definiteness of `⟨·,·⟩` at every real point of `[0,1]`. This is a statement
about the value of a bounded-Lipschitz test at a point, NOT the moment problem: a nonzero test with
every *moment* vanishing is a different question, still open, still needing a constructive
approximation theorem (Bernstein) the repo does not have. So `polyPN_unit_zero` says a polynomial
test with `d` vanishing moments is the zero *function* on `[0,1]` (its value vanishes at every
point), which for the polynomial class does upgrade brick 64's moment-determinacy to a genuine
function-level determinacy; the general (non-polynomial) determinacy is untouched. Nothing here
touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DyadicDense
import Foundations.F1.Analysis.ThetaLipschitz
import Foundations.F1.Analysis.SqrtRealSq
import Foundations.F1.Analysis.Pi

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|a − c| ≤ |a − b| + |b − c|` (local copy of `L2Definite`'s private triangle helper). -/
private theorem abs_sub_tri3 (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- **The cancel identity** `1 − (1 − Y) ≈ Y`, from the additive laws alone. -/
private theorem sub_one_sub (Y : Real) : Req (Rsub one (Rsub one Y)) Y :=
  Req_trans (Radd_congr (Req_refl one) (Rneg_Rsub one Y))
    (Req_trans (Req_symm (Radd_assoc one Y (Rneg one)))
      (Req_trans (Radd_congr (Radd_comm one Y) (Req_refl (Rneg one)))
        (Req_trans (Radd_assoc Y one (Rneg one))
          (Req_trans (Radd_congr (Req_refl Y) (Radd_neg one)) (Radd_zero Y)))))

/-- **The sum bound**: `1/(N+1) + 1/2^m ≤ 1/(k+1)` (with `N = 2k+1`), realized on the two `ofQ`
    substrate values, whenever `2^m` outruns `N+1`. Product-free: `B ≤ A` is the linear
    `N+1 ≤ 2^m`, and `A + A ≈ 1/(k+1)` is a single-variable rational identity. -/
private theorem sum_bound (k m : Nat) (hm : 2 * k + 1 + 1 ≤ 2 ^ m) :
    Rle (Radd (ofQ (⟨1, 2 * k + 1 + 1⟩ : Q) (Nat.succ_pos _)) (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m)))
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  have hBA : Rle (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))
      (ofQ (⟨1, 2 * k + 1 + 1⟩ : Q) (Nat.succ_pos _)) := by
    refine Rle_ofQ_ofQ (two_pow_pos m) (Nat.succ_pos _) ?_
    simp only [Qle]
    have : ((2 * k + 1 + 1 : Nat) : Int) ≤ ((2 ^ m : Nat) : Int) := by exact_mod_cast hm
    omega
  refine Rle_trans (Radd_le_add (Rle_refl _) hBA) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Radd_ofQ_ofQ (Nat.succ_pos _) (Nat.succ_pos _)) ?_
  refine ofQ_congr (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (Nat.succ_pos k) ?_
  simp only [Qeq, add]
  push_cast
  ring_uor

-- ===========================================================================
-- The three positions of the approximant.
-- ===========================================================================

/-- **In-range approximant**: `0 ≤ q < 1`, so brick 75's floor bound applies and the triangle
    inequality carries the distance. -/
private theorem case_mid (x : Real) (q : Q) (hqd : 0 < q.den) (m : Nat)
    (hqn : 0 ≤ q.num) (hqr : q.num.toNat < q.den)
    (A : Real) (hxq : Rle (Rabs (Rsub x (ofQ q hqd))) A) :
    Rle (Rabs (Rsub x (dyadPt m (dyadJC q m))))
      (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) := by
  rw [dyadJC_eq_of_lt q m (dyadJ_lt q hqd hqr m)]
  refine Rle_trans (abs_sub_tri3 x (ofQ q hqd) (dyadPt m (dyadJ q m))) ?_
  refine Radd_le_add hxq ?_
  refine Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Rsub_ofQ_ofQ hqd (two_pow_pos m)))
    (Rabs_ofQ (add_den_pos hqd (two_pow_pos m))))) ?_
  exact Rle_ofQ_ofQ (Qabs_den_pos (add_den_pos hqd (two_pow_pos m))) (two_pow_pos m)
    (dyadApprox_spec q hqd hqn m)

/-- **Below-zero approximant**: `q < 0`, so the clamped index is `0` and the dyadic point is `0`;
    since `x ≥ 0` and `x ≤ q + 1/(N+1) ≤ 1/(N+1)`, the distance is `|x| = x`. -/
private theorem case_lo (x : Real) (h0 : Rle zero x) (q : Q) (hqd : 0 < q.den) (m : Nat)
    (hqneg : q.num < 0)
    (A : Real) (hxq : Rle (Rabs (Rsub x (ofQ q hqd))) A) :
    Rle (Rabs (Rsub x (dyadPt m (dyadJC q m))))
      (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) := by
  have hzero : dyadJC q m = 0 := by
    have htn : q.num.toNat = 0 := by omega
    have hdj : dyadJ q m = 0 := by unfold dyadJ; rw [htn]; simp
    unfold dyadJC; rw [hdj]; exact Nat.min_eq_left (Nat.zero_le _)
  rw [hzero]
  have hp0 : Req (dyadPt m 0) zero := by
    refine ofQ_congr (two_pow_pos m) (by decide) ?_
    simp only [Qeq]; push_cast; ring_uor
  have hxnn : Rnonneg x := Rnonneg_of_Rle_zero h0
  have habs : Req (Rabs (Rsub x (dyadPt m 0))) x :=
    Req_trans (Rabs_congr (Req_trans (Rsub_congr (Req_refl x) hp0) (Rsub_zero x)))
      (Rabs_of_nonneg hxnn)
  have hq0 : Rle (ofQ q hqd) zero := by
    refine Rle_ofQ_ofQ hqd (by decide) ?_
    simp only [Qle]; push_cast; omega
  have hxA : Rle x A :=
    Rle_trans (Rle_Radd_of_Rsub_le (Rle_of_Rabs_le hxq))
      (Rle_trans (Radd_le_add hq0 (Rle_refl A))
        (Rle_of_Req (Req_trans (Radd_comm zero A) (Radd_zero A))))
  have hA_le_AB : Rle A (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) :=
    Rle_trans (Rle_of_Req (Req_symm (Radd_zero A)))
      (Radd_le_add (Rle_refl A) (Rle_zero_of_Rnonneg (Rnonneg_ofQ (two_pow_pos m) (by show (0:Int) ≤ 1; decide))))
  exact Rle_trans (Rle_of_Req habs) (Rle_trans hxA hA_le_AB)

/-- **At-or-above-one approximant**: `q ≥ 1`, so the clamped index is `2^m − 1` and the dyadic
    point is `1 − 1/2^m`; since `x ≤ 1` and `x ≥ q − 1/(N+1) ≥ 1 − 1/(N+1)`, both `x` and the
    point sit in `[1 − 1/(N+1), 1]` and the distance is bounded by `1/(N+1)`. -/
private theorem case_hi (x : Real) (h1 : Rle x one) (q : Q) (hqd : 0 < q.den) (m : Nat)
    (hqn : 0 ≤ q.num) (hqge : q.den ≤ q.num.toNat)
    (A : Real) (hA0 : Rle zero A) (hxq : Rle (Rabs (Rsub x (ofQ q hqd))) A) :
    Rle (Rabs (Rsub x (dyadPt m (dyadJC q m))))
      (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) := by
  have hdj : 2 ^ m ≤ dyadJ q m := by
    unfold dyadJ
    rw [Nat.le_div_iff_mul_le hqd]
    calc 2 ^ m * q.den ≤ 2 ^ m * q.num.toNat := Nat.mul_le_mul_left (2 ^ m) hqge
      _ = q.num.toNat * 2 ^ m := Nat.mul_comm _ _
  have hjhi : dyadJC q m = 2 ^ m - 1 := by
    unfold dyadJC
    exact Nat.min_eq_right (by omega)
  rw [hjhi]
  have h2m1 : (1 : Nat) ≤ 2 ^ m := two_pow_pos m
  have hcast : ((2 ^ m - 1 : Nat) : Int) = ((2 ^ m : Nat) : Int) - 1 := by omega
  have hB0 : Rle zero (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m)) :=
    Rle_zero_of_Rnonneg (Rnonneg_ofQ (two_pow_pos m) (by show (0:Int) ≤ 1; decide))
  have hpB : Req (dyadPt m (2 ^ m - 1)) (Rsub one (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) := by
    refine Req_symm (Req_trans (Rsub_ofQ_ofQ (by decide) (two_pow_pos m))
      (ofQ_congr _ (two_pow_pos m) ?_))
    simp only [Qeq, Qsub, add, neg]
    push_cast [hcast]
    ring_uor
  have hp_le_one : Rle (dyadPt m (2 ^ m - 1)) one := by
    refine Rle_ofQ_ofQ (two_pow_pos m) (by decide) ?_
    simp only [Qle]; push_cast [hcast]; omega
  have hone_le_q : Rle one (ofQ q hqd) := by
    refine Rle_ofQ_ofQ (by decide) hqd ?_
    simp only [Qle]; omega
  have hqA_le : Rle (Rsub (ofQ q hqd) A) x :=
    Rle_trans (Radd_le_add (Rle_refl (ofQ q hqd)) (Rneg_le_of_Rabs_le hxq))
      (Rle_of_Req (Radd_Rsub_self (ofQ q hqd) x))
  have hx_ge_oneA : Rle (Rsub one A) x :=
    Rle_trans (Rsub_le_mono hone_le_q (Rle_refl A)) hqA_le
  have hhi : Rle (Rsub x (dyadPt m (2 ^ m - 1)))
      (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) := by
    have step1 : Rle (Rsub x (dyadPt m (2 ^ m - 1))) (Rsub one (dyadPt m (2 ^ m - 1))) :=
      Rsub_le_mono h1 (Rle_refl _)
    have step2 : Req (Rsub one (dyadPt m (2 ^ m - 1))) (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m)) :=
      Req_trans (Rsub_congr (Req_refl one) hpB) (sub_one_sub (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m)))
    have hB_le_AB : Rle (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))
        (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) :=
      Rle_trans (Rle_of_Req (Req_symm (Req_trans (Radd_comm zero _) (Radd_zero _))))
        (Radd_le_add hA0 (Rle_refl _))
    exact Rle_trans step1 (Rle_trans (Rle_of_Req step2) hB_le_AB)
  have hlo2 : Rle (Rsub (dyadPt m (2 ^ m - 1)) x)
      (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) := by
    have step3 : Rle (Rsub (dyadPt m (2 ^ m - 1)) x) (Rsub one (Rsub one A)) :=
      Rsub_le_mono hp_le_one hx_ge_oneA
    have hA_le_AB : Rle A (Radd A (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) :=
      Rle_trans (Rle_of_Req (Req_symm (Radd_zero A))) (Radd_le_add (Rle_refl A) hB0)
    exact Rle_trans step3 (Rle_trans (Rle_of_Req (sub_one_sub A)) hA_le_AB)
  exact Rabs_le_of_both hhi
    (Rle_trans (Rle_of_Req (Rneg_Rsub x (dyadPt m (2 ^ m - 1)))) hlo2)

-- ===========================================================================
-- The assembly.
-- ===========================================================================

/-- **The distance to the clamped dyadic point is `≤ 1/(N+1) + 1/2^m ≤ 1/(k+1)`**, when `2^m`
    outruns `N+1 = 2k+2`. The three positions of the approximant `x.seq (2k+1)` are handled by
    `case_lo`/`case_mid`/`case_hi`; the sum bound is `sum_bound`. -/
private theorem near_clamped (x : Real) (h0 : Rle zero x) (h1 : Rle x one)
    (k m : Nat) (hm : 2 * k + 1 + 1 ≤ 2 ^ m) :
    Rle (Rabs (Rsub x (dyadPt m (dyadJC (x.seq (2 * k + 1)) m))))
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  have hqd : 0 < (x.seq (2 * k + 1)).den := x.den_pos (2 * k + 1)
  have hxq : Rle (Rabs (Rsub x (ofQ (x.seq (2 * k + 1)) hqd)))
      (ofQ (⟨1, 2 * k + 1 + 1⟩ : Q) (Nat.succ_pos _)) := Rabs_sub_seq_le x (2 * k + 1)
  have hA0 : Rle zero (ofQ (⟨1, 2 * k + 1 + 1⟩ : Q) (Nat.succ_pos _)) :=
    Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos _) (by show (0:Int) ≤ 1; decide))
  refine Rle_trans ?_ (sum_bound k m hm)
  rcases (by omega : (x.seq (2 * k + 1)).num < 0 ∨ 0 ≤ (x.seq (2 * k + 1)).num) with hs | hs
  · exact case_lo x h0 (x.seq (2 * k + 1)) hqd m hs _ hxq
  · rcases (by omega : (x.seq (2 * k + 1)).num.toNat < (x.seq (2 * k + 1)).den
        ∨ (x.seq (2 * k + 1)).den ≤ (x.seq (2 * k + 1)).num.toNat) with hr | hr
    · exact case_mid x (x.seq (2 * k + 1)) hqd m hs hr _ hxq
    · exact case_hi x h1 (x.seq (2 * k + 1)) hqd m hs hr _ hA0 hxq

/-- **EVERY REAL OF `[0,1]` IS DYADICALLY APPROXIMABLE.** -/
theorem dyadicApproximable_of_unit (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    DyadicApproximable x := by
  intro k
  obtain ⟨m, hmq⟩ := exists_depth (⟨1, 1⟩ : Q) (⟨1, 2 * k + 1 + 1⟩ : Q) (by decide)
    (Nat.succ_pos _) (by show (0:Int) < 1; decide)
  have hm : 2 * k + 1 + 1 ≤ 2 ^ m := by
    have h := hmq
    simp only [Qle, mul] at h
    omega
  exact ⟨m, dyadJC (x.seq (2 * k + 1)) m, dyadJC_lt _ m, near_clamped x h0 h1 k m hm⟩

/-- **DEFINITENESS AT EVERY POINT of `[0,1]`.** -/
theorem innerI_self_zero_imp_zero (φ : L2Test) (h : Req (innerI φ φ) zero)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req (φ.f x) zero :=
  zero_of_dyadic_approximable φ h x (dyadicApproximable_of_unit x h0 h1)

/-- **THE POLYNOMIAL CLASS IS THE ZERO FUNCTION ON `[0,1]`**: a `d`-coefficient polynomial test
    whose first `d` moments vanish is zero at every point of `[0,1]` — brick 64's moment
    determinacy upgraded to a function-level determinacy on the polynomial class. -/
theorem polyPN_unit_zero (a b : Nat → Nat) (d : Nat)
    (hmom : ∀ i : Nat, i < d → Req (mellinMoment (polyPN a b d) i) zero)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Req ((polyPN a b d).f x) zero :=
  innerI_self_zero_imp_zero (polyPN a b d) (innerI_polyPN_self_zero a b d hmom) x h0 h1

end Multiplicity.UOR.Bridge.F1Square.Square
