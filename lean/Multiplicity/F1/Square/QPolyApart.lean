/-
F1 square — **factor-theorem apartness for the ℚ-coefficient co-support member**
(`QPolyApart.lean`). `coSupport_member_exists` (`QCoSupportExists.lean`) produces, at every depth
`K`, a rational coefficient vector `c` that is nonzero *as a VECTOR* (`∃ v, cᵥ ≉ 0`) and whose
polynomial test `qPolyTest c hc (K+2)` lies in the co-support level `K`. This brick upgrades the
nonzero-vector to a **nonzero FUNCTION**: the member is apart from `0` at some point of `[0,1]`.

The route is the large-`M` evaluation. The member's value at `x = 1/M` is `ofQ` of the rational
`Σ_{i<d} cᵢ (1/M)ⁱ` (`qPolyTest_eval_ofQ`), and a nonzero coefficient vector makes that value apart
from `0` for a suitable `M` (`poly_nonzero_evalP`): peel the constant term `c₀`; if `c₀ ≉ 0` the term
dominates a small tail (the sum-of-absolute-values bound `evalP_abs_le_sumAbs`), and if `c₀ ≈ 0` the
polynomial is `(1/M)·(shifted)`, nonzero by induction and no-zero-divisors. Since `1/M ∈ [0,1]` for
`M ≥ 1`, this is the apartness witness `coSupport_member_apart`.

HONEST SCOPE. The factor-theorem apartness only — the monomials are linearly independent on `[0,1]`,
so a member with a nonzero coefficient vector is a nonzero function. NOT positivity. Step 4 is RH;
the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.QCoSupportExists

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- A. Rational polynomial evaluation.
-- ===========================================================================

/-- `rⁿ` over `ℚ`. -/
def Qpow (r : Q) : Nat → Q
  | 0 => (⟨1, 1⟩ : Q)
  | n + 1 => mul r (Qpow r n)

/-- Powers keep a positive denominator. -/
theorem Qpow_den (r : Q) (hr : 0 < r.den) : ∀ n, 0 < (Qpow r n).den
  | 0 => Nat.one_pos
  | n + 1 => Qmul_den_pos hr (Qpow_den r hr n)

/-- `qPolyEval c r d = Σ_{i<d} cᵢ · rⁱ`, an embedded `qsumL` over `List.range d`. -/
def qPolyEval (c : Nat → Q) (r : Q) (d : Nat) : Q :=
  qsumL (fun i => mul (c i) (Qpow r i)) (List.range d)

/-- The evaluation's denominator is positive. -/
theorem qPolyEval_den (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (r : Q) (hr : 0 < r.den) (d : Nat) :
    0 < (qPolyEval c r d).den :=
  qsumL_den _ (fun i => Qmul_den_pos (hc i) (Qpow_den r hr i)) (List.range d)

-- ===========================================================================
-- B. The member's value at a rational point of `[0,1]` is `ofQ (qPolyEval)`.
-- ===========================================================================

/-- The clamped monomial at a rational point of `[0,1]`: `(powTest i)(r) ≈ ofQ rⁱ`. -/
theorem powTest_f_ofQ (r : Q) (hrd : 0 < r.den) (h0r : Qle (⟨0, 1⟩ : Q) r)
    (h1r : Qle r (⟨1, 1⟩ : Q)) :
    ∀ i, Req ((powTest i).f (ofQ r hrd)) (ofQ (Qpow r i) (Qpow_den r hrd i))
  | 0 => Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | i + 1 => by
    have hc : Req (clamp01 (ofQ r hrd)) (ofQ r hrd) := clamp01_ofQ hrd h0r h1r
    refine Req_trans (Rmul_congr (powTest_f_ofQ r hrd h0r h1r i) hc) ?_
    refine Req_trans (Rmul_ofQ_ofQ (Qpow_den r hrd i) hrd) ?_
    exact ofQ_congr (Qmul_den_pos (Qpow_den r hrd i) hrd) (Qpow_den r hrd (i + 1))
      (mul_comm (Qpow r i) r)

/-- The rational-scaled monomial at a rational point: `(qMonoTest cᵢ i)(r) ≈ ofQ (cᵢ·rⁱ)`. -/
theorem qMonoTest_f_ofQ (q : Q) (hq : 0 < q.den) (r : Q) (hrd : 0 < r.den)
    (h0r : Qle (⟨0, 1⟩ : Q) r) (h1r : Qle r (⟨1, 1⟩ : Q)) (i : Nat) :
    Req ((qMonoTest q hq i).f (ofQ r hrd))
      (ofQ (mul q (Qpow r i)) (Qmul_den_pos hq (Qpow_den r hrd i))) := by
  refine Req_trans (Rmul_congr (Req_refl (ofQ q hq)) (powTest_f_ofQ r hrd h0r h1r i)) ?_
  exact Rmul_ofQ_ofQ hq (Qpow_den r hrd i)

/-- **THE MEMBER'S VALUE AT A RATIONAL POINT OF `[0,1]` IS `ofQ (qPolyEval)`**: the depth-`d`
    ℚ-coefficient test, evaluated at `r ∈ [0,1]`, is the embedded rational `Σ_{i<d} cᵢ rⁱ`. -/
theorem qPolyTest_eval_ofQ (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d : Nat) (r : Q)
    (hrd : 0 < r.den) (h0r : Qle (⟨0, 1⟩ : Q) r) (h1r : Qle r (⟨1, 1⟩ : Q)) :
    Req ((qPolyTest c hc d).f (ofQ r hrd))
      (ofQ (qPolyEval c r d) (qPolyEval_den c hc r hrd d)) := by
  refine Req_trans (L2sumN_f_eq (fun i => qMonoTest (c i) (hc i) i) (ofQ r hrd) d) ?_
  refine Req_trans (RsumN_congr d (fun i _ => qMonoTest_f_ofQ (c i) (hc i) r hrd h0r h1r i)) ?_
  exact RsumN_ofQ_qsumL_range (fun i => mul (c i) (Qpow r i))
    (fun i => Qmul_den_pos (hc i) (Qpow_den r hrd i)) d

-- ===========================================================================
-- C. A nonzero coefficient vector makes the evaluation apart from `0`.
-- ===========================================================================

-- --- small ℚ helpers ---

/-- `|−a| = |a|`. -/
private theorem Qabs_neg (a : Q) : Qabs (neg a) = Qabs a := by
  simp only [Qabs, neg, Int.natAbs_neg]

/-- `0 + a ≈ a`. -/
private theorem Qzero_add (a : Q) : Qeq (add (⟨0, 1⟩ : Q) a) a := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- `1 · a ≈ a`. -/
private theorem Qone_mul (a : Q) : Qeq (mul (⟨1, 1⟩ : Q) a) a := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- From `a + b ≈ 0` conclude `a ≈ −b`. -/
private theorem Qeq_neg_of_add_zero {a b : Q} (h : Qeq (add a b) (⟨0, 1⟩ : Q)) :
    Qeq a (neg b) := by
  simp only [Qeq, add, neg] at h ⊢
  push_cast at h ⊢
  simp only [Int.neg_mul, Int.mul_one, Int.zero_mul] at h ⊢
  omega

-- --- the bottom-Horner evaluation and the sum-of-absolute-values majorant ---

/-- `evalP r d c = Σ_{i<d} cᵢ rⁱ`, by Horner from the constant term (peels `c₀`). -/
def evalP (r : Q) : Nat → (Nat → Q) → Q
  | 0, _ => (⟨0, 1⟩ : Q)
  | d + 1, c => add (c 0) (mul r (evalP r d (fun i => c (i + 1))))

/-- `sumAbs d c = Σ_{i<d} |cᵢ|`, the uniform majorant of `|evalP r d c|` on `[0,1]`. -/
def sumAbs : Nat → (Nat → Q) → Q
  | 0, _ => (⟨0, 1⟩ : Q)
  | d + 1, c => add (Qabs (c 0)) (sumAbs d (fun i => c (i + 1)))

/-- The Horner evaluation has a positive denominator. -/
theorem evalP_den (r : Q) (hr : 0 < r.den) :
    ∀ (d : Nat) (c : Nat → Q), (∀ i, 0 < (c i).den) → 0 < (evalP r d c).den
  | 0, _, _ => Nat.one_pos
  | d + 1, c, hc =>
    add_den_pos (hc 0) (Qmul_den_pos hr (evalP_den r hr d (fun i => c (i + 1)) (fun i => hc (i + 1))))

/-- The majorant has a positive denominator. -/
theorem sumAbs_den : ∀ (d : Nat) (c : Nat → Q), (∀ i, 0 < (c i).den) → 0 < (sumAbs d c).den
  | 0, _, _ => Nat.one_pos
  | d + 1, c, hc =>
    add_den_pos (Qabs_den_pos (hc 0)) (sumAbs_den d (fun i => c (i + 1)) (fun i => hc (i + 1)))

/-- `map Nat.succ` shifts the summation index: `Σ_{l.map succ} g = Σ_l g(·+1)`. -/
theorem qsumL_map_succ (g : Nat → Q) : ∀ l : List Nat,
    qsumL g (l.map Nat.succ) = qsumL (fun i => g (i + 1)) l
  | [] => rfl
  | i :: rest => by
    show add (g (i + 1)) (qsumL g (rest.map Nat.succ)) = add (g (i + 1)) (qsumL (fun j => g (j + 1)) rest)
    rw [qsumL_map_succ g rest]

/-- **THE BRIDGE `qPolyEval ≈ evalP`**: the `range`-sum form (natural for part B) equals the
    bottom-Horner form (natural for the domination induction). -/
theorem qPolyEval_eq_evalP (r : Q) (hr : 0 < r.den) :
    ∀ (d : Nat) (c : Nat → Q), (∀ i, 0 < (c i).den) → Qeq (qPolyEval c r d) (evalP r d c)
  | 0, _, _ => Qeq_refl _
  | d + 1, c, hc => by
    have hcs : ∀ i, 0 < (c (i + 1)).den := fun i => hc (i + 1)
    have hgden : ∀ i, 0 < (mul (c i) (Qpow r i)).den :=
      fun i => Qmul_den_pos (hc i) (Qpow_den r hr i)
    have hg''den : ∀ i, 0 < (mul (c (i + 1)) (Qpow r i)).den :=
      fun i => Qmul_den_pos (hc (i + 1)) (Qpow_den r hr i)
    -- expand qPolyEval on range (d+1) = 0 :: (range d).map succ
    have hexp : qPolyEval c r (d + 1)
        = add (mul (c 0) (Qpow r 0))
            (qsumL (fun i => mul (c (i + 1)) (Qpow r (i + 1))) (List.range d)) := by
      show qsumL (fun i => mul (c i) (Qpow r i)) (List.range (d + 1)) = _
      rw [List.range_succ_eq_map]
      show add (mul (c 0) (Qpow r 0))
          (qsumL (fun i => mul (c i) (Qpow r i)) (List.map Nat.succ (List.range d))) = _
      rw [qsumL_map_succ (fun i => mul (c i) (Qpow r i)) (List.range d)]
    -- Σ g(i+1) ≈ r · Σ (mul (c (i+1)) (Qpow r i)) = r · qPolyEval (c∘succ)
    have hcongr : Qeq (qsumL (fun i => mul (c (i + 1)) (Qpow r (i + 1))) (List.range d))
        (qsumL (fun i => mul r (mul (c (i + 1)) (Qpow r i))) (List.range d)) := by
      apply qsumL_congr
      intro i
      show Qeq (mul (c (i + 1)) (Qpow r (i + 1))) (mul r (mul (c (i + 1)) (Qpow r i)))
      simp only [Qpow, Qeq, mul]; push_cast; ring_uor
    have hsmul := qsumL_smul r (fun i => mul (c (i + 1)) (Qpow r i)) hr hg''den (List.range d)
    have hstep : Qeq (qsumL (fun i => mul (c (i + 1)) (Qpow r (i + 1))) (List.range d))
        (mul r (qPolyEval (fun i => c (i + 1)) r d)) :=
      Qeq_trans (qsumL_den _ (fun i => Qmul_den_pos hr (hg''den i)) (List.range d)) hcongr hsmul
    -- IH on the shifted coefficients
    have hIH : Qeq (qPolyEval (fun i => c (i + 1)) r d) (evalP r d (fun i => c (i + 1))) :=
      qPolyEval_eq_evalP r hr d (fun i => c (i + 1)) hcs
    -- (c 0)·r⁰ ≈ c 0
    have hg0 : Qeq (mul (c 0) (Qpow r 0)) (c 0) := by
      simp only [Qpow]; exact mul_one (c 0)
    -- assemble
    rw [hexp]
    show Qeq (add (mul (c 0) (Qpow r 0))
        (qsumL (fun i => mul (c (i + 1)) (Qpow r (i + 1))) (List.range d)))
      (add (c 0) (mul r (evalP r d (fun i => c (i + 1)))))
    refine Qadd_congr hg0 ?_
    exact Qeq_trans (Qmul_den_pos hr (qPolyEval_den (fun i => c (i + 1)) hcs r hr d)) hstep
      (Qmul_congr (Qeq_refl r) hIH)

/-- **THE UNIFORM MAJORANT BOUND**: on `[0,1]` (`|r| ≤ 1`) the Horner evaluation is bounded by the
    sum of the coefficient absolute values, `|evalP r d c| ≤ Σ_{i<d} |cᵢ|`. -/
theorem evalP_abs_le_sumAbs (r : Q) (hr : 0 < r.den) (hrabs : Qle (Qabs r) (⟨1, 1⟩ : Q)) :
    ∀ (d : Nat) (c : Nat → Q), (∀ i, 0 < (c i).den) →
      Qle (Qabs (evalP r d c)) (sumAbs d c)
  | 0, _, _ => by show Qle (Qabs (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q); decide
  | d + 1, c, hc => by
    have hcs : ∀ i, 0 < (c (i + 1)).den := fun i => hc (i + 1)
    have hTd : 0 < (evalP r d (fun i => c (i + 1))).den :=
      evalP_den r hr d (fun i => c (i + 1)) hcs
    -- |c₀ + r·T| ≤ |c₀| + |r·T|
    have h1 : Qle (Qabs (add (c 0) (mul r (evalP r d (fun i => c (i + 1))))))
        (add (Qabs (c 0)) (Qabs (mul r (evalP r d (fun i => c (i + 1)))))) :=
      Qabs_add_le (c 0) (mul r (evalP r d (fun i => c (i + 1))))
    -- |r·T| = |r|·|T| ≤ 1·|T| ≈ |T|
    have h2 : Qle (Qabs (mul r (evalP r d (fun i => c (i + 1)))))
        (Qabs (evalP r d (fun i => c (i + 1)))) := by
      rw [Qabs_mul]
      have hs : Qle (mul (Qabs r) (Qabs (evalP r d (fun i => c (i + 1)))))
          (mul (⟨1, 1⟩ : Q) (Qabs (evalP r d (fun i => c (i + 1))))) :=
        Qmul_le_mul_right (Qabs_num_nonneg (evalP r d (fun i => c (i + 1)))) hrabs
      exact Qle_congr_right (Qmul_den_pos (by decide) (Qabs_den_pos hTd))
        (Qone_mul (Qabs (evalP r d (fun i => c (i + 1))))) hs
    -- |T| ≤ Σ|c(·+1)|
    have hIH : Qle (Qabs (evalP r d (fun i => c (i + 1)))) (sumAbs d (fun i => c (i + 1))) :=
      evalP_abs_le_sumAbs r hr hrabs d (fun i => c (i + 1)) hcs
    -- assemble
    show Qle (Qabs (add (c 0) (mul r (evalP r d (fun i => c (i + 1))))))
      (add (Qabs (c 0)) (sumAbs d (fun i => c (i + 1))))
    refine Qle_trans (add_den_pos (Qabs_den_pos (hc 0)) (Qabs_den_pos (Qmul_den_pos hr hTd)))
      h1 ?_
    exact Qadd_le_add (Qle_refl (Qabs (c 0))) (Qle_trans (Qabs_den_pos hTd) h2 hIH)

/-- The majorant has a non-negative numerator. -/
theorem sumAbs_num_nonneg : ∀ (d : Nat) (c : Nat → Q), (0 : Int) ≤ (sumAbs d c).num
  | 0, _ => by show (0 : Int) ≤ (0 : Int); decide
  | d + 1, c => by
    show (0 : Int) ≤ (Qabs (c 0)).num * ((sumAbs d (fun i => c (i + 1))).den : Int)
      + (sumAbs d (fun i => c (i + 1))).num * ((Qabs (c 0)).den : Int)
    have h1 := Int.mul_nonneg (Qabs_num_nonneg (c 0))
      (Int.ofNat_nonneg (sumAbs d (fun i => c (i + 1))).den)
    have h2 := Int.mul_nonneg (sumAbs_num_nonneg d (fun i => c (i + 1)))
      (Int.ofNat_nonneg (Qabs (c 0)).den)
    omega

/-- `1/M ≉ 0`. -/
private theorem Qone_M_ne_zero (M : Nat) : ¬ Qeq (⟨1, M⟩ : Q) (⟨0, 1⟩ : Q) := by
  intro h; simp only [Qeq] at h; omega

/-- The pure-`ℤ` domination kernel: `1 ≤ a`, `1 ≤ cd`, `0 ≤ bn`, `1 ≤ bd`, `M = bn·cd + 1`, then
    `a·(M·bd) ≤ bn·cd` is impossible — the constant term beats the `(1/M)`-scaled tail. -/
private theorem dom_arith {a cd bn bd M : Int} (ha : 1 ≤ a) (hcd : 1 ≤ cd) (hbn : 0 ≤ bn)
    (hbd : 1 ≤ bd) (hM : M = bn * cd + 1) (hle : a * (M * bd) ≤ bn * cd) : False := by
  have hbncd : (0 : Int) ≤ bn * cd := Int.mul_nonneg hbn (by omega)
  have hM0 : 0 ≤ M := by omega
  have hab : 1 ≤ a * bd := by
    have h1 : (0 : Int) ≤ (a - 1) * bd := Int.mul_nonneg (by omega) (by omega)
    have h2 : (a - 1) * bd = a * bd - bd := by ring_uor
    omega
  have hkey : M ≤ a * (M * bd) := by
    have hnn : (0 : Int) ≤ M * (a * bd - 1) := Int.mul_nonneg hM0 (by omega)
    have he : M * (a * bd - 1) = a * (M * bd) - M := by ring_uor
    omega
  have hchain : M ≤ bn * cd := Int.le_trans hkey hle
  omega

/-- The `ℚ`-level domination contradiction: with `M = |B|.num·c₀.den + 1`, `|c₀| ≤ (1/M)·B` is
    impossible once `c₀ ≉ 0` — the concrete `M` chosen so the constant term strictly wins. -/
private theorem dom_arith_Q (c0 B : Q) (hc0d : 0 < c0.den) (hc0 : c0.num ≠ 0) (hBnum : 0 ≤ B.num)
    (hBden : 0 < B.den)
    (hle : Qle (Qabs c0) (mul (⟨1, B.num.toNat * c0.den + 1⟩ : Q) B)) : False := by
  simp only [Qle, Qabs, mul] at hle
  push_cast at hle
  rw [Int.one_mul] at hle
  have ha : (1 : Int) ≤ (c0.num.natAbs : Int) := by
    have h : c0.num.natAbs ≠ 0 := fun hh => hc0 (Int.natAbs_eq_zero.mp hh)
    have : 1 ≤ c0.num.natAbs := Nat.pos_of_ne_zero h
    exact_mod_cast this
  refine dom_arith (a := (c0.num.natAbs : Int)) (cd := (c0.den : Int)) (bn := B.num)
    (bd := (B.den : Int)) (M := (B.num.toNat : Int) * (c0.den : Int) + 1)
    ha (by exact_mod_cast hc0d) hBnum (by exact_mod_cast hBden)
    (by rw [Int.toNat_of_nonneg hBnum]) hle

/-- **LEMMA A**: if the depth-`d+1` Horner value at `1/M` vanishes and `c₀ ≉ 0`, the constant term is
    bounded by the `(1/M)`-scaled majorant, `|c₀| ≤ (1/M)·Σ_{i<d}|cᵢ₊₁|`. -/
theorem evalP_abs_c0_le (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d M : Nat) (hM1 : 1 ≤ M)
    (hV : Qeq (evalP (⟨1, M⟩ : Q) (d + 1) c) (⟨0, 1⟩ : Q)) :
    Qle (Qabs (c 0)) (mul (⟨1, M⟩ : Q) (sumAbs d (fun i => c (i + 1)))) := by
  have hr : 0 < (⟨1, M⟩ : Q).den := hM1
  have hqabs1M : Qabs (⟨1, M⟩ : Q) = (⟨1, M⟩ : Q) := rfl
  have hrabs : Qle (Qabs (⟨1, M⟩ : Q)) (⟨1, 1⟩ : Q) := by
    rw [hqabs1M]; simp only [Qle]; push_cast; omega
  have hTd : 0 < (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1))).den :=
    evalP_den (⟨1, M⟩ : Q) hr d (fun i => c (i + 1)) (fun i => hc (i + 1))
  -- from hV: c 0 ≈ −(mul ⟨1,M⟩ T)
  have hcneg : Qeq (c 0) (neg (mul (⟨1, M⟩ : Q) (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1))))) :=
    Qeq_neg_of_add_zero hV
  have habs : Qeq (Qabs (c 0))
      (Qabs (mul (⟨1, M⟩ : Q) (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1))))) := by
    have h := Qabs_Qeq hcneg
    rwa [Qabs_neg] at h
  have hle : Qle (Qabs (mul (⟨1, M⟩ : Q) (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1)))))
      (mul (⟨1, M⟩ : Q) (sumAbs d (fun i => c (i + 1)))) := by
    rw [Qabs_mul, hqabs1M]
    exact Qmul_le_mul_left (by show (0 : Int) ≤ (1 : Int); decide)
      (evalP_abs_le_sumAbs (⟨1, M⟩ : Q) hr hrabs d (fun i => c (i + 1)) (fun i => hc (i + 1)))
  exact Qle_congr_left (Qabs_den_pos (Qmul_den_pos hr hTd)) (Qeq_symm habs) hle

/-- **A NONZERO COEFFICIENT VECTOR MAKES THE HORNER EVALUATION APART FROM `0`**: for a suitable
    `M ≥ 1`, `evalP (1/M) d c ≉ 0`. Peel `c₀`: if `c₀ ≉ 0` the constant term dominates a `(1/M)`-scaled
    tail (Lemma A + `dom_arith`); if `c₀ ≈ 0` the value is `(1/M)·(shifted)`, nonzero by induction and
    the no-zero-divisor law `Qmul_ne_zero`. -/
theorem poly_nonzero_evalP :
    ∀ (d : Nat) (c : Nat → Q), (∀ i, 0 < (c i).den) →
      (∃ j, j < d ∧ ¬ Qeq (c j) (⟨0, 1⟩ : Q)) →
      ∃ M : Nat, 1 ≤ M ∧ ¬ Qeq (evalP (⟨1, M⟩ : Q) d c) (⟨0, 1⟩ : Q)
  | 0, _, _, ⟨j, hj, _⟩ => absurd hj (Nat.not_lt_zero j)
  | d + 1, c, hc, ⟨j, hjd, hjnz⟩ => by
    by_cases hc0 : Qeq (c 0) (⟨0, 1⟩ : Q)
    · -- c₀ ≈ 0: value is (1/M)·(shifted), nonzero by IH + no-zero-divisors.
      have hj0 : j ≠ 0 := fun h => hjnz (h ▸ hc0)
      obtain ⟨j', rfl⟩ : ∃ j', j = j' + 1 := ⟨j - 1, by omega⟩
      obtain ⟨M, hM1, hMnz⟩ :=
        poly_nonzero_evalP d (fun i => c (i + 1)) (fun i => hc (i + 1)) ⟨j', by omega, hjnz⟩
      have hr : 0 < (⟨1, M⟩ : Q).den := hM1
      have hTd : 0 < (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1))).den :=
        evalP_den (⟨1, M⟩ : Q) hr d (fun i => c (i + 1)) (fun i => hc (i + 1))
      refine ⟨M, hM1, ?_⟩
      intro hV
      have hmulnz : ¬ Qeq (mul (⟨1, M⟩ : Q) (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1))))
          (⟨0, 1⟩ : Q) := Qmul_ne_zero (Qone_M_ne_zero M) hMnz
      have heval : Qeq (evalP (⟨1, M⟩ : Q) (d + 1) c)
          (mul (⟨1, M⟩ : Q) (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1)))) := by
        show Qeq (add (c 0) (mul (⟨1, M⟩ : Q) (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1)))))
          (mul (⟨1, M⟩ : Q) (evalP (⟨1, M⟩ : Q) d (fun i => c (i + 1))))
        exact Qeq_trans (add_den_pos (by decide) (Qmul_den_pos hr hTd))
          (Qadd_congr hc0 (Qeq_refl _)) (Qzero_add _)
      exact hmulnz (Qeq_trans (evalP_den (⟨1, M⟩ : Q) hr (d + 1) c hc) (Qeq_symm heval) hV)
    · -- c₀ ≉ 0: domination.
      refine ⟨(sumAbs d (fun i => c (i + 1))).num.toNat * (c 0).den + 1, by omega, ?_⟩
      intro hV
      have hM1 : 1 ≤ (sumAbs d (fun i => c (i + 1))).num.toNat * (c 0).den + 1 := by omega
      have hc0num : (c 0).num ≠ 0 := fun h => hc0 (by simp only [Qeq]; rw [h]; ring_uor)
      exact dom_arith_Q (c 0) (sumAbs d (fun i => c (i + 1))) (hc 0) hc0num
        (sumAbs_num_nonneg d _) (sumAbs_den d (fun i => c (i + 1)) (fun i => hc (i + 1)))
        (evalP_abs_c0_le c hc d _ hM1 hV)

-- ===========================================================================
-- D. Assembly: the co-support member is apart from `0` on `[0,1]`.
-- ===========================================================================

/-- The reverse of `ofQ_eq_zero`: an embedded rational that is Bishop-equal to `0` in ℝ has ℚ-value
    `0`. The `2/(m+1)` slack collapses through the generalized Archimedean lemma (`Qarch_gen`). -/
theorem Qeq_of_ofQ_eq_zero {q : Q} (hq : 0 < q.den) (h : Req (ofQ q hq) zero) :
    Qeq q (⟨0, 1⟩ : Q) := by
  have hqabs_le : Qle (Qabs q) (⟨0, 1⟩ : Q) := by
    refine Qarch_gen (C := 2) (Qabs_den_pos hq) (by decide) ?_
    intro m
    have hm : Qle (Qabs (Qsub q (⟨0, 1⟩ : Q))) (⟨2, m + 1⟩ : Q) := h m
    have hsub : Qeq q (Qsub q (⟨0, 1⟩ : Q)) := by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    have h1 : Qle (Qabs q) (⟨2, m + 1⟩ : Q) :=
      Qle_congr_left (Qabs_den_pos (Qsub_den_pos hq (by decide)))
        (Qeq_symm (Qabs_Qeq hsub)) hm
    exact Qle_congr_right (Nat.succ_pos m) (Qeq_symm (Qzero_add (⟨2, m + 1⟩ : Q))) h1
  have hnum : q.num.natAbs = 0 := by
    simp only [Qle, Qabs] at hqabs_le
    push_cast at hqabs_le
    omega
  exact (Qeq_zero_iff q).mpr (Int.natAbs_eq_zero.mp hnum)

/-- **FACTOR-THEOREM APARTNESS**: the depth-`K` ℚ-coefficient co-support member of
    `coSupport_member_exists` — nonzero as a VECTOR — is apart from `0` as a FUNCTION at some point of
    `[0,1]`. It lies in the co-support level `K` and takes a value `≉ 0` at `x = 1/M` for a suitable
    `M ≥ 1`. -/
theorem coSupport_member_apart (K : Nat) :
    ∃ (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hsupp : UnitSupported (qPolyTest c hc (K + 2))),
      (HatVanishes (qPolyTest c hc (K + 2)) K (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp (qPolyTest c hc (K + 2)) hsupp)) ∧
      (∃ x, Rle zero x ∧ Rle x one ∧ ¬ Req ((qPolyTest c hc (K + 2)).f x) zero) := by
  obtain ⟨c, hc, hsupp, ⟨v, hv, hvnz⟩, hHV⟩ := coSupport_member_exists K
  obtain ⟨M, hM1, hMnz⟩ := poly_nonzero_evalP (K + 2) c hc ⟨v, List.mem_range.mp hv, hvnz⟩
  have hr : 0 < (⟨1, M⟩ : Q).den := hM1
  have h0r : Qle (⟨0, 1⟩ : Q) (⟨1, M⟩ : Q) := by simp only [Qle]; push_cast; omega
  have h1r : Qle (⟨1, M⟩ : Q) (⟨1, 1⟩ : Q) := by simp only [Qle]; push_cast; omega
  refine ⟨c, hc, hsupp, hHV, ofQ (⟨1, M⟩ : Q) hr, ?_, ?_, ?_⟩
  · exact Rle_zero_of_Rnonneg (Rnonneg_ofQ hr (by show (0 : Int) ≤ 1; decide))
  · exact Rle_ofQ_ofQ hr (by decide) h1r
  · intro hReq
    have heval := qPolyTest_eval_ofQ c hc (K + 2) (⟨1, M⟩ : Q) hr h0r h1r
    have hz : Req (ofQ (qPolyEval c (⟨1, M⟩ : Q) (K + 2))
        (qPolyEval_den c hc (⟨1, M⟩ : Q) hr (K + 2))) zero :=
      Req_trans (Req_symm heval) hReq
    have hqz : Qeq (qPolyEval c (⟨1, M⟩ : Q) (K + 2)) (⟨0, 1⟩ : Q) :=
      Qeq_of_ofQ_eq_zero _ hz
    have hbridge : Qeq (qPolyEval c (⟨1, M⟩ : Q) (K + 2)) (evalP (⟨1, M⟩ : Q) (K + 2) c) :=
      qPolyEval_eq_evalP (⟨1, M⟩ : Q) hr (K + 2) c hc
    exact hMnz (Qeq_trans (qPolyEval_den c hc (⟨1, M⟩ : Q) hr (K + 2)) (Qeq_symm hbridge) hqz)

end Multiplicity.UOR.Bridge.F1Square.Square
