/-
F1 square — **the pre-Hilbert layer, brick 31** (`MomentQuintic.lean`): **THE QUINTIC
EVALUATION** — `∫₀¹ clamp01(x)⁵ dx ≈ 1/6`, and the clamp's fifth Mellin datum
`mellinMoment clampTest 4 ≈ 1/6`.

The evaluation engine at degree five, on the clamped quintic:

- `sumQuinticsQ` — the `ℚ`-level fold `Σ_{i<k} i⁵ = k²(k−1)²(2k²−2k−1)/12`.
- `riemannSum_clampQuint` — the left Riemann sum is exactly `N²(2N²+2N−1)/(12(N+1)⁴)`.
- `genSum_clampQuint_eval` + `quint_defect_le` — the `N⁴` terms cancel and the numerator
  collapses to `−(36N³+78N²+48N+12)`, closed by `≤ 72(N+1)³` coefficientwise.
- **`riemannIntegral_clampQuint_gen`** — `∫₀¹ clamp01⁵ ≈ 1/6` for EVERY valid Lipschitz
  datum.
- **`mellinMoment_clamp_four`** — `⟨clamp, (((1·c)·c)·c)·c⟩ ≈ 1/6` by global collapse.

The clamp's moment data now reads `(1/2, 1/3, 1/4, 1/5, 1/6, …)`. With brick 30, both
engines the NONZERO `K = 2` co-support member `x(1−x)(1−5x+5x²)` consumes are delivered.

HONEST SCOPE. One more exact moment value (degree `n = 4`); the general `1/(n+2)` law
remains open. No continuous parameter, no coupling; step 4 is RH. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentQuartic

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The clamped quintic integrand — globally Lipschitz, equal to `x⁵` on `[0,1]`. -/
def clampQuint : Real → Real := fun x => Rmul (clampQuad x) (clamp01 x)

/-- **The `ℚ`-level quintic fold**: `Σ_{i<k} i⁵/(N+1)⁵ ≈ k²(k−1)²(2k²−2k−1)/(12(N+1)⁵)`. -/
theorem sumQuinticsQ (N : Nat) : ∀ k : Nat,
    Req (RsumN (fun i => ofQ (⟨(i : Int) * (i : Int) * (i : Int) * (i : Int) * (i : Int),
        (N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
          (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N))) k)
      (ofQ (⟨(k : Int) * (k : Int) * (((k : Int) - 1) * ((k : Int) - 1))
          * (2 * (k : Int) * (k : Int) - 2 * (k : Int) - 1),
          12 * ((N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
            (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)))) := by
  intro k
  induction k with
  | zero =>
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (⟨(0 : Int) * (0 : Int) * (((0 : Int) - 1) * ((0 : Int) - 1))
          * (2 * (0 : Int) * (0 : Int) - 2 * (0 : Int) - 1),
        12 * ((N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
      simp only [Qeq]; push_cast; ring_uor)
  | succ k ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
          (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
        (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
    refine ofQ_congr (add_den_pos
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
          (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
        (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
          (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
    show Qeq (add (⟨(k : Int) * (k : Int) * (((k : Int) - 1) * ((k : Int) - 1))
        * (2 * (k : Int) * (k : Int) - 2 * (k : Int) - 1),
        12 * ((N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
      (⟨(k : Int) * (k : Int) * (k : Int) * (k : Int) * (k : Int),
        (N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1)⟩ : Q))
      (⟨((k + 1 : Nat) : Int) * ((k + 1 : Nat) : Int)
          * ((((k + 1 : Nat) : Int) - 1) * (((k + 1 : Nat) : Int) - 1))
          * (2 * ((k + 1 : Nat) : Int) * ((k + 1 : Nat) : Int)
            - 2 * ((k + 1 : Nat) : Int) - 1),
        12 * ((N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor

/-- The clamped quintic at the dyadic sample `i/(N+1)` is exactly `i⁵/(N+1)⁵`. -/
private theorem clampQuint_sample (N i : Nat) (hi : i < N + 1) :
    Req (clampQuint (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨(i : Int) * (i : Int) * (i : Int) * (i : Int) * (i : Int),
        (N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
          (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N))) := by
  have h0u : Qle (⟨0, 1⟩ : Q) (⟨(i : Int), N + 1⟩ : Q) := by
    show (0 : Int) * ((N + 1 : Nat) : Int) ≤ (i : Int) * ((1 : Nat) : Int)
    push_cast; omega
  have hu1 : Qle (⟨(i : Int), N + 1⟩ : Q) (⟨1, 1⟩ : Q) := by
    show (i : Int) * ((1 : Nat) : Int) ≤ 1 * ((N + 1 : Nat) : Int)
    push_cast; omega
  have hc := clamp01_ofQ (Nat.succ_pos N) h0u hu1
  have hsq : Req (clampSq (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨(i : Int) * (i : Int), (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))) :=
    Req_trans (Rmul_congr hc hc) (Rmul_ofQ_ofQ (Nat.succ_pos N) (Nat.succ_pos N))
  have hcube : Req (clampCube (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨(i : Int) * (i : Int) * (i : Int), (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))) :=
    Req_trans (Rmul_congr hsq hc)
      (Rmul_ofQ_ofQ (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))
  have hquad : Req (clampQuad (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨(i : Int) * (i : Int) * (i : Int) * (i : Int),
        (N + 1) * (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
          (Nat.succ_pos N)) (Nat.succ_pos N))) :=
    Req_trans (Rmul_congr hcube hc)
      (Rmul_ofQ_ofQ (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
        (Nat.succ_pos N)) (Nat.succ_pos N))
  refine Req_trans (Rmul_congr hquad hc) ?_
  exact Rmul_ofQ_ofQ (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
    (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)

/-- **The left Riemann sum of the clamped quintic** is `N²(2N²+2N−1)/(12(N+1)⁴)`. -/
theorem riemannSum_clampQuint (N : Nat) :
    Req (riemannSum clampQuint N)
      (ofQ (⟨(N : Int) * (N : Int) * (2 * (N : Int) * (N : Int) + 2 * (N : Int) - 1),
          12 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
            (Nat.succ_pos N)) (Nat.succ_pos N)))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => clampQuint (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (N + 1) (fun i hi => clampQuint_sample N i hi))
      (sumQuinticsQ N (N + 1)))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N)
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
        (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)))) ?_
  refine ofQ_congr (Qmul_den_pos (Nat.succ_pos N)
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N)
        (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N)) (Nat.succ_pos N))))
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
        (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
  show Qeq (mul (⟨1, N + 1⟩ : Q)
      (⟨((N + 1 : Nat) : Int) * ((N + 1 : Nat) : Int)
          * ((((N + 1 : Nat) : Int) - 1) * (((N + 1 : Nat) : Int) - 1))
          * (2 * ((N + 1 : Nat) : Int) * ((N + 1 : Nat) : Int)
            - 2 * ((N + 1 : Nat) : Int) - 1),
        12 * ((N + 1) * (N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q))
    (⟨(N : Int) * (N : Int) * (2 * (N : Int) * (N : Int) + 2 * (N : Int) - 1),
      12 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The telescoped dyadic sum of the clamped quintic at cutoff `M`. -/
theorem genSum_clampQuint_eval (M : Nat) :
    Req (genSum (dyadicTerm clampQuint) M)
      (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
          * (2 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            + 2 * ((2 ^ M - 1 : Nat) : Int) - 1),
          12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
            (Nat.succ_pos _)) (Nat.succ_pos _)))) := by
  refine Req_trans (genSum_telescope clampQuint M) ?_
  have hM := riemannSum_clampQuint (2 ^ M - 1)
  have h0 : Req (dyadicR clampQuint 0) zero :=
    Req_trans (riemannSum_clampQuint (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int)
          * (2 * ((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int)
            + 2 * ((2 ^ 0 - 1 : Nat) : Int) - 1),
        12 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q)
        (⟨0, 1⟩ : Q)
      decide))
  refine Req_trans (Rsub_congr hM h0) ?_
  refine Req_trans (Radd_congr (Req_refl _) ?_) (Radd_zero _)
  exact Req_trans (Rneg_congr (Req_refl zero))
    (Req_trans (Req_symm (Radd_zero (Rneg zero)))
      (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero)))

/-- The rational defect: the `N⁴` terms cancel, the numerator collapses to
    `−(36N³+78N²+48N+12)`, closed by `≤ 72(N+1)³` for `j+1 ≤ 2^M`. -/
theorem quint_defect_le {M j : Nat} (hj : j + 1 ≤ 2 ^ M) :
    Rle (Rabs (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
          * (2 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            + 2 * ((2 ^ M - 1 : Nat) : Int) - 1),
          12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
            (Nat.succ_pos _)) (Nat.succ_pos _))))
        (ofQ (⟨1, 6⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hcol : Req (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * (2 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
          + 2 * ((2 ^ M - 1 : Nat) : Int) - 1),
        12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Nat.succ_pos _)) (Nat.succ_pos _))))
      (ofQ (⟨1, 6⟩ : Q) (by decide)))
      (ofQ (add (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
          * (2 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            + 2 * ((2 ^ M - 1 : Nat) : Int) - 1),
          12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
          (neg (⟨1, 6⟩ : Q)))
        (add_den_pos (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
            (Nat.succ_pos _)) (Nat.succ_pos _))) (by decide))) := by
    refine Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, 6⟩ : Q) (by decide))) ?_
    exact Radd_ofQ_ofQ (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (Nat.succ_pos _)) (Nat.succ_pos _))) (by decide)
  refine Rle_trans (Rle_of_Req (Rabs_congr hcol)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_ofQ (add_den_pos
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (Nat.succ_pos _)) (Nat.succ_pos _))) (by decide)))) ?_
  refine Rle_ofQ_ofQ (Qabs_den_pos (add_den_pos
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (Nat.succ_pos _)) (Nat.succ_pos _))) (by decide))) (Nat.succ_pos j) ?_
  show Qle (Qabs (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
      * (2 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        + 2 * ((2 ^ M - 1 : Nat) : Int) - 1) * 6
      + (-1) * ((12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)
        * (2 ^ M - 1 + 1)) : Nat) : Int),
      12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 6⟩ : Q))
    (⟨1, j + 1⟩ : Q)
  have hnum : ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
      * (2 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        + 2 * ((2 ^ M - 1 : Nat) : Int) - 1) * 6
      + (-1) * ((12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)
        * (2 ^ M - 1 + 1)) : Nat) : Int)
      = -(36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            * ((2 ^ M - 1 : Nat) : Int))
          + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
          + 48 * ((2 ^ M - 1 : Nat) : Int) + 12) := by
    push_cast
    generalize ((2 ^ M - 1 : Nat) : Int) = A
    ring_uor
  rw [hnum]
  show ((((-(36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 48 * ((2 ^ M - 1 : Nat) : Int) + 12)).natAbs : Nat) : Int)) * ((j + 1 : Nat) : Int)
      ≤ 1 * ((12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))
        * 6 : Nat) : Int)
  have hA0 : (0 : Int) ≤ ((2 ^ M - 1 : Nat) : Int) := by omega
  have hA2 : (0 : Int) ≤ ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int) :=
    Int.mul_nonneg hA0 hA0
  have hA3 : (0 : Int) ≤ ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
      * ((2 ^ M - 1 : Nat) : Int) := Int.mul_nonneg hA2 hA0
  have habs : ((((-(36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 48 * ((2 ^ M - 1 : Nat) : Int) + 12)).natAbs : Nat) : Int))
      = 36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
          * ((2 ^ M - 1 : Nat) : Int))
        + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
        + 48 * ((2 ^ M - 1 : Nat) : Int) + 12 := by
    rw [Int.natAbs_neg]
    exact Int.natAbs_of_nonneg (by omega)
  rw [habs]
  have hjA : ((j : Int) + 1) ≤ ((2 ^ M - 1 : Nat) : Int) + 1 := by omega
  have s1 : (36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 48 * ((2 ^ M - 1 : Nat) : Int) + 12) * ((j : Int) + 1)
      ≤ (36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 48 * ((2 ^ M - 1 : Nat) : Int) + 12) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_left hjA (by omega)
  have hpoly : 36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 48 * ((2 ^ M - 1 : Nat) : Int) + 12
      ≤ 72 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1))) := by
    have e : 72 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1)))
        = 72 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            * ((2 ^ M - 1 : Nat) : Int))
          + 216 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
          + 216 * ((2 ^ M - 1 : Nat) : Int) + 72 := by
      generalize ((2 ^ M - 1 : Nat) : Int) = A
      ring_uor
    rw [e]
    omega
  have s2 : (36 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 78 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 48 * ((2 ^ M - 1 : Nat) : Int) + 12) * (((2 ^ M - 1 : Nat) : Int) + 1)
      ≤ (72 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1)))) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right hpoly (by omega)
  have e2 : (72 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1)))) * (((2 ^ M - 1 : Nat) : Int) + 1)
      = 1 * (12 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 6) := by
    generalize ((2 ^ M - 1 : Nat) : Int) = A
    ring_uor
  rw [e2] at s2
  have hgoal := Int.le_trans s1 s2
  have ecast : ((12 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)
      * (2 ^ M - 1 + 1)) * 6 : Nat) : Int)
      = 12 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 6 := by
    push_cast; ring_uor
  have ejcast : ((j + 1 : Nat) : Int) = (j : Int) + 1 := by push_cast; ring_uor
  rw [ecast, ejcast]
  exact hgoal

/-- The rate, general in the Lipschitz datum. -/
theorem genSum_clampQuint_rate (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm clampQuint) (digammaMidx L j))
        (ofQ (⟨1, 6⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have heval := genSum_clampQuint_eval (digammaMidx L j)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr heval
    (Req_refl (ofQ (⟨1, 6⟩ : Q) (by decide)))))) ?_
  refine quint_defect_le ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ clamp01(x)⁵ dx ≈ 1/6`, general in the Lipschitz datum**. -/
theorem riemannIntegral_clampQuint_gen {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (clampQuint x) (clampQuint y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (clampQuint x) (clampQuint y)) :
    Req (riemannIntegral (f := clampQuint) hLd hLn hlip hfc)
      (ofQ (⟨1, 6⟩ : Q) (by decide)) := by
  show Req (Radd (dyadicR clampQuint 0) _) (ofQ (⟨1, 6⟩ : Q) (by decide))
  have hD0 : Req (dyadicR clampQuint 0) zero :=
    Req_trans (riemannSum_clampQuint (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int)
          * (2 * ((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int)
            + 2 * ((2 ^ 0 - 1 : Nat) : Int) - 1),
        12 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q)
        (⟨0, 1⟩ : Q)
      decide))
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm clampQuint) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (ofQ (⟨1, 6⟩ : Q) (by decide)) :=
    Rlim_eval _ (by decide) (fun j => genSum_clampQuint_rate L j)
  refine Req_trans (Radd_congr hD0 hlim) ?_
  exact Req_trans (Radd_comm zero (ofQ (⟨1, 6⟩ : Q) (by decide)))
    (Radd_zero (ofQ (⟨1, 6⟩ : Q) (by decide)))

/-- **`mellinMoment clampTest 4 ≈ 1/6`** — the clamp's fifth Mellin datum. -/
theorem mellinMoment_clamp_four :
    Req (mellinMoment clampTest 4) (ofQ (⟨1, 6⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (clampTest.f x) ((powTest 4).f x)) (clampQuint x) := fun x =>
    Req_trans (Rmul_congr (Req_refl (clamp01 x))
      (Rmul_congr (Rmul_congr (Rmul_congr
        (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
        (Req_refl (clamp01 x))) (Req_refl (clamp01 x))) (Req_refl (clamp01 x))))
      (Rmul_comm (clamp01 x)
        (Rmul (Rmul (Rmul (clamp01 x) (clamp01 x)) (clamp01 x)) (clamp01 x)))
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampQuint x) (clampQuint y)))
      (Rmul (ofQ (l2L clampTest (powTest 4)) (l2L_den clampTest (powTest 4)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x)) (Req_symm (hdist y)))))
      (l2lip clampTest (powTest 4) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampQuint x) (clampQuint y) := fun _ _ h =>
    Rmul_congr (Rmul_congr (Rmul_congr (Rmul_congr (clamp01_congr h) (clamp01_congr h))
      (clamp01_congr h)) (clamp01_congr h)) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampQuint)
    (l2L_den clampTest (powTest 4)) (l2L_num clampTest (powTest 4))
    (l2lip clampTest (powTest 4)) (l2fc clampTest (powTest 4)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampQuint_gen (l2L_den clampTest (powTest 4))
    (l2L_num clampTest (powTest 4)) hlipS hfcS

end Multiplicity.UOR.Bridge.F1Square.Square
