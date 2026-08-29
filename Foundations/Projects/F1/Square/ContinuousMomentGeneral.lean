/-
F1 square — **the pre-Hilbert layer, brick 104** (`ContinuousMomentGeneral.lean`): **the compact power
at exponent `1` is the identity for GENERAL real `t`** — `compactPow a 1 t ≈ t` for every real
`t ∈ [a,1]`, lifting the rational-point value (brick 102) to all reals by density.

The doc flagged the `t^s` identification as holding "at every rational point of `(a,1]` but not for
general real `t`". This closes the `s = 1` case: `compactPow a 1` is Lipschitz (brick 93) and equals `q`
at every rational `q ∈ [a,1]` (brick 102), so for any real `t ∈ [a,1]` the clamped rational sample
`qN = clamp(t.seq N, [a,1])` is within `1/(N+1)` of `t` (`band_approx_close`, via the `1`-Lipschitz band
projection `qBandQ`) and carries the value: `|compactPow a 1 t − t| ≤ (L+1)/(N+1) → 0` (Archimedean
collapse `Rle_of_Rsub_le_eps`). No `exp∘log` inverse is used — the density route goes entirely through
the rational values. The per-sample estimate is factored through `step_bound` with an ABSTRACT rational
`q` to keep the `whnf` elaboration off the nested `Qmin(Qmax …)` term.

HONEST SCOPE. The general-real identification at `s = 1` on `[a,1]`. The general-`s` real-`t` case
iterates the power law on this (bricks 99/103); the `a → 0` limit is still separate. No transform pair,
no inversion, no positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentOne
import Foundations.F1.Analysis.BandClamp
import Foundations.F1.Analysis.RSeqApprox

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Telescoping: `A − C ≈ (A − B) + (B − C)`. -/
private theorem sub_telescope (A B C : Real) : Req (Rsub A C) (Radd (Rsub A B) (Rsub B C)) := by
  refine Req_symm (Req_trans (Radd_assoc A (Rneg B) (Radd B (Rneg C))) ?_)
  refine Req_trans (Radd_congr (Req_refl A) (Req_symm (Radd_assoc (Rneg B) B (Rneg C)))) ?_
  refine Req_trans (Radd_congr (Req_refl A)
    (Radd_congr (Req_trans (Radd_comm (Rneg B) B) (Radd_neg B)) (Req_refl (Rneg C)))) ?_
  exact Radd_congr (Req_refl A) (Req_trans (Radd_comm zero (Rneg C)) (Radd_zero (Rneg C)))

/-- **The per-sample estimate** (abstract rational `q ∈ [a,1]`): `|compactPow a 1 t − t| ≤ L·|t−q| + |t−q|`,
    via the telescope through `compactPow a 1 q ≈ q` (brick 102) and the compact-power Lipschitz bound
    (brick 93). Abstracting `q` keeps `whnf` off the nested clamp term. -/
theorem step_bound (a : Q) (han : 0 < a.num) (had : 0 < a.den) (q : Q) (hqd : 0 < q.den)
    (hqn : 0 < q.num) (hqa : Qle a q) (hq1 : Qle q (⟨1, 1⟩ : Q)) (t : Real) :
    Rle (Rabs (Rsub (compactPow a han had one t) t))
        (Radd (Rmul (ofQ (compactPowL a (⟨1, 1⟩ : Q)) (compactPowL_den a (⟨1, 1⟩ : Q) (by decide) han))
                    (Rabs (Rsub t (ofQ q hqd))))
              (Rabs (Rsub t (ofQ q hqd)))) := by
  have h102 := compactPow_ofQ_one a han had q hqd hqn hqa hq1
  have hlip := compactPow_lipschitz a han had Rnonneg_one (⟨1, 1⟩ : Q) (by decide) (Rle_refl one)
    t (ofQ q hqd)
  have hterm2 : Req (Rabs (Rsub (compactPow a han had one (ofQ q hqd)) t))
      (Rabs (Rsub t (ofQ q hqd))) :=
    Req_trans (Rabs_congr (Rsub_congr h102 (Req_refl t)))
      (Req_trans (Rabs_congr (Req_symm (Rneg_Rsub t (ofQ q hqd)))) (Rabs_Rneg _))
  refine Rle_trans (Rle_of_Req (Rabs_congr (sub_telescope (compactPow a han had one t)
    (compactPow a han had one (ofQ q hqd)) t))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  exact Radd_le_add hlip (Rle_of_Req hterm2)

/-- **The clamped rational approximant is close**: for `t ∈ [a,1]`, `qN = clamp(t.seq N,[a,1])` satisfies
    `|t − qN| ≤ 1/(N+1)`. Via the `1`-Lipschitz band projection `qBandQ` (inert on `[a,1]`). -/
theorem band_approx_close (a : Q) (had : 0 < a.den) (t : Real) (hlo : Rle (ofQ a had) t)
    (hhi : Rle t one) (N : Nat) :
    Rle (Rabs (Rsub t (ofQ (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q))
          (Qmin_den_pos (Qmax_den_pos (t.den_pos N) had) (by decide)))))
        (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) := by
  have hqNd : 0 < (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).den :=
    Qmin_den_pos (Qmax_den_pos (t.den_pos N) had) (by decide)
  have hbridge : Req (qBandQ a (⟨1, 1⟩ : Q) had (by decide) (ofQ (t.seq N) (t.den_pos N)))
      (ofQ (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)) hqNd) := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  have hbt : Req (qBandQ a (⟨1, 1⟩ : Q) had (by decide) t) t := qBandQ_eq_of_band hlo hhi
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm hbt) (Req_symm hbridge)))) ?_
  refine Rle_trans (qBandQ_lipschitz a (⟨1, 1⟩ : Q) had (by decide) t (ofQ (t.seq N) (t.den_pos N))) ?_
  exact Rabs_sub_seq_le t N

/-- Positivity of the clamp numerator (`qN ≥ a > 0`). -/
private theorem clampQ_num_pos (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) (N : Nat)
    (ha1 : Qle a (⟨1, 1⟩ : Q)) :
    0 < (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).num := by
  have hqNd : 0 < (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).den :=
    Qmin_den_pos (Qmax_den_pos (t.den_pos N) had) (by decide)
  have hqNa : Qle a (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)) := Qle_Qmin (Qmax_ge_right (t.seq N) a) ha1
  have h := hqNa; simp only [Qle] at h
  have hqd2 : (0 : Int) < ((Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).den : Int) := by exact_mod_cast hqNd
  have hpos : 0 < a.num * ((Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).den : Int) := Int.mul_pos han hqd2
  have h2 : 0 < (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).num * (a.den : Int) := by omega
  have hdd : (0 : Int) < (a.den : Int) := by exact_mod_cast had
  rcases Int.lt_trichotomy (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).num 0 with hn | h0 | hp
  · exfalso; have := Int.mul_neg_of_neg_of_pos hn hdd; omega
  · exfalso; rw [h0] at h2; simp at h2
  · exact hp

set_option maxHeartbeats 1600000 in
/-- **★ `compactPow a 1 t ≈ t` for GENERAL real `t ∈ [a,1]`** — the `s = 1` `t^s` identification at every
    real point, by density from the rational value (brick 102) + Lipschitz + Archimedean collapse. -/
theorem compactPow_one_general (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (t : Real) (hlo : Rle (ofQ a had) t) (hhi : Rle t one) :
    Req (compactPow a han had one t) t := by
  have hLd : 0 < (compactPowL a (⟨1, 1⟩ : Q)).den := compactPowL_den a (⟨1, 1⟩ : Q) (by decide) han
  have hLn : 0 ≤ (compactPowL a (⟨1, 1⟩ : Q)).num := compactPowL_num a (⟨1, 1⟩ : Q) (by decide) had
  have hLtot_d : 0 < (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).den := add_den_pos hLd (by decide)
  have key : ∀ N : Nat, Rle (Rabs (Rsub (compactPow a han had one t) t))
      (ofQ (mul (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)) (⟨1, N + 1⟩ : Q))
        (Qmul_den_pos hLtot_d (Nat.succ_pos N))) := by
    intro N
    have hqNd : 0 < (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).den :=
      Qmin_den_pos (Qmax_den_pos (t.den_pos N) had) (by decide)
    have hqNa : Qle a (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)) := Qle_Qmin (Qmax_ge_right (t.seq N) a) ha1
    have hqN1 : Qle (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q) := Qmin_le_right _ _
    have hqNn : 0 < (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)).num := clampQ_num_pos a han had t N ha1
    have hdist := band_approx_close a had t hlo hhi N
    refine Rle_trans (step_bound a han had (Qmin (Qmax (t.seq N) a) (⟨1, 1⟩ : Q)) hqNd hqNn hqNa hqN1 t) ?_
    refine Rle_trans (Radd_le_add (Rmul_le_Rmul_left (Rnonneg_ofQ hLd hLn) hdist) hdist) ?_
    refine Rle_trans (Rle_of_Req (Radd_congr (Rmul_ofQ_ofQ hLd (Nat.succ_pos N)) (Req_refl _))) ?_
    refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _)
      (Req_symm (Rone_mul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)))))) ?_
    refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Qmul_den_pos hLd (Nat.succ_pos N))
      (Qmul_den_pos (by decide) (Nat.succ_pos N))) ?_)
    exact ofQ_congr (add_den_pos (Qmul_den_pos hLd (Nat.succ_pos N))
      (Qmul_den_pos (by decide) (Nat.succ_pos N))) (Qmul_den_pos hLtot_d (Nat.succ_pos N))
      (by simp only [Qeq, mul, add]; push_cast; ring_uor)
  have habs0 : Rle (Rabs (Rsub (compactPow a han had one t) t)) zero := by
    refine Rle_of_Rsub_le_eps (C := (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num.toNat)
      (fun k => ?_)
    refine Rle_trans (Rle_of_Req (Rsub_zero _)) (Rle_trans (key k) ?_)
    refine Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_
    have hnum : (((add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num.toNat : Nat) : Int)
        = (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num := by
      refine Int.toNat_of_nonneg ?_
      show (0 : Int) ≤ (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num
      simp only [add]; push_cast; omega
    show (mul (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)) (⟨1, k + 1⟩ : Q)).num * ((k + 1 : Nat) : Int)
        ≤ (((add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num.toNat : Nat) : Int)
          * ((mul (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)) (⟨1, k + 1⟩ : Q)).den : Int)
    rw [hnum]; simp only [mul]; push_cast
    have hd1 : (1 : Int) ≤ ((add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).den : Int) := by
      have := hLtot_d; omega
    have hLtn : (0 : Int) ≤ (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num := by
      simp only [add]; push_cast; omega
    have hprod : (0 : Int) ≤ (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num * ((k : Int) + 1) :=
      Int.mul_nonneg hLtn (by omega)
    have hstep := Int.mul_le_mul_of_nonneg_left hd1 hprod
    calc (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num * 1 * ((k : Int) + 1)
        = (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num * ((k : Int) + 1) * 1 := by ring_uor
      _ ≤ (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num * ((k : Int) + 1)
            * ((add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).den : Int) := hstep
      _ = (add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).num
            * (((add (compactPowL a (⟨1, 1⟩ : Q)) (⟨1, 1⟩ : Q)).den : Int) * ((k : Int) + 1)) := by ring_uor
  have hz : Req (Rabs (Rsub (compactPow a han had one t) t)) zero :=
    Rle_antisymm habs0 (Rle_zero_of_Rnonneg (Rnonneg_Rabs _))
  have hsub0 : Req (Rsub (compactPow a han had one t) t) zero := by
    refine Rle_antisymm (Rle_trans (Rle_Rabs_self _) (Rle_of_Req hz)) ?_
    have hneg : Rle (Rneg (Rsub (compactPow a han had one t) t)) zero :=
      Rle_trans (Rle_Rabs_self _) (Rle_of_Req (Req_trans (Rabs_Rneg _) hz))
    refine Rle_trans (Rle_of_Req (Req_symm Rneg_zero)) ?_
    exact Rle_trans (Rle_Rneg hneg) (Rle_of_Req (Rneg_neg _))
  exact Req_of_Rsub_zero hsub0

end Multiplicity.UOR.Bridge.F1Square.Square
