/-
F1 square — **the Γ function via Spouge's approximation** (the archimedean `Γ′/Γ` place).

For the Li-coefficient / explicit-formula archimedean term we need `Γ` on the real line `z > 0`. Spouge's
approximation
  `Γ(z+1) = (z+a)^{z+½} · e^{−(z+a)} · (c₀ + Σ_{k=1}^{⌈a⌉−1} cₖ/(z+k) + ε_a(z))`,
  `c₀ = √(2π)`,  `cₖ = (−1)^{k−1}/(k−1)! · (a−k)^{k−½} · e^{a−k}`,
is built entirely from `exp` and `log` of POSITIVE reals — every power, including `√(2π) = exp(½·log 2π)`
and the half-integer `(a−k)^{k−½} = exp((k−½)·log(a−k))`, is `x^y := exp(y·log x)`. So NO dedicated
square-root primitive is required: the single real-power combinator `RrpowPos` is the whole foundation.

This file builds that combinator and its laws; Spouge's coefficients, the approximant, and the error
estimate follow.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.RealPow
import F1Square.Analysis.Log
import F1Square.Analysis.Pi
import F1Square.Analysis.RealDiv
import F1Square.Analysis.ComplexZeta

namespace UOR.Bridge.F1Square.Analysis

/-- **The real power `x^y := exp(y · log x)` for a positive base** `x` (positivity witnessed by `k, hk`).
    The single combinator behind every Spouge power: `√(2π) = RrpowPos 2π _ _ ½`,
    `(z+a)^{z+½} = RrpowPos (z+a) _ _ (z+½)`, `(a−k)^{k−½} = RrpowPos (a−k) _ _ (k−½)`. -/
def RrpowPos (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) (y : Real) : Real :=
  RexpReal (Rmul y (RlogPos x k hk))

/-- **`x^y > 0` for a non-negative exponent** (`exp` of a non-negative real is `≥ 1 > 0`). The
    non-negative-exponent powers in Spouge — `√(2π) = exp(½·log 2π)` and `(z+a)^{z+½}` — are positive. -/
theorem Pos_RrpowPos_of_nonneg (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) (y : Real)
    (hy : Rnonneg (Rmul y (RlogPos x k hk))) : Pos (RrpowPos x k hk y) :=
  Pos_RexpReal hy

/-- **`x^y > 0` from a non-negative exponent and a non-negative log** (e.g. base `≥ 1`).
    The clean API split: the caller supplies `Rnonneg (RlogPos x …)` per-case (positive for `x ≥ 1`),
    and `y ≥ 0`; then `y·log x ≥ 0` and `exp(y·log x) > 0`. -/
theorem Pos_RrpowPos_of_nonneg_log (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) (y : Real)
    (hy : Rnonneg y) (hlog : Rnonneg (RlogPos x k hk)) : Pos (RrpowPos x k hk y) :=
  Pos_RexpReal (Rnonneg_Rmul hy hlog)

/-- **The exponent law `x^{y+y'} = x^y · x^{y'}`**: powers add under multiplication, by `exp(a+b)=exp a·exp b`. -/
theorem RrpowPos_add (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) (y y' : Real) :
    Req (RrpowPos x k hk (Radd y y')) (Rmul (RrpowPos x k hk y) (RrpowPos x k hk y')) := by
  show Req (RexpReal (Rmul (Radd y y') (RlogPos x k hk)))
        (Rmul (RexpReal (Rmul y (RlogPos x k hk))) (RexpReal (Rmul y' (RlogPos x k hk))))
  refine Req_trans (RexpReal_congr (Rmul_distrib_right y y' (RlogPos x k hk))) ?_
  exact RexpReal_add (Rmul y (RlogPos x k hk)) (Rmul y' (RlogPos x k hk))

-- ===========================================================================
-- **The digamma function `ψ = Γ′/Γ`** (the archimedean place) as a genuine constructive real, via the
-- convergent series  `ψ(z) = −γ + Σ_{n=0}^∞ [ 1/(n+1) − 1/(n+z) ]`  (valid for `z > 0`; `ψ(1) = −γ`,
-- `ψ(2) = 1−γ`). The architecture mirrors the committed `Ceta` build: a finite partial sum `D z N`, a
-- telescoping tail bound, a reindex absorbing the constant `B = |z−1|`, then `RReg_of_real_bound → Rlim`.
-- ===========================================================================

/-- **`1/x ≥ 0`**: the reciprocal of a positive real is non-negative (its sequence is `Qinv` of
    positive-numerator rationals, which are non-negative). -/
theorem Rnonneg_Rinv (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) :
    Rnonneg (Rinv x k hk) := by
  intro n
  show Qle (neg (Qbound n)) (Qinv (x.seq (RinvR x k n)))
  have hnn : 0 ≤ (Qinv (x.seq (RinvR x k n))).num := Int.ofNat_nonneg _
  have hd : 0 < (Qinv (x.seq (RinvR x k n))).den := Qinv_den_pos (Rinv_num_pos hk (RinvR_ge n))
  have hbn : (0 : Int) ≤ ((n : Int) + 1) := by omega
  simp only [Qle, neg, Qbound]; push_cast
  have h1 : (0 : Int) ≤ (Qinv (x.seq (RinvR x k n))).num * ((n : Int) + 1) :=
    Int.mul_nonneg hnn hbn
  have h2 : (0 : Int) ≤ ((Qinv (x.seq (RinvR x k n))).den : Int) := by exact_mod_cast Nat.zero_le _
  omega

/-- **Targeted `Rinv` antitone bound**: if a positive rational `q` lower-bounds `w` (`ofQ q ≤ w`,
    `q.num > 0`), then `1/w ≤ 1/q = ofQ (Qinv q)`. Proof: `(1/w)·q ≤ (1/w)·w ≈ 1`, then multiply by
    `ofQ (Qinv q) ≥ 0` and use `q·(1/q) ≈ 1`. -/
theorem Rinv_le_ofQ_Qinv {w : Real} {kw : Nat} (hkw : Qlt (Qbound kw) (w.seq kw))
    {q : Q} (hqn : 0 < q.num) (hqd : 0 < q.den) (hqw : Rle (ofQ q hqd) w) :
    Rle (Rinv w kw hkw) (ofQ (Qinv q) (Qinv_den_pos hqn)) := by
  -- (1/w)·q ≤ (1/w)·w ≈ 1
  have hstep1 : Rle (Rmul (Rinv w kw hkw) (ofQ q hqd)) (Rmul (Rinv w kw hkw) w) :=
    Rmul_le_Rmul_left (Rnonneg_Rinv w kw hkw) hqw
  have hstep2 : Rle (Rmul (Rinv w kw hkw) (ofQ q hqd)) one :=
    Rle_trans hstep1 (Rle_of_Req (Req_trans (Rmul_comm (Rinv w kw hkw) w) (Rmul_Rinv_self hkw)))
  -- multiply both sides on the right by ofQ (Qinv q) ≥ 0
  have hQinvnn : Rnonneg (ofQ (Qinv q) (Qinv_den_pos hqn)) :=
    Rnonneg_ofQ (Qinv_den_pos hqn) (Int.le_of_lt (Qinv_num_pos hqd))
  have hstep3 : Rle (Rmul (Rmul (Rinv w kw hkw) (ofQ q hqd)) (ofQ (Qinv q) (Qinv_den_pos hqn)))
      (Rmul one (ofQ (Qinv q) (Qinv_den_pos hqn))) :=
    Rmul_le_Rmul_right hQinvnn hstep2
  -- left side ≈ (1/w)·(q·(1/q)) ≈ (1/w)·1 ≈ 1/w ; right side ≈ ofQ (Qinv q)
  have hqq : Req (Rmul (ofQ q hqd) (ofQ (Qinv q) (Qinv_den_pos hqn))) one :=
    Req_trans (Rmul_ofQ_ofQ hqd (Qinv_den_pos hqn))
      (Req_of_seq_Qeq (fun _ => Qmul_Qinv hqn))
  have hleft : Req (Rmul (Rmul (Rinv w kw hkw) (ofQ q hqd)) (ofQ (Qinv q) (Qinv_den_pos hqn)))
      (Rinv w kw hkw) :=
    Req_trans (Rmul_assoc (Rinv w kw hkw) (ofQ q hqd) (ofQ (Qinv q) (Qinv_den_pos hqn)))
      (Req_trans (Rmul_congr (Req_refl _) hqq) (Rmul_one (Rinv w kw hkw)))
  have hright : Req (Rmul one (ofQ (Qinv q) (Qinv_den_pos hqn))) (ofQ (Qinv q) (Qinv_den_pos hqn)) :=
    Req_trans (Rmul_comm one (ofQ (Qinv q) (Qinv_den_pos hqn))) (Rmul_one _)
  exact Rle_trans (Rle_of_Req (Req_symm hleft)) (Rle_trans hstep3 (Rle_of_Req hright))

/-- The shifted argument `z + n` of the `n`-th digamma term (`RofNat` is `n : ℝ`, from `ComplexPow`,
    already in scope via the `ComplexZeta` import). -/
def digammaArg (z : Real) (n : Nat) : Real := Radd z (RofNat n)

/-- `RofNat n ≥ 0`. -/
theorem Rnonneg_RofNat (n : Nat) : Rnonneg (RofNat n) :=
  Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ (n : Int); exact Int.ofNat_nonneg n)

/-- The rational floor `c` of `z` is also a floor of `z + n`. -/
theorem ofQ_le_digammaArg {z : Real} {c : Q} (hcd : 0 < c.den) (hcz : Rle (ofQ c hcd) z) (n : Nat) :
    Rle (ofQ c hcd) (digammaArg z n) :=
  Rle_trans hcz (Rle_self_Radd_right (Rnonneg_RofNat n))

/-- The uniform positivity witness index for every shifted argument `z + n`: `3 · c.den`. -/
def digammaArgK (c : Q) : Nat := 3 * c.den

/-- The positivity witness for `z + n`, derived uniformly from the floor `c ≤ z`. -/
theorem digammaArg_witness {z : Real} {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) (n : Nat) :
    Qlt (Qbound (digammaArgK c)) ((digammaArg z n).seq (digammaArgK c)) :=
  Rlt_Qbound_of_Rle_ofQ hcn hcd (ofQ_le_digammaArg hcd hcz n)

/-- **Abstract reciprocal-difference identity**: if `a·I ≈ 1` and `Q·P ≈ 1`, then
    `P − I ≈ (a − Q)·(P·I)`. Purely algebraic; the engine of the telescoping digamma term. -/
theorem Rsub_eq_mul_of_inv {a I P Q : Real} (haI : Req (Rmul a I) one) (hQP : Req (Rmul Q P) one) :
    Req (Rsub P I) (Rmul (Rsub a Q) (Rmul P I)) := by
  -- RHS = a·(P·I) − Q·(P·I)
  have hexpand : Req (Rmul (Rsub a Q) (Rmul P I))
      (Rsub (Rmul a (Rmul P I)) (Rmul Q (Rmul P I))) :=
    Rmul_sub_distrib_right a Q (Rmul P I)
  -- a·(P·I) ≈ P·(a·I) ≈ P·1 ≈ P
  have hL : Req (Rmul a (Rmul P I)) P :=
    Req_trans (Rmul_congr (Req_refl a) (Rmul_comm P I))
      (Req_trans (Req_symm (Rmul_assoc a I P))
        (Req_trans (Rmul_congr haI (Req_refl P)) (Req_trans (Rmul_comm one P) (Rmul_one P))))
  -- Q·(P·I) ≈ (Q·P)·I ≈ 1·I ≈ I
  have hR : Req (Rmul Q (Rmul P I)) I :=
    Req_trans (Req_symm (Rmul_assoc Q P I))
      (Req_trans (Rmul_congr hQP (Req_refl I)) (Req_trans (Rmul_comm one I) (Rmul_one I)))
  exact Req_symm (Req_trans hexpand (Rsub_congr hL hR))

/-- **The reciprocal-difference identity** `1/m − 1/a ≈ (a − m)·(1/m)·(1/a)` for a positive real `a`
    (witness `ka`) and positive `m`. The analogue of `Qinv_sub_eq`, the telescoping engine. -/
theorem Rinv_ofQ_sub_eq {a : Real} {ka : Nat} (hka : Qlt (Qbound ka) (a.seq ka)) {m : Nat} (hm : 0 < m) :
    Req (Rsub (ofQ ⟨1, m⟩ hm) (Rinv a ka hka))
      (Rmul (Rsub a (ofQ ⟨(m : Int), 1⟩ Nat.one_pos))
        (Rmul (ofQ ⟨1, m⟩ hm) (Rinv a ka hka))) := by
  have hQPq : ∀ _ : Nat, Qeq (mul (⟨(m : Int), 1⟩ : Q) (⟨1, m⟩ : Q)) (⟨1, 1⟩ : Q) := by
    intro _; simp only [Qeq, mul]; push_cast; ring_uor
  have hQP : Req (Rmul (ofQ (⟨(m : Int), 1⟩ : Q) Nat.one_pos) (ofQ (⟨1, m⟩ : Q) hm)) one :=
    Req_trans (Rmul_ofQ_ofQ Nat.one_pos hm) (Req_of_seq_Qeq hQPq)
  exact Rsub_eq_mul_of_inv (Rmul_Rinv_self hka) hQP

/-- **The `n`-th digamma term** `t_n(z) = 1/(n+1) − 1/(n+z)` (a genuine constructive real). -/
def digammaTerm (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den) (hcz : Rle (ofQ c hcd) z)
    (n : Nat) : Real :=
  Rsub (ofQ ⟨1, n + 1⟩ (Nat.succ_pos n))
    (Rinv (digammaArg z n) (digammaArgK c) (digammaArg_witness hcn hcd hcz n))

/-- `z ≥ 0` (from the positive rational floor `c ≤ z`). -/
theorem Rnonneg_of_ofQ_le {z : Real} {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) : Rnonneg z :=
  Rnonneg_of_Pos (Pos_of_Rle_ofQ hcn hcd hcz)

/-- `n + (−(n+1)) ≈ −1` as constructive reals (the constant part of the term shift). -/
theorem digamma_const_shift (n : Nat) :
    Req (Radd (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos)
        (Rneg (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos))) (Rneg one) := by
  apply Req_of_seq_Qeq; intro k
  show Qeq (add (⟨(n : Int), 1⟩ : Q) (neg (⟨((n : Int) + 1), 1⟩ : Q))) (neg (⟨1, 1⟩ : Q))
  simp only [Qeq, add, neg]; push_cast; ring_uor

/-- `(z + n) − (n+1) ≈ z − 1` as constructive reals. -/
theorem digammaArg_sub_succ_eq (z : Real) (n : Nat) :
    Req (Rsub (digammaArg z n) (ofQ ⟨((n : Int) + 1), 1⟩ Nat.one_pos)) (Rsub z one) := by
  -- (z + n) − (n+1) ≈ z + (n − (n+1)) ≈ z + (−1) ≈ z − 1
  have hassoc : Req (Rsub (digammaArg z n) (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos))
      (Radd z (Radd (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos)
        (Rneg (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos)))) :=
    Radd_assoc z (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos)
      (Rneg (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos))
  refine Req_trans hassoc (Radd_congr (Req_refl z) (digamma_const_shift n))

/-- The positive product factor `P_n = 1/(n+1) · 1/(z+n)` of the `n`-th term. -/
def digammaPfac (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den) (hcz : Rle (ofQ c hcd) z)
    (n : Nat) : Real :=
  Rmul (ofQ ⟨1, n + 1⟩ (Nat.succ_pos n))
    (Rinv (digammaArg z n) (digammaArgK c) (digammaArg_witness hcn hcd hcz n))

/-- `0 < (n+1)·n` for `n ≥ 1` (denominator positivity of the per-term bound). -/
theorem digamma_succ_mul_pos {n : Nat} (hn : 1 ≤ n) : 0 < (n + 1) * n :=
  Nat.mul_pos (Nat.succ_pos n) (by omega)

/-- `1/(z+n) ≤ 1/n` for `n ≥ 1` (the reciprocal is below `1/n` since `z+n ≥ n`). -/
theorem digamma_Rinv_le (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den) (hcz : Rle (ofQ c hcd) z)
    {n : Nat} (hn : 1 ≤ n) :
    Rle (Rinv (digammaArg z n) (digammaArgK c) (digammaArg_witness hcn hcd hcz n))
        (ofQ ⟨1, n⟩ (show 0 < n by omega)) := by
  have hnn : 0 < (⟨(n : Int), 1⟩ : Q).num := by show (0 : Int) < (n : Int); exact_mod_cast hn
  -- ofQ⟨n,1⟩ ≤ z + n  (since z ≥ 0)
  have hle : Rle (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos) (digammaArg z n) := by
    have hz : Rnonneg z := Rnonneg_of_ofQ_le hcn hcd hcz
    refine Rle_trans (Rle_self_Radd_right hz) ?_
    exact Rle_of_Req (Radd_comm (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos) z)
  have hkey := Rinv_le_ofQ_Qinv (digammaArg_witness hcn hcd hcz n) hnn Nat.one_pos hle
  -- Qinv ⟨n,1⟩ = ⟨1,n⟩
  refine Rle_trans hkey (Rle_of_Req (ofQ_congr (Qinv_den_pos hnn) (show 0 < n by omega) ?_))
  show Qeq (Qinv (⟨(n : Int), 1⟩ : Q)) (⟨1, n⟩ : Q)
  simp only [Qinv, Qeq]; push_cast; omega

/-- `0 ≤ P_n` and `P_n ≤ 1/((n+1)·n)`. -/
theorem digammaPfac_bound (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) {n : Nat} (hn : 1 ≤ n) :
    Rnonneg (digammaPfac z hcn hcd hcz n)
    ∧ Rle (digammaPfac z hcn hcd hcz n) (ofQ ⟨1, (n + 1) * n⟩ (digamma_succ_mul_pos hn)) := by
  have hfacnn : Rnonneg (ofQ (⟨1, n + 1⟩ : Q) (Nat.succ_pos n)) :=
    Rnonneg_ofQ (Nat.succ_pos n) (show (0 : Int) ≤ 1 by decide)
  have hInvnn : Rnonneg (Rinv (digammaArg z n) (digammaArgK c) (digammaArg_witness hcn hcd hcz n)) :=
    Rnonneg_Rinv _ _ _
  refine ⟨Rnonneg_Rmul hfacnn hInvnn, ?_⟩
  -- P_n = ofQ⟨1,n+1⟩ · Rinv ≤ ofQ⟨1,n+1⟩ · ofQ⟨1,n⟩ ≈ ofQ⟨1,(n+1)*n⟩
  refine Rle_trans (Rmul_le_Rmul_left hfacnn (digamma_Rinv_le z hcn hcd hcz hn)) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos n) (show 0 < n by omega)) ?_)
  exact ofQ_congr (Qmul_den_pos (Nat.succ_pos n) (show 0 < n by omega)) (digamma_succ_mul_pos hn)
    (by show Qeq (mul (⟨1, n + 1⟩ : Q) (⟨1, n⟩ : Q)) (⟨1, (n + 1) * n⟩ : Q)
        simp only [Qeq, mul]; push_cast; ring_uor)

/-- **Per-term two-sided bound** (`n ≥ 1`): `−B/((n+1)n) ≤ t_n(z) ≤ B/((n+1)n)`, where `B` is a
    rational enclosing `|z−1|` (`−ofQ B ≤ z−1 ≤ ofQ B`). The telescoping per-term estimate. -/
theorem digammaTerm_abs_le (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) {B : Q} (hBd : 0 < B.den)
    (hBlo : Rle (Rneg (ofQ B hBd)) (Rsub z one)) (hBhi : Rle (Rsub z one) (ofQ B hBd))
    {n : Nat} (hn : 1 ≤ n) :
    Rle (Rneg (ofQ (mul B (⟨1, (n + 1) * n⟩ : Q)) (Qmul_den_pos hBd (digamma_succ_mul_pos hn))))
        (digammaTerm z hcn hcd hcz n)
    ∧ Rle (digammaTerm z hcn hcd hcz n)
        (ofQ (mul B (⟨1, (n + 1) * n⟩ : Q)) (Qmul_den_pos hBd (digamma_succ_mul_pos hn))) := by
  -- t_n ≈ (z−1) · P_n
  have hPbound := digammaPfac_bound z hcn hcd hcz hn
  have hPnn := hPbound.1
  have hPhi := hPbound.2
  have hPlo : Rle (Rneg (ofQ (⟨1, (n + 1) * n⟩ : Q) (digamma_succ_mul_pos hn)))
      (digammaPfac z hcn hcd hcz n) := by
    refine Rle_trans ?_ (Rle_zero_of_Rnonneg hPnn)
    -- −ofQ⟨1,(n+1)n⟩ ≤ 0  (since ofQ⟨1,(n+1)n⟩ ≥ 0)
    have h0 : Rle zero (ofQ (⟨1, (n + 1) * n⟩ : Q) (digamma_succ_mul_pos hn)) :=
      Rle_zero_of_Rnonneg (Rnonneg_ofQ (digamma_succ_mul_pos hn) (show (0 : Int) ≤ 1 by decide))
    have hnz : Req (Rneg zero) zero :=
      Req_of_seq_Qeq (fun _ => by simp only [Rneg, zero, ofQ, Qeq, neg]; decide)
    exact Rle_trans (Rle_Rneg h0) (Rle_of_Req hnz)
  -- identity: t_n ≈ (z−1)·P_n
  have hid : Req (digammaTerm z hcn hcd hcz n)
      (Rmul (Rsub z one) (digammaPfac z hcn hcd hcz n)) := by
    have h1 : Req (digammaTerm z hcn hcd hcz n)
        (Rmul (Rsub (digammaArg z n) (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos))
          (digammaPfac z hcn hcd hcz n)) := by
      show Req (Rsub (ofQ (⟨1, n + 1⟩ : Q) (Nat.succ_pos n))
          (Rinv (digammaArg z n) (digammaArgK c) (digammaArg_witness hcn hcd hcz n)))
        (Rmul (Rsub (digammaArg z n) (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos))
          (digammaPfac z hcn hcd hcz n))
      have hsub := Rinv_ofQ_sub_eq (digammaArg_witness hcn hcd hcz n) (m := n + 1) (Nat.succ_pos n)
      -- the literal ⟨(n:Int)+1,1⟩ vs ⟨((n+1:Nat)),1⟩ agree
      refine Req_trans ?_ hsub
      exact Req_refl _
    exact Req_trans h1 (Rmul_congr (digammaArg_sub_succ_eq z n) (Req_refl _))
  -- product bounds
  have hBlo' : Rle (Rneg (ofQ B hBd)) (Rsub z one) := hBlo
  have hupper : Rle (Rmul (Rsub z one) (digammaPfac z hcn hcd hcz n))
      (Rmul (ofQ B hBd) (ofQ (⟨1, (n + 1) * n⟩ : Q) (digamma_succ_mul_pos hn))) :=
    Rmul_le_mul_of_abs hBlo' hBhi hPlo hPhi
  have hlower : Rle (Rneg (Rmul (ofQ B hBd) (ofQ (⟨1, (n + 1) * n⟩ : Q) (digamma_succ_mul_pos hn))))
      (Rmul (Rsub z one) (digammaPfac z hcn hcd hcz n)) :=
    Rneg_mul_le_of_abs hBlo' hBhi hPlo hPhi
  -- ofQ B · ofQ⟨1,(n+1)n⟩ ≈ ofQ (mul B ⟨1,(n+1)n⟩)
  have hprodeq : Req (Rmul (ofQ B hBd) (ofQ (⟨1, (n + 1) * n⟩ : Q) (digamma_succ_mul_pos hn)))
      (ofQ (mul B (⟨1, (n + 1) * n⟩ : Q)) (Qmul_den_pos hBd (digamma_succ_mul_pos hn))) :=
    Rmul_ofQ_ofQ hBd (digamma_succ_mul_pos hn)
  refine ⟨?_, ?_⟩
  · refine Rle_trans (Rle_Rneg (Rle_of_Req hprodeq)) ?_
    exact Rle_trans hlower (Rle_of_Req (Req_symm hid))
  · exact Rle_trans (Rle_of_Req hid) (Rle_trans hupper (Rle_of_Req hprodeq))

-- ---------------------------------------------------------------------------
-- The partial sum `D z N = Σ_{n<N} t_n(z)` and the telescoping tail bound.
-- ---------------------------------------------------------------------------

/-- `(a + t) − b ≈ (a − b) + t` (local copy of `Rsub_Radd_left`). -/
theorem digamma_Rsub_Radd_left (a t b : Real) : Req (Rsub (Radd a t) b) (Radd (Rsub a b) t) :=
  Req_trans (Radd_assoc a t (Rneg b))
    (Req_trans (Radd_congr (Req_refl a) (Radd_comm t (Rneg b)))
      (Req_symm (Radd_assoc a (Rneg b) t)))

/-- A generic finite partial sum `Σ_{i<d} V i`. -/
def digammaRsum (V : Nat → Real) : Nat → Real
  | 0 => zero
  | (d + 1) => Radd (digammaRsum V d) (V d)

/-- **The digamma partial sum** `D z N = Σ_{n<N} t_n(z)`. -/
def digammaSum (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den) (hcz : Rle (ofQ c hcd) z) :
    Nat → Real
  | 0 => zero
  | (N + 1) => Radd (digammaSum z hcn hcd hcz N) (digammaTerm z hcn hcd hcz N)

/-- **The contiguous difference is a range sum**: `D(N+d) − D(N) ≈ Σ_{i<d} t_{N+i}`. -/
theorem digammaSum_diff_eq (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) (N : Nat) :
    ∀ d, Req (Rsub (digammaSum z hcn hcd hcz (N + d)) (digammaSum z hcn hcd hcz N))
        (digammaRsum (fun i => digammaTerm z hcn hcd hcz (N + i)) d)
  | 0 => Radd_neg _
  | (d + 1) =>
      Req_trans (digamma_Rsub_Radd_left (digammaSum z hcn hcd hcz (N + d))
          (digammaTerm z hcn hcd hcz (N + d)) (digammaSum z hcn hcd hcz N))
        (Radd_congr (digammaSum_diff_eq z hcn hcd hcz N d) (Req_refl _))

/-- The telescoping rational tail `B·(1/N − 1/(N+d))`, with positive denominator. The `1 ≤ N`
    requirement is carried at the type for the downstream denominator-positivity proofs. -/
def digammaTailQ (B : Q) (N d : Nat) (_hN : 1 ≤ N) : Q :=
  mul B (Qsub (⟨1, N⟩ : Q) (⟨1, N + d⟩ : Q))

theorem digammaTailQ_den_pos (B : Q) (N d : Nat) (hN : 1 ≤ N) (hBd : 0 < B.den) :
    0 < (digammaTailQ B N d hN).den :=
  Qmul_den_pos hBd (Qsub_den_pos (show 0 < N by omega) (show 0 < N + d by omega))

/-- **The telescoping tail bound** (`1 ≤ N`): `−ofQ(B·(1/N − 1/(N+d))) ≤ Σ_{i<d} t_{N+i} ≤
    ofQ(B·(1/N − 1/(N+d)))`. By induction on `d`: the per-term bound `1/((m+1)m) = 1/m − 1/(m+1)`
    telescopes. -/
theorem digammaTail_two_sided (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) {B : Q} (hBd : 0 < B.den)
    (hBlo : Rle (Rneg (ofQ B hBd)) (Rsub z one)) (hBhi : Rle (Rsub z one) (ofQ B hBd))
    {N : Nat} (hN : 1 ≤ N) :
    ∀ d, Rle (Rneg (ofQ (digammaTailQ B N d hN) (digammaTailQ_den_pos B N d hN hBd)))
          (digammaRsum (fun i => digammaTerm z hcn hcd hcz (N + i)) d)
        ∧ Rle (digammaRsum (fun i => digammaTerm z hcn hcd hcz (N + i)) d)
          (ofQ (digammaTailQ B N d hN) (digammaTailQ_den_pos B N d hN hBd))
  | 0 => by
    -- d=0: sum = 0, tail = B·(1/N − 1/N) = 0
    have heq0 : Req (ofQ (digammaTailQ B N 0 hN) (digammaTailQ_den_pos B N 0 hN hBd)) zero := by
      refine ofQ_congr (digammaTailQ_den_pos B N 0 hN hBd) (by decide) ?_
      show Qeq (mul B (Qsub (⟨1, N⟩ : Q) (⟨1, N + 0⟩ : Q))) (⟨0, 1⟩ : Q)
      simp only [Qeq, mul, Qsub, add, neg]; push_cast; ring_uor
    have hz0 : Req (Rneg (ofQ (digammaTailQ B N 0 hN) (digammaTailQ_den_pos B N 0 hN hBd))) zero := by
      refine Req_trans (Rneg_congr heq0) ?_
      exact Req_of_seq_Qeq (fun _ => by simp only [Rneg, zero, ofQ, Qeq, neg]; decide)
    exact ⟨Rle_of_Req hz0, Rle_of_Req (Req_symm heq0)⟩
  | (d + 1) => by
    obtain ⟨hlo, hhi⟩ := digammaTail_two_sided z hcn hcd hcz hBd hBlo hBhi hN d
    have hnN : 1 ≤ N + d := by omega
    obtain ⟨htlo, hthi⟩ := digammaTerm_abs_le z hcn hcd hcz hBd hBlo hBhi hnN
    -- the per-term denominator (N+d+1)*(N+d)
    -- sum (d+1) = sum d + t_{N+d}
    -- upper:  ≤ ofQ(tail d) + ofQ(B·1/((N+d+1)(N+d))) ≈ ofQ(tail (d+1))
    have hkeyU : Req (Radd (ofQ (digammaTailQ B N d hN) (digammaTailQ_den_pos B N d hN hBd))
        (ofQ (mul B (⟨1, (N + d + 1) * (N + d)⟩ : Q)) (Qmul_den_pos hBd (digamma_succ_mul_pos hnN))))
        (ofQ (digammaTailQ B N (d + 1) hN) (digammaTailQ_den_pos B N (d + 1) hN hBd)) := by
      refine Req_trans (Radd_ofQ_ofQ (digammaTailQ_den_pos B N d hN hBd)
        (Qmul_den_pos hBd (digamma_succ_mul_pos hnN))) ?_
      refine ofQ_congr _ (digammaTailQ_den_pos B N (d + 1) hN hBd) ?_
      show Qeq (add (mul B (Qsub (⟨1, N⟩ : Q) (⟨1, N + d⟩ : Q)))
          (mul B (⟨1, (N + d + 1) * (N + d)⟩ : Q)))
        (mul B (Qsub (⟨1, N⟩ : Q) (⟨1, N + (d + 1)⟩ : Q)))
      simp only [Qeq, mul, Qsub, add, neg]; push_cast; ring_uor
    have hupper : Rle (digammaRsum (fun i => digammaTerm z hcn hcd hcz (N + i)) (d + 1))
        (ofQ (digammaTailQ B N (d + 1) hN) (digammaTailQ_den_pos B N (d + 1) hN hBd)) := by
      show Rle (Radd (digammaRsum (fun i => digammaTerm z hcn hcd hcz (N + i)) d)
          (digammaTerm z hcn hcd hcz (N + d))) _
      exact Rle_trans (Radd_le_add hhi hthi) (Rle_of_Req hkeyU)
    -- lower:  ≥ −ofQ(tail d) − ofQ(B·1/(..)) ≈ −ofQ(tail (d+1))
    have hkeyL : Req (Rneg (ofQ (digammaTailQ B N (d + 1) hN) (digammaTailQ_den_pos B N (d + 1) hN hBd)))
        (Radd (Rneg (ofQ (digammaTailQ B N d hN) (digammaTailQ_den_pos B N d hN hBd)))
          (Rneg (ofQ (mul B (⟨1, (N + d + 1) * (N + d)⟩ : Q))
            (Qmul_den_pos hBd (digamma_succ_mul_pos hnN))))) :=
      Req_trans (Rneg_congr (Req_symm hkeyU)) (Rneg_Radd _ _)
    have hlower : Rle (Rneg (ofQ (digammaTailQ B N (d + 1) hN) (digammaTailQ_den_pos B N (d + 1) hN hBd)))
        (digammaRsum (fun i => digammaTerm z hcn hcd hcz (N + i)) (d + 1)) := by
      show Rle _ (Radd (digammaRsum (fun i => digammaTerm z hcn hcd hcz (N + i)) d)
          (digammaTerm z hcn hcd hcz (N + d)))
      exact Rle_trans (Rle_of_Req hkeyL) (Radd_le_add hlo htlo)
    exact ⟨hlower, hupper⟩

-- ---------------------------------------------------------------------------
-- The reindex absorbing `B`, the regularity, and the limit `digammaCore` / `Digamma`.
-- ---------------------------------------------------------------------------

/-- The reindex `Midx j = (B.num.toNat + 1)·(j+1)` absorbing the constant `B` (mirror `czetaMidx`). -/
def digammaMidx (B : Q) (j : Nat) : Nat := (B.num.toNat + 1) * (j + 1)

/-- `Midx j ≥ 1`. -/
theorem digammaMidx_ge_one (B : Q) (j : Nat) : 1 ≤ digammaMidx B j := by
  unfold digammaMidx; have : 0 < (B.num.toNat + 1) * (j + 1) := Nat.mul_pos (by omega) (by omega)
  omega

/-- `Midx` is monotone. -/
theorem digammaMidx_mono (B : Q) {j k : Nat} (hjk : j ≤ k) : digammaMidx B j ≤ digammaMidx B k :=
  Nat.mul_le_mul_left _ (by omega)

/-- **The reindexed tail is `≤ 1/(j+1)`**: `B·(1/Midx j − 1/(Midx j + d)) ≤ 1/(j+1)` (for `0 ≤ B.num`). -/
theorem digammaTailQ_Midx_le (B : Q) (hBd : 0 < B.den) (hB0 : 0 ≤ B.num) (j d : Nat) :
    Qle (digammaTailQ B (digammaMidx B j) d (digammaMidx_ge_one B j)) (⟨1, j + 1⟩ : Q) := by
  -- B·(1/N − 1/(N+d)) ≤ B·(1/N) ≤ 1/(j+1)
  have hNpos : 0 < digammaMidx B j := digammaMidx_ge_one B j
  -- first:  tail ≤ B·(1/N)   (subtract a non-negative reciprocal, multiply by B ≥ 0)
  have hsuble : Qle (Qsub (⟨1, digammaMidx B j⟩ : Q) (⟨1, digammaMidx B j + d⟩ : Q))
      (⟨1, digammaMidx B j⟩ : Q) := by
    show (Qsub (⟨1, digammaMidx B j⟩ : Q) (⟨1, digammaMidx B j + d⟩ : Q)).num
        * (((⟨1, digammaMidx B j⟩ : Q).den : Int))
      ≤ (1 : Int) * ((Qsub (⟨1, digammaMidx B j⟩ : Q) (⟨1, digammaMidx B j + d⟩ : Q)).den : Int)
    simp only [Qsub, add, neg]; push_cast
    -- goal:  (1·(N+d) + (-1)·N) · N ≤ 1 · (N · (N+d))
    have hN : (0 : Int) ≤ ((digammaMidx B j : Nat) : Int) := Int.ofNat_nonneg _
    have hsq : (0 : Int) ≤ ((digammaMidx B j : Nat) : Int) * ((digammaMidx B j : Nat) : Int) :=
      Int.mul_nonneg hN hN
    have eL : (1 * (((digammaMidx B j : Nat) : Int) + ((d : Nat) : Int))
          + -1 * ((digammaMidx B j : Nat) : Int)) * ((digammaMidx B j : Nat) : Int)
        = ((d : Nat) : Int) * ((digammaMidx B j : Nat) : Int) := by ring_uor
    have eR : (1 : Int) * (((digammaMidx B j : Nat) : Int)
          * (((digammaMidx B j : Nat) : Int) + ((d : Nat) : Int)))
        = ((digammaMidx B j : Nat) : Int) * ((digammaMidx B j : Nat) : Int)
          + ((d : Nat) : Int) * ((digammaMidx B j : Nat) : Int) := by ring_uor
    rw [eL, eR]; omega
  have hstep1 : Qle (digammaTailQ B (digammaMidx B j) d (digammaMidx_ge_one B j))
      (mul B (⟨1, digammaMidx B j⟩ : Q)) :=
    Qmul_le_mul_left hB0 hsuble
  -- second:  B·(1/N) ≤ 1/(j+1)   since  B.num·(j+1) ≤ N·B.den
  have hstep2 : Qle (mul B (⟨1, digammaMidx B j⟩ : Q)) (⟨1, j + 1⟩ : Q) := by
    show (mul B (⟨1, digammaMidx B j⟩ : Q)).num * (((j + 1 : Nat)) : Int)
      ≤ (1 : Int) * ((mul B (⟨1, digammaMidx B j⟩ : Q)).den : Int)
    simp only [mul]
    push_cast
    -- B.num·1·(j+1) ≤ 1·(B.den·N) ,  N = (B.num.toNat+1)(j+1)
    have hNeq : ((digammaMidx B j : Nat) : Int) = ((B.num.toNat : Int) + 1) * ((j : Int) + 1) := by
      unfold digammaMidx; push_cast; ring_uor
    have hBtoNat : (B.num.toNat : Int) = B.num := Int.toNat_of_nonneg hB0
    have hBden1 : (1 : Int) ≤ (B.den : Int) := by exact_mod_cast hBd
    rw [hNeq, hBtoNat]
    -- goal:  B.num * 1 * (j+1) ≤ 1 * (B.den * ((B.num+1)*(j+1)))
    have hj1 : (0 : Int) ≤ (j : Int) + 1 := by omega
    have hfac : B.num * ((j : Int) + 1) ≤ (B.num + 1) * ((j : Int) + 1) :=
      Int.mul_le_mul_of_nonneg_right (by omega) hj1
    have hBden_mul : (B.num + 1) * ((j : Int) + 1)
        ≤ (B.den : Int) * ((B.num + 1) * ((j : Int) + 1)) := by
      have hpos : (0 : Int) ≤ (B.num + 1) * ((j : Int) + 1) :=
        Int.mul_nonneg (by omega) hj1
      have := Int.mul_le_mul_of_nonneg_right hBden1 hpos
      rw [Int.one_mul] at this; exact this
    have : B.num * ((j : Int) + 1) ≤ (B.den : Int) * ((B.num + 1) * ((j : Int) + 1)) :=
      Int.le_trans hfac hBden_mul
    -- reconcile the explicit `* 1` / `1 *`
    have e1 : B.num * 1 * ((j : Int) + 1) = B.num * ((j : Int) + 1) := by ring_uor
    have e2 : (1 : Int) * ((B.den : Int) * ((B.num + 1) * ((j : Int) + 1)))
        = (B.den : Int) * ((B.num + 1) * ((j : Int) + 1)) := by ring_uor
    rw [e1, e2]; exact this
  exact Qle_trans (Qmul_den_pos hBd hNpos) hstep1 hstep2

/-- **The reindexed digamma partial sums form a regular sequence** (`RReg`), the input to `Rlim`. -/
theorem digammaCore_RReg (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) {B : Q} (hBd : 0 < B.den) (hB0 : 0 ≤ B.num)
    (hBlo : Rle (Rneg (ofQ B hBd)) (Rsub z one)) (hBhi : Rle (Rsub z one) (ofQ B hBd)) :
    RReg (fun j => digammaSum z hcn hcd hcz (digammaMidx B j)) := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · -- j ≤ k:  D(Midx j) − D(Midx k) = −Σ ;  −Σ ≤ ofQ(tail) ≤ ofQ⟨1,j+1⟩
    have hM : digammaMidx B j ≤ digammaMidx B k := digammaMidx_mono B hjk
    obtain ⟨d, hd⟩ : ∃ d, digammaMidx B k = digammaMidx B j + d := ⟨_, (Nat.add_sub_cancel' hM).symm⟩
    have hdiff := digammaSum_diff_eq z hcn hcd hcz (digammaMidx B j) d
    rw [← hd] at hdiff
    obtain ⟨hlo, _⟩ := digammaTail_two_sided z hcn hcd hcz hBd hBlo hBhi (digammaMidx_ge_one B j) d
    -- Rsub (D(Midx j)) (D(Midx k)) = −(D(Midx k) − D(Midx j))
    have hneg : Req (Rsub (digammaSum z hcn hcd hcz (digammaMidx B j))
        (digammaSum z hcn hcd hcz (digammaMidx B k)))
        (Rneg (digammaRsum (fun i => digammaTerm z hcn hcd hcz (digammaMidx B j + i)) d)) :=
      Req_trans (Req_symm (Rneg_Rsub _ _)) (Rneg_congr hdiff)
    -- −Σ ≤ ofQ(tail)   (from −ofQ(tail) ≤ Σ)
    have hle : Rle (Rneg (digammaRsum (fun i => digammaTerm z hcn hcd hcz (digammaMidx B j + i)) d))
        (ofQ (digammaTailQ B (digammaMidx B j) d (digammaMidx_ge_one B j))
          (digammaTailQ_den_pos B (digammaMidx B j) d (digammaMidx_ge_one B j) hBd)) := by
      refine Rle_trans (Rle_Rneg hlo) (Rle_of_Req ?_)
      exact Req_of_seq_Qeq (fun n => by
        simp only [Rneg, ofQ, Qeq, neg]; push_cast; ring_uor)
    refine Rle_trans (Rle_of_Req hneg) (Rle_trans hle ?_)
    refine Rle_trans (Rle_ofQ_ofQ (digammaTailQ_den_pos B (digammaMidx B j) d _ hBd)
      (Nat.succ_pos _) (digammaTailQ_Midx_le B hBd hB0 j d)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos _) _ (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · -- k ≤ j:  D(Midx j) − D(Midx k) = Σ ;  Σ ≤ ofQ(tail) ≤ ofQ⟨1,k+1⟩
    have hM : digammaMidx B k ≤ digammaMidx B j := digammaMidx_mono B hkj
    obtain ⟨d, hd⟩ : ∃ d, digammaMidx B j = digammaMidx B k + d := ⟨_, (Nat.add_sub_cancel' hM).symm⟩
    have hdiff := digammaSum_diff_eq z hcn hcd hcz (digammaMidx B k) d
    rw [← hd] at hdiff
    obtain ⟨_, hhi⟩ := digammaTail_two_sided z hcn hcd hcz hBd hBlo hBhi (digammaMidx_ge_one B k) d
    refine Rle_trans (Rle_of_Req hdiff) (Rle_trans hhi ?_)
    refine Rle_trans (Rle_ofQ_ofQ (digammaTailQ_den_pos B (digammaMidx B k) d _ hBd)
      (Nat.succ_pos _) (digammaTailQ_Midx_le B hBd hB0 k d)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos _) _
      (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **The digamma core** `Σ_{n=0}^∞ [1/(n+1) − 1/(n+z)]`, as a genuine constructive real (`Rlim`). -/
def digammaCore (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) {B : Q} (hBd : 0 < B.den) (hB0 : 0 ≤ B.num)
    (hBlo : Rle (Rneg (ofQ B hBd)) (Rsub z one)) (hBhi : Rle (Rsub z one) (ofQ B hBd)) : Real :=
  Rlim (fun j => digammaSum z hcn hcd hcz (digammaMidx B j))
    (digammaCore_RReg z hcn hcd hcz hBd hB0 hBlo hBhi)

/-- **The digamma function `ψ(z) = Γ′/Γ(z)`** (the archimedean place), as a genuine constructive real:
    `ψ(z) = −γ + Σ_{n=0}^∞ [1/(n+1) − 1/(n+z)]`  (`ψ(1) = −γ`, `ψ(2) = 1 − γ`). -/
def Digamma (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) {B : Q} (hBd : 0 < B.den) (hB0 : 0 ≤ B.num)
    (hBlo : Rle (Rneg (ofQ B hBd)) (Rsub z one)) (hBhi : Rle (Rsub z one) (ofQ B hBd)) : Real :=
  Radd (Rneg Rgamma_h) (digammaCore z hcn hcd hcz hBd hB0 hBlo hBhi)

-- ---------------------------------------------------------------------------
-- **`ψ(1) = −γ`** — the convention witness (non-vacuity of `Digamma`). At `z = 1` every term
-- `1/(n+1) − 1/(n+1) ≈ 0`, so the core series vanishes and `ψ(1) ≈ −γ`.
-- ---------------------------------------------------------------------------

/-- **The factored digamma term** `t_n(z) ≈ (z−1)·P_n` (no bound hypotheses; the algebraic core of
    `digammaTerm_abs_le`'s identity, extracted for the `ψ(1)=−γ` witness). -/
theorem digammaTerm_eq_factored (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) (n : Nat) :
    Req (digammaTerm z hcn hcd hcz n) (Rmul (Rsub z one) (digammaPfac z hcn hcd hcz n)) := by
  have h1 : Req (digammaTerm z hcn hcd hcz n)
      (Rmul (Rsub (digammaArg z n) (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos))
        (digammaPfac z hcn hcd hcz n)) := by
    show Req (Rsub (ofQ (⟨1, n + 1⟩ : Q) (Nat.succ_pos n))
        (Rinv (digammaArg z n) (digammaArgK c) (digammaArg_witness hcn hcd hcz n)))
      (Rmul (Rsub (digammaArg z n) (ofQ (⟨((n : Int) + 1), 1⟩ : Q) Nat.one_pos))
        (digammaPfac z hcn hcd hcz n))
    have hsub := Rinv_ofQ_sub_eq (digammaArg_witness hcn hcd hcz n) (m := n + 1) (Nat.succ_pos n)
    exact Req_trans (Req_refl _) hsub
  exact Req_trans h1 (Rmul_congr (digammaArg_sub_succ_eq z n) (Req_refl _))

/-- **The digamma term vanishes at `z = 1`**: `t_n(1) ≈ 0` (since `z−1 ≈ 0`). -/
theorem digammaTerm_one_eq_zero {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) one) (n : Nat) :
    Req (digammaTerm one hcn hcd hcz n) zero := by
  refine Req_trans (digammaTerm_eq_factored one hcn hcd hcz n) ?_
  -- (1−1)·P ≈ 0·P ≈ P·0 ≈ 0
  have hz : Req (Rsub one one) zero := Radd_neg one
  refine Req_trans (Rmul_congr hz (Req_refl _)) ?_
  refine Req_trans (Rmul_comm zero (digammaPfac one hcn hcd hcz n)) ?_
  exact Rmul_zero (digammaPfac one hcn hcd hcz n)

/-- **The digamma partial sum vanishes at `z = 1`**: `D 1 N ≈ 0` for all `N`. -/
theorem digammaSum_one_eq_zero {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) one) :
    ∀ N, Req (digammaSum one hcn hcd hcz N) zero
  | 0 => Req_refl zero
  | (N + 1) => by
      show Req (Radd (digammaSum one hcn hcd hcz N) (digammaTerm one hcn hcd hcz N)) zero
      refine Req_trans (Radd_congr (digammaSum_one_eq_zero hcn hcd hcz N)
        (digammaTerm_one_eq_zero hcn hcd hcz N)) ?_
      exact Radd_zero zero

/-- **A sequence that is `≈ 0` pointwise tends to `0`** (every term equal to `0` is well within the
    convergence modulus). -/
theorem RTendsTo_zero_of_Req_zero {X : Nat → Real} (h : ∀ j, Req (X j) zero) :
    RTendsTo X zero := by
  intro k n
  -- |（X k).seq n − 0| ≤ 2/(n+1) ≤ 2/(k+1) + 2/(n+1)
  have hk := h k n
  refine Qle_trans (show 0 < (⟨2, n + 1⟩ : Q).den by exact Nat.succ_pos n) hk ?_
  exact Qle_add_self (show (0 : Int) ≤ (2 : Int) by omega)

/-- **The digamma core vanishes at `z = 1`**: `digammaCore 1 … ≈ 0`. -/
theorem digammaCore_one_eq_zero {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) one) {B : Q} (hBd : 0 < B.den) (hB0 : 0 ≤ B.num)
    (hBlo : Rle (Rneg (ofQ B hBd)) (Rsub one one)) (hBhi : Rle (Rsub one one) (ofQ B hBd)) :
    Req (digammaCore one hcn hcd hcz hBd hB0 hBlo hBhi) zero := by
  -- the underlying regular sequence is `≈0` pointwise, so it tends to `0`; `Rlim` tends to itself;
  -- uniqueness gives `Rlim ≈ 0`.
  have hseq : ∀ j, Req (digammaSum one hcn hcd hcz (digammaMidx B j)) zero :=
    fun j => digammaSum_one_eq_zero hcn hcd hcz (digammaMidx B j)
  have hto0 : RTendsTo (fun j => digammaSum one hcn hcd hcz (digammaMidx B j)) zero :=
    RTendsTo_zero_of_Req_zero hseq
  have htoL := Rlim_tendsTo (fun j => digammaSum one hcn hcd hcz (digammaMidx B j))
    (digammaCore_RReg one hcn hcd hcz hBd hB0 hBlo hBhi)
  exact RTendsTo_unique htoL hto0

/-- **`ψ(1) = −γ`** (the digamma convention witness; proof that `Digamma` is non-vacuously the
    archimedean `Γ′/Γ`). The series at `z = 1` is all-zero, so `Digamma 1 … = −γ + 0 ≈ −γ`. -/
theorem Digamma_one_eq_neg_gamma :
    Req (Digamma one (c := ⟨1, 1⟩) (by decide) (by decide)
          (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _)))
          (B := ⟨1, 1⟩) (by decide) (by decide)
          -- hBlo : −1 ≤ (1−1) ≈ 0   (since ofQ⟨1,1⟩ ≥ 0 ⟹ −ofQ⟨1,1⟩ ≤ 0 ≈ 1−1)
          (Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg (Rnonneg_ofQ (by decide) (by decide))))
            (Rle_trans (Rle_of_Req Rneg_zero) (Rle_of_Req (Req_symm (Radd_neg one)))))
          -- hBhi : (1−1) ≈ 0 ≤ 1
          (Rle_trans (Rle_of_Req (Radd_neg one))
            (Rle_zero_of_Rnonneg (Rnonneg_ofQ (by decide) (by decide)))))
        (Rneg Rgamma_h) := by
  show Req (Radd (Rneg Rgamma_h) (digammaCore one _ _ _ _ _ _ _)) (Rneg Rgamma_h)
  refine Req_trans (Radd_congr (Req_refl (Rneg Rgamma_h)) (digammaCore_one_eq_zero _ _ _ _ _ _ _)) ?_
  exact Radd_zero (Rneg Rgamma_h)

-- ===========================================================================
-- **Spouge's Γ approximant** (the computational `Γ` object on the real line `z > 0`).
--
-- Spouge's approximation (Spouge 1994, *SIAM J. Numer. Anal.* **31**(3), 931–944; cf. Pugh's thesis,
-- *An Analysis of the Lanczos Gamma Approximation*, 2004, eqns 2.18–2.19):
--
--   `Γ(z+1) = (z+a)^{z+½} · e^{−(z+a)} · ( c₀ + Σ_{k=1}^{N} cₖ/(z+k) ) + ε_S(a,z)`,
--     `N = ⌈a⌉ − 1`,
--     `c₀ = √(2π) = exp(½·log 2π)`,
--     `cₖ = ((−1)^{k−1}/(k−1)!) · (a−k)^{k−½} · e^{a−k}`     (real; `a−k > 0` for `k ≤ N`),
--
-- with the KNOWN explicit RELATIVE error bound (`a ≥ 3`, `Re z ≥ 0`)
--
--   `|ε_S(a,z)| < √a · (2π)^{−(a+½)} · 1/Re(z+a)`.
--
-- The bound is DOCUMENTED here only; we do **not** state it as a Lean theorem, because a rigorous proof
-- presupposes an independent construction of `Γ` against which to compare. The approximant `SpougeGamma`
-- below is an axiom-clean `def`, built entirely from `exp`/`log`/reciprocal of positive reals — every
-- power is `x^y := RrpowPos x _ _ y = exp(y·log x)`, so NO square-root primitive is needed.
-- ===========================================================================

/-- **`√(2π) = exp(½·log 2π)`** (Spouge's `c₀`), built from `exp`/`log` only (`log 2π = log 2 + log π`). -/
def spougeSqrt2pi : Real :=
  RexpReal (Rmul (ofQ ⟨1, 2⟩ (by decide)) (Radd Rlog2c Rlogπc))

/-- The rational scalar `(−1)^{k−1}/(k−1)!` of Spouge's `cₖ` (numerator `±1` via `(-1)^{k-1} : Int`,
    denominator `(k−1)!`). -/
def spougeSign (k : Nat) : Q := ⟨(-1 : Int) ^ (k - 1), fct (k - 1)⟩

/-- The denominator `(k−1)!` of `spougeSign k` is positive. -/
theorem spougeSign_den_pos (k : Nat) : 0 < (spougeSign k).den := fct_pos (k - 1)

/-- `(a − k).den = a.den` (used for the `ofQ` denominator positivity of `a−k`). -/
theorem Qsub_nat_den_pos {a : Q} (hadp : 0 < a.den) (k : Nat) :
    0 < (Qsub a (⟨(k : Int), 1⟩ : Q)).den := by
  show 0 < a.den * 1; omega

/-- **Spouge's coefficient** `cₖ = ((−1)^{k−1}/(k−1)!) · (a−k)^{k−½} · e^{a−k}` (real), for a rational
    parameter `a` (denominator positive `hadp`) with `a − k > 1` (so the positive base `a−k` of the
    half-integer power `(a−k)^{k−½} = exp((k−½)·log(a−k))` has the immediate positivity witness
    `Qbound 0 = ⟨1,1⟩ < a−k` at index `0`). The exponent `k − ½ = (2k−1)/2` is the rational `⟨2k−1, 2⟩`.

    Marked `@[irreducible]`: the body nests `exp`/`log` of `a−k`, so leaving it reducible lets the
    bracket recursion (`spougeBracketAux`) drive `whnf` into those transcendental sub-terms, which is
    expensive and can stall elaboration. Sealing `spougeCoeff` keeps each `cₖ` an opaque atom. -/
@[irreducible] def spougeCoeff (a : Q) (hadp : 0 < a.den) (k : Nat)
    (hak : Qlt (⟨1, 1⟩ : Q) (Qsub a ⟨(k : Int), 1⟩)) : Real :=
  Rmul
    (Rmul
      (ofQ (spougeSign k) (spougeSign_den_pos k))
      (RrpowPos (ofQ (Qsub a ⟨(k : Int), 1⟩) (Qsub_nat_den_pos hadp k)) 0 hak
        (ofQ ⟨2 * (k : Int) - 1, 2⟩ (show 0 < 2 by decide))))
    (RexpReal (ofQ (Qsub a ⟨(k : Int), 1⟩) (Qsub_nat_den_pos hadp k)))

/-- The Spouge bracket `c₀ + Σ_{k=1}^{N} cₖ · 1/(z+k)`, accumulated downward over `k = N, N−1, …, 1`.
    The hypothesis `ha k _ _` supplies the per-`k` positivity `a − k > 1`; each reciprocal `1/(z+k)`
    reuses the `digammaArg`/`digammaArg_witness` enclosure machinery (`z ≥ c > 0 ⟹ z+k > 0`). -/
def spougeBracketAux (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) (a : Q) (hadp : 0 < a.den) :
    (m : Nat) → (ha : ∀ (k : Nat), 1 ≤ k → k ≤ m → Qlt (⟨1, 1⟩ : Q) (Qsub a ⟨(k : Int), 1⟩)) → Real
  | 0, _ => spougeSqrt2pi
  | (k + 1), ha =>
      Radd (spougeBracketAux z hcn hcd hcz a hadp k
              (fun j hj1 hjk => ha j hj1 (Nat.le_succ_of_le hjk)))
        (Rmul (spougeCoeff a hadp (k + 1) (ha (k + 1) (Nat.le_add_left 1 k) (Nat.le_refl _)))
          (Rinv (digammaArg z (k + 1)) (digammaArgK c) (digammaArg_witness hcn hcd hcz (k + 1))))

/-- **Spouge's bracket** `c₀ + Σ_{k=1}^{N} cₖ/(z+k)`. The hypothesis `ha` is bounded `1 ≤ k ≤ N`
    (only those `cₖ` are summed); this is what makes `ha` satisfiable for a concrete `a` (e.g. `a = N+2`).
    The earlier unbounded `∀ k ≥ 1` was vacuous: no finite `a` keeps `a − k > 1` for arbitrarily large `k`. -/
def spougeBracket (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) (a : Q) (hadp : 0 < a.den) (N : Nat)
    (ha : ∀ (k : Nat), 1 ≤ k → k ≤ N → Qlt (⟨1, 1⟩ : Q) (Qsub a ⟨(k : Int), 1⟩)) : Real :=
  spougeBracketAux z hcn hcd hcz a hadp N ha

/-- The base `z + a` of Spouge's leading power, as a constructive real. -/
def spougeBase (z : Real) (a : Q) (hadp : 0 < a.den) : Real := Radd z (ofQ a hadp)

/-- `z + a ≥ c` (the floor `c ≤ z` plus `a > 0`), hence the positivity witness for the base power. -/
theorem ofQ_le_spougeBase {z : Real} {c : Q} (hcd : 0 < c.den) (hcz : Rle (ofQ c hcd) z)
    {a : Q} (hadp : 0 < a.den) (han : 0 ≤ a.num) : Rle (ofQ c hcd) (spougeBase z a hadp) :=
  Rle_trans hcz (Rle_self_Radd_right (Rnonneg_ofQ hadp han))

/-- The positivity witness for `z + a` at index `digammaArgK c`. -/
theorem spougeBase_witness {z : Real} {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) {a : Q} (hadp : 0 < a.den) (han : 0 ≤ a.num) :
    Qlt (Qbound (digammaArgK c)) ((spougeBase z a hadp).seq (digammaArgK c)) :=
  Rlt_Qbound_of_Rle_ofQ hcn hcd (ofQ_le_spougeBase hcd hcz hadp han)

/-- **Spouge's Γ approximant** — `SpougeGamma z … N` approximates `Γ(z+1)` by
    `(z+a)^{z+½} · e^{−(z+a)} · (c₀ + Σ_{k=1}^{N} cₖ/(z+k))`, a genuine constructive real for real
    `z > 0` (enclosed by the rational floor `c`, `0 < c ≤ z`). (Here "approximates" is prose: NO
    `Req`/`≈` to the true `Γ` is asserted — see the error note below.)

    Built from `exp`/`log`/reciprocal of positive reals ONLY:
    * `(z+a)^{z+½} = RrpowPos (z+a) _ _ (z + ½)`  (base `z+a > 0`; exponent `z + ½`),
    * `e^{−(z+a)} = RexpReal (−(z+a))`,
    * the bracket `c₀ + Σ cₖ/(z+k)` from `spougeBracket`.

    `a : Q` is a free rational parameter `≥ 3` (denominator positive `hadp`, numerator non-negative `han`),
    and `ha` certifies `a − k > 1` for every `1 ≤ k ≤ N` (needed for `(a−k)^{k−½}`).

    ⚠ CALLER OBLIGATION (UNCHECKED): the cited Spouge error bound is valid ONLY when `N = ⌈a⌉ − 1`.
    `N` is a FREE argument here and is NOT constrained to `⌈a⌉ − 1` by the type. Passing any other `N`
    still yields a well-formed real, but the documented bound below does NOT apply to it. ⚠

    The relative error obeys Spouge's bound `|ε_S(a,z)| < √a · (2π)^{−(a+½)} / Re(z+a)` (`a ≥ 3`,
    `Re z ≥ 0`, AND `N = ⌈a⌉ − 1`); see the section header. That bound is documented, not asserted, as
    a rigorous proof presupposes an independent `Γ`. -/
def SpougeGamma (z : Real) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcz : Rle (ofQ c hcd) z) (a : Q) (hadp : 0 < a.den) (han : 0 ≤ a.num) (N : Nat)
    (ha : ∀ (k : Nat), 1 ≤ k → k ≤ N → Qlt (⟨1, 1⟩ : Q) (Qsub a ⟨(k : Int), 1⟩)) : Real :=
  Rmul
    (Rmul
      (RrpowPos (spougeBase z a hadp) (digammaArgK c)
        (spougeBase_witness hcn hcd hcz hadp han)
        (Radd z (ofQ ⟨1, 2⟩ (by decide))))
      (RexpReal (Rneg (spougeBase z a hadp))))
    (spougeBracket z hcn hcd hcz a hadp N ha)

/-- **`SpougeGamma` is non-vacuous** (instantiation witness at `z = 1`, `a = 4`, `N = 2`). With the
    bounded hypothesis `1 ≤ k ≤ N`, the per-`k` positivity `a − k > 1` is now satisfiable:
    `k = 1 ⟹ 4−1 = 3 > 1`, `k = 2 ⟹ 4−2 = 2 > 1`. (The old unbounded `∀ k ≥ 1` admitted no witness.) -/
noncomputable def spougeGammaWitness : Real :=
  SpougeGamma one (c := ⟨1, 1⟩) (by decide) (by decide)
    (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _)))
    (a := ⟨4, 1⟩) (by decide) (by decide) 2
    (fun k hk1 hk2 => by
      -- 1 ≤ k ≤ 2 ⟹ Qlt ⟨1,1⟩ (Qsub ⟨4,1⟩ ⟨k,1⟩): k=1 → 3>1, k=2 → 2>1
      have hk : k = 1 ∨ k = 2 := by omega
      show Qlt (⟨1, 1⟩ : Q) (Qsub (⟨4, 1⟩ : Q) (⟨(k : Int), 1⟩ : Q))
      rcases hk with h | h <;> subst h <;>
        (show Qlt (⟨1, 1⟩ : Q) (Qsub (⟨4, 1⟩ : Q) (⟨_, 1⟩ : Q)); simp only [Qlt, Qsub, add, neg]; decide))

-- ===========================================================================
-- **`log x ≥ 0` for `x ≥ 1`** via the direct artanh-sign route (no `exp∘log = id`).
--
-- `RlogPos x = 2·artanh(t)`, `t = (x−1)/(x+1)`.  For `x ≥ 1` the argument `t ≥ 0`-ish (slack),
-- so the artanh diagonal `artSum t (·)` clears the regularity floor `−1/(n+1)`.  The crux is a
-- rational lower bound `artSum t N ≥ −2|t|` for possibly-negative tiny `t`, via oddness of the
-- artanh series + the existing geometric upper bound on the negated (non-negative) base.
-- ===========================================================================

/-- The denominator is unchanged by negating the base: `(qpow (neg t) n).den = (qpow t n).den`. -/
theorem qpow_neg_den (t : Q) : ∀ n, (qpow (neg t) n).den = (qpow t n).den
  | 0 => rfl
  | (n + 1) => by
      show (mul (neg t) (qpow (neg t) n)).den = (mul t (qpow t n)).den
      show (neg t).den * (qpow (neg t) n).den = t.den * (qpow t n).den
      rw [qpow_neg_den t n]; rfl

/-- The numerator flips sign for ODD powers: `(qpow (neg t) (2j+1)).num = −(qpow t (2j+1)).num`. -/
theorem qpow_neg_num_odd (t : Q) :
    ∀ j, (qpow (neg t) (2 * j + 1)).num = -(qpow t (2 * j + 1)).num
  | 0 => by
      show (mul (neg t) (qpow (neg t) 0)).num = -(mul t (qpow t 0)).num
      simp only [qpow, mul, neg]; omega
  | (j + 1) => by
      have hstep : 2 * (j + 1) + 1 = (2 * j + 1) + 1 + 1 := by omega
      rw [hstep]
      show (-t.num) * ((-t.num) * (qpow (neg t) (2 * j + 1)).num)
        = -(t.num * (t.num * (qpow t (2 * j + 1)).num))
      rw [qpow_neg_num_odd t j]; ring_uor

/-- Odd power of a negated base: `(−t)^{2j+1} ≈ −t^{2j+1}`. -/
theorem qpow_neg_odd (t : Q) (j : Nat) :
    Qeq (qpow (neg t) (2 * j + 1)) (neg (qpow t (2 * j + 1))) := by
  show (qpow (neg t) (2 * j + 1)).num * ((neg (qpow t (2 * j + 1))).den : Int)
    = (neg (qpow t (2 * j + 1))).num * ((qpow (neg t) (2 * j + 1)).den : Int)
  rw [qpow_neg_num_odd t j, qpow_neg_den t (2 * j + 1)]
  show -(qpow t (2 * j + 1)).num * ((qpow t (2 * j + 1)).den : Int)
    = -(qpow t (2 * j + 1)).num * ((qpow t (2 * j + 1)).den : Int)
  rfl

/-- `−(a+b) ≈ (−a)+(−b)` (in fact a strict equality up to the canonical form). -/
theorem Qneg_add (a b : Q) : Qeq (neg (add a b)) (add (neg a) (neg b)) := by
  show (neg (add a b)).num * ((add (neg a) (neg b)).den : Int)
    = (add (neg a) (neg b)).num * ((neg (add a b)).den : Int)
  simp only [add, neg]; push_cast; ring_uor

/-- `artTerm (−t) j ≈ −(artTerm t j)` — the artanh term is odd. -/
theorem artTerm_neg {t : Q} (htd : 0 < t.den) (j : Nat) :
    Qeq (artTerm (neg t) j) (neg (artTerm t j)) := by
  show Qeq (mul (qpow (neg t) (2 * j + 1)) ⟨1, 2 * j + 1⟩) (neg (mul (qpow t (2 * j + 1)) ⟨1, 2 * j + 1⟩))
  have hbden : 0 < (mul (neg (qpow t (2 * j + 1))) ⟨1, 2 * j + 1⟩).den :=
    Qmul_den_pos (qpow_den_pos htd _) (Nat.succ_pos _)
  refine Qeq_trans hbden
    (Qmul_congr (qpow_neg_odd t j) (Qeq_refl (⟨1, 2 * j + 1⟩ : Q))) ?_
  show (mul (neg (qpow t (2 * j + 1))) ⟨1, 2 * j + 1⟩).num * ((neg (mul (qpow t (2 * j + 1)) ⟨1, 2 * j + 1⟩)).den : Int)
    = (neg (mul (qpow t (2 * j + 1)) ⟨1, 2 * j + 1⟩)).num * ((mul (neg (qpow t (2 * j + 1))) ⟨1, 2 * j + 1⟩).den : Int)
  simp only [mul, neg]; push_cast; ring_uor

/-- **The artanh partial sum is odd**: `artSum (−t) N ≈ −(artSum t N)`. -/
theorem artSum_neg {t : Q} (htd : 0 < t.den) : ∀ N, Qeq (artSum (neg t) N) (neg (artSum t N))
  | 0 => artTerm_neg htd 0
  | (N + 1) => by
      show Qeq (add (artSum (neg t) N) (artTerm (neg t) (N + 1)))
        (neg (add (artSum t N) (artTerm t (N + 1))))
      have hsum := artSum_neg htd N
      have hterm := artTerm_neg htd (N + 1)
      have hmid : Qeq (add (artSum (neg t) N) (artTerm (neg t) (N + 1)))
          (add (neg (artSum t N)) (neg (artTerm t (N + 1)))) :=
        Qadd_congr hsum hterm
      have hmidden : 0 < (add (neg (artSum t N)) (neg (artTerm t (N + 1)))).den :=
        add_den_pos (artSum_den_pos htd N) (artTerm_den_pos htd (N + 1))
      exact Qeq_trans hmidden hmid (Qeq_symm (Qneg_add (artSum t N) (artTerm t (N + 1))))

/-- **Geometric cap on the artanh partial sum**: for a non-negative base `s` with `s² ≤ ½`
    (i.e. `½ ≤ 1−s²`), `artSum s N ≤ 2·s`.  From the cleared geometric bound `artSum·(1−s²) ≤ s`,
    replacing `1−s²` by its lower bound `½` (`artSum ≥ 0`) and cancelling. -/
theorem artSum_le_two_arg {s : Q} (hs0 : 0 ≤ s.num) (hsd : 0 < s.den)
    (hW : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul s s))) (N : Nat) :
    Qle (artSum s N) (mul (⟨2, 1⟩ : Q) s) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul s s)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos hsd hsd)
  have hWnn : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul s s)).num := by
    -- from ⟨1,2⟩ ≤ W:  W.den ≤ W.num·2,  W.den > 0 ⟹ W.num > 0
    have hle : (1 : Int) * ((Qsub (⟨1, 1⟩ : Q) (mul s s)).den : Int)
        ≤ (Qsub (⟨1, 1⟩ : Q) (mul s s)).num * 2 := hW
    have hdpos : (0 : Int) < ((Qsub (⟨1, 1⟩ : Q) (mul s s)).den : Int) := by exact_mod_cast hWd
    omega
  -- artSum·(1−s²) ≤ s
  have hgeo := artSum_le_geo hs0 hsd hWnn N
  -- artSum·⟨1,2⟩ ≤ artSum·(1−s²)
  have hsum0 : 0 ≤ (artSum s N).num := artSum_nonneg hs0 hsd N
  have hstep : Qle (mul (artSum s N) (⟨1, 2⟩ : Q)) (mul (artSum s N) (Qsub ⟨1, 1⟩ (mul s s))) :=
    Qmul_le_mul_left hsum0 hW
  have hcap : Qle (mul (artSum s N) (⟨1, 2⟩ : Q)) s :=
    Qle_trans (Qmul_den_pos (artSum_den_pos hsd N)
      (Qsub_den_pos Nat.one_pos (Qmul_den_pos hsd hsd))) hstep hgeo
  -- multiply by ⟨2,1⟩ on the right and use ⟨1,2⟩·⟨2,1⟩ ≈ 1
  have hmul := Qmul_le_mul_right (show (0 : Int) ≤ (⟨2, 1⟩ : Q).num by decide) hcap
  -- (artSum·⟨1,2⟩)·⟨2,1⟩ ≈ artSum,  s·⟨2,1⟩ ≈ ⟨2,1⟩·s
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos (artSum_den_pos hsd N)
        (show 0 < (⟨1, 2⟩ : Q).den by decide)) (show 0 < (⟨2, 1⟩ : Q).den by decide))
    (Qeq_le ?_) (Qle_trans (Qmul_den_pos hsd (show 0 < (⟨2, 1⟩ : Q).den by decide))
      hmul (Qeq_le (mul_comm s (⟨2, 1⟩ : Q))))
  -- artSum ≈ (artSum·⟨1,2⟩)·⟨2,1⟩
  show (artSum s N).num * (((mul (mul (artSum s N) (⟨1, 2⟩ : Q)) (⟨2, 1⟩ : Q))).den : Int)
    = (mul (mul (artSum s N) (⟨1, 2⟩ : Q)) (⟨2, 1⟩ : Q)).num * ((artSum s N).den : Int)
  simp only [mul]; push_cast; ring_uor

/-- `|t| ≤ ½ ⟹ ½ ≤ 1 − t²` (the geometric-cap hypothesis, from the small-argument bound). -/
theorem one_sub_sq_ge_half {t : Q} (hsmall : Qle (Qabs t) (⟨1, 2⟩ : Q)) :
    Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul t t)) := by
  -- |t.num|·2 ≤ t.den
  have h1 : (t.num.natAbs : Int) * 2 ≤ (t.den : Int) := by
    have h' : (t.num.natAbs : Int) * ((⟨1, 2⟩ : Q).den : Int)
        ≤ (⟨1, 2⟩ : Q).num * ((Qabs t).den : Int) := hsmall
    have hden : (Qabs t).den = t.den := rfl
    rw [hden] at h'; simp only at h'; push_cast at h' ⊢; omega
  have h1nn : (0 : Int) ≤ (t.num.natAbs : Int) * 2 := Int.mul_nonneg (Int.ofNat_nonneg _) (by decide)
  -- 4·t.num² ≤ t.den² (square the inequality)
  have hsq : ((t.num.natAbs : Int) * 2) * ((t.num.natAbs : Int) * 2)
      ≤ (t.den : Int) * (t.den : Int) :=
    Int.mul_le_mul h1 h1 h1nn (Int.ofNat_nonneg _)
  have hnat : (t.num.natAbs : Int) * (t.num.natAbs : Int) = t.num * t.num :=
    Int.natAbs_mul_self
  -- 2·t.num² ≤ t.den²  (linear in the atoms, given 4·t.num² ≤ t.den² and t.num² ≥ 0)
  have hnumsq_nn : (0 : Int) ≤ t.num * t.num := by
    rcases Int.le_total 0 t.num with h | h
    · exact Int.mul_nonneg h h
    · have hn : (0 : Int) ≤ -t.num := by omega
      have := Int.mul_nonneg hn hn
      have e : (-t.num) * (-t.num) = t.num * t.num := by ring_uor
      rw [e] at this; exact this
  have hkey : 2 * (t.num * t.num) ≤ (t.den : Int) * (t.den : Int) := by
    have e : ((t.num.natAbs : Int) * 2) * ((t.num.natAbs : Int) * 2)
        = 4 * (t.num * t.num) := by rw [← hnat]; ring_uor
    rw [e] at hsq; omega
  -- goal: 1·t.den_W ≤ W.num·2, where W = ⟨t.den²−t.num², t.den²⟩
  show (1 : Int) * ((Qsub (⟨1, 1⟩ : Q) (mul t t)).den : Int)
    ≤ (Qsub (⟨1, 1⟩ : Q) (mul t t)).num * 2
  simp only [Qsub, add, neg, mul]; push_cast
  -- LHS = t.den·t.den ; RHS = (t.den·t.den − t.num·t.num)·2
  omega

/-- **The artanh lower bound for small (possibly negative) arguments**: for `|t| ≤ ½`,
    `artSum t N ≥ −2·|t|`.  Non-negative `t`: `artSum ≥ 0 ≥ −2|t|`.  Negative `t = −s`: oddness
    `artSum t N = −artSum s N` and the geometric cap `artSum s N ≤ 2s = 2|t|`. -/
theorem artSum_ge_neg_two_arg {t : Q} (htd : 0 < t.den) (hsmall : Qle (Qabs t) (⟨1, 2⟩ : Q))
    (N : Nat) : Qle (neg (mul (⟨2, 1⟩ : Q) (Qabs t))) (artSum t N) := by
  rcases Int.le_total 0 t.num with ht0 | ht0
  · -- t ≥ 0:  −2|t| ≤ 0 ≤ artSum
    have hnn : 0 ≤ (artSum t N).num := artSum_nonneg ht0 htd N
    show (neg (mul (⟨2, 1⟩ : Q) (Qabs t))).num * ((artSum t N).den : Int)
      ≤ (artSum t N).num * ((neg (mul (⟨2, 1⟩ : Q) (Qabs t))).den : Int)
    simp only [neg, mul, Qabs]; push_cast
    -- goal: −(2·|t.num|)·artSum.den ≤ artSum.num·(1·t.den)
    have hL : (0 : Int) ≤ 2 * (t.num.natAbs : Int) * ((artSum t N).den : Int) :=
      Int.mul_nonneg (Int.mul_nonneg (by decide) (Int.ofNat_nonneg _)) (Int.ofNat_nonneg _)
    have hR : (0 : Int) ≤ (artSum t N).num * (1 * (t.den : Int)) :=
      Int.mul_nonneg hnn (Int.mul_nonneg (by decide) (Int.ofNat_nonneg _))
    have hLe : -(2 * (t.num.natAbs : Int)) * ((artSum t N).den : Int)
        = -(2 * (t.num.natAbs : Int) * ((artSum t N).den : Int)) := by ring_uor
    rw [hLe]; omega
  · -- t < 0:  s = −t,  artSum t N = −artSum s N ≥ −2 s = −2|t|
    have hs0 : 0 ≤ (neg t).num := by show (0 : Int) ≤ -t.num; omega
    have hsd : 0 < (neg t).den := htd
    have hsmall_s : Qle (Qabs (neg t)) (⟨1, 2⟩ : Q) := by rw [Qabs_neg]; exact hsmall
    have hW := one_sub_sq_ge_half hsmall_s
    -- artSum s N ≤ 2 s
    have hcap : Qle (artSum (neg t) N) (mul (⟨2, 1⟩ : Q) (neg t)) :=
      artSum_le_two_arg hs0 hsd hW N
    -- |t| = s  (as Q, num/den);  2|t| ≈ 2s
    have habs_eq : Qeq (mul (⟨2, 1⟩ : Q) (Qabs t)) (mul (⟨2, 1⟩ : Q) (neg t)) := by
      refine Qmul_congr (Qeq_refl _) ?_
      show (Qabs t).num * ((neg t).den : Int) = (neg t).num * ((Qabs t).den : Int)
      show (t.num.natAbs : Int) * (t.den : Int) = (-t.num) * (t.den : Int)
      have : (t.num.natAbs : Int) = -t.num := by omega
      rw [this]
    -- −artSum s N ≈ artSum t N   (oddness, undoing the double negation)
    have hdneg : Qeq (neg (neg (artSum t N))) (artSum t N) := by
      show (neg (neg (artSum t N))).num * ((artSum t N).den : Int)
        = (artSum t N).num * ((neg (neg (artSum t N))).den : Int)
      simp only [neg]; ring_uor
    have hodd : Qeq (neg (artSum (neg t) N)) (artSum t N) :=
      Qeq_trans (show 0 < (neg (neg (artSum t N))).den from artSum_den_pos htd N)
        (Qneg_congr (artSum_neg htd N)) hdneg
    -- assemble:  neg (2|t|) ≈ neg(2s) ≤ neg(artSum s N) ≈ artSum t N
    have hcap_neg : Qle (neg (mul (⟨2, 1⟩ : Q) (neg t))) (neg (artSum (neg t) N)) :=
      Qneg_le_neg hcap
    have hstep1 : Qle (neg (mul (⟨2, 1⟩ : Q) (Qabs t))) (neg (mul (⟨2, 1⟩ : Q) (neg t))) :=
      Qeq_le (Qneg_congr habs_eq)
    refine Qle_trans (show 0 < (neg (mul (⟨2, 1⟩ : Q) (neg t))).den from
        Qmul_den_pos (by decide) htd) hstep1
      (Qle_trans (show 0 < (neg (artSum (neg t) N)).den from
          artSum_den_pos (show 0 < (neg t).den from htd) N)
        hcap_neg (Qeq_le hodd))

/-- The artanh reindex is `≥ 2(j+1)` (since `ρ.den²+4ρ.den ≥ 5`), so `Rⱼ+1 ≥ 2(j+1)`. -/
theorem Rartanh_R_ge_two (ρ : Q) (hρd : 0 < ρ.den) (j : Nat) :
    2 * (j + 1) ≤ Rartanh_R ρ j := by
  unfold Rartanh_R
  have h5 : 5 ≤ ρ.den * ρ.den + 4 * ρ.den := by
    have h1 : 1 ≤ ρ.den := hρd
    have hsq : 1 ≤ ρ.den * ρ.den := Nat.mul_le_mul h1 h1
    omega
  have h1 : 2 * (j + 1) ≤ 5 * (j + 1) := Nat.mul_le_mul_right _ (by omega : 2 ≤ 5)
  have h2 : 5 * (j + 1) ≤ (ρ.den * ρ.den + 4 * ρ.den) * (j + 1) :=
    Nat.mul_le_mul_right _ h5
  exact Nat.le_trans h1 h2

/-- **`artanh t ≥ 0` for `t ≥ 0`-as-a-real** (`Rnonneg t`): at each diagonal index the argument
    `v = t.seq Rⱼ` satisfies `v ≥ −1/(Rⱼ+1)`; if `v ≥ 0` then `artSum v Rⱼ ≥ 0`, and if `v < 0`
    then `|v| ≤ 1/(Rⱼ+1) ≤ ½`, so `artSum v Rⱼ ≥ −2|v| ≥ −2/(Rⱼ+1) ≥ −1/(n+1)` (since `Rⱼ ≥ 2(n+1)`). -/
theorem Rnonneg_Rartanh_of_nonneg (t : Real) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (hb : ∀ n, Qle (Qabs (t.seq n)) ρ) (ht : Rnonneg t) :
    Rnonneg (Rartanh t ρ hρ0 hρd hlt hb) := by
  intro n
  show Qle (neg (Qbound n)) (artSum (t.seq (Rartanh_R ρ n)) (Rartanh_R ρ n))
  generalize hR : Rartanh_R ρ n = R
  have hvd : 0 < (t.seq R).den := t.den_pos _
  have hRge : 2 * (n + 1) ≤ R := hR ▸ Rartanh_R_ge_two ρ hρd n
  -- v ≥ −Qbound R
  have hvlo : Qle (neg (Qbound R)) (t.seq R) := ht R
  rcases Int.le_total 0 (t.seq R).num with hv0 | hv0
  · -- v ≥ 0 : artSum ≥ 0 ≥ −Qbound n
    have hnn : 0 ≤ (artSum (t.seq R) R).num := artSum_nonneg hv0 hvd R
    have hsd : (0 : Int) ≤ ((artSum (t.seq R) R).den : Int) := Int.ofNat_nonneg _
    show Qle (neg (Qbound n)) (artSum (t.seq R) R)
    show (neg (Qbound n)).num * ((artSum (t.seq R) R).den : Int)
      ≤ (artSum (t.seq R) R).num * ((neg (Qbound n)).den : Int)
    simp only [neg, Qbound]; push_cast
    have hR2 : (0 : Int) ≤ (artSum (t.seq R) R).num * ((n : Int) + 1) :=
      Int.mul_nonneg hnn (by omega)
    omega
  · -- v < 0 : |v| ≤ Qbound R ≤ ½, so artSum v R ≥ −2|v| ≥ −2/(R+1) ≥ −1/(n+1)
    -- |v| ≤ Qbound R
    have habsv : Qle (Qabs (t.seq R)) (Qbound R) := by
      -- from neg (Qbound R) ≤ v and v < 0:  |v| = −v ≤ Qbound R
      show (Qabs (t.seq R)).num * ((Qbound R).den : Int)
        ≤ (Qbound R).num * ((Qabs (t.seq R)).den : Int)
      have hvlo' : (neg (Qbound R)).num * ((t.seq R).den : Int)
        ≤ (t.seq R).num * ((neg (Qbound R)).den : Int) := hvlo
      simp only [neg, Qbound, Qabs] at hvlo' ⊢
      have habs : ((t.seq R).num.natAbs : Int) = -(t.seq R).num := by omega
      rw [habs]
      push_cast at hvlo' ⊢
      -- goal: -num·(R+1) ≤ 1·v.den ;  hvlo': -1·v.den ≤ num·(R+1)
      have halign : -(t.seq R).num * ((R : Int) + 1) = -((t.seq R).num * ((R : Int) + 1)) := by
        ring_uor
      rw [halign]
      omega
    -- Qbound R ≤ ½  (R+1 ≥ 2)
    have hsmall : Qle (Qabs (t.seq R)) (⟨1, 2⟩ : Q) :=
      Qle_trans (Qbound_den_pos R) habsv (by
        show (1 : Int) * (2 : Int) ≤ 1 * ((R + 1 : Nat) : Int); push_cast; omega)
    -- artSum v R ≥ −2|v|
    have hlb := artSum_ge_neg_two_arg hvd hsmall R
    -- −2|v| ≥ −2·Qbound R ≥ −Qbound n
    have hstep : Qle (neg (mul (⟨2, 1⟩ : Q) (Qbound R)))
        (neg (mul (⟨2, 1⟩ : Q) (Qabs (t.seq R)))) :=
      Qneg_le_neg (Qmul_le_mul_left (by decide) habsv)
    -- −2·Qbound R ≥ −Qbound n :  2/(R+1) ≤ 1/(n+1) ⟺ 2(n+1) ≤ R+1
    have hfloor : Qle (neg (Qbound n)) (neg (mul (⟨2, 1⟩ : Q) (Qbound R))) := by
      apply Qneg_le_neg
      show (mul (⟨2, 1⟩ : Q) (Qbound R)).num * ((Qbound n).den : Int)
        ≤ (Qbound n).num * ((mul (⟨2, 1⟩ : Q) (Qbound R)).den : Int)
      simp only [mul, Qbound]; push_cast; omega
    have hbd1 : 0 < (neg (mul (⟨2, 1⟩ : Q) (Qbound R))).den :=
      Qmul_den_pos (by decide) (Qbound_den_pos R)
    have hbd2 : 0 < (neg (mul (⟨2, 1⟩ : Q) (Qabs (t.seq R)))).den :=
      Qmul_den_pos (by decide) (Qabs_den_pos hvd)
    exact Qle_trans hbd1 hfloor (Qle_trans hbd2 hstep hlb)

/-- **The t-map lower bound on `[0,1]`**: `q − 1 ≤ tmap q` for `0 ≤ q ≤ 1` (dividing the negative
    `q−1` by `q+1 ≥ 1` makes it less negative).  Cleared: `(q−1)·q.den·q.num ≤ 0`. -/
theorem tmap_ge_sub {q : Q} (hqn : 0 ≤ q.num) (hqd : 0 < q.den) (hq1 : Qle q ⟨1, 1⟩) :
    Qle (Qsub q ⟨1, 1⟩) (tmap q) := by
  have hle1 : q.num ≤ (q.den : Int) := by
    have h : q.num * ((1 : Nat) : Int) ≤ (1 : Int) * (q.den : Int) := hq1
    push_cast at h; omega
  show (Qsub q ⟨1, 1⟩).num * ((tmap q).den : Int) ≤ (tmap q).num * ((Qsub q ⟨1, 1⟩).den : Int)
  have htoNat : ((q.num * 1 + 1 * (q.den : Int)).toNat : Int) = q.num + (q.den : Int) := by
    rw [Int.toNat_of_nonneg (by omega)]; ring_uor
  -- expand both sides to closed Int forms
  have hLHS : (Qsub q ⟨1, 1⟩).num * ((tmap q).den : Int)
      = (q.num - (q.den : Int)) * ((q.den : Int) * (q.num + (q.den : Int))) := by
    show (Qsub q ⟨1, 1⟩).num * (((tmap q).den : Nat) : Int) = _
    simp only [tmap, mul, Qsub, add, neg, Qinv]; push_cast; rw [htoNat]; ring_uor
  have hRHS : (tmap q).num * ((Qsub q ⟨1, 1⟩).den : Int)
      = (q.num - (q.den : Int)) * (q.den : Int) * (q.den : Int) := by
    show (tmap q).num * (((Qsub q ⟨1, 1⟩).den : Nat) : Int) = _
    simp only [tmap, mul, Qsub, add, neg, Qinv]; push_cast; ring_uor
  rw [hLHS, hRHS]
  -- RHS − LHS = (q.num−q.den)·q.den·q.num ≤ 0
  have hkey : (q.num - (q.den : Int)) * (q.den : Int) * (q.den : Int)
      - (q.num - (q.den : Int)) * ((q.den : Int) * (q.num + (q.den : Int)))
      = -((q.num - (q.den : Int)) * (q.den : Int) * q.num) := by ring_uor
  have hprod : (0 : Int) ≤ -((q.num - (q.den : Int)) * (q.den : Int) * q.num) := by
    have hd : (0 : Int) ≤ (q.den : Int) := Int.ofNat_nonneg _
    have h1 : (0 : Int) ≤ ((q.den : Int) - q.num) * (q.den : Int) :=
      Int.mul_nonneg (by omega) hd
    have h2 : (0 : Int) ≤ ((q.den : Int) - q.num) * (q.den : Int) * q.num :=
      Int.mul_nonneg h1 hqn
    have he : -((q.num - (q.den : Int)) * (q.den : Int) * q.num)
        = ((q.den : Int) - q.num) * (q.den : Int) * q.num := by ring_uor
    omega
  omega

/-- **The log artanh-argument is non-negative for `y ≥ 1`**: the diagonal `Rlog_seq y` (with
    `Rlog_seq y n = tmap (y_{2(n+1)})`) clears the floor `−1/(n+1)`.  If `y_R ≥ 1` then `tmap ≥ 0`;
    else `y_R ∈ (0,1)` and `tmap ≥ y_R − 1 ≥ −2/(R+1) ≥ −1/(n+1)` (`R = 2(n+1)`, from `y ≥ 1`). -/
theorem Rnonneg_Rlog_seq_of_one_le (y : Real) (hypos : ∀ n, 0 < (y.seq n).num)
    (hden : ∀ n, 0 < (Rlog_seq y n).den) (hy1 : Rle one y) :
    Rnonneg (⟨Rlog_seq y, Rlog_regular y hypos, hden⟩ : Real) := by
  intro n
  show Qle (neg (Qbound n)) (tmap (y.seq (Rlog_R n)))
  have hqd : 0 < (y.seq (Rlog_R n)).den := y.den_pos _
  have hqn : 0 ≤ (y.seq (Rlog_R n)).num := Int.le_of_lt (hypos _)
  -- per-index from y ≥ 1:  1 ≤ y_R + 2/(R+1)   (one.seq R = ⟨1,1⟩)
  have hy1R : Qle (⟨1, 1⟩ : Q) (add (y.seq (Rlog_R n)) ⟨2, Rlog_R n + 1⟩) := hy1 (Rlog_R n)
  rcases Int.le_total ((y.seq (Rlog_R n)).den : Int) (y.seq (Rlog_R n)).num with hge1' | hle1'
  · -- y_R ≥ 1 :  tmap ≥ 0 ≥ −Qbound n
    have hge1 : Qle (⟨1, 1⟩ : Q) (y.seq (Rlog_R n)) := by
      show (1 : Int) * ((y.seq (Rlog_R n)).den : Int) ≤ (y.seq (Rlog_R n)).num * 1
      push_cast; omega
    have hnn : 0 ≤ (tmap (y.seq (Rlog_R n))).num := tmap_num_nonneg hge1
    have htd : 0 < (tmap (y.seq (Rlog_R n))).den :=
      Qmul_den_pos (Qsub_den_pos hqd Nat.one_pos) (Qinv_den_pos (by
        show 0 < (add (y.seq (Rlog_R n)) ⟨1, 1⟩).num
        have h2 := Int.ofNat_nonneg (y.seq (Rlog_R n)).den
        show 0 < (y.seq (Rlog_R n)).num * 1 + 1 * ((y.seq (Rlog_R n)).den : Int); omega))
    show (neg (Qbound n)).num * ((tmap (y.seq (Rlog_R n))).den : Int)
      ≤ (tmap (y.seq (Rlog_R n))).num * ((neg (Qbound n)).den : Int)
    simp only [neg, Qbound]; push_cast
    have hL : (0 : Int) ≤ (tmap (y.seq (Rlog_R n))).num * ((n : Int) + 1) :=
      Int.mul_nonneg hnn (by omega)
    have hR2 : (0 : Int) ≤ (1 : Int) * ((tmap (y.seq (Rlog_R n))).den : Int) :=
      Int.mul_nonneg (by decide) (Int.ofNat_nonneg _)
    omega
  · -- y_R ≤ 1 :  tmap ≥ y_R − 1 ≥ −2/(R+1) ≥ −Qbound n
    have hle1 : Qle (y.seq (Rlog_R n)) (⟨1, 1⟩ : Q) := by
      show (y.seq (Rlog_R n)).num * (1 : Int) ≤ 1 * ((y.seq (Rlog_R n)).den : Int)
      push_cast; omega
    have htsub := tmap_ge_sub hqn hqd hle1  -- Qsub q 1 ≤ tmap q
    -- neg ⟨2, R+1⟩ ≤ Qsub q 1   (from 1 ≤ q + 2/(R+1))
    have hmid : Qle (neg (⟨2, Rlog_R n + 1⟩ : Q)) (Qsub (y.seq (Rlog_R n)) ⟨1, 1⟩) := by
      show (neg (⟨2, Rlog_R n + 1⟩ : Q)).num * ((Qsub (y.seq (Rlog_R n)) ⟨1, 1⟩).den : Int)
        ≤ (Qsub (y.seq (Rlog_R n)) ⟨1, 1⟩).num * ((neg (⟨2, Rlog_R n + 1⟩ : Q)).den : Int)
      have hy1R' : (1 : Int) * ((add (y.seq (Rlog_R n)) ⟨2, Rlog_R n + 1⟩).den : Int)
        ≤ (add (y.seq (Rlog_R n)) ⟨2, Rlog_R n + 1⟩).num * ((⟨1, 1⟩ : Q).den : Int) := hy1R
      simp only [neg, Qsub, add] at hy1R' ⊢
      push_cast at hy1R' ⊢
      -- abbreviate q.num, q.den, (R+1) as atoms; expand the product
      have hexp : ((y.seq (Rlog_R n)).num * 1 + -(1 : Int) * (y.seq (Rlog_R n)).den)
            * ((Rlog_R n : Int) + 1)
          = (y.seq (Rlog_R n)).num * ((Rlog_R n : Int) + 1)
            - (y.seq (Rlog_R n)).den * ((Rlog_R n : Int) + 1) := by ring_uor
      have hexp2 : ((y.seq (Rlog_R n)).num * ((Rlog_R n : Int) + 1) + 2 * (y.seq (Rlog_R n)).den) * 1
          = (y.seq (Rlog_R n)).num * ((Rlog_R n : Int) + 1) + 2 * (y.seq (Rlog_R n)).den := by ring_uor
      have hden_eq : ((y.seq (Rlog_R n)).den * (Rlog_R n + 1) : Int)
          = (y.seq (Rlog_R n)).den * ((Rlog_R n : Int) + 1) := by push_cast; ring_uor
      rw [hexp]
      -- hy1R' now:  den·(R+1) ≤ q.num·(R+1) + 2·den ;  goal: −2·den ≤ q.num·(R+1) − den·(R+1)
      omega
    -- neg (Qbound n) ≤ neg ⟨2, R+1⟩   (2/(R+1) ≤ 1/(n+1),  R = 2(n+1))
    have hfloor : Qle (neg (Qbound n)) (neg (⟨2, Rlog_R n + 1⟩ : Q)) := by
      apply Qneg_le_neg
      show (2 : Int) * ((Qbound n).den : Int) ≤ (Qbound n).num * ((Rlog_R n + 1 : Nat) : Int)
      simp only [Qbound]; unfold Rlog_R; push_cast; omega
    have hbd1 : 0 < (neg (⟨2, Rlog_R n + 1⟩ : Q)).den := Nat.succ_pos _
    have hbd2 : 0 < (Qsub (y.seq (Rlog_R n)) ⟨1, 1⟩).den := Qsub_den_pos hqd Nat.one_pos
    exact Qle_trans hbd1 hfloor (Qle_trans hbd2 hmid htsub)

/-- **`log y ≥ 0` for a `[1/M,M]`-presented `y ≥ 1`**: `Rlog y M = 2·artanh((y−1)/(y+1))`, and the
    artanh argument is `Rnonneg` (step 3), so the product `2·(≥0)` is `≥ 0` (`Rnonneg_Rmul`). -/
theorem Rnonneg_Rlog_of_one_le (y : Real) (M : Q) (hMd : 0 < M.den) (hMge : Qle (⟨1, 1⟩ : Q) M)
    (hypos : ∀ n, 0 < (y.seq n).num) (hhi : ∀ n, Qle (y.seq n) M)
    (hlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) M)) (hy1 : Rle one y) :
    Rnonneg (Rlog y M hMd hMge hypos hhi hlo) := by
  -- recover ρ and the artanh-argument denominators, exactly as in `Rlog`
  have hMge' : (1 : Int) * (M.den : Int) ≤ M.num * 1 := hMge
  have hMn : 0 ≤ M.num := by omega
  have hρ0 : 0 ≤ (⟨M.num - (M.den : Int), M.num.toNat + M.den⟩ : Q).num := by
    show 0 ≤ M.num - (M.den : Int); omega
  have hρd : 0 < (⟨M.num - (M.den : Int), M.num.toNat + M.den⟩ : Q).den := by
    show 0 < M.num.toNat + M.den; omega
  have hlt : (⟨M.num - (M.den : Int), M.num.toNat + M.den⟩ : Q).num.toNat
      < (⟨M.num - (M.den : Int), M.num.toNat + M.den⟩ : Q).den := by
    show (M.num - (M.den : Int)).toNat < M.num.toNat + M.den
    have h1 : ((M.num.toNat : Nat) : Int) = M.num := Int.toNat_of_nonneg hMn
    have h2 : ((M.num - (M.den : Int)).toNat : Int) = M.num - (M.den : Int) :=
      Int.toNat_of_nonneg (by omega)
    have : ((M.num - (M.den : Int)).toNat : Int) < ((M.num.toNat + M.den : Nat) : Int) := by
      push_cast [h1, h2]; omega
    exact_mod_cast this
  have hden : ∀ n, 0 < (Rlog_seq y n).den := by
    intro n
    refine Qmul_den_pos (Qsub_den_pos (y.den_pos _) Nat.one_pos) (Qinv_den_pos ?_)
    have h := Int.ofNat_nonneg (y.seq (Rlog_R n)).den
    have h2 := hypos (Rlog_R n)
    show 0 < (y.seq (Rlog_R n)).num * 1 + 1 * ((y.seq (Rlog_R n)).den : Int)
    omega
  have hb : ∀ n, Qle (Qabs ((⟨Rlog_seq y, Rlog_regular y hypos, hden⟩ : Real).seq n))
      (⟨M.num - (M.den : Int), M.num.toNat + M.den⟩ : Q) := by
    intro n
    have hca : 0 < (add (y.seq (Rlog_R n)) ⟨1, 1⟩).num := by
      have h := Int.ofNat_nonneg (y.seq (Rlog_R n)).den; have := hypos (Rlog_R n)
      show 0 < (y.seq (Rlog_R n)).num * 1 + 1 * ((y.seq (Rlog_R n)).den : Int); omega
    have hM1 : 0 < (add M ⟨1, 1⟩).num := by show 0 < M.num * 1 + 1 * (M.den : Int); omega
    exact Qle_trans (show 0 < (tmap M).den from
        Qmul_den_pos (Qsub_den_pos hMd Nat.one_pos) (Qinv_den_pos hM1))
      (tmap_abs_le (y.den_pos _) hMd hca hM1 (hhi (Rlog_R n)) (hlo (Rlog_R n)))
      (Qeq_le (tmap_M_eq hMd hMn))
  -- the bridge: `Rlog y M … = Rmul (ofQ 2) (Rartanh ⟨Rlog_seq y, …⟩ ρ …)` (proof-irrelevant args)
  have hbridge : Rlog y M hMd hMge hypos hhi hlo
      = Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rartanh ⟨Rlog_seq y, Rlog_regular y hypos, hden⟩
            (⟨M.num - (M.den : Int), M.num.toNat + M.den⟩ : Q) hρ0 hρd hlt hb) := rfl
  rw [hbridge]
  exact Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 2; decide))
    (Rnonneg_Rartanh_of_nonneg _ _ hρ0 hρd hlt hb
      (Rnonneg_Rlog_seq_of_one_le y hypos hden hy1))

/-- **`log x ≥ 0` for `x ≥ 1`** (`Rnonneg (RlogPos x k hk)`): the direct artanh-sign route.
    `RlogPos x = Rlog (reindexed x) M = 2·artanh((x−1)/(x+1))`; the reindex preserves `x ≥ 1`
    (a wider regularity slack), and the artanh argument is `Rnonneg` by steps 2–3. -/
theorem Rnonneg_RlogPos (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) (hx1 : Rle one x) :
    Rnonneg (RlogPos x k hk) := by
  -- the reindexed presentation y still satisfies y ≥ 1
  have hy1 : Rle one ⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun n => x.den_pos _⟩ := by
    intro n
    show Qle (⟨1, 1⟩ : Q) (add (x.seq (RlogPosR x k n)) ⟨2, n + 1⟩)
    have hself : n ≤ RlogPosR x k n := RlogPosR_self x k n
    -- from x ≥ 1 at index (RlogPosR x k n):  1 ≤ x_m + 2/(m+1) ≤ x_m + 2/(n+1)
    have hxm : Qle (⟨1, 1⟩ : Q) (add (x.seq (RlogPosR x k n)) ⟨2, RlogPosR x k n + 1⟩) :=
      hx1 (RlogPosR x k n)
    refine Qle_trans (add_den_pos (x.den_pos _) (Nat.succ_pos _)) hxm ?_
    refine Qadd_le_add (Qle_refl _) ?_
    show (2 : Int) * ((n + 1 : Nat) : Int) ≤ 2 * ((RlogPosR x k n + 1 : Nat) : Int)
    push_cast; omega
  -- reconstruct the five `Rlog` hypotheses from the `RlogPos` body (any valid proofs suffice,
  -- by proof irrelevance the resulting `Rlog y M …` is defeq to `RlogPos x k hk`)
  have hLn : 0 < (RL x k).num := RL_num_pos hk
  have hLd : 0 < (RL x k).den := RL_den_pos
  have hLinvn : 0 < (Qinv (RL x k)).num := Qinv_num_pos hLd
  have hLinvd : 0 < (Qinv (RL x k)).den := Qinv_den_pos hLn
  have hAd : 0 < (add (Qabs (x.seq 0)) ⟨2, 1⟩).den :=
    add_den_pos (Qabs_den_pos (x.den_pos 0)) Nat.one_pos
  have hAn : 0 ≤ (add (Qabs (x.seq 0)) ⟨2, 1⟩).num := by
    simp only [add, Qabs]
    have h1 := Int.ofNat_nonneg (x.seq 0).num.natAbs
    have h2 := Int.ofNat_nonneg (x.seq 0).den
    push_cast; omega
  have h1A : Qle (⟨1, 1⟩ : Q) (add (Qabs (x.seq 0)) ⟨2, 1⟩) := by
    simp only [Qle, add, Qabs]
    have h1 := Int.ofNat_nonneg (x.seq 0).num.natAbs
    have h2 := Int.ofNat_nonneg (x.seq 0).den
    push_cast; omega
  refine Rnonneg_Rlog_of_one_le
    ⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun n => x.den_pos _⟩
    (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k)))
    (add_den_pos hAd hLinvd)
    (Qle_trans hAd h1A (Qle_add_right_nonneg (Int.le_of_lt hLinvn)))
    (fun n => Rinv_num_pos hk (RlogPosR_tail x k n))
    (fun n => Qle_trans (add_den_pos (x.den_pos 0) Nat.one_pos)
      (Rlog_ub x (RlogPosR x k n))
      (Qle_trans hAd (Qadd_le_add (Qle_self_Qabs (x.seq 0)) (Qle_refl _))
        (Qle_add_right_nonneg (Int.le_of_lt hLinvn))))
    (fun n => by
      have hqn : 0 < (x.seq (RlogPosR x k n)).num := Rinv_num_pos hk (RlogPosR_tail x k n)
      have hqd : 0 < (x.seq (RlogPosR x k n)).den := x.den_pos _
      have hqL : Qle (RL x k) (x.seq (RlogPosR x k n)) := Rinv_lb hk (RlogPosR_tail x k n)
      exact Qle_trans (Qmul_den_pos hLd hLinvd)
        (Qeq_le (Qeq_symm (Qmul_Qinv hLn)))
        (Qle_trans (Qmul_den_pos hqd hLinvd)
          (Qmul_le_mul hLd hqd hLinvd (Int.le_of_lt hLn) (Int.le_of_lt hLinvn) hqL (Qle_refl _))
          (Qmul_le_mul_left (Int.le_of_lt hqn) (Qle_add_left_nonneg hAn))))
    hy1

/-- **`x^y > 0` for base `x ≥ 1` and non-negative exponent `y`**: `y·log x ≥ 0` (since `log x ≥ 0`),
    so `exp(y·log x) > 0`.  The API capstone for the `x ≥ 1` Spouge powers. -/
theorem Pos_RrpowPos_of_base_ge_one (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k)) (y : Real)
    (hy : Rnonneg y) (hx1 : Rle one x) : Pos (RrpowPos x k hk y) :=
  Pos_RrpowPos_of_nonneg_log x k hk y hy (Rnonneg_RlogPos x k hk hx1)

end UOR.Bridge.F1Square.Analysis
