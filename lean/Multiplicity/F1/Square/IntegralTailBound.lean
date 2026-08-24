/-
F1 square — **certified integration, brick 107** (`IntegralTailBound.lean`): **THE DYADIC TAIL
BOUND** — a Lipschitz integrand that VANISHES on `[1/2^m, 1]` has `|∫₀¹ f| ≤ B/2^m`, where `B` is
any global bound on `|f|`:

    `|f| ≤ B`,  `f ≈ 0` on `[1/2^m, 1]`   ⟹   `|∫₀¹ f| ≤ B · (1/2^m)`
      (`riemannIntegral_dyadic_tail_bound`).

WHY (the Sonine route, step 3, the a→0 Mellin limit). Brick 106 (`compactPow_one_eq_clamp`) pins
the compact power `compactPow a 1` to the clamped identity on `[a, 1]`, leaving the floor-dependence
of `compactMoment φ a 1` (versus `mellinMoment φ 1`) supported on `[0, a)`. This brick is the
locality tool that converts "the two integrands agree above the floor" into a QUANTITATIVE
`O(B·a)` bound on the integral of their difference — the missing ingredient for the `a → 0` limit.
The genuine subdivision identity `∫₀¹ = ∫₀^a + ∫_a^1` at an ARBITRARY rational `a` is not in the
repo (there is no adjacency/concatenation law), but it is **not needed**: the floor sequence is
ours to choose, so at the DYADIC floors `a = 1/2^m` the bound follows from the midpoint split alone,
iterated by induction — the `[1/2, 1]` half vanishes by hypothesis, the `[0, 1/2]` half rescales to
depth `m` under the affine pullback, and the width factor `1/2` supplies the geometric decay.

The induction is on the depth `m`. At `m = 0` the tail hypothesis is vacuous (only `x = 1`) and the
bound is the global `|∫₀¹ f| ≤ B` (comparison against the constants `±B`). At `m+1`, split at the
midpoint: on `[1/2, 1] ⊆ [1/2^{m+1}, 1]` the integrand is `≈ 0`, so that piece is `0` by the window
bound; on `[0, 1/2]` the affine pullback `x ↦ f(x/2)` is bounded by the same `B`, vanishes on
`[1/2^m, 1]` (since `x/2 ∈ [1/2^{m+1}, 1/2]`), and the inductive hypothesis gives `B/2^m`, scaled by
the width `1/2` to `B/2^{m+1}`.

Mechanical note (mirroring `riemannIntegralI_ge_dyadic`): the depth `m` sits inside the
denominator-positivity PROOF TERMS `2^m > 0`, so the recursion carries `f`, `L` and their
certificates as explicit arguments and the depth is moved by `Nat.pow_succ` only inside the `Qeq`
goals, where no proof terms live.

HONEST SCOPE. A quantitative decay bound for the certified `[0,1]` integral of a globally-Lipschitz
integrand that vanishes on a dyadic tail. Integration substrate; nothing here touches the Weil form
or a transform pair. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DyadicDescent
import Multiplicity.F1.Analysis.MellinDecay

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Base case: the global absolute bound `|∫₀¹ f| ≤ B`.
-- ===========================================================================

/-- **The global absolute bound**: `|f| ≤ B` (everywhere) ⟹ `|∫₀¹ f| ≤ B` — comparison against the
    constants `±B` at the shared modulus `L` (the zero-modulus constants weakened up to `L`), whose
    integrals evaluate to `±B` by `riemannIntegral_const_gen`. (Private base case of the tail bound.) -/
private theorem riemannIntegral_abs_le {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (B : Q) (hBd : 0 < B.den) (hbd : ∀ x, Rle (Rabs (f x)) (ofQ B hBd)) :
    Rle (Rabs (riemannIntegral hLd hLn hlip hfc)) (ofQ B hBd) := by
  have hzeroL : Qle (⟨0, 1⟩ : Q) L := by
    show (0 : Int) * (L.den : Int) ≤ L.num * 1
    rw [Int.zero_mul, Int.mul_one]; exact hLn
  have hlipB : ∀ x y, Rle (Rabs (Rsub (ofQ B hBd) (ofQ B hBd)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
    lip_weaken (by decide) hLd hzeroL (const_lip0 (ofQ B hBd))
  have hlipnB : ∀ x y, Rle (Rabs (Rsub (Rneg (ofQ B hBd)) (Rneg (ofQ B hBd))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
    lip_weaken (by decide) hLd hzeroL (const_lip0 (Rneg (ofQ B hBd)))
  have hcB : Req (riemannIntegral (f := fun _ => ofQ B hBd) hLd hLn hlipB
      (fun _ _ _ => Req_refl _)) (ofQ B hBd) :=
    riemannIntegral_const_gen (ofQ B hBd) hLd hLn hlipB (fun _ _ _ => Req_refl _)
  have hcnB : Req (riemannIntegral (f := fun _ => Rneg (ofQ B hBd)) hLd hLn hlipnB
      (fun _ _ _ => Req_refl _)) (Rneg (ofQ B hBd)) :=
    riemannIntegral_const_gen (Rneg (ofQ B hBd)) hLd hLn hlipnB (fun _ _ _ => Req_refl _)
  refine Rabs_le_of_both ?_ ?_
  · exact Rle_trans (riemannIntegral_le hLd hLn hlip hfc hlipB (fun _ _ _ => Req_refl _)
      (fun x => Rle_of_Rabs_le (hbd x))) (Rle_of_Req hcB)
  · have hlo : Rle (Rneg (ofQ B hBd)) (riemannIntegral hLd hLn hlip hfc) :=
      Rle_trans (Rle_of_Req (Req_symm hcnB))
        (riemannIntegral_le hLd hLn hlipnB (fun _ _ _ => Req_refl _) hlip hfc
          (fun x => Rneg_le_of_Rabs_le (hbd x)))
    exact Rle_trans (Rle_Rneg hlo) (Rle_of_Req (Rneg_Rneg (ofQ B hBd)))

-- ===========================================================================
-- Affine-pullback arithmetic helpers (private).
-- ===========================================================================

/-- On `[·, 1]`: `affineMap a (1/2) x ≤ 1` when `a + 1/2 ≤ 1` and `x ≤ 1`. -/
private theorem affine_upper (a : Q) (ha : 0 < a.den)
    (haw : Qle (add a (⟨1, 2⟩ : Q)) (⟨1, 1⟩ : Q)) {x : Real} (hx1 : Rle x one) :
    Rle (affineMap a (⟨1, 2⟩ : Q) ha (by decide) x) one := by
  show Rle (Radd (ofQ a ha) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x)) one
  refine Rle_trans (Radd_le_add (Rle_refl _)
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hx1)) ?_
  refine Rle_trans (Radd_le_add (Rle_refl _) (Rle_of_Req (Rmul_one _))) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ ha (by decide))) ?_
  exact Rle_ofQ_ofQ (add_den_pos ha (by decide)) (by decide) haw

-- ===========================================================================
-- The dyadic tail bound.
-- ===========================================================================

set_option maxHeartbeats 3200000 in
/-- **THE DYADIC TAIL BOUND**: a globally-bounded (`|f| ≤ B`), Lipschitz integrand that vanishes on
    the dyadic tail `[1/2^m, 1]` has `|∫₀¹ f| ≤ B · (1/2^m)`. Induction on the depth `m`: at `0` the
    global bound; at `m+1` the midpoint split kills the `[1/2,1]` half and the `[0,1/2]` half
    rescales to depth `m` under the affine pullback, the width `1/2` supplying the geometric decay. -/
theorem riemannIntegral_dyadic_tail_bound (B : Q) (hBd : 0 < B.den) (hBn : 0 ≤ B.num) :
    ∀ (m : Nat) (f : Real → Real) (L : Q) (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
      (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
      (hfc : ∀ x y, Req x y → Req (f x) (f y))
      (_hbd : ∀ x, Rle (Rabs (f x)) (ofQ B hBd))
      (_htail : ∀ x, Rle (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m)) x → Rle x one → Req (f x) zero),
      Rle (Rabs (riemannIntegral hLd hLn hlip hfc))
          (ofQ (mul B (⟨1, 2 ^ m⟩ : Q)) (Qmul_den_pos hBd (two_pow_pos m)))
  | 0, f, L, hLd, hLn, hlip, hfc, hbd, _htail => by
      refine Rle_trans (riemannIntegral_abs_le hLd hLn hlip hfc B hBd hbd) ?_
      refine Rle_of_Req (ofQ_congr hBd (Qmul_den_pos hBd (two_pow_pos 0)) ?_)
      simp only [Qeq, mul, Nat.pow_zero]; push_cast; ring_uor
  | (m + 1), f, L, hLd, hLn, hlip, hfc, hbd, htail => by
      have hpow : (2 : Nat) ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
      have h2m : (1 : Nat) ≤ 2 ^ m := two_pow_pos m
      have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
      have hle12 : Qle (⟨1, 2 ^ (m + 1)⟩ : Q) (⟨1, 2⟩ : Q) := by
        have h2 : (2 : Nat) ≤ 2 ^ (m + 1) := by omega
        have hc : ((2 : Nat) : Int) ≤ ((2 ^ (m + 1) : Nat) : Int) := Int.ofNat_le.mpr h2
        simp only [Qle]
        omega
      -- Right half `[1/2,1]`: the integrand vanishes there, so `|∫| ≤ 0`.
      have hI1 : Rle (Rabs (riemannIntegralI hLd hLn hlip hfc (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
            (by decide) (by decide) (by decide)))
          (ofQ (mul (⟨1, 2⟩ : Q) (⟨0, 1⟩ : Q)) (by decide)) := by
        refine riemannIntegralI_abs_le_window hLd hLn hlip hfc (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (⟨0, 1⟩ : Q)
          (by decide) (by decide) (by decide) (by decide) ?_
        intro x hx0 hx1
        have hlo : Rle (ofQ (⟨1, 2 ^ (m + 1)⟩ : Q) (two_pow_pos (m + 1)))
            (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x) :=
          Rle_trans (Rle_ofQ_ofQ (two_pow_pos (m + 1)) (by decide) hle12)
            (Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
              (Rnonneg_of_Rle_zero hx0)))
        have hval : Req (f (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x)) zero :=
          htail _ hlo (affine_upper (⟨1, 2⟩ : Q) (by decide) (by decide) hx1)
        exact Rle_of_Req (Req_trans (Rabs_congr hval) (Req_trans Rabs_zero (Req_symm hz0)))
      -- Left half `[0,1/2]`: the affine pullback drops to depth `m`; apply the IH.
      have hI0 : Rle (Rabs (riemannIntegralI hLd hLn hlip hfc (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)
            (by decide) (by decide) (by decide)))
          (ofQ (mul B (⟨1, 2 ^ (m + 1)⟩ : Q)) (Qmul_den_pos hBd (two_pow_pos (m + 1)))) := by
        have hIH := riemannIntegral_dyadic_tail_bound B hBd hBn m
          (fun x => f (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x))
          (mul L (⟨1, 2⟩ : Q)) (Qmul_den_pos hLd (by decide)) (Int.mul_nonneg hLn (by decide))
          (affine_lip hLd hLn hlip (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))
          (fun x y h => hfc _ _ (affineMap_congr (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) h))
          (fun x => hbd (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x))
          (fun x hx0 hx1 => by
            refine htail (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x) ?_
              (affine_upper (⟨0, 1⟩ : Q) (by decide) (by decide) hx1)
            have heq : Req (ofQ (⟨1, 2 ^ (m + 1)⟩ : Q) (two_pow_pos (m + 1)))
                (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2 ^ m⟩ : Q) (two_pow_pos m))) := by
              refine Req_trans (Req_symm (ofQ_congr (Qmul_den_pos (by decide) (two_pow_pos m))
                (two_pow_pos (m + 1)) ?_)) (Req_symm (Rmul_ofQ_ofQ (by decide) (two_pow_pos m)))
              simp only [Qeq, mul]; rw [hpow]; push_cast; ring_uor
            have hstep : Rle (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2 ^ m⟩ : Q)
                  (two_pow_pos m))) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x) :=
              Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hx0
            have hshift : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x)
                (Radd (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x)) :=
              Req_symm (Req_trans (Radd_congr hz0 (Req_refl _))
                (Req_trans (Radd_comm zero _) (Radd_zero _)))
            exact Rle_trans (Rle_of_Req heq) (Rle_trans hstep (Rle_of_Req hshift)))
        refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide) (by decide) _)) ?_
        refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hIH) ?_
        refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (by decide)
          (Qmul_den_pos hBd (two_pow_pos m)))) ?_
        refine Rle_of_Req (ofQ_congr (Qmul_den_pos (by decide) (Qmul_den_pos hBd (two_pow_pos m)))
          (Qmul_den_pos hBd (two_pow_pos (m + 1))) ?_)
        simp only [Qeq, mul]; rw [hpow]; push_cast; ring_uor
      -- assemble: split, triangle, bound each half, absorb the vanishing tail.
      refine Rle_trans (Rle_of_Req (Rabs_congr (riemannIntegral_split_half hLd hLn hlip hfc))) ?_
      refine Rle_trans (Rabs_Radd _ _) ?_
      refine Rle_trans (Radd_le_add hI0 hI1) ?_
      refine Rle_of_Req (Req_trans
        (Radd_ofQ_ofQ (Qmul_den_pos hBd (two_pow_pos (m + 1))) (by decide))
        (ofQ_congr (add_den_pos (Qmul_den_pos hBd (two_pow_pos (m + 1))) (by decide))
          (Qmul_den_pos hBd (two_pow_pos (m + 1))) ?_))
      simp only [Qeq, add, mul]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
