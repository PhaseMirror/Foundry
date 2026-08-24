/-
F1 square — **the pre-Hilbert layer, brick 49** (`MomentPairing.lean`): **THE BILINEAR MOMENT
PAIRING CONVERGES** — the off-diagonal companion to the `ℓ²` norm:

    `⟪φ, ψ⟫  :=  Σ_n ⟨φ, xⁿ⟩·⟨ψ, xⁿ⟩  =  crossMomL2 φ ψ`   (a constructed `Real`),

with the diagonal identity `⟪φ, φ⟫ ≈ momentL2Sq φ` (`crossMomL2_diag`). Brick 46 bounded the
cross sums uniformly; this brick shows they actually converge, so the moment sequences carry a
genuine bilinear pairing and not merely a norm.

THE SQUARE ROOT IS EXACT, WHICH IS WHY THIS STAYS SQRT-FREE. The Cauchy modulus needs an
*absolute* bound on a window `Σ_{a ≤ n < a+K}`, and the natural route — Cauchy–Schwarz on the
window against brick 39's two tails — produces `(2M_φ²/(a+1))·(2M_ψ²/(a+1))`, which is the
**exact square of the rational** `2·M_φ·M_ψ/(a+1)` (`crossBound`). So `Rle_of_Rsq_le` turns the
squared bound into the linear one with no square root anywhere: the substrate has no `sqrt` on
general reals, and none is needed. (The AM-GM route `|ab| ≤ ½(a²+b²)` would also work, but needs
a real algebraic expansion; this one needs only rational arithmetic.)

The rescale is then LINEAR, as in brick 40 — the modulus wanted here is `1/(j+1)`, not its square
— and reuses brick 40's `scale_cross` with `crossScale φ ψ = 2|M_φ.num||M_ψ.num| + 1`, which
dominates `2·M_φ·M_ψ` because both denominators are `≥ 1`.

HONEST SCOPE. The bilinear `ℓ²` pairing of the moment sequences of bounded-Lipschitz tests on
`[0,1]`. It is a pairing on moment data, not an inner product on a completed function space, and
nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentGram
import Multiplicity.F1.Square.MomentEnergyDetect
import Multiplicity.F1.Analysis.SqrtRealCmp

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The window cross sum and its exact-square bound.
-- ===========================================================================

/-- The moment sequence shifted past the cut `a`. -/
def momShift (φ : L2Test) (a : Nat) : Nat → Real := fun i => mellinMoment φ (a + i)

/-- The window cross sum `Σ_{i<K} ⟨φ, x^{a+i}⟩·⟨ψ, x^{a+i}⟩`. -/
def crossWindow (φ ψ : L2Test) (a K : Nat) : Real :=
  innerN (momShift φ a) (momShift ψ a) K

/-- The diagonal window is brick 39's squared-moment tail. -/
theorem crossWindow_diag (φ : L2Test) (a K : Nat) :
    Req (innerN (momShift φ a) (momShift φ a) K) (momentSqTail φ a K) := Req_refl _

/-- The rational window bound `2·M_φ·M_ψ/(a+1)` — the EXACT square root of the product of the
    two brick-39 tail bounds. -/
def crossBound (φ ψ : L2Test) (a : Nat) : Q :=
  ⟨2 * φ.M.num * ψ.M.num, φ.M.den * ψ.M.den * (a + 1)⟩

theorem crossBound_den (φ ψ : L2Test) (a : Nat) : 0 < (crossBound φ ψ a).den :=
  Nat.mul_pos (Nat.mul_pos φ.hMd ψ.hMd) (Nat.succ_pos a)

theorem crossBound_num (φ ψ : L2Test) (a : Nat) : 0 ≤ (crossBound φ ψ a).num :=
  Int.mul_nonneg (Int.mul_nonneg (by decide) φ.hMn) ψ.hMn

/-- **The window obeys Cauchy–Schwarz against the two tails.** -/
theorem crossWindow_sq_le (φ ψ : L2Test) (a K : Nat) :
    Rle (Rmul (crossWindow φ ψ a K) (crossWindow φ ψ a K))
        (Rmul (momentSqTail φ a K) (momentSqTail ψ a K)) :=
  cauchy_schwarz (momShift φ a) (momShift ψ a) K

/-- **THE WINDOW BOUND**: `|Σ_{i<K} ⟨φ,x^{a+i}⟩⟨ψ,x^{a+i}⟩| ≤ 2·M_φ·M_ψ/(a+1)`, uniformly in
    the window length `K`. -/
theorem crossWindow_abs_le (φ ψ : L2Test) (a K : Nat) :
    Rle (Rabs (crossWindow φ ψ a K)) (ofQ (crossBound φ ψ a) (crossBound_den φ ψ a)) := by
  refine Rle_of_Rsq_le (Rnonneg_Rabs _)
    (Rnonneg_ofQ (crossBound_den φ ψ a) (crossBound_num φ ψ a)) ?_
  have habs : Req (Rmul (Rabs (crossWindow φ ψ a K)) (Rabs (crossWindow φ ψ a K)))
      (Rmul (crossWindow φ ψ a K) (crossWindow φ ψ a K)) :=
    Req_trans (Req_symm (Rabs_Rmul _ _)) (Rabs_of_nonneg (Rnonneg_Rmul_self _))
  refine Rle_trans (Rle_of_Req habs) ?_
  refine Rle_trans (crossWindow_sq_le φ ψ a K) ?_
  -- lift each tail to its brick-39 rational bound
  refine Rle_trans (Rmul_le_Rmul_right (momentSqTail_nonneg ψ a K)
    (momentSqTail_le φ a K)) ?_
  refine Rle_trans (Rmul_le_Rmul_left
    (Rnonneg_ofQ (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos a))
      (Qmul_num_nonneg (Qmul_num_nonneg φ.hMn φ.hMn) (by show (0 : Int) ≤ 2; decide)))
    (momentSqTail_le ψ a K)) ?_
  -- the product of the two rational bounds IS the square of `crossBound`
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ _ _)) ?_
  refine Rle_trans (Rle_of_Req (ofQ_congr _ (Qmul_den_pos (crossBound_den φ ψ a)
    (crossBound_den φ ψ a)) ?_)) (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ _ _)))
  simp only [Qeq, mul, crossBound]
  push_cast
  ring_uor

-- ===========================================================================
-- The partial sums are Cauchy.
-- ===========================================================================

/-- The cross partial sums split at a cut, the remainder being the window. -/
theorem crossMomSum_split (φ ψ : L2Test) (a K : Nat) :
    Req (crossMomSum φ ψ (a + K))
      (Radd (crossMomSum φ ψ a) (crossWindow φ ψ a K)) :=
  RsumN_split_at _ a K

/-- **The increment past a cut is bounded by the window bound.** -/
theorem crossMomSum_diff_abs_le (φ ψ : L2Test) (a K : Nat) :
    Rle (Rabs (Rsub (crossMomSum φ ψ (a + K)) (crossMomSum φ ψ a)))
      (ofQ (crossBound φ ψ a) (crossBound_den φ ψ a)) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr (crossMomSum_split φ ψ a K) (Req_refl _))
    (Rsub_Radd_cancel_left (crossMomSum φ ψ a) (crossWindow φ ψ a K))))) ?_
  exact crossWindow_abs_le φ ψ a K

/-- `|a − b| = |b − a|`. -/
private theorem abs_sub_comm (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub_flip a b))

-- ===========================================================================
-- The linear rescale.
-- ===========================================================================

/-- The index rescale for the cross pairing: any natural `≥ 2·M_φ·M_ψ` will do, and
    `2|M_φ.num||M_ψ.num| + 1` is one (both denominators are `≥ 1`). -/
def crossScale (φ ψ : L2Test) : Nat := 2 * (φ.M.num.natAbs * ψ.M.num.natAbs) + 1

/-- The rescaled window bound beats the canonical modulus: `2M_φM_ψ/(c(k+1)+1) ≤ 1/(k+1)`. -/
theorem crossScale_bound (φ ψ : L2Test) (k : Nat) :
    Qle (crossBound φ ψ (crossScale φ ψ * (k + 1))) (⟨1, k + 1⟩ : Q) := by
  show 2 * φ.M.num * ψ.M.num * ((k + 1 : Nat) : Int)
      ≤ 1 * ((φ.M.den * ψ.M.den * (crossScale φ ψ * (k + 1) + 1) : Nat) : Int)
  have hnφ : ((φ.M.num.natAbs : Nat) : Int) = φ.M.num := Int.natAbs_of_nonneg φ.hMn
  have hnψ : ((ψ.M.num.natAbs : Nat) : Int) = ψ.M.num := Int.natAbs_of_nonneg ψ.hMn
  have hc : ((crossScale φ ψ : Nat) : Int) = 2 * (φ.M.num * ψ.M.num) + 1 := by
    show ((2 * (φ.M.num.natAbs * ψ.M.num.natAbs) + 1 : Nat) : Int) = _
    push_cast
    rw [hnφ, hnψ]
  have hD : (1 : Int) ≤ (φ.M.den : Int) * (ψ.M.den : Int) := by
    have h1 : (1 : Int) ≤ (φ.M.den : Int) := by have := φ.hMd; omega
    have h2 : (1 : Int) ≤ (ψ.M.den : Int) := by have := ψ.hMd; omega
    exact Int.mul_le_mul h1 h2 (by decide) (by omega)
  have hP : (0 : Int) ≤ φ.M.num * ψ.M.num := Int.mul_nonneg φ.hMn ψ.hMn
  -- `2·(M_φ·M_ψ) ≤ crossScale · (d_φ·d_ψ)`
  have hCnn : (0 : Int) ≤ ((crossScale φ ψ : Nat) : Int) := Int.ofNat_nonneg _
  have hstep : ((crossScale φ ψ : Nat) : Int) * 1
      ≤ ((crossScale φ ψ : Nat) : Int) * ((φ.M.den : Int) * (ψ.M.den : Int)) :=
    Int.mul_le_mul_of_nonneg_left hD hCnn
  have hmain : 2 * (φ.M.num * ψ.M.num)
      ≤ ((crossScale φ ψ : Nat) : Int) * ((φ.M.den : Int) * (ψ.M.den : Int)) := by
    rw [hc] at hstep ⊢
    omega
  have hk : (0 : Int) ≤ ((k : Int) + 1) := by omega
  have hcross := scale_cross (A := φ.M.num * ψ.M.num)
    (d2 := (φ.M.den : Int) * (ψ.M.den : Int))
    (c := ((crossScale φ ψ : Nat) : Int)) (k := (k : Int) + 1) hD hk hmain
  push_cast
  push_cast at hcross
  have e : 2 * φ.M.num * ψ.M.num * ((k : Int) + 1)
      = φ.M.num * ψ.M.num * 2 * ((k : Int) + 1) := by ring_uor
  rw [e]
  exact hcross

/-- The rescaled cross partial sums. -/
def crossIdx (φ ψ : L2Test) (j : Nat) : Real :=
  crossMomSum φ ψ (crossScale φ ψ * (j + 1))

/-- **The rescaled cross sums are Cauchy at the canonical modulus.** -/
theorem crossIdx_dist (φ ψ : L2Test) (j k : Nat) :
    Rle (Rabs (Rsub (crossIdx φ ψ j) (crossIdx φ ψ k)))
      (ofQ (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
        (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))) := by
  have key : ∀ p q : Nat, p ≤ q →
      Rle (Rabs (Rsub (crossIdx φ ψ q) (crossIdx φ ψ p)))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) := by
    intro p q hpq
    obtain ⟨d, hd⟩ := Nat.le.dest
      (Nat.mul_le_mul_left (crossScale φ ψ) (Nat.succ_le_succ hpq))
    show Rle (Rabs (Rsub (crossMomSum φ ψ (crossScale φ ψ * (q + 1)))
      (crossMomSum φ ψ (crossScale φ ψ * (p + 1))))) _
    rw [← hd]
    refine Rle_trans (crossMomSum_diff_abs_le φ ψ (crossScale φ ψ * (p + 1)) d) ?_
    exact Rle_ofQ_ofQ _ (Nat.succ_pos p) (crossScale_bound φ ψ p)
  rcases Nat.le_total j k with hjk | hkj
  · refine Rle_trans (Rle_of_Req (abs_sub_comm _ _)) ?_
    refine Rle_trans (key j k hjk) ?_
    exact Rle_ofQ_ofQ _ _ (Qle_self_add (x := (⟨1, j + 1⟩ : Q)) (p := (⟨1, k + 1⟩ : Q))
      (by show (0 : Int) ≤ 1; decide))
  · refine Rle_trans (key k j hkj) ?_
    exact Rle_ofQ_ofQ _ _ (Qle_self_add_l (x := (⟨1, k + 1⟩ : Q)) (p := (⟨1, j + 1⟩ : Q))
      (by show (0 : Int) ≤ 1; decide))

theorem crossIdx_RReg (φ ψ : L2Test) : RReg (crossIdx φ ψ) :=
  RReg_of_real_bound _ (fun j k => add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (fun j k => add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
    (fun _ _ => Qle_refl _)
    (fun j k => Rle_of_Rabs_le (crossIdx_dist φ ψ j k))

/-- **THE BILINEAR MOMENT PAIRING**: `⟪φ, ψ⟫ = Σ_n ⟨φ, xⁿ⟩·⟨ψ, xⁿ⟩`, as a constructed real. -/
def crossMomL2 (φ ψ : L2Test) : Real := Rlim (crossIdx φ ψ) (crossIdx_RReg φ ψ)

/-- The partial sums converge to the pairing at the canonical rate. -/
theorem crossMomL2_approx (φ ψ : L2Test) (j : Nat) :
    Rle (Rabs (Rsub (crossIdx φ ψ j) (crossMomL2 φ ψ)))
      (ofQ (⟨2, j + 1⟩ : Q) (Nat.succ_pos j)) :=
  Rabs_dist_Rlim (crossIdx_RReg φ ψ) j

-- ===========================================================================
-- The diagonal identity.
-- ===========================================================================

/-- On the diagonal the rescaled cross sums are the partial energies, hence monotone. -/
theorem crossIdx_diag_mono (φ : L2Test) {i j : Nat} (h : i ≤ j) :
    Rle (crossIdx φ φ i) (crossIdx φ φ j) := by
  obtain ⟨d, hd⟩ := Nat.le.dest
    (Nat.mul_le_mul_left (crossScale φ φ) (Nat.succ_le_succ h))
  show Rle (momentSqSum φ (crossScale φ φ * (i + 1)))
    (momentSqSum φ (crossScale φ φ * (j + 1)))
  rw [← hd]
  exact momentSqSum_mono φ (crossScale φ φ * (i + 1)) d

/-- **THE DIAGONAL IDENTITY**: `⟪φ, φ⟫ ≈ momentL2Sq φ` — the bilinear pairing restricts to the
    `ℓ²` energy, so it is the genuine inner product of the moment geometry. -/
theorem crossMomL2_diag (φ : L2Test) : Req (crossMomL2 φ φ) (momentL2Sq φ) := by
  refine Rle_antisymm ?_ ?_
  · exact Rlim_le_const (crossIdx_RReg φ φ)
      (fun k => momentSqSum_le_momentL2Sq φ (crossScale φ φ * (k + 1)))
  · refine Rlim_le_const (momentSqIdx_RReg φ) (fun k => ?_)
    have hterm : Rle (crossIdx φ φ k) (crossMomL2 φ φ) :=
      term_le_Rlim (crossIdx_RReg φ φ) (fun i j h => crossIdx_diag_mono φ h) k
    -- `momentSqSum φ (momScale·(k+1)) ≤ crossIdx φ φ (momScale·(k+1)) ≤ ⟪φ,φ⟫`
    have hcut : momScale φ * (k + 1) ≤ crossScale φ φ * (momScale φ * (k + 1) + 1) := by
      have h1 : momScale φ * (k + 1) + 1
          ≤ crossScale φ φ * (momScale φ * (k + 1) + 1) :=
        Nat.le_mul_of_pos_left _ (Nat.succ_pos _)
      omega
    obtain ⟨d, hd⟩ := Nat.le.dest hcut
    refine Rle_trans ?_ (term_le_Rlim (crossIdx_RReg φ φ)
      (fun i j h => crossIdx_diag_mono φ h) (momScale φ * (k + 1)))
    show Rle (momentSqSum φ (momScale φ * (k + 1)))
      (momentSqSum φ (crossScale φ φ * (momScale φ * (k + 1) + 1)))
    rw [← hd]
    exact momentSqSum_mono φ (momScale φ * (k + 1)) d

end Multiplicity.UOR.Bridge.F1Square.Square
