/-
F1 square — **the pre-Hilbert layer, brick 30** (`MomentQuartic.lean`): **THE QUARTIC
EVALUATION** — `∫₀¹ clamp01(x)⁴ dx ≈ 1/5`, and the clamp's fourth Mellin datum
`mellinMoment clampTest 3 ≈ 1/5`.

The evaluation engine mirrored to degree four, on the clamped quartic:

- `sumQuarticsQ` — the `ℚ`-level Faulhaber fold `Σ_{i<k} i⁴ = k(k−1)(2k−1)(3k²−3k−1)/30`.
- `riemannSum_clampQuad` — the left Riemann sum is exactly `N(2N+1)(3N²+3N−1)/(30(N+1)⁴)`.
- `genSum_clampQuad_eval` + `quad_defect_le` — the telescoped sums and the rational defect:
  the `N⁴` terms cancel and the numerator collapses to `−(75N³+175N²+125N+30)`, bounded by
  the coefficientwise comparison `75N³+175N²+125N+30 ≤ 150(N+1)³` (nonlinear monomials
  handled as `omega` atoms over explicit nonnegativity facts).
- **`riemannIntegral_clampQuad_gen`** — `∫₀¹ clamp01⁴ ≈ 1/5` for EVERY valid Lipschitz
  datum.
- **`mellinMoment_clamp_three`** — `⟨clamp, ((1·c)·c)·c⟩ ≈ 1/5` by global collapse.

The clamp's moment data now reads `(1/2, 1/3, 1/4, 1/5, …)`. This is the first of the two
evaluations (with the quintic) that the NONZERO `K = 2` co-support member
`x(1−x)(1−5x+5x²)` consumes.

HONEST SCOPE. One more exact moment value (degree `n = 3`); the general `1/(n+2)` law
remains open. No continuous parameter, no coupling; step 4 is RH. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentCube

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The clamped quartic integrand — globally Lipschitz, equal to `x⁴` on `[0,1]`. -/
def clampQuad : Real → Real := fun x => Rmul (clampCube x) (clamp01 x)

/-- **The `ℚ`-level quartic fold** (Faulhaber):
    `Σ_{i<k} i⁴/(N+1)⁴ ≈ k(k−1)(2k−1)(3k²−3k−1)/(30(N+1)⁴)`. -/
theorem sumQuarticsQ (N : Nat) : ∀ k : Nat,
    Req (RsumN (fun i => ofQ (⟨(i : Int) * (i : Int) * (i : Int) * (i : Int),
        (N + 1) * (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
          (Nat.succ_pos N)) (Nat.succ_pos N))) k)
      (ofQ (⟨(k : Int) * ((k : Int) - 1) * (2 * (k : Int) - 1)
          * (3 * (k : Int) * (k : Int) - 3 * (k : Int) - 1),
          30 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
            (Nat.succ_pos N)) (Nat.succ_pos N)))) := by
  intro k
  induction k with
  | zero =>
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (⟨(0 : Int) * ((0 : Int) - 1) * (2 * (0 : Int) - 1)
          * (3 * (0 : Int) * (0 : Int) - 3 * (0 : Int) - 1),
        30 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
      simp only [Qeq]; push_cast; ring_uor)
  | succ k ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
          (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
        (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
    refine ofQ_congr (add_den_pos
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
          (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
        (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
          (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
    show Qeq (add (⟨(k : Int) * ((k : Int) - 1) * (2 * (k : Int) - 1)
        * (3 * (k : Int) * (k : Int) - 3 * (k : Int) - 1),
        30 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
      (⟨(k : Int) * (k : Int) * (k : Int) * (k : Int),
        (N + 1) * (N + 1) * (N + 1) * (N + 1)⟩ : Q))
      (⟨((k + 1 : Nat) : Int) * (((k + 1 : Nat) : Int) - 1) * (2 * ((k + 1 : Nat) : Int) - 1)
          * (3 * ((k + 1 : Nat) : Int) * ((k + 1 : Nat) : Int)
            - 3 * ((k + 1 : Nat) : Int) - 1),
        30 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor

/-- The clamped quartic at the dyadic sample `i/(N+1)` is exactly `i⁴/(N+1)⁴`. -/
private theorem clampQuad_sample (N i : Nat) (hi : i < N + 1) :
    Req (clampQuad (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨(i : Int) * (i : Int) * (i : Int) * (i : Int),
        (N + 1) * (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
          (Nat.succ_pos N)) (Nat.succ_pos N))) := by
  have hc := clampCube_sample' N i hi
  have h0u : Qle (⟨0, 1⟩ : Q) (⟨(i : Int), N + 1⟩ : Q) := by
    show (0 : Int) * ((N + 1 : Nat) : Int) ≤ (i : Int) * ((1 : Nat) : Int)
    push_cast; omega
  have hu1 : Qle (⟨(i : Int), N + 1⟩ : Q) (⟨1, 1⟩ : Q) := by
    show (i : Int) * ((1 : Nat) : Int) ≤ 1 * ((N + 1 : Nat) : Int)
    push_cast; omega
  have hcl := clamp01_ofQ (Nat.succ_pos N) h0u hu1
  refine Req_trans (Rmul_congr hc hcl) ?_
  exact Rmul_ofQ_ofQ
    (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))
    (Nat.succ_pos N)
where
  /-- Local re-derivation of the cube sample (the brick-26 original is private there). -/
  clampCube_sample' (N i : Nat) (hi : i < N + 1) :
      Req (clampCube (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
        (ofQ (⟨(i : Int) * (i : Int) * (i : Int), (N + 1) * (N + 1) * (N + 1)⟩ : Q)
          (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
            (Nat.succ_pos N))) := by
    have h0u : Qle (⟨0, 1⟩ : Q) (⟨(i : Int), N + 1⟩ : Q) := by
      show (0 : Int) * ((N + 1 : Nat) : Int) ≤ (i : Int) * ((1 : Nat) : Int)
      push_cast; omega
    have hu1 : Qle (⟨(i : Int), N + 1⟩ : Q) (⟨1, 1⟩ : Q) := by
      show (i : Int) * ((1 : Nat) : Int) ≤ 1 * ((N + 1 : Nat) : Int)
      push_cast; omega
    have hc := clamp01_ofQ (Nat.succ_pos N) h0u hu1
    refine Req_trans (Rmul_congr (Req_trans (Rmul_congr hc hc)
      (Rmul_ofQ_ofQ (Nat.succ_pos N) (Nat.succ_pos N))) hc) ?_
    exact Rmul_ofQ_ofQ (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N)

/-- **The left Riemann sum of the clamped quartic** is `N(2N+1)(3N²+3N−1)/(30(N+1)⁴)`. -/
theorem riemannSum_clampQuad (N : Nat) :
    Req (riemannSum clampQuad N)
      (ofQ (⟨(N : Int) * (2 * (N : Int) + 1) * (3 * (N : Int) * (N : Int) + 3 * (N : Int) - 1),
          30 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
            (Nat.succ_pos N)) (Nat.succ_pos N)))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => clampQuad (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (N + 1) (fun i hi => clampQuad_sample N i hi))
      (sumQuarticsQ N (N + 1)))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N)
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
        (Nat.succ_pos N)) (Nat.succ_pos N)))) ?_
  refine ofQ_congr (Qmul_den_pos (Nat.succ_pos N)
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
        (Nat.succ_pos N)) (Nat.succ_pos N))))
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))
        (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
  show Qeq (mul (⟨1, N + 1⟩ : Q)
      (⟨((N + 1 : Nat) : Int) * (((N + 1 : Nat) : Int) - 1) * (2 * ((N + 1 : Nat) : Int) - 1)
          * (3 * ((N + 1 : Nat) : Int) * ((N + 1 : Nat) : Int)
            - 3 * ((N + 1 : Nat) : Int) - 1),
        30 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q))
    (⟨(N : Int) * (2 * (N : Int) + 1) * (3 * (N : Int) * (N : Int) + 3 * (N : Int) - 1),
      30 * ((N + 1) * (N + 1) * (N + 1) * (N + 1))⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The telescoped dyadic sum of the clamped quartic at cutoff `M`. -/
theorem genSum_clampQuad_eval (M : Nat) :
    Req (genSum (dyadicTerm clampQuad) M)
      (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1)
          * (3 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            + 3 * ((2 ^ M - 1 : Nat) : Int) - 1),
          30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
            (Nat.succ_pos _)) (Nat.succ_pos _)))) := by
  refine Req_trans (genSum_telescope clampQuad M) ?_
  have hM := riemannSum_clampQuad (2 ^ M - 1)
  have h0 : Req (dyadicR clampQuad 0) zero :=
    Req_trans (riemannSum_clampQuad (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * (2 * ((2 ^ 0 - 1 : Nat) : Int) + 1)
          * (3 * ((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int)
            + 3 * ((2 ^ 0 - 1 : Nat) : Int) - 1),
        30 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q)
        (⟨0, 1⟩ : Q)
      decide))
  refine Req_trans (Rsub_congr hM h0) ?_
  refine Req_trans (Radd_congr (Req_refl _) ?_) (Radd_zero _)
  exact Req_trans (Rneg_congr (Req_refl zero))
    (Req_trans (Req_symm (Radd_zero (Rneg zero)))
      (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero)))

/-- The rational defect: the `N⁴` terms cancel, the numerator collapses to
    `−(75N³+175N²+125N+30)`, and `75N³+175N²+125N+30 ≤ 150(N+1)³` closes the bound
    `≤ 1/(j+1)` for `j+1 ≤ 2^M`. -/
theorem quad_defect_le {M j : Nat} (hj : j + 1 ≤ 2 ^ M) :
    Rle (Rabs (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1)
          * (3 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            + 3 * ((2 ^ M - 1 : Nat) : Int) - 1),
          30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
            (Nat.succ_pos _)) (Nat.succ_pos _))))
        (ofQ (⟨1, 5⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hcol : Req (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1)
        * (3 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
          + 3 * ((2 ^ M - 1 : Nat) : Int) - 1),
        30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Nat.succ_pos _)) (Nat.succ_pos _))))
      (ofQ (⟨1, 5⟩ : Q) (by decide)))
      (ofQ (add (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1)
          * (3 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            + 3 * ((2 ^ M - 1 : Nat) : Int) - 1),
          30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
          (neg (⟨1, 5⟩ : Q)))
        (add_den_pos (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))
            (Nat.succ_pos _)) (Nat.succ_pos _))) (by decide))) := by
    refine Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, 5⟩ : Q) (by decide))) ?_
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
  show Qle (Qabs (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1)
      * (3 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        + 3 * ((2 ^ M - 1 : Nat) : Int) - 1) * 5
      + (-1) * ((30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)
        * (2 ^ M - 1 + 1)) : Nat) : Int),
      30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 5⟩ : Q))
    (⟨1, j + 1⟩ : Q)
  have hnum : ((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1)
      * (3 * ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        + 3 * ((2 ^ M - 1 : Nat) : Int) - 1) * 5
      + (-1) * ((30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)
        * (2 ^ M - 1 + 1)) : Nat) : Int)
      = -(75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            * ((2 ^ M - 1 : Nat) : Int))
          + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
          + 125 * ((2 ^ M - 1 : Nat) : Int) + 30) := by
    push_cast
    generalize ((2 ^ M - 1 : Nat) : Int) = A
    ring_uor
  rw [hnum]
  show ((((-(75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 125 * ((2 ^ M - 1 : Nat) : Int) + 30)).natAbs : Nat) : Int)) * ((j + 1 : Nat) : Int)
      ≤ 1 * ((30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))
        * 5 : Nat) : Int)
  have hA0 : (0 : Int) ≤ ((2 ^ M - 1 : Nat) : Int) := by omega
  have hA2 : (0 : Int) ≤ ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int) :=
    Int.mul_nonneg hA0 hA0
  have hA3 : (0 : Int) ≤ ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
      * ((2 ^ M - 1 : Nat) : Int) := Int.mul_nonneg hA2 hA0
  have habs : ((((-(75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 125 * ((2 ^ M - 1 : Nat) : Int) + 30)).natAbs : Nat) : Int))
      = 75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
          * ((2 ^ M - 1 : Nat) : Int))
        + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
        + 125 * ((2 ^ M - 1 : Nat) : Int) + 30 := by
    rw [Int.natAbs_neg]
    exact Int.natAbs_of_nonneg (by omega)
  rw [habs]
  have hjA : ((j : Int) + 1) ≤ ((2 ^ M - 1 : Nat) : Int) + 1 := by omega
  have s1 : (75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 125 * ((2 ^ M - 1 : Nat) : Int) + 30) * ((j : Int) + 1)
      ≤ (75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 125 * ((2 ^ M - 1 : Nat) : Int) + 30) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_left hjA (by omega)
  have hpoly : 75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 125 * ((2 ^ M - 1 : Nat) : Int) + 30
      ≤ 150 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1))) := by
    have e : 150 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1)))
        = 150 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
            * ((2 ^ M - 1 : Nat) : Int))
          + 450 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
          + 450 * ((2 ^ M - 1 : Nat) : Int) + 150 := by
      generalize ((2 ^ M - 1 : Nat) : Int) = A
      ring_uor
    rw [e]
    omega
  have s2 : (75 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int)
        * ((2 ^ M - 1 : Nat) : Int))
      + 175 * (((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int))
      + 125 * ((2 ^ M - 1 : Nat) : Int) + 30) * (((2 ^ M - 1 : Nat) : Int) + 1)
      ≤ (150 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1)))) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right hpoly (by omega)
  have e2 : (150 * ((((2 ^ M - 1 : Nat) : Int) + 1) * ((((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1)))) * (((2 ^ M - 1 : Nat) : Int) + 1)
      = 1 * (30 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 5) := by
    generalize ((2 ^ M - 1 : Nat) : Int) = A
    ring_uor
  rw [e2] at s2
  have hgoal := Int.le_trans s1 s2
  have ecast : ((30 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)
      * (2 ^ M - 1 + 1)) * 5 : Nat) : Int)
      = 30 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)
        * (((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 5 := by
    push_cast; ring_uor
  have ejcast : ((j + 1 : Nat) : Int) = (j : Int) + 1 := by push_cast; ring_uor
  rw [ecast, ejcast]
  exact hgoal

/-- The rate, general in the Lipschitz datum. -/
theorem genSum_clampQuad_rate (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm clampQuad) (digammaMidx L j))
        (ofQ (⟨1, 5⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have heval := genSum_clampQuad_eval (digammaMidx L j)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr heval
    (Req_refl (ofQ (⟨1, 5⟩ : Q) (by decide)))))) ?_
  refine quad_defect_le ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ clamp01(x)⁴ dx ≈ 1/5`, general in the Lipschitz datum**. -/
theorem riemannIntegral_clampQuad_gen {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (clampQuad x) (clampQuad y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (clampQuad x) (clampQuad y)) :
    Req (riemannIntegral (f := clampQuad) hLd hLn hlip hfc)
      (ofQ (⟨1, 5⟩ : Q) (by decide)) := by
  show Req (Radd (dyadicR clampQuad 0) _) (ofQ (⟨1, 5⟩ : Q) (by decide))
  have hD0 : Req (dyadicR clampQuad 0) zero :=
    Req_trans (riemannSum_clampQuad (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * (2 * ((2 ^ 0 - 1 : Nat) : Int) + 1)
          * (3 * ((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int)
            + 3 * ((2 ^ 0 - 1 : Nat) : Int) - 1),
        30 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q)
        (⟨0, 1⟩ : Q)
      decide))
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm clampQuad) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (ofQ (⟨1, 5⟩ : Q) (by decide)) :=
    Rlim_eval _ (by decide) (fun j => genSum_clampQuad_rate L j)
  refine Req_trans (Radd_congr hD0 hlim) ?_
  exact Req_trans (Radd_comm zero (ofQ (⟨1, 5⟩ : Q) (by decide)))
    (Radd_zero (ofQ (⟨1, 5⟩ : Q) (by decide)))

/-- **`mellinMoment clampTest 3 ≈ 1/5`** — the clamp's fourth Mellin datum. -/
theorem mellinMoment_clamp_three :
    Req (mellinMoment clampTest 3) (ofQ (⟨1, 5⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (clampTest.f x) ((powTest 3).f x)) (clampQuad x) := fun x =>
    Req_trans (Rmul_congr (Req_refl (clamp01 x))
      (Rmul_congr (Rmul_congr
        (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
        (Req_refl (clamp01 x))) (Req_refl (clamp01 x))))
      (Rmul_comm (clamp01 x) (Rmul (Rmul (clamp01 x) (clamp01 x)) (clamp01 x)))
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampQuad x) (clampQuad y)))
      (Rmul (ofQ (l2L clampTest (powTest 3)) (l2L_den clampTest (powTest 3)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x)) (Req_symm (hdist y)))))
      (l2lip clampTest (powTest 3) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampQuad x) (clampQuad y) := fun _ _ h =>
    Rmul_congr (Rmul_congr (Rmul_congr (clamp01_congr h) (clamp01_congr h))
      (clamp01_congr h)) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampQuad)
    (l2L_den clampTest (powTest 3)) (l2L_num clampTest (powTest 3))
    (l2lip clampTest (powTest 3)) (l2fc clampTest (powTest 3)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampQuad_gen (l2L_den clampTest (powTest 3))
    (l2L_num clampTest (powTest 3)) hlipS hfcS

end Multiplicity.UOR.Bridge.F1Square.Square
