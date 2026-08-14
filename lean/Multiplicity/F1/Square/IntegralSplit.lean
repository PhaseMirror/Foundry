/-
F1 square — **certified integration, the missing structural law** (`IntegralSplit.lean`):
**THE INTEGRAL SPLITS AT THE MIDPOINT** —

    `∫₀¹ f  ≈  ∫₀^{1/2} f  +  ∫_{1/2}^1 f`   (`riemannIntegral_split_half`).

Until now the integral API carried only the laws that leave the *interval* alone —
nonnegativity, monotonicity, additivity in the integrand, congruence, negation, rational scaling.
There was no way to relate an integral to integrals over sub-intervals, which is why
`∫₀¹ φ² ≈ 0 ⟹ φ ≈ 0` (L² definiteness, and with it Hilbert-section nondegeneracy and general
determinacy) had no route: those all need "positive on a piece ⟹ positive overall".

The proof is exact at every finite level and analytic only in the limit. The two half-integrals
are, by definition, `1/2` times integrals of the affine pullbacks `f(x/2)` and `f((1+x)/2)`, and
the partition points of the two halves at level `m` **interleave exactly** into the partition
points of `f` at level `m+1`:

    left  `i/(N+1)  ↦  i/(2N+2)`,      right `i/(N+1)  ↦  (N+1+i)/(2N+2)`,

so `½·D_m(f(x/2)) + ½·D_m(f((1+x)/2)) = D_{m+1}(f)` as a finite identity (`riemannSum_halves`),
with `RsumN_split_at` doing the two-block flattening. The index bookkeeping — `dyadicR g k` is
`riemannSum g (2^k − 1)`, and `2^(k+1) − 1 = 2(2^k − 1) + 1` — is routed through `subst`-based
index congruences (`riemannSum_idx`), because rewriting those `Nat` indices directly is not
type-correct: they occur inside the `Nat.succ_pos` proof terms the denominators carry.

The limit is then three applications of `riemannIntegral_dyadic_dist` and the Archimedean
criterion: the gap is `(D + E)/(k+1)` for every `k`, where `D` and `E` are the two effective
dyadic error constants.

HONEST SCOPE. One split, at the midpoint, for the Lipschitz class on `[0,1]`.
NOTE ON "the Lipschitz class on `[0,1]`". The hypothesis `hlip` quantifies over ALL reals, not
just `[0,1]`, so the class is the GLOBALLY Lipschitz functions — `x(1−x)` as a bare function is
not in it, and callers supply a clamped representative (`clampTest`). This is the standing
convention of the `riemannIntegral` gateway and of `L2Test`, inherited rather than introduced
here, but the shorter phrase reads as a weaker requirement than the statement imposes.
 Composing it under
the affine pullback gives every dyadic subdivision, but that composition is not performed here,
and nothing about non-dyadic split points is claimed. Nothing here touches the Weil form or the
crux; it is integration substrate. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.IntegralCS
import Multiplicity.F1Square.Square.MomentNorm

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Index congruences (the type-correct way past the `Nat.succ_pos` proof terms).
-- ===========================================================================

/-- Riemann sums at equal indices agree — by `subst`, since rewriting the index in place would
    strand the `Nat.succ_pos` proof terms the denominators carry. -/
theorem riemannSum_idx (g : Real → Real) {N M : Nat} (h : N = M) :
    Req (riemannSum g N) (riemannSum g M) := by subst h; exact Req_refl _

/-- The same for the underlying finite sums. -/
theorem RsumN_idx (F : Nat → Real) {N M : Nat} (h : N = M) :
    Req (RsumN F N) (RsumN F M) := by subst h; exact Req_refl _

-- ===========================================================================
-- The partition points interleave.
-- ===========================================================================

/-- The left half's `i`-th partition point is the finer partition's `i`-th. -/
theorem affine_left_point (N i : Nat) :
    Req (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide)
          (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
        (ofQ (⟨(i : Int), 2 * N + 1 + 1⟩ : Q) (Nat.succ_pos _)) := by
  show Req (Radd (ofQ (⟨0, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) _
  refine Req_trans (Radd_congr (Req_refl _) (Rmul_ofQ_ofQ (by decide) (Nat.succ_pos N))) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (Qmul_den_pos (by decide) (Nat.succ_pos N))) ?_
  refine ofQ_congr _ (Nat.succ_pos _) ?_
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- The right half's `i`-th partition point is the finer partition's `(N+1+i)`-th. -/
theorem affine_right_point (N i : Nat) :
    Req (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide)
          (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
        (ofQ (⟨((N + 1 + i : Nat) : Int), 2 * N + 1 + 1⟩ : Q) (Nat.succ_pos _)) := by
  show Req (Radd (ofQ (⟨1, 2⟩ : Q) (by decide))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) _
  refine Req_trans (Radd_congr (Req_refl _) (Rmul_ofQ_ofQ (by decide) (Nat.succ_pos N))) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (Qmul_den_pos (by decide) (Nat.succ_pos N))) ?_
  refine ofQ_congr _ (Nat.succ_pos _) ?_
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- **THE BLOCK IDENTITY**, exact at every level: half the left pullback's Riemann sum plus half
    the right pullback's IS the doubled-partition Riemann sum of `f`. -/
theorem riemannSum_halves (f : Real → Real)
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (N : Nat) :
    Req (Radd
          (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (riemannSum (fun x => f (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)
              (by decide) (by decide) x)) N))
          (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (riemannSum (fun x => f (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
              (by decide) (by decide) x)) N)))
        (riemannSum f (2 * N + 1)) := by
  have hd : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨1, 2 * N + 1 + 1⟩ : Q) (Nat.succ_pos _)) := by
    refine Req_trans (Rmul_ofQ_ofQ (by decide) (Nat.succ_pos N)) ?_
    refine ofQ_congr _ (Nat.succ_pos _) ?_
    simp only [Qeq, mul]; push_cast; ring_uor
  have hL : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
      (riemannSum (fun x => f (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)
        (by decide) (by decide) x)) N))
      (Rmul (ofQ (⟨1, 2 * N + 1 + 1⟩ : Q) (Nat.succ_pos _))
        (RsumN (fun i => f (ofQ (⟨(i : Int), 2 * N + 1 + 1⟩ : Q) (Nat.succ_pos _))) (N + 1))) := by
    refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
    exact Rmul_congr hd (RsumN_congr (N + 1) (fun i _ => hfc _ _ (affine_left_point N i)))
  have hR : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
      (riemannSum (fun x => f (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
        (by decide) (by decide) x)) N))
      (Rmul (ofQ (⟨1, 2 * N + 1 + 1⟩ : Q) (Nat.succ_pos _))
        (RsumN (fun i => f (ofQ (⟨((N + 1 + i : Nat) : Int), 2 * N + 1 + 1⟩ : Q)
          (Nat.succ_pos _))) (N + 1))) := by
    refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
    exact Rmul_congr hd (RsumN_congr (N + 1) (fun i _ => hfc _ _ (affine_right_point N i)))
  refine Req_trans (Radd_congr hL hR) ?_
  refine Req_trans (Req_symm (Rmul_distrib _ _ _)) ?_
  refine Rmul_congr (Req_refl _) ?_
  refine Req_trans (Req_symm (RsumN_split_at
    (fun i => f (ofQ (⟨(i : Int), 2 * N + 1 + 1⟩ : Q) (Nat.succ_pos _))) (N + 1) (N + 1))) ?_
  exact RsumN_idx _ (by omega)

/-- The block identity at the dyadic levels: `½·D_m(left) + ½·D_m(right) = D_{m+1}(f)`. -/
theorem dyadicR_halves (f : Real → Real)
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (m : Nat) :
    Req (Radd
          (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (dyadicR (fun x => f (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)
              (by decide) (by decide) x)) m))
          (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (dyadicR (fun x => f (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
              (by decide) (by decide) x)) m)))
        (dyadicR f (m + 1)) := by
  have hp : 1 ≤ 2 ^ m := Nat.one_le_two_pow
  have hidx : 2 * (2 ^ m - 1) + 1 = 2 ^ (m + 1) - 1 := by
    have hpow : 2 ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
    omega
  exact Req_trans (riemannSum_halves f hfc (2 ^ m - 1)) (riemannSum_idx f hidx)

-- ===========================================================================
-- The two half-pullbacks, named — so the unifier never has to guess `f` from a
-- lambda carrying `by decide` proof terms (that unification whnf-explodes).
-- ===========================================================================

/-- The left half's affine pullback, `x ↦ f(x/2)`. -/
def halfL (f : Real → Real) : Real → Real :=
  fun x => f (affineMap (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x)

/-- The right half's affine pullback, `x ↦ f((1+x)/2)`. -/
def halfR (f : Real → Real) : Real → Real :=
  fun x => f (affineMap (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) x)

/-- The block identity, restated on the named pullbacks. -/
theorem dyadicR_halves_named (f : Real → Real)
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (m : Nat) :
    Req (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (dyadicR (halfL f) m))
              (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (dyadicR (halfR f) m)))
        (dyadicR f (m + 1)) :=
  dyadicR_halves f hfc m

-- ===========================================================================
-- The limit: three dyadic reads at a common depth, then the Archimedean criterion.
-- ===========================================================================

/-- Distributing a scalar through a difference. -/
private theorem Rmul_Rsub (c a b : Real) : Req (Rmul c (Rsub a b)) (Rsub (Rmul c a) (Rmul c b)) :=
  Req_trans (Rmul_distrib c a (Rneg b)) (Radd_congr (Req_refl _) (Rmul_neg_right c b))

/-- `|a − c| ≤ |a − b| + |b − c|` (local copy). -/
private theorem abs_sub_tri (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- `|a − b| = |b − a|` (local copy). -/
private theorem abs_sub_swap (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub_flip a b))

/-- Halving a distance halves its bound. -/
private theorem half_dist {I D : Real} {B : Q} (hBd : 0 < B.den)
    (h : Rle (Rabs (Rsub I D)) (ofQ B hBd)) :
    Rle (Rabs (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) I)
                    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) D)))
      (ofQ (mul (⟨1, 2⟩ : Q) B) (Qmul_den_pos (by decide) hBd)) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rmul_Rsub _ I D)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg (by decide)
    (by show (0 : Int) ≤ 1; decide) (Rsub I D))) ?_
  refine Rle_trans (Rmul_le_Rmul_left
    (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 1; decide)) h) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) hBd)

set_option maxHeartbeats 1000000 in
/-- **THE SPLITTING LAW**, certificate-general form: the integral over `[0,1]` is the sum of the
    two half-interval integrals, each carried by its own affine pullback and modulus. -/
theorem riemannIntegral_split_half_gen {f : Real → Real} {L L' : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (hL'd : 0 < L'.den) (hL'n : 0 ≤ L'.num)
    (hlip1 : ∀ x y, Rle (Rabs (Rsub (halfL f x) (halfL f y)))
      (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))))
    (hfc1 : ∀ x y, Req x y → Req (halfL f x) (halfL f y))
    (hlip2 : ∀ x y, Rle (Rabs (Rsub (halfR f x) (halfR f y)))
      (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))))
    (hfc2 : ∀ x y, Req x y → Req (halfR f x) (halfR f y)) :
    Req (riemannIntegral hLd hLn hlip hfc)
      (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (riemannIntegral hL'd hL'n hlip1 hfc1))
            (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (riemannIntegral hL'd hL'n hlip2 hfc2))) := by
  have hA : (0 : Int) ≤ ((L.num.toNat + 2 : Nat) : Int) := Int.ofNat_nonneg _
  have hgap : ∀ k : Nat,
      Rle (Rabs (Rsub (riemannIntegral hLd hLn hlip hfc)
        (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (riemannIntegral hL'd hL'n hlip1 hfc1))
              (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (riemannIntegral hL'd hL'n hlip2 hfc2)))))
        (ofQ (⟨(((L.num.toNat + 2) + (L'.num.toNat + 2) : Nat) : Int), k + 1⟩ : Q)
          (Nat.succ_pos k)) := by
    intro k
    have d0 := riemannIntegral_dyadic_dist hLd hLn hlip hfc (m := k + 2) (by omega)
    have d1 := riemannIntegral_dyadic_dist hL'd hL'n hlip1 hfc1 (m := k + 1) (by omega)
    have d2 := riemannIntegral_dyadic_dist hL'd hL'n hlip2 hfc2 (m := k + 1) (by omega)
    have hsecond : Rle (Rabs (Rsub (dyadicR f (k + 2))
        (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (riemannIntegral hL'd hL'n hlip1 hfc1))
              (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (riemannIntegral hL'd hL'n hlip2 hfc2)))))
        (Radd (ofQ (mul (⟨1, 2⟩ : Q) (⟨((L'.num.toNat + 2 : Nat) : Int), k + 1⟩ : Q))
                (Qmul_den_pos (by decide) (Nat.succ_pos k)))
              (ofQ (mul (⟨1, 2⟩ : Q) (⟨((L'.num.toNat + 2 : Nat) : Int), k + 1⟩ : Q))
                (Qmul_den_pos (by decide) (Nat.succ_pos k)))) := by
      refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
        (Req_symm (dyadicR_halves_named f hfc (k + 1))) (Req_refl _)))) ?_
      refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Radd_Radd _ _ _ _))) ?_
      refine Rle_trans (Rabs_Radd _ _) ?_
      exact Radd_le_add
        (half_dist (Nat.succ_pos k) (Rle_trans (Rle_of_Req (abs_sub_swap _ _)) d1))
        (half_dist (Nat.succ_pos k) (Rle_trans (Rle_of_Req (abs_sub_swap _ _)) d2))
    refine Rle_trans (abs_sub_tri _ (dyadicR f (k + 2)) _) ?_
    refine Rle_trans (Radd_le_add d0 hsecond) ?_
    refine Rle_trans (Radd_le_add (Rle_refl _) (Rle_of_Req
      (Req_trans (Radd_ofQ_ofQ (Qmul_den_pos (by decide) (Nat.succ_pos k))
        (Qmul_den_pos (by decide) (Nat.succ_pos k)))
        (ofQ_congr (b := (⟨((L'.num.toNat + 2 : Nat) : Int), k + 1⟩ : Q))
          _ (Nat.succ_pos k) (by
          simp only [Qeq, add, mul]; push_cast; ring_uor))))) ?_
    refine Rle_trans (Radd_le_add
      (Rle_ofQ_ofQ (a := (⟨((L.num.toNat + 2 : Nat) : Int), k + 2⟩ : Q))
                   (b := (⟨((L.num.toNat + 2 : Nat) : Int), k + 1⟩ : Q))
        (by show 0 < k + 2; omega) (Nat.succ_pos k) (by
          show ((L.num.toNat + 2 : Nat) : Int) * ((k + 1 : Nat) : Int)
              ≤ ((L.num.toNat + 2 : Nat) : Int) * ((k + 2 : Nat) : Int)
          exact Int.mul_le_mul_of_nonneg_left
            (show ((k + 1 : Nat) : Int) ≤ ((k + 2 : Nat) : Int) by push_cast; omega) hA))
      (Rle_refl _)) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k))) ?_
    exact Rle_ofQ_ofQ _ (Nat.succ_pos k)
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  refine Rle_antisymm
    (Rle_of_Rsub_le_eps (C := (L.num.toNat + 2) + (L'.num.toNat + 2)) (fun k => ?_))
    (Rle_of_Rsub_le_eps (C := (L.num.toNat + 2) + (L'.num.toNat + 2)) (fun k => ?_))
  · exact Rle_of_Rabs_le (hgap k)
  · exact Rle_of_Rabs_le (Rle_trans (Rle_of_Req (abs_sub_swap _ _)) (hgap k))

set_option maxHeartbeats 1000000 in
/-- **THE INTEGRAL SPLITS AT THE MIDPOINT**: `∫₀¹ f ≈ ∫₀^{1/2} f + ∫_{1/2}^1 f`, over the
    gateway's own `riemannIntegralI`. -/
theorem riemannIntegral_split_half {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) :
    Req (riemannIntegral hLd hLn hlip hfc)
      (Radd
        (riemannIntegralI hLd hLn hlip hfc (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q)
          (by decide) (by decide) (by decide))
        (riemannIntegralI hLd hLn hlip hfc (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)
          (by decide) (by decide) (by decide))) :=
  riemannIntegral_split_half_gen hLd hLn hlip hfc
    (Qmul_den_pos hLd (by decide)) (Int.mul_nonneg hLn (by decide))
    (affine_lip hLd hLn hlip (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))
    (fun x y h => hfc _ _ (affineMap_congr (⟨0, 1⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) h))
    (affine_lip hLd hLn hlip (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide))
    (fun x y h => hfc _ _ (affineMap_congr (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q) (by decide) (by decide) h))

end Multiplicity.UOR.Bridge.F1Square.Square
