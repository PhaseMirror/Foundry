/-
F1 square — **exhaustion-independence of the improper half-line integral** (exhaustion rung 4b).

The certified improper Mellin integral `∫₁^∞ f = improperIntegral1` is defined as the Bishop limit of
the reindexed partial sums `genSum (integralTerm ..) (digammaMidx K j)` — the `digammaMidx K` schedule
is one particular cofinal integer exhaustion of the half-line. This file proves that the *value* does
not depend on that choice: **any** integer schedule `R : ℕ → ℕ` that grows at least as fast as
`digammaMidx K` (`digammaMidx K j ≤ R j`) yields the *same* `Rlim` as `improperIntegral1`.

The engine is the committed telescoping tail bound `genTail_two_sided`: for `A ≥ B ≥ 1` the real gap
`genSum T A − genSum T B` is the range sum `Σ_{i<A−B} T(B+i)`, bounded by `±ofQ(digammaTailQ K B (A−B))`
and hence (by `digammaTailQ_Midx_le`) by `ofQ ⟨1, j+1⟩` when `B = digammaMidx K j`. So the two schedules
are within `1/(j+1)` at every index `j`, and a diagonal Archimedean argument (`Qarch_gen`) over the
`Rlim` diagonal `4n+3`, packaged once as `Rlim_approx_eq`, equates the limits via `Req_of_lin_bound`.

The growth hypothesis `hgrow` is load-bearing and honest: `RTendsTo` carries a *fixed* canonical modulus
`2/(k+1)`, which the raw partial sums (tail rate `K/N`) meet only once the schedule is accelerated to
grow at least as fast as `digammaMidx K`; without `hgrow` the acceleration fails for general `K`.

HONEST SCOPE. Exhaustion-independence of the improper integral — any integer schedule growing at least
as fast as `digammaMidx K` yields the same `Rlim` as `improperIntegral1`, via the committed tail bound
`genTail_two_sided` and the `Req`/`Rlim` machinery, so the improper Mellin integral is
schedule-independent. It builds NO dilation covariance, NO factorization, NO positivity, NO determinacy,
NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay none.
Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.ImproperIntegral
import Multiplicity.F1Square.Analysis.ThetaLipschitz

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **Seq-level gap from a real gap** — if `|P − Q| ≤ ofQ ⟨C, N+1⟩` as reals, then the raw rational
    approximants at index `N` satisfy `|P_N − Q_N| ≤ ⟨C+2, N+1⟩`. Routes through the intermediate index
    `2m+1` (where the real hypothesis reads its arguments) with two `Qabs_sub_triangle` steps, absorbing
    the two regularity slacks and the `2/(m+1)` real-comparison modulus into a `3/(m+1)` tail that the
    Archimedean lemma `Qarch_gen` discards; the residual `C/(N+1)` plus the two `1/(N+1)` regularity
    terms collapse to `(C+2)/(N+1)`. -/
theorem seq_gap_bound (P V : Real) {C N : Nat}
    (hb : Rle (Rabs (Rsub P V)) (ofQ (⟨(C : Int), N + 1⟩ : Q) (Nat.succ_pos N))) :
    Qle (Qabs (Qsub (P.seq N) (V.seq N))) (⟨(C : Int) + 2, N + 1⟩ : Q) := by
  refine Qarch_gen (C := 3)
    (Qabs_den_pos (Qsub_den_pos (P.den_pos N) (V.den_pos N))) (Nat.succ_pos N) (fun m => ?_)
  have hmid : Qle (Qabs (Qsub (P.seq (2 * m + 1)) (V.seq (2 * m + 1))))
      (add (⟨(C : Int), N + 1⟩ : Q) ⟨2, m + 1⟩) := hb m
  have hP := P.reg N (2 * m + 1)
  have hV := V.reg (2 * m + 1) N
  have t1 := Qabs_sub_triangle (a := P.seq N) (b := P.seq (2 * m + 1)) (c := V.seq N)
    (P.den_pos N) (P.den_pos (2 * m + 1)) (V.den_pos N)
  have t2 := Qabs_sub_triangle (a := P.seq (2 * m + 1)) (b := V.seq (2 * m + 1)) (c := V.seq N)
    (P.den_pos (2 * m + 1)) (V.den_pos (2 * m + 1)) (V.den_pos N)
  have c2 := Qle_trans
    (add_den_pos (Qabs_den_pos (Qsub_den_pos (P.den_pos (2 * m + 1)) (V.den_pos (2 * m + 1))))
      (Qabs_den_pos (Qsub_den_pos (V.den_pos (2 * m + 1)) (V.den_pos N))))
    t2 (Qadd_le_add hmid hV)
  have c1 := Qle_trans
    (add_den_pos (Qabs_den_pos (Qsub_den_pos (P.den_pos N) (P.den_pos (2 * m + 1))))
      (Qabs_den_pos (Qsub_den_pos (P.den_pos (2 * m + 1)) (V.den_pos N))))
    t1 (Qadd_le_add hP c2)
  have hregroup : Qeq
      (add (add (Qbound N) (Qbound (2 * m + 1)))
        (add (add (⟨(C : Int), N + 1⟩ : Q) ⟨2, m + 1⟩) (add (Qbound (2 * m + 1)) (Qbound N))))
      (add (⟨(C : Int) + 2, N + 1⟩ : Q) ⟨3, m + 1⟩) := by
    simp only [Qeq, add, Qbound, neg]; push_cast; ring_uor
  exact Qle_trans
    (add_den_pos (add_den_pos (Qbound_den_pos N) (Qbound_den_pos (2 * m + 1)))
      (add_den_pos (add_den_pos (Nat.succ_pos N) (Nat.succ_pos m))
        (add_den_pos (Qbound_den_pos (2 * m + 1)) (Qbound_den_pos N))))
    c1 (Qeq_le hregroup)

/-- **Approximate limit-equality** — if two regular sequences of reals are within `C/(j+1)` at every
    index `j` (`Rabs (X j − Y j) ≤ ofQ ⟨C, j+1⟩`), their Bishop limits are equal. Both diagonals sit at
    `4n+3`, so `seq_gap_bound` gives `|X_{4n+3} − Y_{4n+3}| ≤ (C+2)/(4n+4) ≤ (C+2)/(n+1)`, which
    `Req_of_lin_bound` turns into `≈`. The `_of_approx`-style congruence that a *rate* (not exact
    termwise equality) suffices to identify limits. -/
theorem Rlim_approx_eq (X Y : Nat → Real) (hX : RReg X) (hY : RReg Y) {C : Nat}
    (hclose : ∀ j, Rle (Rabs (Rsub (X j) (Y j))) (ofQ (⟨(C : Int), j + 1⟩ : Q) (Nat.succ_pos j))) :
    Req (Rlim X hX) (Rlim Y hY) := by
  refine Req_of_lin_bound (C := C + 2) (fun n => ?_)
  have hgap := seq_gap_bound (X (4 * n + 3)) (Y (4 * n + 3)) (C := C) (N := 4 * n + 3)
    (hclose (4 * n + 3))
  have hmono : Qle (⟨(C : Int) + 2, 4 * n + 3 + 1⟩ : Q) (⟨((C + 2 : Nat) : Int), n + 1⟩ : Q) := by
    show ((C : Int) + 2) * ((n + 1 : Nat) : Int) ≤ ((C + 2 : Nat) : Int) * ((4 * n + 3 + 1 : Nat) : Int)
    push_cast
    have h1 : (n : Int) + 1 ≤ 4 * (n : Int) + 3 + 1 := by omega
    have h2 : (0 : Int) ≤ (C : Int) + 2 := by have := Int.ofNat_nonneg C; omega
    exact Int.mul_le_mul_of_nonneg_left h1 h2
  exact Qle_trans (Nat.succ_pos _) hgap hmono

/-- **Per-index schedule closeness** — for the generic decay term `T` with `|T m| ≤ K/((m+1)m)`, the
    faster schedule `R` and the canonical `digammaMidx K` schedule agree within `1/(j+1)` at index `j`:
    `Rabs (genSum T (R j) − genSum T (digammaMidx K j)) ≤ ofQ ⟨1, j+1⟩`. The gap is a range sum
    (`genSum_diff_eq`) bounded two-sidedly by the telescoping tail (`genTail_two_sided`), whose value at
    a `digammaMidx K j` start is `≤ 1/(j+1)` (`digammaTailQ_Midx_le`). -/
theorem genSum_close (T : Nat → Real) {K : Q} (hKd : 0 < K.den) (hK0 : 0 ≤ K.num)
    (hb : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm)))) (T m)
      ∧ Rle (T m) (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
    (R : Nat → Nat) (hgrow : ∀ j, digammaMidx K j ≤ R j) (j : Nat) :
    Rle (Rabs (Rsub (genSum T (R j)) (genSum T (digammaMidx K j))))
        (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hN : 1 ≤ digammaMidx K j := digammaMidx_ge_one K j
  obtain ⟨d, hd⟩ : ∃ d, R j = digammaMidx K j + d :=
    ⟨R j - digammaMidx K j, (Nat.add_sub_cancel' (hgrow j)).symm⟩
  have hdiff := genSum_diff_eq T (digammaMidx K j) d
  rw [← hd] at hdiff
  obtain ⟨hlo, hhi⟩ := genTail_two_sided T hKd hb hN d
  have hneg : Rle (Rneg (digammaRsum (fun i => T (digammaMidx K j + i)) d))
      (ofQ (digammaTailQ K (digammaMidx K j) d hN)
        (digammaTailQ_den_pos K (digammaMidx K j) d hN hKd)) :=
    Rle_trans (Rle_Rneg hlo) (Rle_of_Req (Rneg_neg _))
  have hRabsD : Rle (Rabs (digammaRsum (fun i => T (digammaMidx K j + i)) d))
      (ofQ (digammaTailQ K (digammaMidx K j) d hN)
        (digammaTailQ_den_pos K (digammaMidx K j) d hN hKd)) :=
    Rabs_le_of_both hhi hneg
  refine Rle_trans (Rle_of_Req (Rabs_congr hdiff)) (Rle_trans hRabsD ?_)
  exact Rle_ofQ_ofQ (digammaTailQ_den_pos K (digammaMidx K j) d hN hKd) (Nat.succ_pos j)
    (digammaTailQ_Midx_le K hKd hK0 j d)

/-- **Exhaustion-independence of `∫₁^∞ f`** — any integer schedule `R` with `digammaMidx K j ≤ R j`
    yields the same Bishop limit as `improperIntegral1`. The two schedules are within `1/(j+1)` at every
    index (`genSum_close`), so their limits coincide (`Rlim_approx_eq`). The improper Mellin integral is
    thus schedule-independent — it depends only on the integrand's decay data, not on the chosen
    cofinal exhaustion. -/
theorem improper_schedule_eq {f : Real → Real} {L K : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hKd : 0 < K.den) (hK0 : 0 ≤ K.num)
    (hb : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
          (integralTerm hLd hLn hlip hfc m)
      ∧ Rle (integralTerm hLd hLn hlip hfc m)
          (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
    (R : Nat → Nat) (hgrow : ∀ j, digammaMidx K j ≤ R j)
    (hRegR : RReg (fun j => genSum (integralTerm hLd hLn hlip hfc) (R j))) :
    Req (Rlim (fun j => genSum (integralTerm hLd hLn hlip hfc) (R j)) hRegR)
        (improperIntegral1 hLd hLn hlip hfc hKd hK0 hb) :=
  Rlim_approx_eq (C := 1)
    (fun j => genSum (integralTerm hLd hLn hlip hfc) (R j))
    (fun j => genSum (integralTerm hLd hLn hlip hfc) (digammaMidx K j))
    hRegR
    (genSum_RReg (integralTerm hLd hLn hlip hfc) hKd hK0 hb)
    (fun j => genSum_close (integralTerm hLd hLn hlip hfc) hKd hK0 hb R hgrow j)

end Multiplicity.UOR.Bridge.F1Square.Square
