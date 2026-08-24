/-
F1 square — **the pre-Hilbert layer, brick 24** (`MomentSquare.lean`): **THE FIRST QUADRATIC
EVALUATION OF THE GATEWAY** — `∫₀¹ clamp01(x)² dx ≈ 1/3`, and the clamp's second Mellin datum
`mellinMoment clampTest 1 ≈ 1/3`.

The integrand is the globally-Lipschitz *clamped* square (the bare `x²` is not admissible);
the evaluation mirrors the identity engine (`IntegralEval.lean`) one polynomial degree up:

- `sumSquaresQ` — the `ℚ`-level square fold `Σ_{i<k} i²/(N+1)² ≈ k(k−1)(2k−1)/(6(N+1)²)`.
- `riemannSum_clampSq` — at the dyadic samples the clamp is inert (`clamp01_ofQ`), so the left
  Riemann sum is exactly `N(2N+1)/(6(N+1)²)`.
- `genSum_clampSq_eval` + `sq_defect_le` — the telescoped dyadic sums, and the rational defect
  `|N(2N+1)/(6(N+1)²) − 1/3| = (9N+6)/(18(N+1)²) ≤ 1/(j+1)` for `j+1 ≤ 2^M` (the `natAbs`
  collapse of the negative numerator at the symbolic level).
- **`riemannIntegral_clampSq_gen`** — `∫₀¹ clamp01² ≈ 1/3` for EVERY valid Lipschitz datum
  (`Rlim_eval` on the rate), the quadratic mirror of `riemannIntegral_id_gen`.
- **`mellinMoment_clamp_one`** — `⟨clamp, clamp·1⟩ = ∫₀¹ x·x ≈ 1/3`: the integrand collapses
  globally to the clamped square, certified at the pairing's own modulus by transport.

With bricks 23–24 the clamp's moment data reads `(1/2, 1/3, …)` — the Hausdorff moment
sequence of Lebesgue measure on `[0,1]`, delivered value by value by the kernel.

HONEST SCOPE. One more exact moment value (degree `n = 1`); the general `1/(n+2)` law, and
any transform value (the clamp has no half-line decay), remain open. No continuous parameter,
no coupling; step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.TestAlgebra
import Multiplicity.F1.Analysis.IntegralEval

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The clamped square integrand — globally Lipschitz, equal to `x²` on `[0,1]`. -/
def clampSq : Real → Real := fun x => Rmul (clamp01 x) (clamp01 x)

/-- **The `ℚ`-level square fold**: `Σ_{i<k} i²/(N+1)² ≈ k(k−1)(2k−1)/(6(N+1)²)`. -/
theorem sumSquaresQ (N : Nat) : ∀ k : Nat,
    Req (RsumN (fun i => ofQ (⟨(i : Int) * (i : Int), (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))) k)
      (ofQ (⟨(k : Int) * ((k : Int) - 1) * (2 * (k : Int) - 1),
          6 * ((N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)))) := by
  intro k
  induction k with
  | zero =>
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (⟨(0 : Int) * ((0 : Int) - 1) * (2 * (0 : Int) - 1),
        6 * ((N + 1) * (N + 1))⟩ : Q)
      simp only [Qeq]; push_cast; ring_uor)
  | succ k ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ
      (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))) ?_
    refine ofQ_congr (add_den_pos
      (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)))
      (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))) ?_
    show Qeq (add (⟨(k : Int) * ((k : Int) - 1) * (2 * (k : Int) - 1),
        6 * ((N + 1) * (N + 1))⟩ : Q)
      (⟨(k : Int) * (k : Int), (N + 1) * (N + 1)⟩ : Q))
      (⟨((k + 1 : Nat) : Int) * (((k + 1 : Nat) : Int) - 1)
          * (2 * ((k + 1 : Nat) : Int) - 1), 6 * ((N + 1) * (N + 1))⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor

/-- The clamped square at the dyadic sample `i/(N+1)` is exactly `i²/(N+1)²` (the clamp is
    inert at `[0,1]`-rationals). -/
private theorem clampSq_sample (N i : Nat) (hi : i < N + 1) :
    Req (clampSq (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨(i : Int) * (i : Int), (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))) := by
  have h0u : Qle (⟨0, 1⟩ : Q) (⟨(i : Int), N + 1⟩ : Q) := by
    show (0 : Int) * ((N + 1 : Nat) : Int) ≤ (i : Int) * ((1 : Nat) : Int)
    push_cast; omega
  have hu1 : Qle (⟨(i : Int), N + 1⟩ : Q) (⟨1, 1⟩ : Q) := by
    show (i : Int) * ((1 : Nat) : Int) ≤ 1 * ((N + 1 : Nat) : Int)
    push_cast; omega
  have hc := clamp01_ofQ (Nat.succ_pos N) h0u hu1
  exact Req_trans (Rmul_congr hc hc) (Rmul_ofQ_ofQ (Nat.succ_pos N) (Nat.succ_pos N))

/-- **The left Riemann sum of the clamped square** is `N(2N+1)/(6(N+1)²)`. -/
theorem riemannSum_clampSq (N : Nat) :
    Req (riemannSum clampSq N)
      (ofQ (⟨(N : Int) * (2 * (N : Int) + 1), 6 * ((N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => clampSq (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (N + 1) (fun i hi => clampSq_sample N i hi))
      (sumSquaresQ N (N + 1)))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N)
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)))) ?_
  refine ofQ_congr (Qmul_den_pos (Nat.succ_pos N)
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))))
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))) ?_
  show Qeq (mul (⟨1, N + 1⟩ : Q)
      (⟨((N + 1 : Nat) : Int) * (((N + 1 : Nat) : Int) - 1)
          * (2 * ((N + 1 : Nat) : Int) - 1), 6 * ((N + 1) * (N + 1))⟩ : Q))
    (⟨(N : Int) * (2 * (N : Int) + 1), 6 * ((N + 1) * (N + 1))⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The telescoped dyadic sum of the clamped square at cutoff `M` is the exact rational
    `N(2N+1)/(6(N+1)²)` at `N = 2^M − 1`. -/
theorem genSum_clampSq_eval (M : Nat) :
    Req (genSum (dyadicTerm clampSq) M)
      (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1),
          6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))) := by
  refine Req_trans (genSum_telescope clampSq M) ?_
  have hM := riemannSum_clampSq (2 ^ M - 1)
  have h0 : Req (dyadicR clampSq 0) zero :=
    Req_trans (riemannSum_clampSq (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * (2 * ((2 ^ 0 - 1 : Nat) : Int) + 1),
        6 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q) (⟨0, 1⟩ : Q)
      decide))
  refine Req_trans (Rsub_congr hM h0) ?_
  refine Req_trans (Radd_congr (Req_refl _) ?_) (Radd_zero _)
  exact Req_trans (Rneg_congr (Req_refl zero))
    (Req_trans (Req_symm (Radd_zero (Rneg zero)))
      (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero)))

/-- The rational defect: `|N(2N+1)/(6(N+1)²) − 1/3| ≤ 1/(j+1)` at `N = 2^M − 1` whenever
    `j + 1 ≤ 2^M` (the numerator collapses to `−(9N+6)` and `(9N+6)(j+1) ≤ 18(N+1)²`). -/
theorem sq_defect_le {M j : Nat} (hj : j + 1 ≤ 2 ^ M) :
    Rle (Rabs (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1),
          6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
        (ofQ (⟨1, 3⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hcol : Req (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1),
        6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
      (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
      (ofQ (⟨1, 3⟩ : Q) (by decide)))
      (ofQ (add (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1),
          6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q) (neg (⟨1, 3⟩ : Q)))
        (add_den_pos (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (by decide))) := by
    refine Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, 3⟩ : Q) (by decide))) ?_
    exact Radd_ofQ_ofQ (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (by decide)
  refine Rle_trans (Rle_of_Req (Rabs_congr hcol)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_ofQ (add_den_pos
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))
    (by decide)))) ?_
  refine Rle_ofQ_ofQ (Qabs_den_pos (add_den_pos
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))
    (by decide))) (Nat.succ_pos j) ?_
  show Qle (Qabs (⟨((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1) * 3
      + (-1) * ((6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) : Nat) : Int),
      6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 3⟩ : Q)) (⟨1, j + 1⟩ : Q)
  have hnum : ((2 ^ M - 1 : Nat) : Int) * (2 * ((2 ^ M - 1 : Nat) : Int) + 1) * 3
      + (-1) * ((6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) : Nat) : Int)
      = -(9 * ((2 ^ M - 1 : Nat) : Int) + 6) := by
    push_cast; ring_uor
  rw [hnum]
  show ((((-(9 * ((2 ^ M - 1 : Nat) : Int) + 6)).natAbs : Nat) : Int)) * ((j + 1 : Nat) : Int)
      ≤ 1 * ((6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 3 : Nat) : Int)
  have habs : (((-(9 * ((2 ^ M - 1 : Nat) : Int) + 6)).natAbs : Nat) : Int)
      = 9 * ((2 ^ M - 1 : Nat) : Int) + 6 := by
    rw [Int.natAbs_neg]
    exact Int.natAbs_of_nonneg (by omega)
  rw [habs]
  have hjA : ((j : Int) + 1) ≤ ((2 ^ M - 1 : Nat) : Int) + 1 := by omega
  have s1 : (9 * ((2 ^ M - 1 : Nat) : Int) + 6) * ((j : Int) + 1)
      ≤ (9 * ((2 ^ M - 1 : Nat) : Int) + 6) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_left hjA (by omega)
  have s2 : (9 * ((2 ^ M - 1 : Nat) : Int) + 6) * (((2 ^ M - 1 : Nat) : Int) + 1)
      ≤ (18 * (((2 ^ M - 1 : Nat) : Int) + 1)) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right (by omega) (by omega)
  have e : (18 * (((2 ^ M - 1 : Nat) : Int) + 1)) * (((2 ^ M - 1 : Nat) : Int) + 1)
      = 1 * (6 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 3) := by
    generalize ((2 ^ M - 1 : Nat) : Int) = A
    ring_uor
  rw [e] at s2
  have hgoal : (9 * ((2 ^ M - 1 : Nat) : Int) + 6) * ((j : Int) + 1)
      ≤ 1 * (6 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 3) :=
    Int.le_trans s1 s2
  have ecast : ((6 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 3 : Nat) : Int)
      = 6 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 3 := by
    push_cast; ring_uor
  have ejcast : ((j + 1 : Nat) : Int) = (j : Int) + 1 := by push_cast; ring_uor
  rw [ecast, ejcast]
  exact hgoal

/-- The rate, general in the Lipschitz datum: the telescoped sums sit within `1/(j+1)` of
    `1/3` for EVERY schedule. -/
theorem genSum_clampSq_rate (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm clampSq) (digammaMidx L j))
        (ofQ (⟨1, 3⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have heval := genSum_clampSq_eval (digammaMidx L j)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr heval
    (Req_refl (ofQ (⟨1, 3⟩ : Q) (by decide)))))) ?_
  refine sq_defect_le ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ clamp01(x)² dx ≈ 1/3`, general in the Lipschitz datum** — the first quadratic
    evaluation of the certified gateway. -/
theorem riemannIntegral_clampSq_gen {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (clampSq x) (clampSq y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (clampSq x) (clampSq y)) :
    Req (riemannIntegral (f := clampSq) hLd hLn hlip hfc) (ofQ (⟨1, 3⟩ : Q) (by decide)) := by
  show Req (Radd (dyadicR clampSq 0) _) (ofQ (⟨1, 3⟩ : Q) (by decide))
  have hD0 : Req (dyadicR clampSq 0) zero :=
    Req_trans (riemannSum_clampSq (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * (2 * ((2 ^ 0 - 1 : Nat) : Int) + 1),
        6 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q) (⟨0, 1⟩ : Q)
      decide))
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm clampSq) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (ofQ (⟨1, 3⟩ : Q) (by decide)) :=
    Rlim_eval _ (by decide) (fun j => genSum_clampSq_rate L j)
  refine Req_trans (Radd_congr hD0 hlim) ?_
  exact Req_trans (Radd_comm zero (ofQ (⟨1, 3⟩ : Q) (by decide)))
    (Radd_zero (ofQ (⟨1, 3⟩ : Q) (by decide)))

/-- **`mellinMoment clampTest 1 ≈ 1/3`** — the clamp's second Mellin datum: the pairing
    integrand `clamp·(1·clamp)` collapses globally to the clamped square, certified at the
    pairing's own modulus by transport, and the quadratic evaluation delivers the value. -/
theorem mellinMoment_clamp_one :
    Req (mellinMoment clampTest 1) (ofQ (⟨1, 3⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (clampTest.f x) ((powTest 1).f x)) (clampSq x) := fun x =>
    Rmul_congr (Req_refl _) (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampSq x) (clampSq y)))
      (Rmul (ofQ (l2L clampTest (powTest 1)) (l2L_den clampTest (powTest 1)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x)) (Req_symm (hdist y)))))
      (l2lip clampTest (powTest 1) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampSq x) (clampSq y) := fun _ _ h =>
    Rmul_congr (clamp01_congr h) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampSq)
    (l2L_den clampTest (powTest 1)) (l2L_num clampTest (powTest 1))
    (l2lip clampTest (powTest 1)) (l2fc clampTest (powTest 1)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampSq_gen (l2L_den clampTest (powTest 1))
    (l2L_num clampTest (powTest 1)) hlipS hfcS

end Multiplicity.UOR.Bridge.F1Square.Square
