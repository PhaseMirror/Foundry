/-
F1 square — **the dilog kernel `Φ`** (`DilogPhi.lean`): the totalized integrand of the `t4` dilog
`∫₁⁴ log x/(x−1) dx`. The pointwise identity

    `log x/(x−1) = ∫₀¹ ds/(1 + s(x−1))`     (removable singularity at `x = 1` REMOVED by construction)

turns the dilog integrand into an integral-valued kernel: with `u = x − 1 ∈ [0, 3]`,

    `Φ(u) := ∫₀¹ clampedInv 1 (1 + s·band_{[0,3]}(u)) ds`,

a genuine `riemannIntegral` for every real `u` — total, `1`-Lipschitz in `u` (the integral of the
pointwise `clampedInv` Lipschitz bound, via `riemannIntegral_le_unit` against constants), congruent,
and **antitone at rationals** (`Phi_ofQ_anti`, via the sample-level comparison — every sample of the
inner integrand at rational `(s, u)` is the EXACT rational `1/(1+su)` by `clampedInv_ofQ`). At `u=0`:
`Φ(0)=1` — the singular value, carried without any singular object.

HONEST SCOPE. The kernel and its certificates only; no dilog piece is constructed here and nothing
is evaluated. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.MonotoneIntegral
import Multiplicity.F1Square.Analysis.T4PoleAPieces

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The parameter band [0, 3].
-- ===========================================================================

/-- The `[0,3]` parameter band (the dilog's `u = x−1` range over `x ∈ [1,4]`). -/
def bandU (x : Real) : Real := qBandQ ⟨0, 1⟩ ⟨3, 1⟩ (by decide) (by decide) x

/-- The band respects `≈`. -/
theorem bandU_congr {x y : Real} (h : Req x y) : Req (bandU x) (bandU y) :=
  qBandQ_congr ⟨0, 1⟩ ⟨3, 1⟩ (by decide) (by decide) h

/-- The band is `1`-Lipschitz. -/
theorem bandU_lip (x y : Real) : Rle (Rabs (Rsub (bandU x) (bandU y))) (Rabs (Rsub x y)) :=
  qBandQ_lipschitz ⟨0, 1⟩ ⟨3, 1⟩ (by decide) (by decide) x y

/-- The band is non-negative (floor `0`). -/
theorem bandU_nonneg (x : Real) : Rnonneg (bandU x) := by
  intro n
  refine Qle_trans (by decide) ?_ (qBandQ_ge ⟨0, 1⟩ ⟨3, 1⟩ (by decide) (by decide)
    (by decide) x n)
  show Qle (neg (Qbound n)) (⟨0, 1⟩ : Q)
  simp only [Qle, neg, Qbound]; push_cast; omega

/-- The band is `≤ 3`. -/
theorem bandU_le (x : Real) : Rle (bandU x) (ofQ (⟨3, 1⟩ : Q) (by decide)) := by
  intro n
  refine Qle_trans (by decide) (qBandQ_le ⟨0, 1⟩ ⟨3, 1⟩ (by decide) (by decide) x n) ?_
  show Qle (⟨3, 1⟩ : Q) (add (⟨3, 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  simp only [Qle, add]; push_cast; omega

/-- `|band u| ≤ 3`. -/
theorem bandU_abs (x : Real) : Rle (Rabs (bandU x)) (ofQ (⟨3, 1⟩ : Q) (by decide)) :=
  Rle_trans (Rle_of_Req (Rabs_of_nonneg (bandU_nonneg x))) (bandU_le x)

/-- The band is inert on `[0,3]`-rationals. -/
theorem bandU_ofQ {u : Q} (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu3 : Qle u (⟨3, 1⟩ : Q)) : Req (bandU (ofQ u hud)) (ofQ u hud) :=
  qBandQ_eq_of_band (Rle_ofQ_ofQ (by decide) hud h0u) (Rle_ofQ_ofQ hud (by decide) hu3)

-- ===========================================================================
-- Rational kit: reciprocal antitone, scalar monotone, positivity.
-- ===========================================================================

/-- **The rational reciprocal is antitone on positives**: `0 < a ≤ b ⟹ 1/b ≤ 1/a`. -/
theorem Qinv_anti {a b : Q} (han : 0 < a.num) (hbn : 0 < b.num) (h : Qle a b) :
    Qle (Qinv b) (Qinv a) := by
  simp only [Qle, Qinv] at h ⊢
  rw [Int.toNat_of_nonneg (Int.le_of_lt han), Int.toNat_of_nonneg (Int.le_of_lt hbn)]
  rw [Int.mul_comm ((b.den : Nat) : Int) a.num, Int.mul_comm ((a.den : Nat) : Int) b.num]
  exact h

/-- Multiplication by a non-negative rational is monotone: `s ≥ 0, p ≤ q ⟹ s·p ≤ s·q`. -/
private theorem qmul_le_left {s p q : Q} (hs : 0 ≤ s.num) (h : Qle p q) :
    Qle (mul s p) (mul s q) := by
  simp only [Qle, mul] at h ⊢
  push_cast
  have e1 : (s.num * p.num) * ((s.den : Int) * (q.den : Int))
      = (s.num * (s.den : Int)) * (p.num * (q.den : Int)) := by ring_uor
  have e2 : (s.num * q.num) * ((s.den : Int) * (p.den : Int))
      = (s.num * (s.den : Int)) * (q.num * (p.den : Int)) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left h (Int.mul_nonneg hs (Int.ofNat_nonneg s.den))

/-- `1 + s·u` has positive numerator for `s, u ≥ 0`. -/
theorem one_add_mul_num_pos {s u : Q} (hsd : 0 < s.den) (hud : 0 < u.den)
    (hs : 0 ≤ s.num) (hu : 0 ≤ u.num) :
    0 < (add (⟨1, 1⟩ : Q) (mul s u)).num := by
  show 0 < (1 : Int) * ((s.den * u.den : Nat) : Int) + (s.num * u.num) * ((1 : Nat) : Int)
  have h1 : (0 : Int) ≤ s.num * u.num := Int.mul_nonneg hs hu
  have h2 : (0 : Int) < ((s.den * u.den : Nat) : Int) := by
    exact_mod_cast Nat.mul_pos hsd hud
  omega

/-- `1 ≤ 1 + s·u` for `s, u ≥ 0`. -/
theorem one_le_one_add_mul {s u : Q} (hs : 0 ≤ s.num) (hu : 0 ≤ u.num) :
    Qle (⟨1, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (mul s u)) := by
  show (1 : Int) * (((1 * (s.den * u.den) : Nat)) : Int)
      ≤ ((1 : Int) * ((s.den * u.den : Nat) : Int) + (s.num * u.num) * ((1 : Nat) : Int))
        * ((1 : Nat) : Int)
  have h1 : (0 : Int) ≤ s.num * u.num := Int.mul_nonneg hs hu
  have h2 : (0 : Int) ≤ ((s.den * u.den : Nat) : Int) := Int.ofNat_nonneg _
  push_cast
  omega

-- ===========================================================================
-- The inner integrand `s ↦ 1/(1 + s·band(u))` and its gateway certificates.
-- ===========================================================================

/-- **The inner integrand**: `s ↦ clampedInv 1 (1 + s·band_{[0,3]}(u))`, total in both arguments. -/
def phiInner (u : Real) (s : Real) : Real :=
  clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd one (Rmul s (bandU u)))

/-- The inner integrand respects `≈` in `s`. -/
theorem phiInner_congr (u : Real) : ∀ x y : Real, Req x y → Req (phiInner u x) (phiInner u y) :=
  fun _ _ h => clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_congr (Req_refl one) (Rmul_congr h (Req_refl (bandU u))))

/-- The clamp constant `(1/1)·(1/1)` collapses to `1`. -/
private theorem clampK_one : Req (ofQ (mul (Qinv (⟨1, 1⟩ : Q)) (Qinv (⟨1, 1⟩ : Q)))
    (Qmul_den_pos (Qinv_den_pos (by decide)) (Qinv_den_pos (by decide)))) one :=
  ofQ_congr _ (by decide) (by decide)

/-- The inner integrand is `16`-Lipschitz in `s` (true constant `3 = |band|`; weakened to `16`
    so the dyadic schedule reaches every bracket level `M ≤ 16`). -/
theorem phiInner_lip (u : Real) : ∀ x y : Real,
    Rle (Rabs (Rsub (phiInner u x) (phiInner u y)))
        (Rmul (ofQ (⟨16, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  have hargs : Req (Rsub (Radd one (Rmul x (bandU u))) (Radd one (Rmul y (bandU u))))
      (Rmul (bandU u) (Rsub x y)) := by
    refine Req_trans (Rsub_Radd_Radd one (Rmul x (bandU u)) one (Rmul y (bandU u))) ?_
    refine Req_trans (Radd_congr (Radd_neg one) (Req_refl _)) ?_
    refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
    refine Req_trans (Rsub_congr (Rmul_comm x (bandU u)) (Rmul_comm y (bandU u))) ?_
    exact Req_symm (Rmul_sub_distrib (bandU u) x y)
  have habs : Rle (Rabs (Rmul (bandU u) (Rsub x y)))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) :=
    Rle_trans (Rle_of_Req (Rabs_Rmul (bandU u) (Rsub x y)))
      (Rmul_le_Rmul_right (Rnonneg_Rabs _) (bandU_abs u))
  refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) _ _) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ _ ?_)
    (Rle_trans (Rle_of_Req (Rabs_congr hargs)) habs)) ?_
  · show (0 : Int) ≤ (mul (Qinv (⟨1, 1⟩ : Q)) (Qinv (⟨1, 1⟩ : Q))).num
    decide
  refine Rle_trans (Rle_of_Req (Req_trans (Rmul_congr clampK_one (Req_refl _))
    (Rone_mul _))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

-- ===========================================================================
-- The kernel `Φ` and its outer certificates.
-- ===========================================================================

/-- **The dilog kernel**: `Φ(u) = ∫₀¹ ds/(1 + s·band(u))` — a certified integral for every real
    `u`; equals `log(1+u)/u` on `[0,3]` with the `u = 0` singularity removed by construction. -/
def Phi (u : Real) : Real :=
  riemannIntegral (f := phiInner u) (L := (⟨16, 1⟩ : Q)) (by decide) (by decide)
    (phiInner_lip u) (phiInner_congr u)

/-- `Φ` respects `≈`. -/
theorem Phi_congr : ∀ u v : Real, Req u v → Req (Phi u) (Phi v) := by
  intro u v h
  exact riemannIntegral_congr (by decide) (by decide) (phiInner_lip u) (phiInner_congr u)
    (phiInner_lip v) (phiInner_congr v)
    (fun s => clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (Radd_congr (Req_refl one) (Rmul_congr (Req_refl s) (bandU_congr h))))

/-- **The kernel difference bound**: `Φ(u) ≤ |band(u) − band(v)| + Φ(v)` — the integral of the
    pointwise `clampedInv` Lipschitz estimate, via the unit-local comparison against the constant. -/
theorem Phi_diff_le (u v : Real) :
    Rle (Phi u) (Radd (Rabs (Rsub (bandU u) (bandU v))) (Phi v)) := by
  refine Rle_trans (riemannIntegral_le_unit (L := (⟨16, 1⟩ : Q)) (by decide) (by decide)
    (phiInner_lip u) (phiInner_congr u)
    (lip_const_add _ (phiInner_lip v)) (congr_const_add _ (phiInner_congr v))
    ?_)
    (Rle_of_Req (int_const_add_eval (Rabs (Rsub (bandU u) (bandU v))) (by decide) (by decide)
      (phiInner_lip v) (phiInner_congr v) (Req_refl (Phi v))))
  intro s h0 h1
  have hs1 : Rle (Rabs s) one :=
    Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_of_Rle_zero h0))) h1
  have hargs : Req (Rsub (Radd one (Rmul s (bandU u))) (Radd one (Rmul s (bandU v))))
      (Rmul s (Rsub (bandU u) (bandU v))) := by
    refine Req_trans (Rsub_Radd_Radd one (Rmul s (bandU u)) one (Rmul s (bandU v))) ?_
    refine Req_trans (Radd_congr (Radd_neg one) (Req_refl _)) ?_
    refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
    exact Req_symm (Rmul_sub_distrib s (bandU u) (bandU v))
  have habs : Rle (Rabs (Rmul s (Rsub (bandU u) (bandU v))))
      (Rabs (Rsub (bandU u) (bandU v))) := by
    refine Rle_trans (Rle_of_Req (Rabs_Rmul s (Rsub (bandU u) (bandU v)))) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) hs1) ?_
    exact Rle_of_Req (Rone_mul _)
  have hlipd : Rle (Rabs (Rsub (phiInner u s) (phiInner v s)))
      (Rabs (Rsub (bandU u) (bandU v))) := by
    refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) _ _) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ _ ?_)
      (Rle_trans (Rle_of_Req (Rabs_congr hargs)) habs)) ?_
    · show (0 : Int) ≤ (mul (Qinv (⟨1, 1⟩ : Q)) (Qinv (⟨1, 1⟩ : Q))).num
      decide
    exact Rle_of_Req (Req_trans (Rmul_congr clampK_one (Req_refl _)) (Rone_mul _))
  refine Rle_trans (Rle_Radd_of_Rsub_le (Rle_of_Rabs_le hlipd)) ?_
  exact Rle_of_Req (Radd_comm (phiInner v s) (Rabs (Rsub (bandU u) (bandU v))))

/-- **`Φ` is `16`-Lipschitz** (true constant `1`; stated at the gateway modulus `16` so the outer
    dyadic schedule reaches every bracket level `M ≤ 16`). -/
theorem Phi_lip : ∀ u v : Real,
    Rle (Rabs (Rsub (Phi u) (Phi v)))
        (Rmul (ofQ (⟨16, 1⟩ : Q) (by decide)) (Rabs (Rsub u v))) := by
  intro u v
  have h1 : Rle (Rsub (Phi u) (Phi v)) (Rabs (Rsub (bandU u) (bandU v))) := by
    refine Rsub_le_of_le_Radd ?_
    exact Rle_trans (Phi_diff_le u v) (Rle_of_Req (Radd_comm _ _))
  have h2 : Rle (Rsub (Phi v) (Phi u)) (Rabs (Rsub (bandU u) (bandU v))) := by
    refine Rsub_le_of_le_Radd ?_
    refine Rle_trans (Phi_diff_le v u) (Rle_of_Req ?_)
    refine Req_trans (Radd_congr (Req_trans (Rabs_congr (Req_symm (Rneg_Rsub_flip
      (bandU u) (bandU v)))) (Rabs_Rneg _)) (Req_refl (Phi u))) ?_
    exact Radd_comm _ _
  have habs : Rle (Rabs (Rsub (Phi u) (Phi v))) (Rabs (Rsub (bandU u) (bandU v))) := by
    refine Rabs_le_of_both h1 ?_
    exact Rle_trans (Rle_of_Req (Rneg_Rsub_flip (Phi u) (Phi v))) h2
  refine Rle_trans habs (Rle_trans (bandU_lip u v) ?_)
  refine Rle_trans (Rle_of_Req (Req_symm (Rone_mul _))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

-- ===========================================================================
-- Exact rational point values and antitonicity at rationals.
-- ===========================================================================

/-- **The inner integrand at rational points is the exact rational** `1/(1+su)`
    (`s ≥ 0`, `u ∈ [0,3]`). -/
theorem phiInner_ofQ {u s : Q} (hud : 0 < u.den) (hsd : 0 < s.den)
    (h0u : Qle (⟨0, 1⟩ : Q) u) (hu3 : Qle u (⟨3, 1⟩ : Q))
    (hun : 0 ≤ u.num) (hsn : 0 ≤ s.num) :
    Req (phiInner (ofQ u hud) (ofQ s hsd))
        (ofQ (Qinv (add (⟨1, 1⟩ : Q) (mul s u)))
          (Qinv_den_pos (one_add_mul_num_pos hsd hud hsn hun))) := by
  have harg : Req (Radd one (Rmul (ofQ s hsd) (bandU (ofQ u hud))))
      (ofQ (add (⟨1, 1⟩ : Q) (mul s u)) (add_den_pos (by decide) (Qmul_den_pos hsd hud))) := by
    refine Req_trans (Radd_congr (Req_refl one) (Req_trans
      (Rmul_congr (Req_refl (ofQ s hsd)) (bandU_ofQ hud h0u hu3))
      (Rmul_ofQ_ofQ hsd hud))) ?_
    exact Radd_ofQ_ofQ (by decide) (Qmul_den_pos hsd hud)
  refine Req_trans (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) harg) ?_
  exact clampedInv_ofQ (by decide) (by decide) (add_den_pos (by decide) (Qmul_den_pos hsd hud))
    (one_add_mul_num_pos hsd hud hsn hun) (one_le_one_add_mul hsn hun)

/-- **`Φ` is antitone at `[0,3]`-rationals**: `0 ≤ p ≤ q ≤ 3 ⟹ Φ(q) ≤ Φ(p)` — every dyadic
    sample of the inner integrands is an exact rational, and `1/(1+sq) ≤ 1/(1+sp)`. -/
theorem Phi_ofQ_anti {p q : Q} (hpd : 0 < p.den) (hqd : 0 < q.den)
    (h0p : Qle (⟨0, 1⟩ : Q) p) (hpq : Qle p q) (hq3 : Qle q (⟨3, 1⟩ : Q))
    (hpn : 0 ≤ p.num) (hqn : 0 ≤ q.num) :
    Rle (Phi (ofQ q hqd)) (Phi (ofQ p hpd)) := by
  have h0q : Qle (⟨0, 1⟩ : Q) q := Qle_trans hpd h0p hpq
  have hp3 : Qle p (⟨3, 1⟩ : Q) := Qle_trans hqd hpq hq3
  refine riemannIntegral_le_sample (by decide) (by decide)
    (phiInner_lip (ofQ q hqd)) (phiInner_congr (ofQ q hqd))
    (phiInner_lip (ofQ p hpd)) (phiInner_congr (ofQ p hpd)) ?_
  intro N i _hi
  have hsn : (0 : Int) ≤ ((⟨(i : Int), N + 1⟩ : Q)).num := Int.ofNat_nonneg i
  refine Rle_trans (Rle_of_Req (phiInner_ofQ hqd (Nat.succ_pos N) h0q hq3 hqn hsn)) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (phiInner_ofQ hpd (Nat.succ_pos N) h0p hp3
    hpn hsn)))
  refine Rle_ofQ_ofQ _ _ ?_
  refine Qinv_anti (one_add_mul_num_pos (Nat.succ_pos N) hpd hsn hpn)
    (one_add_mul_num_pos (Nat.succ_pos N) hqd hsn hqn) ?_
  refine Qadd_le_add (Qle_refl (⟨1, 1⟩ : Q)) ?_
  exact qmul_le_left hsn hpq

end Multiplicity.UOR.Bridge.F1Square.Analysis
