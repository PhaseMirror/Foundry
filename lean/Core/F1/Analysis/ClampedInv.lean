/-
F1 square — **the clamped-reciprocal gadget** (`ClampedInv.lean`): the totalized reciprocal

    `clampedInv a x  :=  1 / max(x, a)`     (rational floor `a > 0`)

as a certified-integration integrand — total on ℝ, `≈`-congruent, globally Lipschitz with the
RATIONAL constant `(1/a)²`, and inert (`≈ 1/x`) on `[a, ∞)`. This is the recorded next Sonine
brick: the tent test's remaining `WeilSlot` components (`f̃(0) = log 2`, the archimedean tail
`−1 − 6·log 2 + 3·log 3`) have rational-function integrands (`2 − 1/x`, `−(x²−x+2)/(x(x+1))`,
`−2/(x²−1)` past the support), and partial fractions reduce every one of them to affine
combinations of THIS gadget — which the `riemannIntegral`/`riemannIntegralI` gateway can then
integrate, because the gadget carries exactly the gateway's Lipschitz + congruence data.

Design (why per-index, why uniform): `Rinv` demands a positivity witness `k` with
`x_k > 1/(k+1)` — witness data that varies with `x`, so `x ↦ 1/x` is not total and cannot be an
integrand. The per-index clamp `qClampQ a x` (seq `n ↦ max(xₙ, a)`, the floor-`a` generalization
of `qClampOne`) keeps the argument `≥ a` at EVERY index by construction, so ONE witness
(`k = 2·a.den`, `Qbound k < a`) works for every `x` — the composition is total. Lipschitz
composes: the clamp is `1`-Lipschitz (`Qmax_const_lip`), and above the floor the reciprocal is
`(1/a)²`-Lipschitz via the difference identity `1/u − 1/v = (v−u)·(1/u)(1/v)` lifted to the Real
level (`Rinv_sub_Rinv`) with both reciprocals capped by `1/a` (`Rinv_le_ofQ_inv`). The whole
argument is algebraic over the `Rinv` laws — no per-index reasoning about `Rmul`'s reindex.

HONEST SCOPE. Substrate for the crux route's steps 1–2 (certified Weil integrals); no
positivity, no crux claim. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RQmaxClamp
import Core.F1.Analysis.RlogAbsLip
import Core.F1.Analysis.RlimProps

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Strict/non-strict order transitivity at the ℚ level (for the uniform witness).
-- ===========================================================================

/-- `a < b ≤ c ⟹ a < c` on ℚ (middle and final denominators positive). -/
theorem Qlt_of_Qlt_Qle {a b c : Q} (_hb : 0 < b.den) (hc : 0 < c.den)
    (hab : Qlt a b) (hbc : Qle b c) : Qlt a c := by
  unfold Qlt Qle at *
  apply Int.lt_of_mul_lt_mul_right _ (Int.ofNat_nonneg b.den)
  have hc' : (0 : Int) < (c.den : Int) := by exact_mod_cast hc
  have t1 : a.num * (b.den : Int) * (c.den : Int) < b.num * (a.den : Int) * (c.den : Int) := by
    have hstep : (a.num * (b.den : Int) + 1) * (c.den : Int)
        ≤ b.num * (a.den : Int) * (c.den : Int) :=
      Int.mul_le_mul_of_nonneg_right (by omega) (Int.le_of_lt hc')
    have hexp : (a.num * (b.den : Int) + 1) * (c.den : Int)
        = a.num * (b.den : Int) * (c.den : Int) + (c.den : Int) := by ring_uor
    omega
  have t2 : b.num * (c.den : Int) * (a.den : Int) ≤ c.num * (b.den : Int) * (a.den : Int) :=
    Int.mul_le_mul_of_nonneg_right hbc (Int.ofNat_nonneg _)
  have e1 : a.num * (c.den : Int) * (b.den : Int)
      = a.num * (b.den : Int) * (c.den : Int) := Int.mul_right_comm _ _ _
  have e2 : b.num * (a.den : Int) * (c.den : Int)
      = b.num * (c.den : Int) * (a.den : Int) := Int.mul_right_comm _ _ _
  have e3 : c.num * (a.den : Int) * (b.den : Int)
      = c.num * (b.den : Int) * (a.den : Int) := Int.mul_right_comm _ _ _
  omega

/-- The uniform-witness inequality: `1/(2·a.den + 1) < a` for any positive rational `a`. -/
theorem Qbound_lt_pos {a : Q} (han : 0 < a.num) (had : 0 < a.den) :
    Qlt (Qbound (2 * a.den)) a := by
  show (1 : Int) * (a.den : Int) < a.num * ((2 * a.den + 1 : Nat) : Int)
  have h1 : (1 : Int) * ((2 * a.den + 1 : Nat) : Int)
      ≤ a.num * ((2 * a.den + 1 : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_right (by omega) (Int.ofNat_nonneg _)
  push_cast at h1 ⊢
  omega

-- ===========================================================================
-- The per-index clamp at an arbitrary rational floor `a` (the floor-`a`
-- generalization of `qClampOne`).
-- ===========================================================================

/-- **The per-index rational clamp at floor `a`**: `seq n := max(xₙ, a)` — `≥ a` at every index
    by construction, regular because `Qmax` is `1`-Lipschitz in its first argument. -/
def qClampQ (a : Q) (had : 0 < a.den) (x : Real) : Real where
  seq := fun n => Qmax (x.seq n) a
  reg := by
    intro m n
    exact Qle_trans
      (Qabs_den_pos (Qsub_den_pos (x.den_pos m) (x.den_pos n)))
      (Qmax_const_lip (x.seq m) (x.seq n) a (x.den_pos m) (x.den_pos n) had)
      (x.reg m n)
  den_pos := fun n => Qmax_den_pos (x.den_pos n) had

/-- The clamp is `≥ a` per index — by construction. -/
theorem qClampQ_ge (a : Q) (had : 0 < a.den) (x : Real) (n : Nat) :
    Qle a ((qClampQ a had x).seq n) :=
  Qmax_ge_right (x.seq n) a

/-- **The uniform positivity witness**: at index `2·a.den` the clamped value exceeds
    `Qbound (2·a.den)` — for EVERY `x`, with no data extracted from `x`. This is what makes the
    clamped reciprocal total. -/
theorem qClampQ_witness (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x : Real) :
    Qlt (Qbound (2 * a.den)) ((qClampQ a had x).seq (2 * a.den)) :=
  Qlt_of_Qlt_Qle had (Qmax_den_pos (x.den_pos _) had)
    (Qbound_lt_pos han had) (qClampQ_ge a had x (2 * a.den))

/-- The clamp respects `≈` (immediate from the `1`-Lipschitz `Qmax` step, index by index). -/
theorem qClampQ_congr (a : Q) (had : 0 < a.den) {x y : Real} (h : Req x y) :
    Req (qClampQ a had x) (qClampQ a had y) := by
  intro n
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos (x.den_pos n) (y.den_pos n)))
    (Qmax_const_lip (x.seq n) (y.seq n) a (x.den_pos n) (y.den_pos n) had)
    (h n)

/-- **The clamp is `1`-Lipschitz** at the Real level: `|max(x,a) − max(y,a)| ≤ |x − y|`. -/
theorem qClampQ_lipschitz (a : Q) (had : 0 < a.den) (x y : Real) :
    Rle (Rabs (Rsub (qClampQ a had x) (qClampQ a had y))) (Rabs (Rsub x y)) := by
  intro n
  show Qle (Qabs (Qsub (Qmax (x.seq (2 * n + 1)) a) (Qmax (y.seq (2 * n + 1)) a)))
      (add (Qabs (Qsub (x.seq (2 * n + 1)) (y.seq (2 * n + 1)))) (⟨2, n + 1⟩ : Q))
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (y.den_pos _)))
    (Qmax_const_lip (x.seq (2 * n + 1)) (y.seq (2 * n + 1)) a
      (x.den_pos _) (y.den_pos _) had)
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- `|y| ≤ c` from `0 ≤ y.num` and `y ≤ c` (local copy; the `RQmaxClamp` original is private). -/
private theorem Qabs_le_of_nonneg' {y c : Q} (hy : 0 ≤ y.num) (h : Qle y c) : Qle (Qabs y) c := by
  show (↑y.num.natAbs : Int) * (c.den : Int) ≤ c.num * (y.den : Int)
  rw [Int.natAbs_of_nonneg hy]; exact h

/-- **The clamp is inert on `[a, ∞)`**: where `x ≥ a` (Real-level), `qClampQ a x ≈ x`. -/
theorem qClampQ_eq_of_ge {a : Q} {had : 0 < a.den} {x : Real}
    (hx : Rle (ofQ a had) x) : Req (qClampQ a had x) x := by
  refine Req_of_lin_bound (C := 2) ?_
  intro n
  show Qle (Qabs (Qsub (Qmax (x.seq n) a) (x.seq n))) (⟨(2 : Int), n + 1⟩ : Q)
  have hxn : Qle a (add (x.seq n) (⟨2, n + 1⟩ : Q)) := hx n
  by_cases h : Qle (x.seq n) a
  · rw [Qmax_eq_right h]
    refine Qabs_le_of_nonneg' ?_ (Qsub_le_of_le_add (x.den_pos n) (Nat.succ_pos n) hxn)
    have hh := h; simp only [Qle] at hh
    simp only [Qsub, add, neg]; push_cast at hh ⊢
    have hneg : -(x.seq n).num * ((a.den : Nat) : Int)
        = -((x.seq n).num * ((a.den : Nat) : Int)) := Int.neg_mul _ _
    omega
  · rw [Qmax_eq_left h]
    have h0 : (Qsub (x.seq n) (x.seq n)).num = 0 := by simp only [Qsub, add, neg]; ring_uor
    refine Qabs_le_of_nonneg' (by rw [h0]; exact Int.le_refl 0) ?_
    show (Qsub (x.seq n) (x.seq n)).num * ((n + 1 : Nat) : Int)
        ≤ (2 : Int) * ((Qsub (x.seq n) (x.seq n)).den : Int)
    rw [h0]; simp only [Int.zero_mul]
    exact Int.mul_nonneg (by omega) (Int.ofNat_nonneg _)

/-- The clamp is `≥ a` at the Real level. -/
theorem Rle_ofQ_qClampQ (a : Q) (had : 0 < a.den) (x : Real) :
    Rle (ofQ a had) (qClampQ a had x) := by
  intro n
  show Qle a (add (Qmax (x.seq n) a) (⟨2, n + 1⟩ : Q))
  exact Qle_trans (Qmax_den_pos (x.den_pos n) had) (Qmax_ge_right (x.seq n) a)
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

-- ===========================================================================
-- The reciprocal above a rational floor: the cap `1/u ≤ 1/a` and the
-- difference identity `1/u − 1/v ≈ (v − u)·((1/u)·(1/v))`, at the Real level.
-- ===========================================================================

/-- **The reciprocal's floor cap**: `u ≥ a > 0 ⟹ 1/u ≤ 1/a`. Route:
    `1/u ≈ ((1/a)·a)·(1/u) ≈ (1/a)·(a·(1/u)) ≤ (1/a)·(u·(1/u)) ≈ 1/a`. -/
theorem Rinv_le_ofQ_inv {a : Q} (han : 0 < a.num) (had : 0 < a.den) {u : Real} {k : Nat}
    (hk : Qlt (Qbound k) (u.seq k)) (hu : Rle (ofQ a had) u) :
    Rle (Rinv u k hk) (ofQ (Qinv a) (Qinv_den_pos han)) := by
  have hQ : Qeq (mul (Qinv a) a) (⟨1, 1⟩ : Q) :=
    Qeq_trans (Qmul_den_pos had (Qinv_den_pos han)) (Qmul_comm (Qinv a) a) (Qmul_Qinv han)
  have h1a : Req (Rmul (Rmul (ofQ (Qinv a) (Qinv_den_pos han)) (ofQ a had)) (Rinv u k hk))
      (Rinv u k hk) := by
    refine Req_trans (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (Qinv_den_pos han) had)
      (ofQ_congr (Qmul_den_pos (Qinv_den_pos han) had) (by decide) hQ)) (Req_refl _)) ?_
    exact Rone_mul _
  refine Rle_trans (Rle_of_Req (Req_symm h1a)) ?_
  refine Rle_trans (Rle_of_Req
    (Rmul_assoc (ofQ (Qinv a) (Qinv_den_pos han)) (ofQ a had) (Rinv u k hk))) ?_
  refine Rle_trans (Rmul_le_Rmul_left
    (Rnonneg_ofQ (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had)))
    (Rmul_le_Rmul_right (Rnonneg_Rinv u k hk) hu)) ?_
  exact Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) (Rmul_Rinv_self hk)) (Rmul_one _))

/-- **The reciprocal difference identity at the Real level**:
    `1/u − 1/v ≈ (v − u)·((1/u)·(1/v))` — fully algebraic over `Rmul_Rinv_self`. -/
theorem Rinv_sub_Rinv {u v : Real} {ku kv : Nat} (hku : Qlt (Qbound ku) (u.seq ku))
    (hkv : Qlt (Qbound kv) (v.seq kv)) :
    Req (Rsub (Rinv u ku hku) (Rinv v kv hkv))
      (Rmul (Rsub v u) (Rmul (Rinv u ku hku) (Rinv v kv hkv))) := by
  refine Req_symm ?_
  refine Req_trans (Rmul_sub_distrib_right v u (Rmul (Rinv u ku hku) (Rinv v kv hkv))) ?_
  refine Rsub_congr ?_ ?_
  · -- v·((1/u)·(1/v)) ≈ 1/u
    refine Req_trans (Rmul_comm v _) ?_
    refine Req_trans (Rmul_assoc (Rinv u ku hku) (Rinv v kv hkv) v) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Req_trans (Rmul_comm (Rinv v kv hkv) v) (Rmul_Rinv_self hkv))) ?_
    exact Rmul_one _
  · -- u·((1/u)·(1/v)) ≈ 1/v
    refine Req_trans (Req_symm (Rmul_assoc u (Rinv u ku hku) (Rinv v kv hkv))) ?_
    refine Req_trans (Rmul_congr (Rmul_Rinv_self hku) (Req_refl _)) ?_
    exact Rone_mul _

/-- One leg of the reciprocal Lipschitz bound: `1/u − 1/v ≤ (1/a)²·|u − v|` for `u, v ≥ a`. -/
private theorem inv_sub_le_aux {a : Q} (han : 0 < a.num) (had : 0 < a.den) {u v : Real}
    {ku kv : Nat} (hku : Qlt (Qbound ku) (u.seq ku)) (hkv : Qlt (Qbound kv) (v.seq kv))
    (hu : Rle (ofQ a had) u) (hv : Rle (ofQ a had) v) :
    Rle (Rsub (Rinv u ku hku) (Rinv v kv hkv))
      (Rmul (ofQ (mul (Qinv a) (Qinv a)) (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han)))
        (Rabs (Rsub u v))) := by
  refine Rle_trans (Rle_of_Req (Rinv_sub_Rinv hku hkv)) ?_
  refine Rle_trans (Rmul_le_Rmul_right
    (Rnonneg_Rmul (Rnonneg_Rinv u ku hku) (Rnonneg_Rinv v kv hkv))
    (Rle_Rabs_self (Rsub v u))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs _)
    (Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rinv v kv hkv) (Rinv_le_ofQ_inv han had hku hu))
      (Rmul_le_Rmul_left
        (Rnonneg_ofQ (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had)))
        (Rinv_le_ofQ_inv han had hkv hv)))) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Rmul_comm _ _) ?_
  refine Rmul_congr (Rmul_ofQ_ofQ (Qinv_den_pos han) (Qinv_den_pos han)) ?_
  exact Req_trans (Rabs_congr (Req_symm (Rneg_Rsub u v))) (Rabs_Rneg (Rsub u v))

/-- **Reciprocal Lipschitz above a rational floor**: for `u, v ≥ a > 0` (Real-level),
    `|1/u − 1/v| ≤ (1/a)²·|u − v|` — both legs from `inv_sub_le_aux`, joined by
    `Rabs_le_of_both`. -/
theorem Rinv_abs_lipschitz {a : Q} (han : 0 < a.num) (had : 0 < a.den) {u v : Real}
    {ku kv : Nat} (hku : Qlt (Qbound ku) (u.seq ku)) (hkv : Qlt (Qbound kv) (v.seq kv))
    (hu : Rle (ofQ a had) u) (hv : Rle (ofQ a had) v) :
    Rle (Rabs (Rsub (Rinv u ku hku) (Rinv v kv hkv)))
      (Rmul (ofQ (mul (Qinv a) (Qinv a)) (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han)))
        (Rabs (Rsub u v))) := by
  refine Rabs_le_of_both (inv_sub_le_aux han had hku hkv hu hv) ?_
  refine Rle_trans (Rle_of_Req (Rneg_Rsub (Rinv u ku hku) (Rinv v kv hkv))) ?_
  refine Rle_trans (inv_sub_le_aux han had hkv hku hv hu) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _)
    (Req_trans (Rabs_congr (Req_symm (Rneg_Rsub u v))) (Rabs_Rneg (Rsub u v))))

-- ===========================================================================
-- THE CLAMPED RECIPROCAL — total, congruent, globally (1/a)²-Lipschitz,
-- inert on [a, ∞): the integrand-ready 1/x.
-- ===========================================================================

/-- **The clamped reciprocal** `clampedInv a x = 1/max(x, a)` — the totalized `1/x` at rational
    floor `a > 0`. The per-index clamp makes the `Rinv` witness UNIFORM (`2·a.den`), so this is
    a genuine total function of `x` — an integrand. -/
def clampedInv (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x : Real) : Real :=
  Rinv (qClampQ a had x) (2 * a.den) (qClampQ_witness a han had x)

/-- The clamped reciprocal respects `≈` — the gateway's congruence datum. -/
theorem clampedInv_congr (a : Q) (han : 0 < a.num) (had : 0 < a.den) {x y : Real}
    (h : Req x y) : Req (clampedInv a han had x) (clampedInv a han had y) :=
  Rinv_congr _ _ (qClampQ_congr a had h)

/-- The clamped reciprocal is non-negative. -/
theorem Rnonneg_clampedInv (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x : Real) :
    Rnonneg (clampedInv a han had x) :=
  Rnonneg_Rinv _ _ _

/-- **The clamped reciprocal is globally `(1/a)²`-Lipschitz** — the gateway's Lipschitz datum,
    with the RATIONAL constant `(1/a)·(1/a)`: clamp (`1`-Lipschitz) then reciprocal
    (`(1/a)²`-Lipschitz above the floor). -/
theorem clampedInv_lipschitz (a : Q) (han : 0 < a.num) (had : 0 < a.den) (x y : Real) :
    Rle (Rabs (Rsub (clampedInv a han had x) (clampedInv a han had y)))
      (Rmul (ofQ (mul (Qinv a) (Qinv a)) (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han)))
        (Rabs (Rsub x y))) :=
  Rle_trans
    (Rinv_abs_lipschitz han had (qClampQ_witness a han had x) (qClampQ_witness a han had y)
      (Rle_ofQ_qClampQ a had x) (Rle_ofQ_qClampQ a had y))
    (Rmul_le_Rmul_left
      (Rnonneg_ofQ (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han))
        (Int.mul_nonneg (Int.le_of_lt (Qinv_num_pos had)) (Int.le_of_lt (Qinv_num_pos had))))
      (qClampQ_lipschitz a had x y))

/-- **Inertness on `[a, ∞)`**: where `x ≥ a` (Real-level), the clamped reciprocal IS `1/x`
    (any positivity witness for `x`). -/
theorem clampedInv_eq_of_ge {a : Q} {han : 0 < a.num} {had : 0 < a.den} {x : Real} {kx : Nat}
    (hkx : Qlt (Qbound kx) (x.seq kx)) (hx : Rle (ofQ a had) x) :
    Req (clampedInv a han had x) (Rinv x kx hkx) :=
  Rinv_congr _ _ (qClampQ_eq_of_ge hx)

/-- `1/ofQ q ≈ ofQ (1/q)` — the reciprocal of a rational constant is seq-exact (every entry of
    `Rinv (ofQ q)` is literally `Qinv q`). -/
theorem Rinv_ofQ {q : Q} (hqd : 0 < q.den) (hqn : 0 < q.num) {k : Nat}
    (hk : Qlt (Qbound k) ((ofQ q hqd).seq k)) :
    Req (Rinv (ofQ q hqd) k hk) (ofQ (Qinv q) (Qinv_den_pos hqn)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- **The clamped reciprocal of a rational point**: `a ≤ q ⟹ clampedInv a (ofQ q) ≈ ofQ (1/q)` —
    the evaluation form the integral layer consumes at partition points. -/
theorem clampedInv_ofQ {a q : Q} (han : 0 < a.num) (had : 0 < a.den)
    (hqd : 0 < q.den) (hqn : 0 < q.num) (haq : Qle a q) :
    Req (clampedInv a han had (ofQ q hqd)) (ofQ (Qinv q) (Qinv_den_pos hqn)) := by
  have hwit : Qlt (Qbound (2 * a.den)) ((ofQ q hqd).seq (2 * a.den)) :=
    Qlt_of_Qlt_Qle had hqd (Qbound_lt_pos han had) haq
  exact Req_trans
    (clampedInv_eq_of_ge (kx := 2 * a.den) hwit (Rle_ofQ_ofQ had hqd haq))
    (Rinv_ofQ hqd hqn hwit)

-- ===========================================================================
-- The generic Lipschitz-constant upgrade (aligning moduli across summands,
-- as `riemannIntegral_add` requires all pieces to share one `L`).
-- ===========================================================================

/-- A Lipschitz datum at modulus `L` upgrades to any `L' ≥ L` (for a non-negative bound side). -/
theorem lip_mono {L L' : Q} (hLd : 0 < L.den) (hLd' : 0 < L'.den) (h : Qle L L')
    {A B : Real} (hBnn : Rnonneg B) (hb : Rle A (Rmul (ofQ L hLd) B)) :
    Rle A (Rmul (ofQ L' hLd') B) :=
  Rle_trans hb (Rmul_le_Rmul_right hBnn (Rle_ofQ_ofQ hLd hLd' h))

end UOR.Bridge.F1Square.Analysis
