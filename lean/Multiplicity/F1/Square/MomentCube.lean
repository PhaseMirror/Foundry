/-
F1 square — **the pre-Hilbert layer, brick 26** (`MomentCube.lean`): **THE CUBIC EVALUATION**
— `∫₀¹ clamp01(x)³ dx ≈ 1/4`, and the clamp's third Mellin datum
`mellinMoment clampTest 2 ≈ 1/4`.

The identity/square engine (`IntegralEval.lean`/`MomentSquare.lean`) mirrored one more degree
up, on the clamped cube:

- `sumCubesQ` — the `ℚ`-level cube fold `Σ_{i<k} i³ = (k(k−1)/2)²` (Nicomachus).
- `riemannSum_clampCube` — the left Riemann sum is exactly `N²/(4(N+1)²)` (clamp inert at the
  dyadic samples).
- `genSum_clampCube_eval` + `cube_defect_le` — the telescoped sums and the rational defect
  `|N²/(4(N+1)²) − 1/4| = (8N+4)/(16(N+1)²) ≤ 1/(j+1)` for `j+1 ≤ 2^M`.
- **`riemannIntegral_clampCube_gen`** — `∫₀¹ clamp01³ ≈ 1/4` for EVERY valid Lipschitz datum.
- **`mellinMoment_clamp_two`** — `⟨clamp, clamp²·1⟩ ≈ 1/4` by global collapse to the clamped
  cube at the pairing's own modulus.

The clamp's moment data now reads `(1/2, 1/3, 1/4, …)` — the Hausdorff sequence of Lebesgue
measure, three values deep. This is the last evaluation the nonzero co-support member
(`x(1−x)(1−2x)`, whose zeroth moment is `1/2 − 3/3 + 2/4 = 0`) consumes.

HONEST SCOPE. One more exact moment value (degree `n = 2`); the general `1/(n+2)` law remains
open. No continuous parameter, no coupling; step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentSquare

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The clamped cube integrand — globally Lipschitz, equal to `x³` on `[0,1]`. -/
def clampCube : Real → Real := fun x => Rmul (clampSq x) (clamp01 x)

/-- **The `ℚ`-level cube fold** (Nicomachus): `Σ_{i<k} i³/(N+1)³ ≈ (k(k−1))²/(4(N+1)³)`. -/
theorem sumCubesQ (N : Nat) : ∀ k : Nat,
    Req (RsumN (fun i => ofQ (⟨(i : Int) * (i : Int) * (i : Int),
        (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))) k)
      (ofQ (⟨((k : Int) * ((k : Int) - 1)) * ((k : Int) * ((k : Int) - 1)),
          4 * ((N + 1) * (N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N)))) := by
  intro k
  induction k with
  | zero =>
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (⟨((0 : Int) * ((0 : Int) - 1)) * ((0 : Int) * ((0 : Int) - 1)),
        4 * ((N + 1) * (N + 1) * (N + 1))⟩ : Q)
      simp only [Qeq]; push_cast; ring_uor)
  | succ k ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
    refine ofQ_congr (add_den_pos
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N)))
      (Nat.mul_pos (by decide)
        (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))) ?_
    show Qeq (add (⟨((k : Int) * ((k : Int) - 1)) * ((k : Int) * ((k : Int) - 1)),
        4 * ((N + 1) * (N + 1) * (N + 1))⟩ : Q)
      (⟨(k : Int) * (k : Int) * (k : Int), (N + 1) * (N + 1) * (N + 1)⟩ : Q))
      (⟨(((k + 1 : Nat) : Int) * (((k + 1 : Nat) : Int) - 1))
          * (((k + 1 : Nat) : Int) * (((k + 1 : Nat) : Int) - 1)),
        4 * ((N + 1) * (N + 1) * (N + 1))⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor

/-- The clamped cube at the dyadic sample `i/(N+1)` is exactly `i³/(N+1)³`. -/
private theorem clampCube_sample (N i : Nat) (hi : i < N + 1) :
    Req (clampCube (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨(i : Int) * (i : Int) * (i : Int), (N + 1) * (N + 1) * (N + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))) := by
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

/-- **The left Riemann sum of the clamped cube** is `N²/(4(N+1)²)`. -/
theorem riemannSum_clampCube (N : Nat) :
    Req (riemannSum clampCube N)
      (ofQ (⟨(N : Int) * (N : Int), 4 * ((N + 1) * (N + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => clampCube (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (N + 1) (fun i hi => clampCube_sample N i hi))
      (sumCubesQ N (N + 1)))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N)
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N)))) ?_
  refine ofQ_congr (Qmul_den_pos (Nat.succ_pos N)
    (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N)) (Nat.succ_pos N))))
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos N) (Nat.succ_pos N))) ?_
  show Qeq (mul (⟨1, N + 1⟩ : Q)
      (⟨(((N + 1 : Nat) : Int) * (((N + 1 : Nat) : Int) - 1))
          * (((N + 1 : Nat) : Int) * (((N + 1 : Nat) : Int) - 1)),
        4 * ((N + 1) * (N + 1) * (N + 1))⟩ : Q))
    (⟨(N : Int) * (N : Int), 4 * ((N + 1) * (N + 1))⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The telescoped dyadic sum of the clamped cube at cutoff `M` is `N²/(4(N+1)²)` at
    `N = 2^M − 1`. -/
theorem genSum_clampCube_eval (M : Nat) :
    Req (genSum (dyadicTerm clampCube) M)
      (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int),
          4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))) := by
  refine Req_trans (genSum_telescope clampCube M) ?_
  have hM := riemannSum_clampCube (2 ^ M - 1)
  have h0 : Req (dyadicR clampCube 0) zero :=
    Req_trans (riemannSum_clampCube (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int),
        4 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q) (⟨0, 1⟩ : Q)
      decide))
  refine Req_trans (Rsub_congr hM h0) ?_
  refine Req_trans (Radd_congr (Req_refl _) ?_) (Radd_zero _)
  exact Req_trans (Rneg_congr (Req_refl zero))
    (Req_trans (Req_symm (Radd_zero (Rneg zero)))
      (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero)))

/-- The rational defect: `|N²/(4(N+1)²) − 1/4| ≤ 1/(j+1)` at `N = 2^M − 1` for `j+1 ≤ 2^M`
    (the numerator collapses to `−(8N+4)` and `(8N+4)(j+1) ≤ 16(N+1)²`). -/
theorem cube_defect_le {M j : Nat} (hj : j + 1 ≤ 2 ^ M) :
    Rle (Rabs (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int),
          4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
        (ofQ (⟨1, 4⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hcol : Req (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int),
        4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q)
      (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
      (ofQ (⟨1, 4⟩ : Q) (by decide)))
      (ofQ (add (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int),
          4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1))⟩ : Q) (neg (⟨1, 4⟩ : Q)))
        (add_den_pos (Nat.mul_pos (by decide)
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (by decide))) := by
    refine Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, 4⟩ : Q) (by decide))) ?_
    exact Radd_ofQ_ofQ (Nat.mul_pos (by decide)
      (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (by decide)
  refine Rle_trans (Rle_of_Req (Rabs_congr hcol)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_ofQ (add_den_pos
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))
    (by decide)))) ?_
  refine Rle_ofQ_ofQ (Qabs_den_pos (add_den_pos
    (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))
    (by decide))) (Nat.succ_pos j) ?_
  show Qle (Qabs (⟨((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int) * 4
      + (-1) * ((4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) : Nat) : Int),
      4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 4⟩ : Q)) (⟨1, j + 1⟩ : Q)
  have hnum : ((2 ^ M - 1 : Nat) : Int) * ((2 ^ M - 1 : Nat) : Int) * 4
      + (-1) * ((4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) : Nat) : Int)
      = -(8 * ((2 ^ M - 1 : Nat) : Int) + 4) := by
    push_cast; ring_uor
  rw [hnum]
  show ((((-(8 * ((2 ^ M - 1 : Nat) : Int) + 4)).natAbs : Nat) : Int)) * ((j + 1 : Nat) : Int)
      ≤ 1 * ((4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 4 : Nat) : Int)
  have habs : (((-(8 * ((2 ^ M - 1 : Nat) : Int) + 4)).natAbs : Nat) : Int)
      = 8 * ((2 ^ M - 1 : Nat) : Int) + 4 := by
    rw [Int.natAbs_neg]
    exact Int.natAbs_of_nonneg (by omega)
  rw [habs]
  have hjA : ((j : Int) + 1) ≤ ((2 ^ M - 1 : Nat) : Int) + 1 := by omega
  have s1 : (8 * ((2 ^ M - 1 : Nat) : Int) + 4) * ((j : Int) + 1)
      ≤ (8 * ((2 ^ M - 1 : Nat) : Int) + 4) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_left hjA (by omega)
  have s2 : (8 * ((2 ^ M - 1 : Nat) : Int) + 4) * (((2 ^ M - 1 : Nat) : Int) + 1)
      ≤ (16 * (((2 ^ M - 1 : Nat) : Int) + 1)) * (((2 ^ M - 1 : Nat) : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right (by omega) (by omega)
  have e : (16 * (((2 ^ M - 1 : Nat) : Int) + 1)) * (((2 ^ M - 1 : Nat) : Int) + 1)
      = 1 * (4 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 4) := by
    generalize ((2 ^ M - 1 : Nat) : Int) = A
    ring_uor
  rw [e] at s2
  have hgoal : (8 * ((2 ^ M - 1 : Nat) : Int) + 4) * ((j : Int) + 1)
      ≤ 1 * (4 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 4) :=
    Int.le_trans s1 s2
  have ecast : ((4 * ((2 ^ M - 1 + 1) * (2 ^ M - 1 + 1)) * 4 : Nat) : Int)
      = 4 * ((((2 ^ M - 1 : Nat) : Int) + 1) * (((2 ^ M - 1 : Nat) : Int) + 1)) * 4 := by
    push_cast; ring_uor
  have ejcast : ((j + 1 : Nat) : Int) = (j : Int) + 1 := by push_cast; ring_uor
  rw [ecast, ejcast]
  exact hgoal

/-- The rate, general in the Lipschitz datum: the telescoped sums sit within `1/(j+1)` of
    `1/4` for EVERY schedule. -/
theorem genSum_clampCube_rate (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm clampCube) (digammaMidx L j))
        (ofQ (⟨1, 4⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have heval := genSum_clampCube_eval (digammaMidx L j)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr heval
    (Req_refl (ofQ (⟨1, 4⟩ : Q) (by decide)))))) ?_
  refine cube_defect_le ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ clamp01(x)³ dx ≈ 1/4`, general in the Lipschitz datum** — the cubic evaluation of
    the certified gateway. -/
theorem riemannIntegral_clampCube_gen {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (clampCube x) (clampCube y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (clampCube x) (clampCube y)) :
    Req (riemannIntegral (f := clampCube) hLd hLn hlip hfc)
      (ofQ (⟨1, 4⟩ : Q) (by decide)) := by
  show Req (Radd (dyadicR clampCube 0) _) (ofQ (⟨1, 4⟩ : Q) (by decide))
  have hD0 : Req (dyadicR clampCube 0) zero :=
    Req_trans (riemannSum_clampCube (2 ^ 0 - 1)) (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨((2 ^ 0 - 1 : Nat) : Int) * ((2 ^ 0 - 1 : Nat) : Int),
        4 * ((2 ^ 0 - 1 + 1) * (2 ^ 0 - 1 + 1))⟩ : Q) (⟨0, 1⟩ : Q)
      decide))
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm clampCube) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (ofQ (⟨1, 4⟩ : Q) (by decide)) :=
    Rlim_eval _ (by decide) (fun j => genSum_clampCube_rate L j)
  refine Req_trans (Radd_congr hD0 hlim) ?_
  exact Req_trans (Radd_comm zero (ofQ (⟨1, 4⟩ : Q) (by decide)))
    (Radd_zero (ofQ (⟨1, 4⟩ : Q) (by decide)))

/-- **`mellinMoment clampTest 2 ≈ 1/4`** — the clamp's third Mellin datum: the pairing
    integrand `clamp·((1·clamp)·clamp)` collapses globally to the clamped cube. -/
theorem mellinMoment_clamp_two :
    Req (mellinMoment clampTest 2) (ofQ (⟨1, 4⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (clampTest.f x) ((powTest 2).f x)) (clampCube x) := fun x =>
    Req_trans (Rmul_congr (Req_refl (clamp01 x))
      (Rmul_congr (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
        (Req_refl (clamp01 x))))
      (Rmul_comm (clamp01 x) (Rmul (clamp01 x) (clamp01 x)))
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampCube x) (clampCube y)))
      (Rmul (ofQ (l2L clampTest (powTest 2)) (l2L_den clampTest (powTest 2)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x)) (Req_symm (hdist y)))))
      (l2lip clampTest (powTest 2) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampCube x) (clampCube y) := fun _ _ h =>
    Rmul_congr (Rmul_congr (clamp01_congr h) (clamp01_congr h)) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampCube)
    (l2L_den clampTest (powTest 2)) (l2L_num clampTest (powTest 2))
    (l2lip clampTest (powTest 2)) (l2fc clampTest (powTest 2)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampCube_gen (l2L_den clampTest (powTest 2))
    (l2L_num clampTest (powTest 2)) hlipS hfcS

end Multiplicity.UOR.Bridge.F1Square.Square
