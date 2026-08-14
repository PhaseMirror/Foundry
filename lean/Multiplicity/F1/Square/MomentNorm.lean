/-
F1 square — **the pre-Hilbert layer, brick 40** (`MomentNorm.lean`): **THE `ℓ²` NORM OF THE
MOMENT SEQUENCE EXISTS AS A CONSTRUCTED REAL** —

    `‖φ̂‖²  :=  Σ_{n} ⟨φ, xⁿ⟩²  =  momentL2Sq φ`   (a genuine `Real`, not a supremum),

with `0 ≤ ‖φ̂‖² ≤ 2·M_φ²` (`momentL2Sq_nonneg`, `momentL2Sq_le`) and the rescaled partial sums
converging to it at the canonical rate (`momentL2Sq_approx`).

Constructively, "monotone and bounded" does **not** give a limit — a modulus is needed, and brick
39 supplies exactly one: the tail bound `Σ_{i<K} ⟨φ, x^{N+i}⟩² ≤ 2M²/(N+1)`, uniform in `K`. The
construction turns that rate into Bishop regularity by *rescaling the index*: read the partial
sums along `N = c·(j+1)` where `c = momScale φ` is any natural number with `2M² ≤ c` (here
`c = 2·|M.num|² + 1`, which works because `M.den ≥ 1`). Then consecutive reads differ by at most
`2M²/(c(j+1)+1) ≤ 1/(j+1)`, which is the `RReg` modulus on the nose, and `Rlim` applies.

The two ingredients are the split `Σ_{n<N+K} = Σ_{n<N} + Σ_{i<K}(N+i)` (`RsumN_split_at`, a
reusable substrate lemma) and the monotonicity that comes free from the terms being squares.

HONEST SCOPE. The `ℓ²` norm of the *moment* sequence of a bounded-Lipschitz test on `[0,1]`. It
is not a norm on a completed function space, it is not the completion axis's truncation-uniform
weights, and it says nothing about the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentSummable
import Multiplicity.F1Square.Square.BLPipeline

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Splitting a finite sum at an offset**: `Σ_{i<N+K} F i = Σ_{i<N} F i + Σ_{i<K} F (N+i)`. -/
theorem RsumN_split_at (F : Nat → Real) (N : Nat) : ∀ K : Nat,
    Req (RsumN F (N + K)) (Radd (RsumN F N) (RsumN (fun i => F (N + i)) K))
  | 0 => Req_symm (Radd_zero (RsumN F N))
  | K + 1 =>
      Req_trans (Radd_congr (RsumN_split_at F N K) (Req_refl (F (N + K))))
        (Radd_assoc (RsumN F N) (RsumN (fun i => F (N + i)) K) (F (N + K)))

end Multiplicity.UOR.Bridge.F1Square.Analysis

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The partial sums of the squared moments, `Σ_{n<N} ⟨φ, xⁿ⟩²`. -/
def momentSqSum (φ : L2Test) (N : Nat) : Real :=
  RsumN (fun n => Rmul (mellinMoment φ n) (mellinMoment φ n)) N

/-- The partial sums split into a head and the brick-39 window sum. -/
theorem momentSqSum_split (φ : L2Test) (N K : Nat) :
    Req (momentSqSum φ (N + K)) (Radd (momentSqSum φ N) (momentSqTail φ N K)) :=
  RsumN_split_at _ N K

/-- Every window sum is non-negative (its terms are squares). -/
theorem momentSqTail_nonneg (φ : L2Test) (N K : Nat) : Rnonneg (momentSqTail φ N K) :=
  Rnonneg_RsumN K (fun i _ => Rnonneg_Rmul_self (mellinMoment φ (N + i)))

/-- The partial sums are non-decreasing. -/
theorem momentSqSum_mono (φ : L2Test) (N K : Nat) :
    Rle (momentSqSum φ N) (momentSqSum φ (N + K)) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (momentSqSum_split φ N K)))
  exact Rle_self_Radd_right (momentSqTail_nonneg φ N K)

/-- **The Cauchy rate**: growing the partial sum past `N` adds at most `2·M_φ²/(N+1)`. -/
theorem momentSqSum_diff_le (φ : L2Test) (N K : Nat) :
    Rle (Rsub (momentSqSum φ (N + K)) (momentSqSum φ N))
      (ofQ (mul (mul φ.M φ.M) (⟨2, N + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos N))) := by
  refine Rle_trans (Rle_of_Req (Req_trans
    (Rsub_congr (momentSqSum_split φ N K) (Req_refl (momentSqSum φ N)))
    (Rsub_Radd_cancel_left (momentSqSum φ N) (momentSqTail φ N K)))) ?_
  exact momentSqTail_le φ N K

-- ===========================================================================
-- The index rescale that turns the rate into Bishop regularity.
-- ===========================================================================

/-- The index rescale: any natural number `≥ 2·M_φ²` will do, and `2|M.num|² + 1` is one
    (the denominator `M.den ≥ 1` only helps). -/
def momScale (φ : L2Test) : Nat := 2 * φ.M.num.natAbs * φ.M.num.natAbs + 1

/-- The rescale dominates `2M²` after clearing denominators. -/
theorem momScale_bound (φ : L2Test) :
    2 * (φ.M.num * φ.M.num)
      ≤ (momScale φ : Int) * ((φ.M.den : Int) * (φ.M.den : Int)) := by
  have hself : ((φ.M.num.natAbs : Int)) * ((φ.M.num.natAbs : Int)) = φ.M.num * φ.M.num :=
    Int.natAbs_mul_self' φ.M.num
  have hc : (momScale φ : Int) = 2 * (φ.M.num * φ.M.num) + 1 := by
    show ((2 * φ.M.num.natAbs * φ.M.num.natAbs + 1 : Nat) : Int) = _
    push_cast
    rw [← hself]
    ring_uor
  have hA : (0 : Int) ≤ φ.M.num * φ.M.num := by
    rw [← hself]
    exact Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)
  have hd1 : (1 : Int) ≤ (φ.M.den : Int) * (φ.M.den : Int) := by
    have h1 : (1 : Int) ≤ (φ.M.den : Int) := by
      have := φ.hMd; omega
    exact Int.mul_le_mul h1 h1 (by decide) (by omega)
  have hstep : (momScale φ : Int) * 1 ≤ (momScale φ : Int) * ((φ.M.den : Int) * (φ.M.den : Int)) :=
    Int.mul_le_mul_of_nonneg_left hd1 (by omega)
  omega

/-- The rescaled partial sums: `X j = Σ_{n < c·(j+1)} ⟨φ, xⁿ⟩²`. -/
def momentSqIdx (φ : L2Test) (j : Nat) : Real :=
  momentSqSum φ (momScale φ * (j + 1))

/-- **The cross-multiplication that makes any index rescale work**: from `2A ≤ c·d₂` and
    `k ≥ 0`, `A·2·k ≤ d₂·(c·k + 1)` — i.e. `2M²/(c·k+1) ≤ 1/k` once the denominators are
    cleared. Public: every rescaled read of the moment tail (linear `k = j+1` here, quadratic
    `k = (j+1)²` in the truncation-uniform completion) discharges through this one step. -/
theorem scale_cross {A d2 c k : Int} (h1 : (1 : Int) ≤ d2) (hk : (0 : Int) ≤ k)
    (h : 2 * A ≤ c * d2) : A * 2 * k ≤ 1 * (d2 * (c * k + 1)) := by
  have e1 : A * 2 * k = (2 * A) * k := by ring_uor
  have s1 : (2 * A) * k ≤ (c * d2) * k := Int.mul_le_mul_of_nonneg_right h hk
  have e2 : (c * d2) * k = d2 * (c * k) := by ring_uor
  have e3 : 1 * (d2 * (c * k + 1)) = d2 * (c * k) + d2 := by ring_uor
  omega

/-- The rate at the rescaled index: the increment from `k` to any later read is `≤ 1/(k+1)`. -/
theorem momentSqIdx_rate (φ : L2Test) (k d : Nat) :
    Rle (Rsub (momentSqSum φ (momScale φ * (k + 1) + d)) (momentSqIdx φ k))
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  refine Rle_trans (momentSqSum_diff_le φ (momScale φ * (k + 1)) d) ?_
  refine Rle_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos _))
    (Nat.succ_pos k) ?_
  show φ.M.num * φ.M.num * 2 * ((k + 1 : Nat) : Int)
      ≤ 1 * ((φ.M.den * φ.M.den * (momScale φ * (k + 1) + 1) : Nat) : Int)
  have hd1 : (1 : Int) ≤ (φ.M.den : Int) * (φ.M.den : Int) := by
    have h1 : (1 : Int) ≤ (φ.M.den : Int) := by have := φ.hMd; omega
    exact Int.mul_le_mul h1 h1 (by decide) (by omega)
  have hk : (0 : Int) ≤ ((k : Int) + 1) := by omega
  have := scale_cross (A := φ.M.num * φ.M.num) (d2 := (φ.M.den : Int) * (φ.M.den : Int))
    (c := (momScale φ : Int)) (k := (k : Int) + 1) hd1 hk (momScale_bound φ)
  push_cast
  push_cast at this
  exact this

/-- The rescaled sequence is monotone in the index. -/
theorem momentSqIdx_mono (φ : L2Test) {j k : Nat} (h : j ≤ k) :
    Rle (momentSqIdx φ j) (momentSqIdx φ k) := by
  obtain ⟨d, hd⟩ := Nat.le.dest (Nat.mul_le_mul_left (momScale φ) (Nat.succ_le_succ h))
  show Rle (momentSqSum φ (momScale φ * (j + 1))) (momentSqSum φ (momScale φ * (k + 1)))
  rw [← hd]
  exact momentSqSum_mono φ (momScale φ * (j + 1)) d

/-- **The rescaled partial sums form a regular sequence** — the modulus is brick 39's tail rate
    read at the rescaled index. -/
theorem momentSqIdx_RReg (φ : L2Test) : RReg (momentSqIdx φ) := by
  refine RReg_of_real_bound _ (fun _ k => (⟨1, k + 1⟩ : Q)) (fun _ k => Nat.succ_pos k)
    (fun j k => Qle_self_add_l (by show (0 : Int) ≤ 1; decide)) (fun j k => ?_)
  rcases Nat.le_total j k with hjk | hkj
  · refine Rle_trans (Rsub_le_mono (momentSqIdx_mono φ hjk) (Rle_refl (momentSqIdx φ k))) ?_
    refine Rle_trans (Rle_of_Req (Radd_neg (momentSqIdx φ k))) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos k) (by show (0 : Int) ≤ 1; decide))
  · obtain ⟨d, hd⟩ := Nat.le.dest (Nat.mul_le_mul_left (momScale φ) (Nat.succ_le_succ hkj))
    show Rle (Rsub (momentSqSum φ (momScale φ * (j + 1))) (momentSqIdx φ k)) _
    rw [← hd]
    exact momentSqIdx_rate φ k d

/-- **THE `ℓ²` NORM OF THE MOMENT SEQUENCE**, `Σ_n ⟨φ, xⁿ⟩²`, as a constructed real. -/
def momentL2Sq (φ : L2Test) : Real := Rlim (momentSqIdx φ) (momentSqIdx_RReg φ)

/-- The norm is non-negative. -/
theorem momentL2Sq_nonneg (φ : L2Test) : Rnonneg (momentL2Sq φ) :=
  Rnonneg_Rlim (momentSqIdx_RReg φ)
    (fun _ => Rnonneg_RsumN _ (fun i _ => Rnonneg_Rmul_self (mellinMoment φ i)))

/-- **The norm obeys the uniform bound**: `Σ_n ⟨φ, xⁿ⟩² ≤ 2·M_φ²`. -/
theorem momentL2Sq_le (φ : L2Test) :
    Rle (momentL2Sq φ)
      (ofQ (mul (mul φ.M φ.M) (⟨2, 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos 0))) :=
  Rlim_le_ofQ (momentSqIdx_RReg φ) _ (fun k => momentSqSum_le φ (momScale φ * (k + 1)))

/-- **The partial sums converge to the norm** at the canonical rate `2/(j+1)`. -/
theorem momentL2Sq_approx (φ : L2Test) (j : Nat) :
    Rle (Rabs (Rsub (momentSqIdx φ j) (momentL2Sq φ)))
      (ofQ (⟨2, j + 1⟩ : Q) (Nat.succ_pos j)) :=
  Rabs_dist_Rlim (momentSqIdx_RReg φ) j

end Multiplicity.UOR.Bridge.F1Square.Square
