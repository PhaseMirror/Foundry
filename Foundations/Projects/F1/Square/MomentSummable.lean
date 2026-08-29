/-
F1 square — **the pre-Hilbert layer, brick 39** (`MomentSummable.lean`): **THE MOMENT SEQUENCE
IS `ℓ²`, WITH AN EXPLICIT TAIL RATE** — for every test of the bounded-Lipschitz class and every
window `[N, N+K)`,

    `Σ_{i<K} ⟨φ, x^{N+i}⟩² ≤ 2·M_φ² / (N+1)`   (`momentSqTail_le`),

uniformly in `K`. At `N = 0` this is the uniform partial-sum bound `Σ_{n<K} ⟨φ, xⁿ⟩² ≤ 2·M_φ²`
(`momentSqSum_le`), and for `N → ∞` the tails go to zero at rate `1/(N+1)` — the moment sequence
is square-summable, not merely bounded, and its tails are certified small.

This is what brick 38's sharp decay `|⟨φ, xⁿ⟩| ≤ M/(n+1)` was for: `Cauchy–Schwarz` would give
only `O(1/√n)`, whose squares are not summable. Here the square of the sharp bound is dominated
by the telescoping term `2/((n+1)(n+2))`, and that dominating series is summed **exactly**:

    `Σ_{i<K} 2/((N+i+1)(N+i+2)) = 2K/((N+1)(N+K+1))`   (`teleFrom_eq`),

a closed form at every `(N, K)` — no limit, no estimate. The uniform bound is then one rational
comparison `2K/((N+1)(N+K+1)) ≤ 2/(N+1)`.

HONEST SCOPE. A summability rate for the compact `[0,1]` moment map on the bounded-Lipschitz
class. This is *not* the completion axis's truncation-uniform `ℓ²` weights (those are about the
discrete coordinates of `innerN`), and nothing here touches the Weil form: step 4 is RH. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentDecay

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Squaring a two-sided bound**: `|m| ≤ B` with `B ≥ 0` gives `m² ≤ B²`. Routed through the
    absolute value (`|m·m| = |m|·|m|`), so no sign case split on `m` is needed. -/
theorem Rsq_le_of_abs_le {m B : Real} (hB : Rnonneg B) (h : Rle (Rabs m) B) :
    Rle (Rmul m m) (Rmul B B) :=
  Rle_of_Rabs_le (Rle_trans (Rle_of_Req (Rabs_Rmul m m)) (Rsq_mono (Rnonneg_Rabs m) hB h))

-- ===========================================================================
-- The dominating telescoping series, summed exactly.
-- ===========================================================================

/-- The dominating term `2/((n+1)(n+2))` — the telescoping majorant of `1/(n+1)²`. -/
def teleTerm (n : Nat) : Q := ⟨2, (n + 1) * (n + 2)⟩

theorem teleTerm_den (n : Nat) : 0 < (teleTerm n).den :=
  Nat.mul_pos (Nat.succ_pos n) (Nat.succ_pos (n + 1))

/-- The exact partial sum of the telescoping series over the window `[N, N+K)`:
    `2/(N+1) − 2/(N+K+1) = 2K/((N+1)(N+K+1))`. -/
def teleFrom (N K : Nat) : Q := ⟨2 * (K : Int), (N + 1) * (N + K + 1)⟩

theorem teleFrom_den (N K : Nat) : 0 < (teleFrom N K).den :=
  Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos (N + K))

/-- One telescoping step: `teleFrom N K + teleTerm (N+K) = teleFrom N (K+1)` — exact. -/
theorem teleFrom_step (N K : Nat) :
    Qeq (add (teleFrom N K) (teleTerm (N + K))) (teleFrom N (K + 1)) := by
  simp only [Qeq, add, teleFrom, teleTerm]
  push_cast
  ring_uor

/-- **THE EXACT TELESCOPING SUM**: `Σ_{i<K} 2/((N+i+1)(N+i+2)) = 2K/((N+1)(N+K+1))`. -/
theorem teleFrom_eq (N : Nat) : ∀ K : Nat,
    Req (RsumN (fun i => ofQ (teleTerm (N + i)) (teleTerm_den (N + i))) K)
      (ofQ (teleFrom N K) (teleFrom_den N K))
  | 0 => Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) ⟨2 * ((0 : Nat) : Int), (N + 1) * (N + 0 + 1)⟩
      show (0 : Int) * (((N + 1) * (N + 0 + 1) : Nat) : Int) = 2 * ((0 : Nat) : Int) * ((1 : Nat) : Int)
      simp)
  | K + 1 =>
      Req_trans (Radd_congr (teleFrom_eq N K) (Req_refl _))
        (Req_trans (Radd_ofQ_ofQ (teleFrom_den N K) (teleTerm_den (N + K)))
          (ofQ_congr (add_den_pos (teleFrom_den N K) (teleTerm_den (N + K)))
            (teleFrom_den N (K + 1)) (teleFrom_step N K)))

/-- The window sum is bounded by the head rate, uniformly in the window length:
    `2K/((N+1)(N+K+1)) ≤ 2/(N+1)`. -/
theorem teleFrom_le (N K : Nat) : Qle (teleFrom N K) (⟨2, N + 1⟩ : Q) := by
  show 2 * (K : Int) * ((N + 1 : Nat) : Int) ≤ 2 * (((N + 1) * (N + K + 1) : Nat) : Int)
  have hk : (K : Int) ≤ ((N + K + 1 : Nat) : Int) := by push_cast; omega
  have h1 : (K : Int) * ((N + 1 : Nat) : Int) ≤ ((N + K + 1 : Nat) : Int) * ((N + 1 : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_right hk (Int.ofNat_nonneg _)
  have h2 : ((N + K + 1 : Nat) : Int) * ((N + 1 : Nat) : Int)
      = (((N + 1) * (N + K + 1) : Nat) : Int) := by push_cast; ring_uor
  rw [h2] at h1
  rw [Int.mul_assoc]
  exact Int.mul_le_mul_of_nonneg_left h1 (by decide)

-- ===========================================================================
-- The squared moments.
-- ===========================================================================

/-- The squared-moment sum over the window `[N, N+K)`. -/
def momentSqTail (φ : L2Test) (N K : Nat) : Real :=
  RsumN (fun i => Rmul (mellinMoment φ (N + i)) (mellinMoment φ (N + i))) K

/-- **The squared term bound**: `⟨φ, xⁿ⟩² ≤ M_φ² · 2/((n+1)(n+2))`. The square of the sharp
    decay is `M²/(n+1)²`, and `1/(n+1)² ≤ 2/((n+1)(n+2))` because `n+2 ≤ 2(n+1)`. -/
theorem mellinMoment_sq_le (φ : L2Test) (n : Nat) :
    Rle (Rmul (mellinMoment φ n) (mellinMoment φ n))
      (Rmul (ofQ (mul φ.M φ.M) (Qmul_den_pos φ.hMd φ.hMd))
        (ofQ (teleTerm n) (teleTerm_den n))) := by
  have hpn : (0 : Int) ≤ ((⟨1, n + 1⟩ : Q)).num := by show (0 : Int) ≤ 1; decide
  have hBd : 0 < (mul φ.M (⟨1, n + 1⟩ : Q)).den := Qmul_den_pos φ.hMd (Nat.succ_pos n)
  have hBnn : Rnonneg (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) hBd) :=
    Rnonneg_ofQ hBd (Qmul_num_nonneg φ.hMn hpn)
  have hsq := Rsq_le_of_abs_le hBnn (mellinMoment_abs_le φ n)
  -- the squared rational bound, rearranged and compared
  have hrearr : Qeq (mul (mul φ.M (⟨1, n + 1⟩ : Q)) (mul φ.M (⟨1, n + 1⟩ : Q)))
      (mul (mul φ.M φ.M) (mul (⟨1, n + 1⟩ : Q) (⟨1, n + 1⟩ : Q))) := by
    simp only [Qeq, mul]
    push_cast
    ring_uor
  have hcmp : Qle (mul (⟨1, n + 1⟩ : Q) (⟨1, n + 1⟩ : Q)) (teleTerm n) := by
    show (1 : Int) * 1 * (((n + 1) * (n + 2) : Nat) : Int)
        ≤ 2 * (((n + 1) * (n + 1) : Nat) : Int)
    have hn : (n + 1) * (n + 2) ≤ 2 * ((n + 1) * (n + 1)) := by
      have h1 : (n + 1) * (n + 2) ≤ (n + 1) * (2 * (n + 1)) :=
        Nat.mul_le_mul_left _ (by omega)
      have h2 : (n + 1) * (2 * (n + 1)) = 2 * ((n + 1) * (n + 1)) := Nat.mul_left_comm _ _ _
      omega
    have hc : (((n + 1) * (n + 2) : Nat) : Int) ≤ ((2 * ((n + 1) * (n + 1)) : Nat) : Int) := by
      exact_mod_cast hn
    push_cast at hc ⊢
    omega
  have hQ : Qle (mul (mul φ.M (⟨1, n + 1⟩ : Q)) (mul φ.M (⟨1, n + 1⟩ : Q)))
      (mul (mul φ.M φ.M) (teleTerm n)) :=
    Qle_trans (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd)
        (Qmul_den_pos (Nat.succ_pos n) (Nat.succ_pos n)))
      (Qeq_le hrearr)
      (Qmul_le_mul_left (Qmul_num_nonneg φ.hMn φ.hMn) hcmp)
  refine Rle_trans hsq ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hBd hBd)) ?_
  refine Rle_trans (Rle_ofQ_ofQ (Qmul_den_pos hBd hBd)
    (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (teleTerm_den n)) hQ) ?_
  exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (Qmul_den_pos φ.hMd φ.hMd) (teleTerm_den n)))

/-- The window sum against the exact telescoping value. -/
theorem momentSqTail_exact_le (φ : L2Test) (N K : Nat) :
    Rle (momentSqTail φ N K)
      (Rmul (ofQ (mul φ.M φ.M) (Qmul_den_pos φ.hMd φ.hMd))
        (ofQ (teleFrom N K) (teleFrom_den N K))) := by
  refine Rle_trans (RsumN_le K (fun i _ => mellinMoment_sq_le φ (N + i))) ?_
  exact Rle_of_Req (Req_trans (RsumN_Rmul_const _ _ K)
    (Rmul_congr (Req_refl _) (teleFrom_eq N K)))

/-- **THE `ℓ²` TAIL BOUND**: `Σ_{i<K} ⟨φ, x^{N+i}⟩² ≤ 2·M_φ²/(N+1)`, uniformly in the window
    length `K`. The tails go to zero at rate `1/(N+1)`, so the squared moments are summable. -/
theorem momentSqTail_le (φ : L2Test) (N K : Nat) :
    Rle (momentSqTail φ N K)
      (ofQ (mul (mul φ.M φ.M) (⟨2, N + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos N))) := by
  refine Rle_trans (momentSqTail_exact_le φ N K) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (Qmul_den_pos φ.hMd φ.hMd)
    (teleFrom_den N K))) ?_
  exact Rle_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (teleFrom_den N K))
    (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos N))
    (Qmul_le_mul_left (Qmul_num_nonneg φ.hMn φ.hMn) (teleFrom_le N K))

/-- **THE UNIFORM PARTIAL-SUM BOUND**: `Σ_{n<K} ⟨φ, xⁿ⟩² ≤ 2·M_φ²` for every `K`. This is the
    `N = 0` window, reindexed. -/
theorem momentSqSum_le (φ : L2Test) (K : Nat) :
    Rle (RsumN (fun n => Rmul (mellinMoment φ n) (mellinMoment φ n)) K)
      (ofQ (mul (mul φ.M φ.M) (⟨2, 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos φ.hMd φ.hMd) (Nat.succ_pos 0))) := by
  refine Rle_trans (Rle_of_Req (RsumN_congr K (fun i _ => ?_))) (momentSqTail_le φ 0 K)
  rw [Nat.zero_add]
  exact Req_refl _

end Multiplicity.UOR.Bridge.F1Square.Square
