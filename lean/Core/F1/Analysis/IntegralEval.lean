/-
F1 square — certified integration, **the evaluation layer**: `Rlim_eval` (a rate-convergent
Bishop limit evaluates exactly) and **`∫₀¹ x dx ≈ 1/2`** (`riemannIntegral_id`) — the first
NON-CONSTANT certified integral evaluation in the substrate.

WHY (Sonine route, steps 1–2). The Weil pairing's two interface fields (`WeilSlot.poles`,
`WeilSlot.archTail`) are integrals whose piecewise-polynomial closed forms are "routine but
unverified in print" (`Weil.lean`); transcribing them would breach the gate, so they must be
REDUCED in the kernel. The reduction bottoms out in evaluating the gateway's integrals on
explicit integrands, and the gateway had only `riemannIntegral_const`. This file supplies the
two missing engines:

- `Rlim_eval` — if every `X j` sits within `1/(j+1)` of a rational `c` (a real `Rle` on
  `Rabs (Rsub (X j) (ofQ c))`), then `Rlim X ≈ ofQ c`. Proof at the diagonal: the limit's
  `n`-th approximant is `(X (4n+3)).seq (4n+3)`, and the rate hypothesis at index `m = 2n+1`
  lands the `Radd`-inflated sample exactly there (`2(2n+1)+1 = 4n+3`), giving the linear
  bound `1/(4n+4) + 2/(2n+2) ≤ 2/(n+1)` that `Req_of_lin_bound` consumes.
- `riemannSum_id` — the left Riemann sum of the identity is the Gauss value
  `N/(2(N+1))` (the `Σ i` fold evaluated at the `ℚ` level, `sumIota`).
- **`riemannIntegral_id`** — `D₀ = 0` and the telescoped dyadic sums sit within
  `1/(2·2^M)` of `1/2` (`M = digammaMidx 1 j = 2(j+1)`, so the rate `1/(j+1)` holds), hence
  the limit is `1/2` by `Rlim_eval`.

Downstream (`WeilSlotLinear.lean`): with `_const`, `_add`, `_smul`, and `_id`, every
piecewise-LINEAR integrand evaluates in closed form over any rational interval — exactly the
stratum Bombieri's admissible class needs for the tent tests.

HONEST SCOPE. An integration-substrate brick on the crux route's step 1; no positivity, no
crux claim. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.IntervalIntegral

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The limit-evaluation engine.
-- ===========================================================================

/-- **A rate-convergent Bishop limit evaluates exactly**: if every `X j` is within `1/(j+1)`
    of the rational `c` (as reals), the limit IS `ofQ c`. -/
theorem Rlim_eval {X : Nat → Real} (hX : RReg X) {c : Q} (hc : 0 < c.den)
    (hrate : ∀ j, Rle (Rabs (Rsub (X j) (ofQ c hc)))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) :
    Req (Rlim X hX) (ofQ c hc) := by
  refine Req_of_lin_bound (C := 2) (fun n => ?_)
  have h := hrate (4 * n + 3) (2 * n + 1)
  have hshape : Qle (Qabs (Qsub ((X (4 * n + 3)).seq (2 * (2 * n + 1) + 1)) c))
      (add (⟨1, 4 * n + 3 + 1⟩ : Q) (⟨2, 2 * n + 1 + 1⟩ : Q)) := h
  have hidx : 2 * (2 * n + 1) + 1 = 4 * n + 3 := by omega
  rw [hidx] at hshape
  refine Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) hshape ?_
  -- `1/(4n+4) + 2/(2n+2) ≤ 2/(n+1)`: the difference clears to `6(n+1)² ≥ 0`.
  show Qle (add (⟨1, 4 * n + 3 + 1⟩ : Q) (⟨2, 2 * n + 1 + 1⟩ : Q)) (⟨2, n + 1⟩ : Q)
  show (1 * ((2 * n + 1 + 1 : Nat) : Int) + 2 * ((4 * n + 3 + 1 : Nat) : Int))
      * ((n + 1 : Nat) : Int)
    ≤ 2 * (((4 * n + 3 + 1) * (2 * n + 1 + 1) : Nat) : Int)
  push_cast
  have hsq : (0 : Int) ≤ ((n : Int) + 1) * ((n : Int) + 1) :=
    Int.mul_nonneg (by omega) (by omega)
  have hd6 : 2 * (((4 : Int) * n + 3 + 1) * (2 * n + 1 + 1))
      - (1 * (2 * (n : Int) + 1 + 1) + 2 * (4 * n + 3 + 1)) * (n + 1)
      = 6 * (((n : Int) + 1) * ((n : Int) + 1)) := by ring_uor
  omega

-- ===========================================================================
-- The identity integrand: Lipschitz datum and the Gauss sum.
-- ===========================================================================

/-- The identity is `1`-Lipschitz. -/
theorem lip_id : ∀ x y : Real,
    Rle (Rabs (Rsub x y)) (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  exact Rle_of_Req (Req_symm (Req_trans
    (Rmul_comm (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y)))
    (Rmul_one (Rabs (Rsub x y)))))

/-- The identity respects `≈`. -/
theorem congr_id : ∀ x y : Real, Req x y → Req x y := fun _ _ h => h

/-- **The `ℚ`-level Gauss fold**: `Σ_{i<k} i/(N+1) ≈ k(k−1)/(2(N+1))`. -/
theorem sumIota (N : Nat) : ∀ k : Nat,
    Req (RsumN (fun i => ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)) k)
      (ofQ (⟨(k : Int) * ((k : Int) - 1), 2 * (N + 1)⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.succ_pos N))) := by
  intro k
  induction k with
  | zero =>
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (⟨(0 : Int) * ((0 : Int) - 1), 2 * (N + 1)⟩ : Q)
      simp only [Qeq]; push_cast; ring_uor)
  | succ k ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos N))
      (Nat.succ_pos N)) ?_
    refine ofQ_congr (add_den_pos (Nat.mul_pos (by decide) (Nat.succ_pos N))
      (Nat.succ_pos N)) (Nat.mul_pos (by decide) (Nat.succ_pos N)) ?_
    show Qeq (add (⟨(k : Int) * ((k : Int) - 1), 2 * (N + 1)⟩ : Q)
      (⟨(k : Int), N + 1⟩ : Q)) (⟨((k + 1 : Nat) : Int) * (((k + 1 : Nat) : Int) - 1),
        2 * (N + 1)⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor

/-- **The left Riemann sum of the identity is the Gauss value** `N/(2(N+1))`. -/
theorem riemannSum_id (N : Nat) :
    Req (riemannSum (fun x => x) N)
      (ofQ (⟨(N : Int), 2 * (N + 1)⟩ : Q) (Nat.mul_pos (by decide) (Nat.succ_pos N))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _) (sumIota N (N + 1))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N)
    (Nat.mul_pos (by decide) (Nat.succ_pos N))) ?_
  refine ofQ_congr (Qmul_den_pos (Nat.succ_pos N)
    (Nat.mul_pos (by decide) (Nat.succ_pos N)))
    (Nat.mul_pos (by decide) (Nat.succ_pos N)) ?_
  show Qeq (mul (⟨1, N + 1⟩ : Q) (⟨((N + 1 : Nat) : Int) * (((N + 1 : Nat) : Int) - 1),
    2 * (N + 1)⟩ : Q)) (⟨(N : Int), 2 * (N + 1)⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

-- ===========================================================================
-- The evaluation ∫₀¹ x dx ≈ 1/2.
-- ===========================================================================

/-- `ofQ ⟨0, d⟩ ≈ 0` for any positive denominator. -/
theorem ofQ_zero_num {d : Nat} (hd : 0 < d) : Req (ofQ (⟨0, d⟩ : Q) hd) zero :=
  Req_of_seq_Qeq (fun _ => by show Qeq (⟨0, d⟩ : Q) (⟨0, 1⟩ : Q); simp only [Qeq]; push_cast; ring_uor)

/-- The telescoped dyadic sum of the identity at cutoff `M` is `1/2 − 1/(2·2^M)` (as the
    explicit rational `(2^M − 1)/(2·2^M)` with the `−1+1` denominator normalization). -/
theorem genSum_id_eval (M : Nat) :
    Req (genSum (dyadicTerm (fun x => x)) M)
      (ofQ (⟨((2 ^ M - 1 : Nat) : Int), 2 * (2 ^ M - 1 + 1)⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.succ_pos _))) := by
  refine Req_trans (genSum_telescope (fun x => x) M) ?_
  have hM : Req (dyadicR (fun x => x) M)
      (ofQ (⟨((2 ^ M - 1 : Nat) : Int), 2 * (2 ^ M - 1 + 1)⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.succ_pos _))) := riemannSum_id (2 ^ M - 1)
  have h0 : Req (dyadicR (fun x => x) 0) zero :=
    Req_trans (riemannSum_id (2 ^ 0 - 1)) (ofQ_zero_num _)
  refine Req_trans (Rsub_congr hM h0) ?_
  refine Req_trans (Radd_congr (Req_refl _) ?_) (Radd_zero _)
  exact Req_trans (Rneg_congr (Req_refl zero))
    (Req_trans (Req_symm (Radd_zero (Rneg zero)))
      (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero)))

/-- The rational defect: `|(2^M−1)/(2(2^M−1+1)) − 1/2| ≤ 1/(j+1)` whenever `j + 1 ≤ 2^M`. -/
theorem gauss_defect_le {M j : Nat} (hj : j + 1 ≤ 2 ^ M) :
    Rle (Rabs (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int), 2 * (2 ^ M - 1 + 1)⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.succ_pos _))) (ofQ (⟨1, 2⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hcol : Req (Rsub (ofQ (⟨((2 ^ M - 1 : Nat) : Int), 2 * (2 ^ M - 1 + 1)⟩ : Q)
      (Nat.mul_pos (by decide) (Nat.succ_pos _))) (ofQ (⟨1, 2⟩ : Q) (by decide)))
      (ofQ (add (⟨((2 ^ M - 1 : Nat) : Int), 2 * (2 ^ M - 1 + 1)⟩ : Q) (neg (⟨1, 2⟩ : Q)))
        (add_den_pos (Nat.mul_pos (by decide) (Nat.succ_pos _)) (by decide))) := by
    refine Req_trans (Radd_congr (Req_refl _)
      (Rneg_ofQ (⟨1, 2⟩ : Q) (by decide))) ?_
    exact Radd_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos _)) (by decide)
  refine Rle_trans (Rle_of_Req (Rabs_congr hcol)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_ofQ (add_den_pos
    (Nat.mul_pos (by decide) (Nat.succ_pos _)) (by decide)))) ?_
  refine Rle_ofQ_ofQ (Qabs_den_pos (add_den_pos
    (Nat.mul_pos (by decide) (Nat.succ_pos _)) (by decide))) (Nat.succ_pos j) ?_
  -- the cleared inequality, entirely at the `Int` level (no `Q` whnf on the symbolic `2^M`)
  have hEc : ((2 ^ M - 1 : Nat) : Int) = ((2 ^ M : Nat) : Int) - 1 := by
    have h1 : 1 ≤ 2 ^ M := Nat.one_le_two_pow
    omega
  have hE : 2 ^ M - 1 + 1 = 2 ^ M := by
    have h1 : 1 ≤ 2 ^ M := Nat.one_le_two_pow
    omega
  show Qle (Qabs (⟨((2 ^ M - 1 : Nat) : Int) * 2 + (-1) * ((2 * (2 ^ M - 1 + 1) : Nat) : Int),
    2 * (2 ^ M - 1 + 1) * 2⟩ : Q)) (⟨1, j + 1⟩ : Q)
  have hnum : ((2 ^ M - 1 : Nat) : Int) * 2 + (-1) * ((2 * (2 ^ M - 1 + 1) : Nat) : Int)
      = -2 := by
    rw [hE, hEc]; push_cast; ring_uor
  rw [hnum]
  show Qle (⟨(2 : Int), 2 * (2 ^ M - 1 + 1) * 2⟩ : Q) (⟨1, j + 1⟩ : Q)
  show (2 : Int) * ((j + 1 : Nat) : Int) ≤ 1 * ((2 * (2 ^ M - 1 + 1) * 2 : Nat) : Int)
  rw [hE]
  push_cast
  have hjc : ((j : Int) + 1) ≤ ((2 ^ M : Nat) : Int) := by exact_mod_cast hj
  push_cast at hjc
  omega

/-- The rate, general in the Lipschitz datum: the telescoped sums sit within `1/(j+1)` of
    `1/2` for EVERY schedule (`M = digammaMidx L j ≥ j + 1`, so `1/(2·2^M) ≤ 1/(j+1)`). -/
theorem genSum_id_rate (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm (fun x => x)) (digammaMidx L j))
        (ofQ (⟨1, 2⟩ : Q) (by decide))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have heval := genSum_id_eval (digammaMidx L j)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr heval
    (Req_refl (ofQ (⟨1, 2⟩ : Q) (by decide)))))) ?_
  refine gauss_defect_le ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ x dx ≈ 1/2`, general in the Lipschitz datum** — the value is `1/2` for every
    valid `(L, hlip, hfc)` (the schedule changes, the limit does not): the anchor `D₀ = 0`
    and the telescoped limit evaluates by the rate + `Rlim_eval`. -/
theorem riemannIntegral_id_gen {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub x y)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req x y) :
    Req (riemannIntegral (f := fun x => x) hLd hLn hlip hfc) half := by
  show Req (Radd (dyadicR (fun x => x) 0) _) half
  have hD0 : Req (dyadicR (fun x => x) 0) zero :=
    Req_trans (riemannSum_id (2 ^ 0 - 1)) (ofQ_zero_num _)
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm (fun x => x)) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (ofQ (⟨1, 2⟩ : Q) (by decide)) :=
    Rlim_eval _ (by decide) (fun j => genSum_id_rate L j)
  refine Req_trans (Radd_congr hD0 hlim) ?_
  exact Req_trans (Radd_comm zero (ofQ (⟨1, 2⟩ : Q) (by decide)))
    (Radd_zero (ofQ (⟨1, 2⟩ : Q) (by decide)))

/-- **`∫₀¹ x dx ≈ 1/2`** — the headline instance at the canonical modulus `L = 1`. -/
theorem riemannIntegral_id :
    Req (riemannIntegral (f := fun x => x) (L := (⟨1, 1⟩ : Q)) (by decide) (by decide)
      lip_id congr_id) half :=
  riemannIntegral_id_gen (by decide) (by decide) lip_id congr_id

end UOR.Bridge.F1Square.Analysis
