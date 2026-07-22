/-
F1 square — **square-root Lipschitz bound and the real-radicand √**.

The constructive √ of a *rational* (`Rsqrt`) is Lipschitz-½ on `[1, ∞)`:
`|√x − √y| ≤ ½|x − y|` for `x, y ≥ 1` (`Rsqrt_lipschitz`). The engine is the difference-of-squares
factoring `(√x − √y)(√x + √y) = x − y` (from `(√·)² = ·`) divided through by `√x + √y ≥ 2` — but the
lower bound `2 ≤ |√x + √y|` is read off `√x + √y ≥ 2` via `x ≤ |x|` (no `|·|`-of-nonnegative needed),
keeping the argument multiplicative throughout (`Rabs_Rmul`).

This is the regularity modulus (`½ · 2/(j+1) = 1/(j+1)`) for the real-radicand square root: the limit
of the rational √'s of the (clamped-to-`≥1`) rational approximants of `a ≥ 1` — the `√t` factor of the
theta modular transform at a real argument.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.SqrtRealCmp
import Core.F1.Analysis.RabsLemmas

namespace UOR.Bridge.F1Square.Analysis

/-- `(ofQ a) − (ofQ b) ≈ ofQ (a − b)` (both are pointwise constant `a − b`). -/
private theorem Rsub_ofQ {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) :
    Req (Rsub (ofQ a ha) (ofQ b hb)) (ofQ (Qsub a b) (Qsub_den_pos ha hb)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- `½ · 2 · x ≈ x`. -/
private theorem Rhalf_two_mul (x : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x)) x := by
  refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
  refine Req_trans (Rmul_congr (Rmul_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_
  refine Req_trans (Rmul_congr
    (ofQ_congr (by decide) (by decide) (by decide : Qeq (mul (⟨1, 2⟩ : Q) (⟨2, 1⟩ : Q)) (⟨1, 1⟩ : Q)))
    (Req_refl _)) ?_
  exact Req_trans (Rmul_comm _ x) (Rmul_one x)

/-- **`Rsqrt` is Lipschitz-½ on `[1, ∞)`**: `|√x − √y| ≤ ½|x − y|` for rationals `x, y ≥ 1`. -/
theorem Rsqrt_lipschitz {x y : Q} (hxd : 0 < x.den) (hyd : 0 < y.den)
    (hx0 : Qle (⟨0, 1⟩ : Q) x) (hy0 : Qle (⟨0, 1⟩ : Q) y)
    (hx1 : Qle (⟨1, 1⟩ : Q) x) (hy1 : Qle (⟨1, 1⟩ : Q) y) :
    Rle (Rabs (Rsub (Rsqrt x hxd hx0) (Rsqrt y hyd hy0)))
        (ofQ (mul (⟨1, 2⟩ : Q) (Qabs (Qsub x y)))
          (Qmul_den_pos (by decide) (Qabs_den_pos (Qsub_den_pos hxd hyd)))) := by
  let s := Rsqrt x hxd hx0
  let t := Rsqrt y hyd hy0
  -- `2 ≤ |s + t|`, from `s, t ≥ 1` and `u ≤ |u|`.
  have hreq2 : Req (ofQ (⟨2, 1⟩ : Q) (by decide)) (Radd one one) :=
    Req_trans (ofQ_congr (by decide) (add_den_pos (by decide) (by decide))
        (by decide : Qeq (⟨2, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q))))
      (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))
  have h2st : Rle (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Radd s t)) :=
    Rle_trans (Rle_trans (Rle_of_Req hreq2)
        (Radd_le_add (Rsqrt_ge_one hxd hx0 hx1) (Rsqrt_ge_one hyd hy0 hy1)))
      (Rle_Rabs_self (Radd s t))
  -- `(s − t)(s + t) ≈ ofQ (x − y)`, so `|s − t|·|s + t| ≈ ofQ |x − y|`.
  have hprod : Req (Rmul (Rsub s t) (Radd s t)) (ofQ (Qsub x y) (Qsub_den_pos hxd hyd)) :=
    Req_trans (Rmul_sub_add_self s t)
      (Req_trans (Rsub_congr (Rsqrt_sq x hxd hx0) (Rsqrt_sq y hyd hy0))
        (Rsub_ofQ hxd hyd))
  have habs : Req (Rmul (Rabs (Rsub s t)) (Rabs (Radd s t)))
      (ofQ (Qabs (Qsub x y)) (Qabs_den_pos (Qsub_den_pos hxd hyd))) :=
    Req_trans (Req_symm (Rabs_Rmul (Rsub s t) (Radd s t)))
      (Req_trans (Rabs_congr hprod) (Rabs_ofQ (Qsub_den_pos hxd hyd)))
  -- `2·|s − t| ≤ |s + t|·|s − t| = |s − t|·|s + t| ≈ ofQ |x − y|`.
  have hchain : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Rsub s t)))
      (ofQ (Qabs (Qsub x y)) (Qabs_den_pos (Qsub_den_pos hxd hyd))) :=
    Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs (Rsub s t)) h2st)
      (Rle_of_Req (Req_trans (Rmul_comm (Rabs (Radd s t)) (Rabs (Rsub s t))) habs))
  -- multiply by `½ ≥ 0`: `|s − t| ≈ ½·2·|s − t| ≤ ½·ofQ|x − y| = ofQ (½|x − y|)`.
  refine Rle_trans (Rle_of_Req (Req_symm (Rhalf_two_mul (Rabs (Rsub s t))))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hchain) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (by decide) (Qabs_den_pos (Qsub_den_pos hxd hyd)))

-- ===========================================================================
-- The real-radicand square root `√a` for `a ≥ 1`, as the limit of the rational √'s of the shifted
-- approximants `cₙ = a_{4n+3} + 2/(4n+4) ≥ 1` (the shift makes `cₙ ≥ 1` automatic, the reindex
-- tightens the Lipschitz modulus `½·|cⱼ−cₖ|` to `1/(2(j+1))+1/(2(k+1)) ≤ 1/(j+1)+1/(k+1)`).
-- ===========================================================================

/-- `Qeq` commutes with `Qabs` (the rational reverse of `Rabs_congr`). -/
private theorem Qabs_congr_q {a b : Q} (h : Qeq a b) : Qeq (Qabs a) (Qabs b) := by
  have key : a.num.natAbs * b.den = b.num.natAbs * a.den := by
    unfold Qeq at h
    have hh := congrArg Int.natAbs h
    rw [Int.natAbs_mul, Int.natAbs_mul, Int.natAbs_ofNat, Int.natAbs_ofNat] at hh
    exact hh
  show ((a.num.natAbs : Int)) * (b.den : Int) = ((b.num.natAbs : Int)) * (a.den : Int)
  exact_mod_cast key

/-- The shifted rational approximant `cₙ = a_{4n+3} + 2/(4n+4)` of `a` — always `≥ 1` when `a ≥ 1`. -/
def rsqrtRealSeq (a : Real) (n : Nat) : Q := add (a.seq (4 * n + 3)) (⟨2, 4 * n + 4⟩ : Q)

theorem rsqrtRealSeq_den_pos (a : Real) (n : Nat) : 0 < (rsqrtRealSeq a n).den :=
  add_den_pos (a.den_pos _) (by show 0 < 4 * n + 4; omega)

/-- `cₙ ≥ 1` — exactly the `a ≥ 1` regularity statement at index `4n+3` (the shift is `Qbound`). -/
theorem rsqrtRealSeq_ge_one (a : Real) (ha : Rle one a) (n : Nat) :
    Qle (⟨1, 1⟩ : Q) (rsqrtRealSeq a n) := ha (4 * n + 3)

theorem rsqrtRealSeq_ge_zero (a : Real) (ha : Rle one a) (n : Nat) :
    Qle (⟨0, 1⟩ : Q) (rsqrtRealSeq a n) :=
  Qle_trans (by decide) (by decide : Qle (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)) (rsqrtRealSeq_ge_one a ha n)

/-- The sequence of rational square roots `√cₙ`. -/
def rsqrtRealX (a : Real) (ha : Rle one a) (n : Nat) : Real :=
  Rsqrt (rsqrtRealSeq a n) (rsqrtRealSeq_den_pos a n) (rsqrtRealSeq_ge_zero a ha n)

set_option maxHeartbeats 800000 in
/-- **The approximant gap** `|cⱼ − cₖ| ≤ 4/(4j+4) + 4/(4k+4)` — triangle split into the `a`-gap (from
    `a`'s regularity) and the `2/(4·+4)`-gap (both bounded by `2/(4·+4)`). -/
theorem rsqrtRealSeq_diff_le (a : Real) (j k : Nat) :
    Qle (Qabs (Qsub (rsqrtRealSeq a j) (rsqrtRealSeq a k)))
        (add (add (⟨1, 4 * j + 4⟩ : Q) (⟨1, 4 * k + 4⟩ : Q))
             (add (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q))) := by
  have hjd : 0 < (⟨2, 4 * j + 4⟩ : Q).den := by show 0 < 4 * j + 4; omega
  have hkd : 0 < (⟨2, 4 * k + 4⟩ : Q).den := by show 0 < 4 * k + 4; omega
  have heq : Qeq (Qsub (rsqrtRealSeq a j) (rsqrtRealSeq a k))
      (add (Qsub (a.seq (4 * j + 3)) (a.seq (4 * k + 3)))
           (Qsub (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q))) := by
    simp only [rsqrtRealSeq, Qeq, Qsub, add, neg]; push_cast; ring_uor
  have h1 : Qeq (Qabs (⟨2, 4 * j + 4⟩ : Q)) (⟨2, 4 * j + 4⟩ : Q) :=
    Qabs_of_nonneg (by show (0 : Int) ≤ 2; decide)
  have h2 : Qeq (Qabs (neg (⟨2, 4 * k + 4⟩ : Q))) (⟨2, 4 * k + 4⟩ : Q) := by
    rw [Qabs_neg]; exact Qabs_of_nonneg (by show (0 : Int) ≤ 2; decide)
  have hbd : Qle (Qabs (Qsub (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q)))
      (add (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q)) :=
    Qle_trans (add_den_pos (Qabs_den_pos hjd) (Qabs_den_pos hkd))
      (Qabs_add_le (⟨2, 4 * j + 4⟩ : Q) (neg (⟨2, 4 * k + 4⟩ : Q)))
      (Qadd_le_add (Qeq_le h1) (Qeq_le h2))
  have hareg : Qle (Qabs (Qsub (a.seq (4 * j + 3)) (a.seq (4 * k + 3))))
      (add (⟨1, 4 * j + 4⟩ : Q) (⟨1, 4 * k + 4⟩ : Q)) := by
    have h := a.reg (4 * j + 3) (4 * k + 3); unfold Qbound at h; exact h
  have e1 : Qle (Qabs (Qsub (rsqrtRealSeq a j) (rsqrtRealSeq a k)))
      (Qabs (add (Qsub (a.seq (4 * j + 3)) (a.seq (4 * k + 3)))
           (Qsub (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q)))) :=
    Qeq_le (Qabs_congr_q heq)
  have e2 : Qle (Qabs (add (Qsub (a.seq (4 * j + 3)) (a.seq (4 * k + 3)))
        (Qsub (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q))))
      (add (Qabs (Qsub (a.seq (4 * j + 3)) (a.seq (4 * k + 3))))
        (Qabs (Qsub (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q)))) :=
    Qabs_add_le _ _
  have e3 : Qle (add (Qabs (Qsub (a.seq (4 * j + 3)) (a.seq (4 * k + 3))))
        (Qabs (Qsub (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q))))
      (add (add (⟨1, 4 * j + 4⟩ : Q) (⟨1, 4 * k + 4⟩ : Q))
           (add (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q))) :=
    Qadd_le_add hareg hbd
  exact Qle_trans (Qabs_den_pos (add_den_pos (Qsub_den_pos (a.den_pos _) (a.den_pos _))
      (Qsub_den_pos hjd hkd))) e1
    (Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (a.den_pos _) (a.den_pos _)))
        (Qabs_den_pos (Qsub_den_pos hjd hkd))) e2 e3)

set_option maxHeartbeats 800000 in
/-- The reindexed √cₙ partial sequence is regular. -/
theorem rsqrtRealX_RReg (a : Real) (ha : Rle one a) : RReg (rsqrtRealX a ha) := by
  refine RReg_of_real_bound (rsqrtRealX a ha)
    (fun j k => add (⟨3, 8 * (j + 1)⟩ : Q) (⟨3, 8 * (k + 1)⟩ : Q))
    (fun j k => add_den_pos (by show 0 < 8 * (j + 1); omega) (by show 0 < 8 * (k + 1); omega))
    (fun j k => Qadd_le_add (by simp only [Qle]; push_cast; omega)
      (by simp only [Qle]; push_cast; omega)) ?_
  intro j k
  refine Rle_trans (Rle_of_Rabs_le (Rsqrt_lipschitz (rsqrtRealSeq_den_pos a j)
      (rsqrtRealSeq_den_pos a k) (rsqrtRealSeq_ge_zero a ha j) (rsqrtRealSeq_ge_zero a ha k)
      (rsqrtRealSeq_ge_one a ha j) (rsqrtRealSeq_ge_one a ha k))) ?_
  refine Rle_ofQ_ofQ _ _ ?_
  have hstep : Qle (mul (⟨1, 2⟩ : Q) (Qabs (Qsub (rsqrtRealSeq a j) (rsqrtRealSeq a k))))
      (mul (⟨1, 2⟩ : Q) (add (add (⟨1, 4 * j + 4⟩ : Q) (⟨1, 4 * k + 4⟩ : Q))
        (add (⟨2, 4 * j + 4⟩ : Q) (⟨2, 4 * k + 4⟩ : Q)))) :=
    Qmul_le_mul_left (by show (0 : Int) ≤ 1; decide) (rsqrtRealSeq_diff_le a j k)
  refine Qle_trans (Qmul_den_pos (by decide) (add_den_pos
      (add_den_pos (by show 0 < 4 * j + 4; omega) (by show 0 < 4 * k + 4; omega))
      (add_den_pos (by show 0 < 4 * j + 4; omega) (by show 0 < 4 * k + 4; omega)))) hstep (Qeq_le ?_)
  simp only [Qeq, mul, add]; push_cast; ring_uor

/-- **The constructive square root of a real `a ≥ 1`** — the Bishop limit of the rational √'s of the
    shifted approximants. The defining identity `(√a)² = a` is the remaining piece (needs limit
    arithmetic for the squaring step). -/
def RsqrtReal (a : Real) (ha : Rle one a) : Real := Rlim (rsqrtRealX a ha) (rsqrtRealX_RReg a ha)

/-- **`√a ≥ 0`.** -/
theorem RsqrtReal_nonneg (a : Real) (ha : Rle one a) : Rnonneg (RsqrtReal a ha) :=
  Rnonneg_Rlim_seq _ (fun _n => Rsqrt_nonneg _ _ _)

-- ===========================================================================
-- Toward `(√a)² = a`: limit-uniqueness at a general rate, and the convergence `ofQ cₙ → a`.
-- ===========================================================================

/-- **Limit uniqueness at a general (per-axis constant) rate** — if `X k → L` with rate
    `Cₖ/(k+1)+Cₙ/(n+1)` and `X k → L'` with rate `Cₖ'/(k+1)+Cₙ'/(n+1)`, then `L ≈ L'`. The `RTendsTo`
    uniqueness argument carries through verbatim for any constants (the Archimedean lemma kills the
    `k`-tail and the linear-bound criterion the `n`-residual). -/
theorem RTendsTo_gen_unique {X : Nat → Real} {L L' : Real} {Ck Cn Ck' Cn' : Nat}
    (hL : ∀ k n, Qle (Qabs (Qsub ((X k).seq n) (L.seq n)))
      (add (⟨(Ck : Int), k + 1⟩ : Q) (⟨(Cn : Int), n + 1⟩ : Q)))
    (hL' : ∀ k n, Qle (Qabs (Qsub ((X k).seq n) (L'.seq n)))
      (add (⟨(Ck' : Int), k + 1⟩ : Q) (⟨(Cn' : Int), n + 1⟩ : Q))) : Req L L' := by
  apply Req_of_lin_bound (C := Cn + Cn')
  intro n
  apply Qarch_gen (C := Ck + Ck')
    (Qabs_den_pos (Qsub_den_pos (L.den_pos n) (L'.den_pos n))) (Nat.succ_pos n)
  intro k
  have htri := Qabs_sub_triangle (a := L.seq n) (b := (X k).seq n) (c := L'.seq n)
    (L.den_pos n) ((X k).den_pos n) (L'.den_pos n)
  have hb1 : Qle (Qabs (Qsub (L.seq n) ((X k).seq n)))
      (add (⟨(Ck : Int), k + 1⟩ : Q) (⟨(Cn : Int), n + 1⟩ : Q)) := by
    rw [Qabs_Qsub_comm]; exact hL k n
  have hfin : Qle (add (add (⟨(Ck : Int), k + 1⟩ : Q) (⟨(Cn : Int), n + 1⟩ : Q))
        (add (⟨(Ck' : Int), k + 1⟩ : Q) (⟨(Cn' : Int), n + 1⟩ : Q)))
      (add (⟨((Cn + Cn' : Nat) : Int), n + 1⟩ : Q) (⟨((Ck + Ck' : Nat) : Int), k + 1⟩ : Q)) := by
    apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor
  exact Qle_trans
    (add_den_pos (Qabs_den_pos (Qsub_den_pos (L.den_pos n) ((X k).den_pos n)))
      (Qabs_den_pos (Qsub_den_pos ((X k).den_pos n) (L'.den_pos n)))) htri
    (Qle_trans (add_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)))
      (Qadd_le_add hb1 (hL' k n)) hfin)

/-- **`ofQ cₙ → a`** — the shifted rational approximants converge to `a` (rate `2/(k+1)+2/(n+1)`,
    i.e. exactly `RTendsTo`). Triangle through `a_{4k+3}`: the shift contributes `2/(4k+4)`, `a`'s
    regularity `1/(4k+4)+1/(m+1)`, summing to `3/(4k+4)+1/(m+1) ≤ 2/(k+1)+2/(m+1)`. -/
theorem rsqrtRealSeq_tendsTo (a : Real) :
    RTendsTo (fun n => ofQ (rsqrtRealSeq a n) (rsqrtRealSeq_den_pos a n)) a := by
  intro k m
  show Qle (Qabs (Qsub (rsqrtRealSeq a k) (a.seq m))) (add (⟨2, k + 1⟩ : Q) (⟨2, m + 1⟩ : Q))
  have htri := Qabs_sub_triangle (a := rsqrtRealSeq a k) (b := a.seq (4 * k + 3)) (c := a.seq m)
    (rsqrtRealSeq_den_pos a k) (a.den_pos _) (a.den_pos _)
  have hshift : Qeq (Qsub (rsqrtRealSeq a k) (a.seq (4 * k + 3))) (⟨2, 4 * k + 4⟩ : Q) := by
    simp only [rsqrtRealSeq, Qsub, add, neg, Qeq]; push_cast; ring_uor
  have ha2 : Qeq (Qabs (⟨2, 4 * k + 4⟩ : Q)) (⟨2, 4 * k + 4⟩ : Q) :=
    Qabs_of_nonneg (by show (0 : Int) ≤ 2; decide)
  have hc1 : Qle (Qabs (Qsub (rsqrtRealSeq a k) (a.seq (4 * k + 3)))) (⟨2, 4 * k + 4⟩ : Q) :=
    Qeq_le (Qeq_trans (by show 0 < 4 * k + 4; omega) (Qabs_congr_q hshift) ha2)
  have hc2 : Qle (Qabs (Qsub (a.seq (4 * k + 3)) (a.seq m)))
      (add (⟨1, 4 * k + 4⟩ : Q) (⟨1, m + 1⟩ : Q)) := by
    have h := a.reg (4 * k + 3) m; unfold Qbound at h; exact h
  have hreg : Qeq (add (⟨2, 4 * k + 4⟩ : Q) (add (⟨1, 4 * k + 4⟩ : Q) (⟨1, m + 1⟩ : Q)))
      (add (⟨3, 4 * k + 4⟩ : Q) (⟨1, m + 1⟩ : Q)) := by
    simp only [Qeq, add]; push_cast; ring_uor
  have htail : Qle (add (⟨3, 4 * k + 4⟩ : Q) (⟨1, m + 1⟩ : Q))
      (add (⟨2, k + 1⟩ : Q) (⟨2, m + 1⟩ : Q)) :=
    Qadd_le_add (by simp only [Qle]; push_cast; omega) (by simp only [Qle]; push_cast; omega)
  exact Qle_trans
    (add_den_pos (Qabs_den_pos (Qsub_den_pos (rsqrtRealSeq_den_pos a k) (a.den_pos _)))
      (Qabs_den_pos (Qsub_den_pos (a.den_pos _) (a.den_pos _)))) htri
    (Qle_trans (add_den_pos (by show 0 < 4 * k + 4; omega)
        (add_den_pos (by show 0 < 4 * k + 4; omega) (Nat.succ_pos _)))
      (Qadd_le_add hc1 hc2)
      (Qle_trans (add_den_pos (by show 0 < 4 * k + 4; omega) (Nat.succ_pos _))
        (Qeq_le hreg) htail))

-- ===========================================================================
-- General limit-arithmetic infrastructure for the squaring step.
-- ===========================================================================

/-- **`RTendsTo` ⟹ real `Rabs` rate**: `X k → L` gives `|X k − L| ≤ 2/(k+1)` as reals. -/
theorem RTendsTo_Rabs_rate {X : Nat → Real} {L : Real} (h : RTendsTo X L) (k : Nat) :
    Rle (Rabs (Rsub (X k) L)) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  intro n
  show Qle (Qabs ((Rsub (X k) L).seq n)) (add (⟨2, k + 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  refine Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (h k (2 * n + 1)) ?_
  exact Qadd_le_add (Qle_refl _) (by simp only [Qle]; push_cast; omega)

/-- **`q ≤ q²` for `q ≥ 1`** (rational). -/
theorem Qle_self_mul_self_of_ge_one {q : Q} (hqd : 0 < q.den) (h1 : Qle (⟨1, 1⟩ : Q) q) :
    Qle q (mul q q) := by
  have hn : (q.den : Int) ≤ q.num := by simp only [Qle] at h1; simpa using h1
  have hnn : 0 ≤ q.num := by omega
  have hfac : 0 ≤ q.num * (q.den : Int) := Int.mul_nonneg hnn (Int.ofNat_nonneg _)
  have hkey : q.num * (q.den : Int) * (q.den : Int) ≤ q.num * (q.den : Int) * q.num :=
    Int.mul_le_mul_of_nonneg_left hn hfac
  have e : q.num * ((q.den : Int) * (q.den : Int)) = q.num * (q.den : Int) * (q.den : Int) := by ring_uor
  have e2 : q.num * q.num * (q.den : Int) = q.num * (q.den : Int) * q.num := by ring_uor
  simp only [Qle, mul]; push_cast
  rw [e, e2]; exact hkey

/-- **`|x| ≤ B` for `0 ≤ x ≤ B`** (`B ≥ 0` rational). -/
theorem Rabs_le_of_nonneg_le {x : Real} {B : Q} (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hx : Rnonneg x) (hxB : Rle x (ofQ B hBd)) : Rle (Rabs x) (ofQ B hBd) := by
  intro m
  show Qle (Qabs (x.seq m)) (add B (⟨2, m + 1⟩ : Q))
  refine Qabs_le_of_both (hxB m) ?_
  have h1 : Qle (neg (x.seq m)) (neg (neg (Qbound m))) := Qneg_le_neg (hx m)
  have h2 : Qle (neg (neg (Qbound m))) (⟨2, m + 1⟩ : Q) := by
    simp only [Qle, neg, Qbound]; push_cast; omega
  have h3 : Qle (⟨2, m + 1⟩ : Q) (add B (⟨2, m + 1⟩ : Q)) :=
    Qle_trans (add_den_pos (Nat.succ_pos _) hBd) (Qle_self_add hBn)
      (Qeq_le (add_comm (⟨2, m + 1⟩ : Q) B))
  exact Qle_trans (neg_den_pos (neg_den_pos (Qbound_den_pos m))) h1
    (Qle_trans (Nat.succ_pos _) h2 h3)

/-- **Real `Rabs` rate ⟹ general-rate componentwise** — the converter feeding `RTendsTo_gen_unique`. -/
theorem rate_to_gen {W : Nat → Real} {M : Real} {C : Nat}
    (h : ∀ k, Rle (Rabs (Rsub (W k) M)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    ∀ k n, Qle (Qabs (Qsub ((W k).seq n) (M.seq n)))
      (add (⟨(C : Int), k + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) := by
  intro k n
  have hpos : Rle (Rsub (W k) M) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_of_Rabs_le (h k)
  have hsymm : Req (Rabs (Rsub M (W k))) (Rabs (Rsub (W k) M)) :=
    Req_trans (Rabs_congr (Req_symm (Rneg_Rsub (W k) M))) (Rabs_Rneg (Rsub (W k) M))
  have hneg : Rle (Rsub M (W k)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_of_Rabs_le (Rle_trans (Rle_of_Req hsymm) (h k))
  refine Qabs_le_of_both (seq_diff_le (W k) M _ (Nat.succ_pos k) hpos n) ?_
  have hn := seq_diff_le M (W k) _ (Nat.succ_pos k) hneg n
  have heq : Qeq (neg (Qsub ((W k).seq n) (M.seq n))) (Qsub (M.seq n) ((W k).seq n)) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  exact Qle_congr_left (Qsub_den_pos (M.den_pos n) ((W k).den_pos n)) (Qeq_symm heq) hn

/-- The approximant `√cₖ` is bounded by `B := xBound a + 2` (since `√cₖ ≤ cₖ ≤ B`, `cₖ ≥ 1`). -/
theorem rsqrtRealX_le (a : Real) (ha : Rle one a) (k : Nat) :
    Rle (rsqrtRealX a ha k) (ofQ (⟨(xBound a : Int) + 2, 1⟩ : Q) Nat.one_pos) := by
  have hcnB : Qle (rsqrtRealSeq a k) (⟨(xBound a : Int) + 2, 1⟩ : Q) := by
    have ha3 : Qle (a.seq (4 * k + 3)) (⟨(xBound a : Int), 1⟩ : Q) :=
      Qle_trans (Qabs_den_pos (a.den_pos _)) (Qle_self_Qabs _) (canon_bound a (4 * k + 3))
    have hsh : Qle (⟨2, 4 * k + 4⟩ : Q) (⟨2, 1⟩ : Q) := by simp only [Qle]; push_cast; omega
    refine Qle_trans (add_den_pos Nat.one_pos Nat.one_pos)
      (Qadd_le_add ha3 hsh) (Qeq_le ?_)
    simp only [Qeq, add]; push_cast; ring_uor
  have hsqle : Rle (Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k))
      (Rmul (ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k))
            (ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k))) :=
    Rle_trans (Rle_of_Req (Rsqrt_sq _ _ _))
      (Rle_trans (Rle_ofQ_ofQ _ _
          (Qle_self_mul_self_of_ge_one (rsqrtRealSeq_den_pos a k) (rsqrtRealSeq_ge_one a ha k)))
        (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ _ _))))
  refine Rle_trans (Rle_of_Rsq_le (Rsqrt_nonneg _ _ _)
    (Rnonneg_ofQ _ (by have := rsqrtRealSeq_ge_zero a ha k; simp only [Qle] at this; simpa using this))
    hsqle) ?_
  exact Rle_ofQ_ofQ _ _ hcnB

/-- `|√cₖ| ≤ B`. -/
theorem rsqrtRealX_abs_le (a : Real) (ha : Rle one a) (k : Nat) :
    Rle (Rabs (rsqrtRealX a ha k)) (ofQ (⟨(xBound a : Int) + 2, 1⟩ : Q) Nat.one_pos) :=
  Rabs_le_of_nonneg_le Nat.one_pos (by show (0 : Int) ≤ (xBound a : Int) + 2; omega)
    (Rsqrt_nonneg _ _ _) (rsqrtRealX_le a ha k)

/-- `|√a| ≤ B`. -/
theorem RsqrtReal_abs_le (a : Real) (ha : Rle one a) :
    Rle (Rabs (RsqrtReal a ha)) (ofQ (⟨(xBound a : Int) + 2, 1⟩ : Q) Nat.one_pos) :=
  Rabs_le_of_nonneg_le Nat.one_pos (by show (0 : Int) ≤ (xBound a : Int) + 2; omega)
    (RsqrtReal_nonneg a ha)
    (Rlim_le_ofQ (rsqrtRealX_RReg a ha) Nat.one_pos (fun k => rsqrtRealX_le a ha k))

set_option maxHeartbeats 800000 in
/-- **`(√a)² = a`** — the defining identity of the real-radicand square root. Both `√cₙ·√cₙ = ofQ cₙ`
    converge: to `a` (the approximants, `rsqrtRealSeq_tendsTo`) and to `(√a)²` (the product estimate
    `|√cₙ·√cₙ − √a·√a| = |√cₙ−√a|·|√cₙ+√a| ≤ (2/(n+1))·2B`), so the two limits agree
    (`RTendsTo_gen_unique`). -/
theorem RsqrtReal_sq (a : Real) (ha : Rle one a) :
    Req (Rmul (RsqrtReal a ha) (RsqrtReal a ha)) a := by
  have hprodrate : ∀ k, Rle (Rabs (Rsub (Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k))
        (Rmul (RsqrtReal a ha) (RsqrtReal a ha))))
      (ofQ (⟨4 * ((xBound a : Int) + 2), k + 1⟩ : Q) (Nat.succ_pos k)) := by
    intro k
    have e1 : Req (Rabs (Rsub (Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k))
          (Rmul (RsqrtReal a ha) (RsqrtReal a ha))))
        (Rmul (Rabs (Rsub (rsqrtRealX a ha k) (RsqrtReal a ha)))
              (Rabs (Radd (rsqrtRealX a ha k) (RsqrtReal a ha)))) :=
      Req_trans (Rabs_congr (Req_symm (Rmul_sub_add_self (rsqrtRealX a ha k) (RsqrtReal a ha))))
        (Rabs_Rmul _ _)
    have haddbd : Rle (Rabs (Radd (rsqrtRealX a ha k) (RsqrtReal a ha)))
        (ofQ (⟨2 * ((xBound a : Int) + 2), 1⟩ : Q) Nat.one_pos) :=
      Rle_trans (Rabs_Radd _ _)
        (Rle_trans (Radd_le_add (rsqrtRealX_abs_le a ha k) (RsqrtReal_abs_le a ha))
          (Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
            (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))))
    have hsubbd : Rle (Rabs (Rsub (rsqrtRealX a ha k) (RsqrtReal a ha)))
        (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) :=
      RTendsTo_Rabs_rate (Rlim_tendsTo (rsqrtRealX a ha) (rsqrtRealX_RReg a ha)) k
    refine Rle_trans (Rle_of_Req e1) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs _) haddbd) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ _ (by show (0 : Int) ≤ 2 * ((xBound a : Int) + 2); omega)) hsubbd) ?_
    exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, mul]; push_cast; ring_uor)))
  have hWLL := rate_to_gen hprodrate
  have hWa : ∀ k n, Qle (Qabs (Qsub ((Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k)).seq n) (a.seq n)))
      (add (⟨2, k + 1⟩ : Q) (⟨4, n + 1⟩ : Q)) := by
    intro k n
    have heqk : Req (Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k))
        (ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k)) :=
      Rsqrt_sq (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k) (rsqrtRealSeq_ge_zero a ha k)
    have htri := Qabs_sub_triangle
      (a := (Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k)).seq n)
      (b := (ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k)).seq n) (c := a.seq n)
      ((Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k)).den_pos n)
      ((ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k)).den_pos n) (a.den_pos n)
    have hb1 : Qle (Qabs (Qsub ((Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k)).seq n)
        ((ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k)).seq n))) (⟨2, n + 1⟩ : Q) := heqk n
    have hb2 := rsqrtRealSeq_tendsTo a k n
    have hfin : Qle (add (⟨2, n + 1⟩ : Q) (add (⟨2, k + 1⟩ : Q) (⟨2, n + 1⟩ : Q)))
        (add (⟨2, k + 1⟩ : Q) (⟨4, n + 1⟩ : Q)) := by
      apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor
    exact Qle_trans
      (add_den_pos (Qabs_den_pos (Qsub_den_pos
          ((Rmul (rsqrtRealX a ha k) (rsqrtRealX a ha k)).den_pos n)
          ((ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k)).den_pos n)))
        (Qabs_den_pos (Qsub_den_pos
          ((ofQ (rsqrtRealSeq a k) (rsqrtRealSeq_den_pos a k)).den_pos n) (a.den_pos n)))) htri
      (Qle_trans (add_den_pos (Nat.succ_pos _) (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)))
        (Qadd_le_add hb1 hb2) hfin)
  exact RTendsTo_gen_unique hWLL hWa

/-- **`√a` is the unique non-negative square root** of `a ≥ 1`: any `y ≥ 0` with `y² = a` is `√a`. -/
theorem RsqrtReal_unique (a : Real) (ha : Rle one a) {y : Real} (hy : Rnonneg y)
    (hsq : Req (Rmul y y) a) : Req y (RsqrtReal a ha) := by
  have h : Req (Rmul y y) (Rmul (RsqrtReal a ha) (RsqrtReal a ha)) :=
    Req_trans hsq (Req_symm (RsqrtReal_sq a ha))
  exact Rle_antisymm (Rle_of_Rsq_le hy (RsqrtReal_nonneg a ha) (Rle_of_Req h))
    (Rle_of_Rsq_le (RsqrtReal_nonneg a ha) hy (Rle_of_Req (Req_symm h)))

/-- `(a·b)·(c·d) ≈ (a·c)·(b·d)` (middle-swap commutativity). -/
theorem Rmul_mul_mul_comm (a b c d : Real) :
    Req (Rmul (Rmul a b) (Rmul c d)) (Rmul (Rmul a c) (Rmul b d)) :=
  Req_trans (Rmul_assoc a b (Rmul c d))
    (Req_trans (Rmul_congr (Req_refl a) (Req_symm (Rmul_assoc b c d)))
      (Req_trans (Rmul_congr (Req_refl a) (Rmul_congr (Rmul_comm b c) (Req_refl d)))
        (Req_trans (Rmul_congr (Req_refl a) (Rmul_assoc c b d))
          (Req_symm (Rmul_assoc a c (Rmul b d))))))

/-- **`√(a·b) = √a·√b`** for `a, b ≥ 1` (with `a·b ≥ 1`) — multiplicativity of the real √. -/
theorem RsqrtReal_mul (a b : Real) (ha : Rle one a) (hb : Rle one b) (hab : Rle one (Rmul a b)) :
    Req (Rmul (RsqrtReal a ha) (RsqrtReal b hb)) (RsqrtReal (Rmul a b) hab) :=
  RsqrtReal_unique (Rmul a b) hab
    (Rnonneg_Rmul (RsqrtReal_nonneg a ha) (RsqrtReal_nonneg b hb))
    (Req_trans (Rmul_mul_mul_comm (RsqrtReal a ha) (RsqrtReal b hb)
        (RsqrtReal a ha) (RsqrtReal b hb))
      (Rmul_congr (RsqrtReal_sq a ha) (RsqrtReal_sq b hb)))

-- ===========================================================================
-- The square root of an arbitrary positive real (scaling `√a = (1/N)·√(N²a)` with `N²a ≥ 1`).
-- ===========================================================================

/-- **The square root of a positive real `a`** (with `N²·a ≥ 1`, `N ≥ 1`) — `√a = (1/N)·√(N²a)`,
    extending `RsqrtReal` below `1`. The caller supplies `N` large enough that `N²a ≥ 1`. -/
def RsqrtRealPos (a : Real) (N : Nat) (hN : 0 < N)
    (hscale : Rle one (Rmul (ofQ (⟨(N : Int) * (N : Int), 1⟩ : Q) Nat.one_pos) a)) : Real :=
  Rmul (ofQ (⟨1, N⟩ : Q) hN)
    (RsqrtReal (Rmul (ofQ (⟨(N : Int) * (N : Int), 1⟩ : Q) Nat.one_pos) a) hscale)

/-- **`√a ≥ 0`** for the positive-real root. -/
theorem RsqrtRealPos_nonneg (a : Real) (N : Nat) (hN : 0 < N)
    (hscale : Rle one (Rmul (ofQ (⟨(N : Int) * (N : Int), 1⟩ : Q) Nat.one_pos) a)) :
    Rnonneg (RsqrtRealPos a N hN hscale) :=
  Rnonneg_Rmul (Rnonneg_ofQ hN (by show (0 : Int) ≤ 1; decide)) (RsqrtReal_nonneg _ _)

/-- **`(√a)² = a`** for the positive-real root: `(1/N)²·(N²a) = a`. -/
theorem RsqrtRealPos_sq (a : Real) (N : Nat) (hN : 0 < N)
    (hscale : Rle one (Rmul (ofQ (⟨(N : Int) * (N : Int), 1⟩ : Q) Nat.one_pos) a)) :
    Req (Rmul (RsqrtRealPos a N hN hscale) (RsqrtRealPos a N hN hscale)) a := by
  show Req (Rmul (Rmul (ofQ (⟨1, N⟩ : Q) hN) _) (Rmul (ofQ (⟨1, N⟩ : Q) hN) _)) a
  refine Req_trans (Rmul_mul_mul_comm (ofQ (⟨1, N⟩ : Q) hN) _ (ofQ (⟨1, N⟩ : Q) hN) _) ?_
  refine Req_trans (Rmul_congr (Rmul_ofQ_ofQ hN hN)
    (RsqrtReal_sq (Rmul (ofQ (⟨(N : Int) * (N : Int), 1⟩ : Q) Nat.one_pos) a) hscale)) ?_
  -- Rmul (ofQ ⟨1, N*N⟩) (Rmul (ofQ ⟨N*N,1⟩) a) ≈ a
  refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
  refine Req_trans (Rmul_congr (Rmul_ofQ_ofQ (Nat.mul_pos hN hN) Nat.one_pos) (Req_refl a)) ?_
  refine Req_trans (Rmul_congr
    (ofQ_congr (Qmul_den_pos (Nat.mul_pos hN hN) Nat.one_pos) (by decide : 0 < (⟨1, 1⟩ : Q).den)
      (by simp only [Qeq, mul]; push_cast; ring_uor)) (Req_refl a)) ?_
  exact Req_trans (Rmul_comm _ a) (Rmul_one a)

end UOR.Bridge.F1Square.Analysis
