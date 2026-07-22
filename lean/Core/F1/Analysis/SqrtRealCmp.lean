/-
F1 square — **real square-root comparison**: the order-monotonicity of squaring on the non-negatives,
`a² ≤ b² ⟹ a ≤ b` (for `a, b ≥ 0`), and its corollaries for the constructive `Rsqrt` — uniqueness
and monotonicity.

Constructively there is no decidable real order, so the inverse-direction comparison `a² ≤ b² ⟹ a ≤ b`
cannot be read off a sign test. It is proved by the Bishop ε-route: for every `ε = 1/(k+1) > 0`,
`c := b + ε` is *strictly* positive (a positive rational lower-bounds it), `a² ≤ b² ≤ c²`, and on a
strictly-positive `c` the difference-of-squares factoring `(c−a)(c+a) = c²−a²` can be divided by the
invertible `c + a` (`Rinv`, with its positivity witness from the rational lower bound) to give
`c − a ≥ 0`, i.e. `a ≤ b + ε`; the ε-limit (`Rle_of_Rsub_le_eps`) closes `a ≤ b`.

This is the comparison the `Rsqrt` subsystem was missing: with it, `Rsqrt` is the *unique* non-negative
square root (`Rsqrt_unique`) and is monotone in its rational radicand (`Rsqrt_mono`).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.SqrtRealSq
import Core.F1.Analysis.Gamma

namespace UOR.Bridge.F1Square.Analysis

/-- **Squaring is order-reflecting against a strictly-positive bound**: if a positive rational `p`
    lower-bounds `c` (so `c + a` is invertible) and `a² ≤ c²` with `a ≥ 0`, then `a ≤ c`. The engine
    is the difference-of-squares factoring divided by `c + a > 0`. -/
theorem Rle_of_Rsq_le_qpos {a c : Real} {p : Q} (hpn : 0 < p.num) (hpd : 0 < p.den)
    (hpc : Rle (ofQ p hpd) c) (ha : Rnonneg a) (h : Rle (Rmul a a) (Rmul c c)) : Rle a c := by
  -- `c + a ≥ ofQ p` (since `a ≥ 0`), giving the positivity witness for the divisor `c + a`.
  have hpca : Rle (ofQ p hpd) (Radd c a) := Rle_trans hpc (Rle_self_Radd_right ha)
  have hk : Qlt (Qbound (3 * p.den)) ((Radd c a).seq (3 * p.den)) :=
    Rlt_Qbound_of_Rle_ofQ hpn hpd hpca
  -- `c² − a² ≥ 0` and `(c − a)(c + a) = c² − a²`.
  have hsq : Rnonneg (Rsub (Rmul c c) (Rmul a a)) := Rnonneg_Rsub_of_Rle h
  have hdiff : Req (Rmul (Rsub c a) (Radd c a)) (Rsub (Rmul c c) (Rmul a a)) := Rmul_sub_add_self c a
  -- `c − a = (c² − a²)·(c + a)⁻¹`, hence non-negative.
  have hcancel : Req (Rmul (Radd c a) (Rinv (Radd c a) (3 * p.den) hk)) one := Rmul_Rinv_self hk
  have hrepr : Req (Rsub c a)
      (Rmul (Rsub (Rmul c c) (Rmul a a)) (Rinv (Radd c a) (3 * p.den) hk)) := by
    refine Req_trans (Req_symm (Rmul_one (Rsub c a))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (Req_symm hcancel)) ?_
    refine Req_trans (Req_symm (Rmul_assoc (Rsub c a) (Radd c a) (Rinv (Radd c a) (3 * p.den) hk))) ?_
    exact Rmul_congr hdiff (Req_refl _)
  have hnn : Rnonneg (Rsub c a) :=
    Rnonneg_congr (Req_symm hrepr)
      (Rnonneg_Rmul hsq (Rnonneg_Rinv (Radd c a) (3 * p.den) hk))
  exact Rle_of_Rnonneg_Rsub hnn

/-- **Squaring is order-reflecting on the non-negatives**: `a² ≤ b² ⟹ a ≤ b` for `a, b ≥ 0`. The
    Bishop ε-route through `Rle_of_Rsq_le_qpos` at the strictly-positive shift `b + 1/(k+1)`. -/
theorem Rle_of_Rsq_le {a b : Real} (ha : Rnonneg a) (hb : Rnonneg b)
    (h : Rle (Rmul a a) (Rmul b b)) : Rle a b := by
  refine Rle_of_Rsub_le_eps (C := 1) ?_
  intro k
  have hpnn : Rnonneg (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rnonneg_ofQ (Nat.succ_pos k) (by show (0 : Int) ≤ 1; decide)
  -- `ck := b + 1/(k+1)`, strictly positive (`ofQ ⟨1,k+1⟩ ≤ ck`), with `b ≤ ck`.
  have hpck : Rle (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) (Radd b (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k))) :=
    Rle_trans (Rle_self_Radd_right hb)
      (Rle_of_Req (Radd_comm (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) b))
  have hbck : Rle b (Radd b (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k))) := Rle_self_Radd_right hpnn
  -- `a² ≤ b² ≤ ck²`, so `a ≤ ck`.
  have hsqle : Rle (Rmul a a)
      (Rmul (Radd b (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)))
            (Radd b (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)))) :=
    Rle_trans h (Rsq_mono hb (Rnonneg_Radd hb hpnn) hbck)
  have hack : Rle a (Radd b (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k))) :=
    Rle_of_Rsq_le_qpos (p := (⟨1, k + 1⟩ : Q)) (by show (0 : Int) < 1; decide) (Nat.succ_pos k)
      hpck ha hsqle
  -- `a − b ≤ ck − b ≈ 1/(k+1)`.
  have hck_sub : Req (Rsub (Radd b (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k))) b)
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Req_trans (Rsub_congr (Radd_comm b (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k))) (Req_refl b)) ?_
    refine Req_trans (Radd_assoc (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) b (Rneg b)) ?_
    refine Req_trans (Radd_congr (Req_refl _) (Radd_neg b)) ?_
    exact Radd_zero (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k))
  exact Rle_trans (Rsub_le_mono hack (Rle_refl b)) (Rle_of_Req hck_sub)

/-- **`Rsqrt` is the unique non-negative square root**: any `y ≥ 0` with `y² = q` equals `Rsqrt q`. -/
theorem Rsqrt_unique {q : Q} (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q) {y : Real}
    (hy : Rnonneg y) (hsq : Req (Rmul y y) (ofQ q hqd)) : Req y (Rsqrt q hqd hq) := by
  have hyr : Req (Rmul y y) (Rmul (Rsqrt q hqd hq) (Rsqrt q hqd hq)) :=
    Req_trans hsq (Req_symm (Rsqrt_sq q hqd hq))
  refine Rle_antisymm ?_ ?_
  · exact Rle_of_Rsq_le hy (Rsqrt_nonneg q hqd hq) (Rle_of_Req hyr)
  · exact Rle_of_Rsq_le (Rsqrt_nonneg q hqd hq) hy (Rle_of_Req (Req_symm hyr))

/-- **`Rsqrt` is monotone in its rational radicand**: `q ≤ q' ⟹ Rsqrt q ≤ Rsqrt q'`. -/
theorem Rsqrt_mono {q q' : Q} (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (⟨0, 1⟩ : Q) q) (hq' : Qle (⟨0, 1⟩ : Q) q') (hqq' : Qle q q') :
    Rle (Rsqrt q hqd hq) (Rsqrt q' hq'd hq') := by
  refine Rle_of_Rsq_le (Rsqrt_nonneg q hqd hq) (Rsqrt_nonneg q' hq'd hq') ?_
  refine Rle_trans (Rle_of_Req (Rsqrt_sq q hqd hq))
    (Rle_trans (Rle_ofQ_ofQ hqd hq'd hqq') (Rle_of_Req (Req_symm (Rsqrt_sq q' hq'd hq'))))

/-- **`√1 = 1`** — the unit radicand (its own square root). -/
theorem Rsqrt_one : Req (Rsqrt (⟨1, 1⟩ : Q) (by decide) (by decide)) one := by
  refine Req_symm (Rsqrt_unique (y := one) (by decide) (by decide) ?_ ?_)
  · exact Rnonneg_ofQ (by decide) (by decide)
  · exact Req_trans (Rmul_one one) (Req_of_seq_Qeq (fun _ => Qeq_refl _))

/-- **`√q ≥ 1` for `q ≥ 1`** — squaring is monotone, anchored at `√1 = 1`. -/
theorem Rsqrt_ge_one {q : Q} (hqd : 0 < q.den) (hq : Qle (⟨0, 1⟩ : Q) q)
    (h1q : Qle (⟨1, 1⟩ : Q) q) : Rle one (Rsqrt q hqd hq) :=
  Rle_trans (Rle_of_Req (Req_symm Rsqrt_one)) (Rsqrt_mono (by decide) hqd (by decide) hq h1q)

end UOR.Bridge.F1Square.Analysis
