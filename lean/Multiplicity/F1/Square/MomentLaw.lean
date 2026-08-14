/-
F1 square — **the pre-Hilbert layer, brick 33** (`MomentLaw.lean`): **THE HAUSDORFF MOMENT
LAW** — `mellinMoment clampTest n ≈ 1/(n+2)` for EVERY `n`, one theorem subsuming the five
per-degree engines. The clamp's moment sequence is the FULL Hausdorff moment data of Lebesgue
measure on `[0,1]`.

No Faulhaber folds. The engine is the discrete mean-value bracket
`(m+1)·iᵐ ≤ (i+1)^(m+1) − i^(m+1) ≤ (m+1)·(i+1)ᵐ` (`pow_succ_lower`/`_upper`), which telescopes
to `(m+1)·Σiᵐ ≤ N^(m+1) ≤ (m+1)·(Σiᵐ + Nᵐ)` (`powSum_lower`/`_upper`), so the left Riemann sums
sit within `1/(N+1)` of `1/(m+1)` UNIFORMLY in the degree (`powSum_defect_le`), and `Rlim_eval`
closes every degree by the same rate.

HONEST SCOPE. All integer moments of the clamp; the continuous Mellin parameter, transform
pair, and inversion remain open; no coupling; step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import Multiplicity.F1Square.Square.TestAlgebra
import Multiplicity.F1Square.Analysis.IntegralEval

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `Σ_{i<k} iᵐ` as a `Nat` recursion. -/
def natPowSum (m : Nat) : Nat → Nat
  | 0 => 0
  | k + 1 => natPowSum m k + k ^ m

/-- **The discrete mean-value bracket, lower half**: `i^(m+1) + (m+1)·iᵐ ≤ (i+1)^(m+1)`. -/
theorem pow_succ_lower (i m : Nat) : i ^ (m + 1) + (m + 1) * i ^ m ≤ (i + 1) ^ (m + 1) := by
  induction m with
  | zero => simp only [Nat.pow_succ, Nat.pow_zero, Nat.one_mul]; omega
  | succ m ih =>
    have e : (i + 1) * (i ^ (m + 1) + (m + 1) * i ^ m)
        = i ^ (m + 2) + (m + 2) * i ^ (m + 1) + (m + 1) * i ^ m := by
      rw [Nat.pow_succ i (m + 1), Nat.pow_succ i m]
      have key : ∀ a x y : Nat,
          (x + 1) * (a * x + (y + 1) * a) = a * x * x + (y + 2) * (a * x) + (y + 1) * a := by
        intro a x y
        have hz : ((x : Int) + 1) * ((a : Int) * x + ((y : Int) + 1) * a)
            = (a : Int) * x * x + ((y : Int) + 2) * ((a : Int) * x) + ((y : Int) + 1) * a := by
          ring_uor
        exact_mod_cast hz
      exact key (i ^ m) i m
    calc i ^ (m + 2) + (m + 2) * i ^ (m + 1)
        ≤ i ^ (m + 2) + (m + 2) * i ^ (m + 1) + (m + 1) * i ^ m := Nat.le_add_right _ _
      _ = (i + 1) * (i ^ (m + 1) + (m + 1) * i ^ m) := e.symm
      _ ≤ (i + 1) * (i + 1) ^ (m + 1) := Nat.mul_le_mul_left _ ih
      _ = (i + 1) ^ (m + 2) := by rw [Nat.pow_succ]; exact Nat.mul_comm _ _

/-- **The discrete mean-value bracket, upper half**: `(i+1)^(m+1) ≤ i^(m+1) + (m+1)·(i+1)ᵐ`. -/
theorem pow_succ_upper (i m : Nat) :
    (i + 1) ^ (m + 1) ≤ i ^ (m + 1) + (m + 1) * (i + 1) ^ m := by
  induction m with
  | zero => simp only [Nat.pow_succ, Nat.pow_zero, Nat.one_mul]; omega
  | succ m ih =>
    have e : (i + 1) * (i ^ (m + 1) + (m + 1) * (i + 1) ^ m)
        = i ^ (m + 2) + i ^ (m + 1) + (m + 1) * (i + 1) ^ (m + 1) := by
      rw [Nat.pow_succ i (m + 1), Nat.pow_succ (i + 1) m]
      have key : ∀ a b x y : Nat,
          (x + 1) * (a * x + (y + 1) * b) = a * x * x + a * x + (y + 1) * (b * (x + 1)) := by
        intro a b x y
        have hz : ((x : Int) + 1) * ((a : Int) * x + ((y : Int) + 1) * b)
            = (a : Int) * x * x + (a : Int) * x + ((y : Int) + 1) * ((b : Int) * (x + 1)) := by
          ring_uor
        exact_mod_cast hz
      exact key (i ^ m) ((i + 1) ^ m) i m
    have hpow : i ^ (m + 1) ≤ (i + 1) ^ (m + 1) := Nat.pow_le_pow_left (Nat.le_succ i) _
    calc (i + 1) ^ (m + 2)
        = (i + 1) * (i + 1) ^ (m + 1) := by rw [Nat.pow_succ]; exact Nat.mul_comm _ _
      _ ≤ (i + 1) * (i ^ (m + 1) + (m + 1) * (i + 1) ^ m) := Nat.mul_le_mul_left _ ih
      _ = i ^ (m + 2) + i ^ (m + 1) + (m + 1) * (i + 1) ^ (m + 1) := e
      _ ≤ i ^ (m + 2) + (i + 1) ^ (m + 1) + (m + 1) * (i + 1) ^ (m + 1) :=
          Nat.add_le_add_right (Nat.add_le_add_left hpow _) _
      _ = i ^ (m + 2) + (m + 2) * (i + 1) ^ (m + 1) := by
          have key2 : ∀ a b y : Nat, a + b + (y + 1) * b = a + (y + 2) * b := by
            intro a b y
            have hz : (a : Int) + b + ((y : Int) + 1) * b = (a : Int) + ((y : Int) + 2) * b := by
              ring_uor
            exact_mod_cast hz
          exact key2 (i ^ (m + 2)) ((i + 1) ^ (m + 1)) m

/-- **The telescoped lower bound**: `(m+1)·Σ_{i<N} iᵐ ≤ N^(m+1)`. -/
theorem powSum_lower (m : Nat) : ∀ N : Nat, (m + 1) * natPowSum m N ≤ N ^ (m + 1) := by
  intro N
  induction N with
  | zero => simp [natPowSum]
  | succ N ih =>
    show (m + 1) * (natPowSum m N + N ^ m) ≤ (N + 1) ^ (m + 1)
    calc (m + 1) * (natPowSum m N + N ^ m)
        = (m + 1) * natPowSum m N + (m + 1) * N ^ m := Nat.mul_add _ _ _
      _ ≤ N ^ (m + 1) + (m + 1) * N ^ m := Nat.add_le_add_right ih _
      _ ≤ (N + 1) ^ (m + 1) := pow_succ_lower N m

/-- **The telescoped upper bound**: `N^(m+1) ≤ (m+1)·(Σ_{i<N} iᵐ + Nᵐ)`. -/
theorem powSum_upper (m : Nat) : ∀ N : Nat, N ^ (m + 1) ≤ (m + 1) * (natPowSum m N + N ^ m) := by
  intro N
  induction N with
  | zero =>
    show 0 ^ (m + 1) ≤ (m + 1) * (0 + 0 ^ m)
    have h0 : (0 : Nat) ^ (m + 1) = 0 := by rw [Nat.pow_succ]; exact Nat.mul_zero _
    rw [h0]; exact Nat.zero_le _
  | succ N ih =>
    show (N + 1) ^ (m + 1) ≤ (m + 1) * (natPowSum m N + N ^ m + (N + 1) ^ m)
    calc (N + 1) ^ (m + 1)
        ≤ N ^ (m + 1) + (m + 1) * (N + 1) ^ m := pow_succ_upper N m
      _ ≤ (m + 1) * (natPowSum m N + N ^ m) + (m + 1) * (N + 1) ^ m :=
          Nat.add_le_add_right ih _
      _ = (m + 1) * (natPowSum m N + N ^ m + (N + 1) ^ m) := (Nat.mul_add _ _ _).symm

/-- The power-test at the dyadic sample is the rational power: `iᵐ/(N+1)ᵐ`. -/
theorem powTest_sample (m N i : Nat) (hi : i < N + 1) :
    Req ((powTest m).f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨((i ^ m : Nat) : Int), (N + 1) ^ m⟩ : Q)
        (Nat.pos_pow_of_pos m (Nat.succ_pos N))) := by
  induction m with
  | zero =>
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨1, 1⟩ : Q) (⟨((i ^ 0 : Nat) : Int), (N + 1) ^ 0⟩ : Q)
      simp only [Nat.pow_zero]; decide)
  | succ m ih =>
    have hc : Req (clamp01 (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
        (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)) := by
      refine clamp01_ofQ (Nat.succ_pos N) ?_ ?_
      · show (0 : Int) * ((N + 1 : Nat) : Int) ≤ (i : Int) * ((1 : Nat) : Int); push_cast; omega
      · show (i : Int) * ((1 : Nat) : Int) ≤ 1 * ((N + 1 : Nat) : Int); push_cast; omega
    refine Req_trans (Rmul_congr ih hc) ?_
    refine Req_trans (Rmul_ofQ_ofQ (Nat.pos_pow_of_pos m (Nat.succ_pos N)) (Nat.succ_pos N)) ?_
    refine ofQ_congr (Qmul_den_pos (Nat.pos_pow_of_pos m (Nat.succ_pos N)) (Nat.succ_pos N))
      (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N)) ?_
    show ((i ^ m : Nat) : Int) * (i : Int) * (((N + 1) ^ (m + 1) : Nat) : Int)
      = ((i ^ (m + 1) : Nat) : Int) * ((((N + 1) ^ m * (N + 1) : Nat)) : Int)
    have hN : i ^ m * i * (N + 1) ^ (m + 1) = i ^ (m + 1) * ((N + 1) ^ m * (N + 1)) := by
      rw [Nat.pow_succ i m, Nat.pow_succ (N + 1) m]
    exact_mod_cast hN

/-- The `ℚ`-level power fold: same denominator `(N+1)ᵐ`. -/
theorem powSum_fold (m N : Nat) : ∀ k : Nat,
    Req (RsumN (fun i => ofQ (⟨((i ^ m : Nat) : Int), (N + 1) ^ m⟩ : Q)
        (Nat.pos_pow_of_pos m (Nat.succ_pos N))) k)
      (ofQ (⟨((natPowSum m k : Nat) : Int), (N + 1) ^ m⟩ : Q)
        (Nat.pos_pow_of_pos m (Nat.succ_pos N))) := by
  intro k
  induction k with
  | zero =>
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (⟨((natPowSum m 0 : Nat) : Int), (N + 1) ^ m⟩ : Q)
      show (0 : Int) * (((N + 1) ^ m : Nat) : Int) = ((0 : Nat) : Int) * ((1 : Nat) : Int)
      push_cast; ring_uor)
  | succ k ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (Nat.pos_pow_of_pos m (Nat.succ_pos N))
      (Nat.pos_pow_of_pos m (Nat.succ_pos N))) ?_
    refine ofQ_congr (add_den_pos (Nat.pos_pow_of_pos m (Nat.succ_pos N))
      (Nat.pos_pow_of_pos m (Nat.succ_pos N))) (Nat.pos_pow_of_pos m (Nat.succ_pos N)) ?_
    show (((natPowSum m k : Nat) : Int) * (((N + 1) ^ m : Nat) : Int)
        + ((k ^ m : Nat) : Int) * (((N + 1) ^ m : Nat) : Int)) * (((N + 1) ^ m : Nat) : Int)
      = ((natPowSum m k + k ^ m : Nat) : Int) * ((((N + 1) ^ m * (N + 1) ^ m : Nat)) : Int)
    generalize (N + 1) ^ m = B
    generalize k ^ m = P
    push_cast
    generalize ((natPowSum m k : Nat) : Int) = S
    generalize ((B : Nat) : Int) = BB
    generalize ((P : Nat) : Int) = PP
    ring_uor

/-- **The left Riemann sum of the power test** is `(Σ_{i<N+1} iᵐ)/(N+1)^(m+1)`. -/
theorem riemannSum_powTest (m N : Nat) :
    Req (riemannSum ((powTest m).f) N)
      (ofQ (⟨((natPowSum m (N + 1) : Nat) : Int), (N + 1) ^ (m + 1)⟩ : Q)
        (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => (powTest m).f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (N + 1) (fun i hi => powTest_sample m N i hi))
      (powSum_fold m N (N + 1)))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) (Nat.pos_pow_of_pos m (Nat.succ_pos N))) ?_
  refine ofQ_congr (Qmul_den_pos (Nat.succ_pos N) (Nat.pos_pow_of_pos m (Nat.succ_pos N)))
    (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N)) ?_
  show (1 : Int) * ((natPowSum m (N + 1) : Nat) : Int) * ((((N + 1) ^ m * (N + 1) : Nat)) : Int)
    = ((natPowSum m (N + 1) : Nat) : Int) * (((N + 1) * (N + 1) ^ m : Nat) : Int)
  generalize (N + 1) ^ m = B
  push_cast
  generalize ((natPowSum m (N + 1) : Nat) : Int) = S
  generalize ((B : Nat) : Int) = BB
  generalize ((N + 1 : Nat) : Int) = MM
  ring_uor

/-- **The uniform defect**: one bound for EVERY degree, `≤ 1/(j+1)` when `j+1 ≤ N+1`. -/
theorem powSum_defect_le (m N j : Nat) (hj : j + 1 ≤ N + 1) :
    Rle (Rabs (Rsub (ofQ (⟨((natPowSum m (N + 1) : Nat) : Int), (N + 1) ^ (m + 1)⟩ : Q)
        (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N)))
        (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hcol : Req (Rsub (ofQ (⟨((natPowSum m (N + 1) : Nat) : Int), (N + 1) ^ (m + 1)⟩ : Q)
      (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N))) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)))
      (ofQ (add (⟨((natPowSum m (N + 1) : Nat) : Int), (N + 1) ^ (m + 1)⟩ : Q)
          (neg (⟨1, m + 1⟩ : Q)))
        (add_den_pos (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N)) (Nat.succ_pos m))) := by
    refine Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m))) ?_
    exact Radd_ofQ_ofQ (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N)) (Nat.succ_pos m)
  refine Rle_trans (Rle_of_Req (Rabs_congr hcol)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_ofQ (add_den_pos
    (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N)) (Nat.succ_pos m)))) ?_
  refine Rle_ofQ_ofQ (Qabs_den_pos (add_den_pos
    (Nat.pos_pow_of_pos (m + 1) (Nat.succ_pos N)) (Nat.succ_pos m))) (Nat.succ_pos j) ?_
  show Qle (Qabs (⟨((natPowSum m (N + 1) : Nat) : Int) * ((m + 1 : Nat) : Int)
      + (-1) * (((N + 1) ^ (m + 1) : Nat) : Int),
      (N + 1) ^ (m + 1) * (m + 1)⟩ : Q)) (⟨1, j + 1⟩ : Q)
  -- Nat facts
  have hlowMul : natPowSum m (N + 1) * (m + 1) ≤ (N + 1) ^ (m + 1) := by
    have h := powSum_lower m (N + 1)
    rw [Nat.mul_comm (m + 1) (natPowSum m (N + 1))] at h
    exact h
  have hupp2 : (N + 1) ^ (m + 1)
      ≤ natPowSum m (N + 1) * (m + 1) + (m + 1) * (N + 1) ^ m := by
    have h := powSum_upper m (N + 1)
    have e : (m + 1) * (natPowSum m (N + 1) + (N + 1) ^ m)
        = natPowSum m (N + 1) * (m + 1) + (m + 1) * (N + 1) ^ m := by
      rw [Nat.mul_add, Nat.mul_comm (m + 1) (natPowSum m (N + 1))]
    omega
  have hpidN : (N + 1) ^ m * (N + 1) = (N + 1) ^ (m + 1) := (Nat.pow_succ _ _).symm
  have hfinalN : ((N + 1) ^ (m + 1) - natPowSum m (N + 1) * (m + 1)) * (j + 1)
      ≤ (N + 1) ^ (m + 1) * (m + 1) := by
    have hsub : (N + 1) ^ (m + 1) - natPowSum m (N + 1) * (m + 1) ≤ (m + 1) * (N + 1) ^ m := by
      omega
    calc ((N + 1) ^ (m + 1) - natPowSum m (N + 1) * (m + 1)) * (j + 1)
        ≤ ((m + 1) * (N + 1) ^ m) * (j + 1) := Nat.mul_le_mul_right _ hsub
      _ ≤ ((m + 1) * (N + 1) ^ m) * (N + 1) := Nat.mul_le_mul_left _ hj
      _ = (m + 1) * ((N + 1) ^ m * (N + 1)) := by rw [Nat.mul_assoc]
      _ = (m + 1) * (N + 1) ^ (m + 1) := by rw [hpidN]
      _ = (N + 1) ^ (m + 1) * (m + 1) := Nat.mul_comm _ _
  have hnatabs : (((natPowSum m (N + 1) : Nat) : Int) * ((m + 1 : Nat) : Int)
      + (-1) * (((N + 1) ^ (m + 1) : Nat) : Int)).natAbs
      = (N + 1) ^ (m + 1) - natPowSum m (N + 1) * (m + 1) := by
    have h1 : (((N + 1) ^ (m + 1) - natPowSum m (N + 1) * (m + 1) : Nat) : Int)
        = (((N + 1) ^ (m + 1) : Nat) : Int)
          - ((natPowSum m (N + 1) * (m + 1) : Nat) : Int) := by omega
    have key : ((natPowSum m (N + 1) : Nat) : Int) * ((m + 1 : Nat) : Int)
        + (-1) * (((N + 1) ^ (m + 1) : Nat) : Int)
        = -(((N + 1) ^ (m + 1) - natPowSum m (N + 1) * (m + 1) : Nat) : Int) := by
      rw [h1, Int.natCast_mul]; ring_uor
    rw [key, Int.natAbs_neg, Int.natAbs_ofNat]
  show (((((natPowSum m (N + 1) : Nat) : Int) * ((m + 1 : Nat) : Int)
      + (-1) * (((N + 1) ^ (m + 1) : Nat) : Int)).natAbs : Nat) : Int) * ((j + 1 : Nat) : Int)
    ≤ 1 * (((N + 1) ^ (m + 1) * (m + 1) : Nat) : Int)
  rw [hnatabs, Int.one_mul]
  exact_mod_cast hfinalN

/-- `dyadicR (powTest (k+1)).f 0 ≈ 0` (the exponent is `≥ 1`, so the sample at `0` vanishes). -/
theorem powTest_dyadicR0 (k : Nat) : Req (dyadicR (powTest (k + 1)).f 0) zero := by
  refine Req_trans (riemannSum_powTest (k + 1) (2 ^ 0 - 1)) ?_
  refine Req_of_seq_Qeq (fun _ => ?_)
  show Qeq (⟨((natPowSum (k + 1) (2 ^ 0 - 1 + 1) : Nat) : Int), (2 ^ 0 - 1 + 1) ^ ((k + 1) + 1)⟩ : Q)
    (⟨0, 1⟩ : Q)
  have h1 : (2 : Nat) ^ 0 - 1 + 1 = 1 := by decide
  rw [h1]
  have hnps : natPowSum (k + 1) 1 = 0 := by
    have h : (0 : Nat) ^ (k + 1) = 0 := by rw [Nat.pow_succ, Nat.mul_zero]
    calc natPowSum (k + 1) 1 = natPowSum (k + 1) 0 + 0 ^ (k + 1) := rfl
      _ = natPowSum (k + 1) 0 + 0 := by rw [h]
      _ = 0 := rfl
  rw [hnps]
  show ((0 : Nat) : Int) * ((1 : Nat) : Int) = (0 : Int) * (((1 : Nat) ^ ((k + 1) + 1) : Nat) : Int)
  rw [Int.ofNat_zero, Int.zero_mul, Int.zero_mul]

/-- The telescoped dyadic sum of the power test at cutoff `M`. -/
theorem genSum_powTest_eval (k M : Nat) :
    Req (genSum (dyadicTerm (powTest (k + 1)).f) M)
      (ofQ (⟨((natPowSum (k + 1) (2 ^ M - 1 + 1) : Nat) : Int), (2 ^ M - 1 + 1) ^ ((k + 1) + 1)⟩ : Q)
        (Nat.pos_pow_of_pos ((k + 1) + 1) (Nat.succ_pos _))) := by
  refine Req_trans (genSum_telescope (powTest (k + 1)).f M) ?_
  refine Req_trans (Rsub_congr (riemannSum_powTest (k + 1) (2 ^ M - 1)) (powTest_dyadicR0 k)) ?_
  refine Req_trans (Radd_congr (Req_refl _) ?_) (Radd_zero _)
  exact Req_trans (Rneg_congr (Req_refl zero))
    (Req_trans (Req_symm (Radd_zero (Rneg zero)))
      (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero)))

/-- The rate, general in the Lipschitz datum. -/
theorem genSum_powTest_rate (k : Nat) (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm (powTest (k + 1)).f) (digammaMidx L j))
        (ofQ (⟨1, k + 2⟩ : Q) (Nat.succ_pos (k + 1)))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (genSum_powTest_eval k (digammaMidx L j))
    (Req_refl _)))) ?_
  refine powSum_defect_le (k + 1) (2 ^ (digammaMidx L j) - 1) j ?_
  have hp : j + 1 ≤ 2 ^ (digammaMidx L j) := by
    have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
    have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
      refine Nat.pow_le_pow_right (by decide) ?_
      show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
      have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
        Nat.mul_le_mul_right (j + 1) (by omega)
      omega
    omega
  have he : 2 ^ (digammaMidx L j) - 1 + 1 = 2 ^ (digammaMidx L j) :=
    Nat.sub_add_cancel Nat.one_le_two_pow
  omega

/-- **`∫₀¹ clamp01(x)^(k+1) dx ≈ 1/(k+2)`** — the certified integral of every positive power. -/
theorem riemannIntegral_powTest_succ (k : Nat) :
    Req (riemannIntegral (powTest (k + 1)).hLd (powTest (k + 1)).hLn
        (powTest (k + 1)).hlip (powTest (k + 1)).hfc) (ofQ (⟨1, k + 2⟩ : Q) (Nat.succ_pos (k + 1))) := by
  show Req (Radd (dyadicR (powTest (k + 1)).f 0) _) (ofQ (⟨1, k + 2⟩ : Q) (Nat.succ_pos (k + 1)))
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm (powTest (k + 1)).f)
      (digammaMidx (powTest (k + 1)).L j))
      (dyadicSum_RReg (powTest (k + 1)).hLd (powTest (k + 1)).hLn
        (powTest (k + 1)).hlip (powTest (k + 1)).hfc))
      (ofQ (⟨1, k + 2⟩ : Q) (Nat.succ_pos (k + 1))) :=
    Rlim_eval _ (Nat.succ_pos (k + 1)) (fun j => genSum_powTest_rate k (powTest (k + 1)).L j)
  refine Req_trans (Radd_congr (powTest_dyadicR0 k) hlim) ?_
  exact Req_trans (Radd_comm zero (ofQ (⟨1, k + 2⟩ : Q) (Nat.succ_pos (k + 1))))
    (Radd_zero (ofQ (⟨1, k + 2⟩ : Q) (Nat.succ_pos (k + 1))))

/-- **THE HAUSDORFF MOMENT LAW**: `mellinMoment clampTest n ≈ 1/(n+2)` for EVERY `n` — the
    clamp's moment sequence is the full Hausdorff moment data of Lebesgue measure on `[0,1]`,
    subsuming the five per-degree engines. -/
theorem mellinMoment_clamp_general (n : Nat) :
    Req (mellinMoment clampTest n) (ofQ (⟨1, n + 2⟩ : Q) (Nat.succ_pos (n + 1))) := by
  have hdist : ∀ x, Req (Rmul (clampTest.f x) ((powTest n).f x)) ((powTest (n + 1)).f x) :=
    fun x => Rmul_comm (clamp01 x) ((powTest n).f x)
  have hlipS : ∀ x y, Rle (Rabs (Rsub ((powTest (n + 1)).f x) ((powTest (n + 1)).f y)))
      (Rmul (ofQ (l2L clampTest (powTest n)) (l2L_den clampTest (powTest n)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x)) (Req_symm (hdist y)))))
      (l2lip clampTest (powTest n) x y)
  have hfcS : ∀ x y, Req x y → Req ((powTest (n + 1)).f x) ((powTest (n + 1)).f y) :=
    fun x y h => (powTest (n + 1)).hfc x y h
  refine Req_trans (riemannIntegral_congr (g := (powTest (n + 1)).f)
    (l2L_den clampTest (powTest n)) (l2L_num clampTest (powTest n))
    (l2lip clampTest (powTest n)) (l2fc clampTest (powTest n)) hlipS hfcS hdist) ?_
  refine Req_trans (riemannIntegral_certif_irrel
    (l2L_den clampTest (powTest n)) (l2L_num clampTest (powTest n)) hlipS hfcS
    (powTest (n + 1)).hLd (powTest (n + 1)).hLn (powTest (n + 1)).hlip (powTest (n + 1)).hfc) ?_
  exact riemannIntegral_powTest_succ n

end Multiplicity.UOR.Bridge.F1Square.Square
