/-
F1 square — **the pre-Hilbert layer, brick 43** (`MomentCompletion.lean`): **THE FIRST GENUINE
`ℓ²` INSTANCE OF THE TRUNCATION-UNIFORM COMPLETION** — the moment vector of any
bounded-Lipschitz test, read along a quadratically rescaled truncation, satisfies `SqCauchyU`:

    `∀ N, d²(momIdx φ j, momIdx φ k) ≤ (1/(j+1) + 1/(k+1))²`   (`momIdx_sqCauchyU`),

with the modulus **independent of the truncation `N`**. So brick 17's truncation-uniform
machinery (`limMemberU`, `limMemberU_converges`) fires on real `ℓ²` data rather than on a
hypothesis: the layer's completion axis and its `L²`/moment axis meet here.

The rescale is the point. Brick 39's tail bound is `2M²/(a+1)` at cut `a`, and the canonical
Cauchy modulus is `(1/(j+1)+1/(k+1))² ≥ 1/(j+1)²` — a SQUARE. A linear rescale `a = c(j+1)`
(brick 40's, enough for the norm) is therefore too slow; the truncation-uniform statement needs
`a = c·(j+1)²` with `c ≥ 2M²`, and then `2M²/(c(j+1)²+1) ≤ 1/(j+1)²` discharges through the
same `scale_cross` step, now at `k = (j+1)²`.

The termwise input is that cutting a coordinate can only remove energy: the difference of two
cuts is zero below the smaller cut and at most the moment above it (`momTrunc_diff_sq_le`), so
the whole squared distance is bounded by a TAIL of the squared-moment series — brick 39's
object — at every truncation `N` at once (`dist2_momTrunc_le`, by cases on `N ≤ a` or
`N = a + d`).

HONEST SCOPE. A realized `SqCauchyU` instance built from the compact `[0,1]` moment map. It is
the completion axis's "genuine `ℓ²` weights" supplied by an actual object, not the `L²`
function-space strong completeness (still open), and it says nothing about the Weil form. The
identification of the resulting `limMemberU` with the moment sequence itself is NOT claimed
here. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentNorm
import Foundations.F1.Square.UniformCompletion

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The moment vector cut at `a`: the moments below `a`, zero above. -/
def momTrunc (φ : L2Test) (a : Nat) : Nat → Real :=
  fun i => if i < a then mellinMoment φ i else zero

/-- The squared-moment tail term: zero below the cut, the squared moment above it. -/
def momTailTerm (φ : L2Test) (a : Nat) : Nat → Real :=
  fun i => if i < a then zero else Rmul (mellinMoment φ i) (mellinMoment φ i)

/-- `|z|² ≈ z²` (local copy: the corresponding lemma in `PairingLimit` is private). -/
private theorem sq_abs (z : Real) : Req (Rmul (Rabs z) (Rabs z)) (Rmul z z) :=
  Req_trans (Req_symm (Rabs_Rmul z z)) (Rabs_of_nonneg (Rnonneg_Rmul_self z))

/-- `(0 − z)² ≈ z²` — the cut difference squares to the plain square. -/
private theorem sub_zero_sq (z : Real) : Req (Rmul (Rsub zero z) (Rsub zero z)) (Rmul z z) := by
  have hz : Req (Rsub zero z) (Rneg z) :=
    Req_trans (Radd_comm zero (Rneg z)) (Radd_zero (Rneg z))
  refine Req_trans (Req_symm (sq_abs (Rsub zero z))) ?_
  refine Req_trans (Rmul_congr (Req_trans (Rabs_congr hz) (Rabs_Rneg z))
    (Req_trans (Rabs_congr hz) (Rabs_Rneg z))) ?_
  exact sq_abs z

/-- **Cutting only removes energy**: the squared difference of two cuts is zero below the
    smaller cut and at most the squared moment above it. -/
theorem momTrunc_diff_sq_le (φ : L2Test) {a b : Nat} (hab : a ≤ b) (i : Nat) :
    Rle (Rmul (Rsub (momTrunc φ a i) (momTrunc φ b i))
              (Rsub (momTrunc φ a i) (momTrunc φ b i)))
        (momTailTerm φ a i) := by
  by_cases hia : i < a
  · have hib : i < b := Nat.lt_of_lt_of_le hia hab
    simp only [momTrunc, momTailTerm, if_pos hia, if_pos hib]
    exact Rle_of_Req (Req_trans (Rmul_congr (Radd_neg _) (Radd_neg _)) (Rmul_zero zero))
  · simp only [momTrunc, momTailTerm, if_neg hia]
    by_cases hib : i < b
    · simp only [if_pos hib]
      exact Rle_of_Req (sub_zero_sq (mellinMoment φ i))
    · simp only [if_neg hib]
      refine Rle_trans (Rle_of_Req (Rmul_congr (Radd_neg zero) (Radd_neg zero))) ?_
      exact Rle_trans (Rle_of_Req (Rmul_zero zero))
        (Rle_zero_of_Rnonneg (Rnonneg_Rmul_self (mellinMoment φ i)))

/-- **The tail sum is bounded by the depth-`a` rate at EVERY truncation**: below the cut the
    terms vanish, above it the sum is brick 39's window sum. -/
theorem RsumN_momTailTerm_le (φ : L2Test) (a N : Nat) :
    Rle (RsumN (momTailTerm φ a) N)
      (ofQ (mul (mul φ.M φ.M) (⟨2, a + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos a))) := by
  have hbnn : Rnonneg (ofQ (mul (mul φ.M φ.M) (⟨2, a + 1⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos a))) :=
    Rnonneg_ofQ _ (Qmul_num_nonneg (Qmul_num_nonneg φ.hMn φ.hMn)
      (by show (0 : Int) ≤ 2; decide))
  have hzero : ∀ M : Nat, M ≤ a → Req (RsumN (momTailTerm φ a) M) zero := by
    intro M hM
    refine RsumN_zero M (fun i hi => ?_)
    simp only [momTailTerm, if_pos (Nat.lt_of_lt_of_le hi hM)]
    exact Req_refl zero
  rcases Nat.le_total N a with hNa | haN
  · exact Rle_trans (Rle_of_Req (hzero N hNa)) (Rle_zero_of_Rnonneg hbnn)
  · obtain ⟨d, hd⟩ := Nat.le.dest haN
    rw [← hd]
    refine Rle_trans (Rle_of_Req (RsumN_split_at (momTailTerm φ a) a d)) ?_
    refine Rle_trans (Rle_of_Req (Radd_congr (hzero a (Nat.le_refl a)) (Req_refl _))) ?_
    refine Rle_trans (Rle_of_Req (Req_trans (Radd_comm zero _) (Radd_zero _))) ?_
    refine Rle_trans (Rle_of_Req (RsumN_congr d (fun i _ => ?_))) (momentSqTail_le φ a d)
    simp only [momTailTerm, if_neg (Nat.not_lt.mpr (Nat.le_add_right a i))]
    exact Req_refl _

/-- **The squared distance between two cuts is a tail**, uniformly in the truncation. -/
theorem dist2_momTrunc_le (φ : L2Test) {a b : Nat} (hab : a ≤ b) (N : Nat) :
    Rle (dist2 (momTrunc φ a) (momTrunc φ b) N)
      (ofQ (mul (mul φ.M φ.M) (⟨2, a + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos a))) :=
  Rle_trans (RsumN_le N (fun i _ => momTrunc_diff_sq_le φ hab i))
    (RsumN_momTailTerm_le φ a N)

-- ===========================================================================
-- The quadratic rescale.
-- ===========================================================================

/-- The quadratically rescaled cut: `a(j) = c·(j+1)²` with `c = momScale φ ≥ 2M²`. The square
    is forced — the Cauchy modulus the completion axis uses is itself a square. -/
def momIdx (φ : L2Test) (j : Nat) : Nat → Real :=
  momTrunc φ (momScale φ * ((j + 1) * (j + 1)))

/-- The rate at the rescaled cut beats the square of the canonical modulus. -/
theorem momIdx_rate (φ : L2Test) (j k : Nat) :
    Qle (mul (mul φ.M φ.M) (⟨2, momScale φ * ((j + 1) * (j + 1)) + 1⟩ : Q))
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
           (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) := by
  -- step 1: the rescaled tail is below `1/(j+1)²`
  have hstep1 : Qle (mul (mul φ.M φ.M) (⟨2, momScale φ * ((j + 1) * (j + 1)) + 1⟩ : Q))
      (mul (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) := by
    show φ.M.num * φ.M.num * 2 * (((j + 1) * (j + 1) : Nat) : Int)
        ≤ 1 * 1 * ((φ.M.den * φ.M.den * (momScale φ * ((j + 1) * (j + 1)) + 1) : Nat) : Int)
    have hk : (0 : Int) ≤ ((j : Int) + 1) * ((j : Int) + 1) :=
      Int.mul_nonneg (by omega) (by omega)
    have hc := scale_cross (A := φ.M.num * φ.M.num) (d2 := (φ.M.den : Int) * (φ.M.den : Int))
      (c := (momScale φ : Int)) (k := ((j : Int) + 1) * ((j : Int) + 1))
      (by
        have h1 : (1 : Int) ≤ (φ.M.den : Int) := by have := φ.hMd; omega
        exact Int.mul_le_mul h1 h1 (by decide) (by omega))
      hk (momScale_bound φ)
    push_cast
    push_cast at hc
    exact hc
  -- step 2: `1/(j+1)² ≤ (1/(j+1) + 1/(k+1))²`
  have hpS : Qle (⟨1, j + 1⟩ : Q) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) := by
    show (1 : Int) * (((j + 1) * (k + 1) : Nat) : Int)
        ≤ (1 * ((k + 1 : Nat) : Int) + 1 * ((j + 1 : Nat) : Int)) * ((j + 1 : Nat) : Int)
    have hexp : (1 * ((k : Int) + 1) + 1 * ((j : Int) + 1)) * ((j : Int) + 1)
        = ((j : Int) + 1) * ((k : Int) + 1) + ((j : Int) + 1) * ((j : Int) + 1) := by ring_uor
    have hsq : (0 : Int) ≤ ((j : Int) + 1) * ((j : Int) + 1) :=
      Int.mul_nonneg (by omega) (by omega)
    push_cast
    omega
  have hstep2 : Qle (mul (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q))
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
           (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) :=
    Qmul_le_mul (Nat.succ_pos j) (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
      (Nat.succ_pos j) (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
      hpS hpS
  exact Qle_trans (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)) hstep1 hstep2

/-- **THE TRUNCATION-UNIFORM SQUARED-CAUCHY INSTANCE**: the rescaled moment cuts satisfy the
    canonical Cauchy modulus at EVERY truncation — genuine `ℓ²` weights, realized. -/
theorem momIdx_sqCauchyU (φ : L2Test) : SqCauchyU (momIdx φ) := by
  intro N j k
  rcases Nat.le_total j k with hjk | hkj
  · have hab : momScale φ * ((j + 1) * (j + 1)) ≤ momScale φ * ((k + 1) * (k + 1)) :=
      Nat.mul_le_mul_left _ (Nat.mul_le_mul (Nat.succ_le_succ hjk) (Nat.succ_le_succ hjk))
    refine Rle_trans (dist2_momTrunc_le φ hab N) ?_
    exact Rle_ofQ_ofQ _ _ (momIdx_rate φ j k)
  · have hab : momScale φ * ((k + 1) * (k + 1)) ≤ momScale φ * ((j + 1) * (j + 1)) :=
      Nat.mul_le_mul_left _ (Nat.mul_le_mul (Nat.succ_le_succ hkj) (Nat.succ_le_succ hkj))
    refine Rle_trans (Rle_of_Req (dist2_symm (momIdx φ j) (momIdx φ k) N)) ?_
    refine Rle_trans (dist2_momTrunc_le φ hab N) ?_
    refine Rle_ofQ_ofQ _ _ (Qle_trans (Qmul_den_pos (add_den_pos (Nat.succ_pos k)
      (Nat.succ_pos j)) (add_den_pos (Nat.succ_pos k) (Nat.succ_pos j)))
      (momIdx_rate φ k j) ?_)
    exact Qeq_le (Qmul_congr (by simp only [Qeq, add]; push_cast; ring_uor)
      (by simp only [Qeq, add]; push_cast; ring_uor))

/-- **THE COMPLETION FIRES ON `ℓ²` DATA**: the truncation-uniform limit member of the moment
    cuts exists as a construction, and the cuts converge to it in the squared distance at every
    truncation, `d²(momIdx φ j, ·) ≤ N·(2/(j+1))²`. (The identification of that member with the
    moment sequence itself is not claimed here.) -/
theorem momIdx_completes (φ : L2Test) (N j : Nat) :
    Rle (dist2 (momIdx φ j) (limMemberU (momIdx φ) (momIdx_sqCauchyU φ)) N)
      (ofQ (mul (⟨(N : Int), 1⟩ : Q) (mul (⟨2, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q)))
        (Qmul_den_pos Nat.one_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)))) :=
  limMemberU_converges (momIdx_sqCauchyU φ) N j

end Multiplicity.UOR.Bridge.F1Square.Square
