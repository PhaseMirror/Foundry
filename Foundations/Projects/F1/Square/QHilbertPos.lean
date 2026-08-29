/-
F1 square — **the rational Hilbert form is positive-definite** (`QHilbertPos.lean`), the second brick
of the Hausdorff *sufficient*-direction arc (construct an L² member from a valid moment sequence).
The moment-problem construction runs orthogonal polynomials `q_k` through Gram–Schmidt against the
Hilbert inner product; that needs the norms `‖q_k‖² = ⟨q_k,q_k⟩` to be strictly positive for every
nonzero polynomial. This brick supplies exactly that, at the rational-form level:

  `qHil_self_pos` :  a nonzero coefficient vector `c` gives `qHil c c d > 0`.

The bridge here is a **definiteness of the L² inner product at a rational point**, itself the natural
strengthening of the dyadic definiteness `innerI_self_pos_of_dyadic`:

  `innerI_self_pos_of_ratpoint` :  `φ(ofQ r)² > 0`  ⟹  `∫₀¹ φ² > 0`   for a **rational** `r ∈ [0,1]`.

The constructive obstruction that forced the earlier statement to dyadic points — one cannot *locate*
a general real `x` inside a dyadic interval — dissolves for a *rational* point: the enclosing dyadic
index `j = ⌊r·2^m⌋` (clamped to `< 2^m`) is computed in `ℕ`, and `sq_ge_on_piece_near` (the density
half of `L2Definite`) carries the pointwise positivity across the piece even though `r` need not be
the endpoint. Assembly of `qHil_self_pos`: a nonzero `c` is apart from `0` at some `x = 1/M`
(`poly_nonzero_evalP`), the value there is a nonzero *rational* `v` so `v² > 0` decidably, hence
`Pos (φ(1/M)²)`, hence `Pos (∫₀¹ φ²)` by ratpoint definiteness, hence `qHil c c d > 0` through the
`innerI_qPolyTest_qPolyTest` bridge.

HONEST SCOPE. Positive-*definiteness* of the finite rational Hilbert form (`qHil c c > 0` for nonzero
`c`) and the reusable rational-point L² definiteness behind it. This is a foundation for the
orthogonal-polynomial / Riesz construction of the sufficient direction; it is NOT that construction,
NOT the moment-range surjectivity result, and NOT any positivity beyond the finite form. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.L2Definite
import Foundations.F1.Square.QHilbertForm
import Foundations.F1.Square.QPolyApart
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local ℚ/ℝ helpers (private).
-- ===========================================================================

/-- A nonzero integer has a strictly-positive square. (Extracted to a clean bound variable so
    `ring_uor` does not mis-atomize a repeated projection.) -/
private theorem Int_mul_self_pos {a : Int} (h : a ≠ 0) : 0 < a * a := by
  rcases Int.lt_trichotomy a 0 with hlt | heq | hgt
  · have hp : (0 : Int) < -a := by omega
    have hprod := Int.mul_pos hp hp
    have e : -a * -a = a * a := by ring_uor
    rwa [e] at hprod
  · exact absurd heq h
  · exact Int.mul_pos hgt hgt

/-- `Rsub` of two embedded rationals collapses to the embedded difference (local copy of the
    `TentSlot` private). -/
private theorem ofQ_sub_loc {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) :
    Req (Rsub (ofQ a ha) (ofQ b hb)) (ofQ (Qsub a b) (Qsub_den_pos ha hb)) :=
  Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ b hb))
    (Radd_ofQ_ofQ (a := a) (b := neg b) ha hb)

/-- `1/M ∈ [0,1]` for `M ≥ 1` — proven in a clean minimal context so `omega` never ingests the
    surrounding `¬Qeq` hypotheses (whose presence otherwise leads `omega` to pull `Classical.choice`). -/
private theorem q0M (M : Nat) (hM : 1 ≤ M) : Qle (⟨0, 1⟩ : Q) (⟨1, M⟩ : Q) := by
  simp only [Qle]; push_cast; omega

private theorem qM1 (M : Nat) (hM : 1 ≤ M) : Qle (⟨1, M⟩ : Q) (⟨1, 1⟩ : Q) := by
  simp only [Qle]; push_cast; omega

/-- A rational apart from `0` has nonzero numerator (clean-context extractor). -/
private theorem num_ne_zero_of_Qne {q : Q} (h : ¬ Qeq q (⟨0, 1⟩ : Q)) : q.num ≠ 0 := by
  intro hn; exact h (by simp only [Qeq]; rw [hn]; ring_uor)

/-- **`Pos (ofQ q)` forces `q > 0` as a rational**: a strictly-positive embedded rational has positive
    numerator. -/
private theorem Qlt_zero_of_Pos_ofQ {q : Q} (hq : 0 < q.den) (h : Pos (ofQ q hq)) :
    Qlt (⟨0, 1⟩ : Q) q := by
  obtain ⟨n, hn⟩ := h
  have hd : (0 : Int) < (q.den : Int) := by exact_mod_cast hq
  -- `hn : Qbound n < (ofQ q hq).seq n = q`, i.e. `q.den < q.num·(n+1)` (`Qbound n = ⟨1, n+1⟩`).
  have hn' : (q.den : Int) < q.num * ((n : Int) + 1) := by
    have hh := hn
    simp only [Qlt, Qbound] at hh
    have hseq : (ofQ q hq).seq n = q := rfl
    rw [hseq] at hh
    push_cast at hh
    omega
  have hpos : 0 < q.num := by
    rcases Int.lt_trichotomy q.num 0 with hlt | heq | hgt
    · exfalso
      have hnn : (0 : Int) ≤ (n : Int) + 1 := by omega
      have hle0 := Int.mul_le_mul_of_nonneg_right (Int.le_of_lt hlt) hnn
      omega
    · exfalso; rw [heq] at hn'; omega
    · exact hgt
  show (0 : Int) * (q.den : Int) < q.num * 1
  omega

-- Pure-ℤ side inequalities, so no nonlinear reasoning is asked of `omega`. Each is the
-- cross-multiplied `Qle` numerator obligation for the piece-nearness, derived from the *divided*
-- bound by one monotone multiplication.
private theorem near_side_hi (j rd rn P : Int) (hP0 : 0 ≤ P) (h : j * rd - rn * P ≤ rd) :
    (j * rd + -rn * P) * P ≤ 1 * (P * rd) := by
  have hm := Int.mul_le_mul_of_nonneg_right h hP0
  have e1 : (j * rd + -rn * P) * P = (j * rd - rn * P) * P := by ring_uor
  have e2 : (1 : Int) * (P * rd) = rd * P := by ring_uor
  rw [e1, e2]; exact hm

private theorem near_side_lo (j rd rn P : Int) (hP0 : 0 ≤ P) (h : rn * P - j * rd ≤ rd) :
    -(j * rd + -rn * P) * P ≤ 1 * (P * rd) := by
  have hm := Int.mul_le_mul_of_nonneg_right h hP0
  have e1 : -(j * rd + -rn * P) * P = (rn * P - j * rd) * P := by ring_uor
  have e2 : (1 : Int) * (P * rd) = rd * P := by ring_uor
  rw [e1, e2]; exact hm

/-- The two-sided bound from the division equation, over abstract naturals — so `omega` never sees a
    division term (which it cannot combine with the products). -/
private theorem floor_val_bound (Qq R N rd : Nat) (heq : rd * Qq + R = N) (hR : R < rd) :
    -(rd : Int) ≤ (Qq : Int) * (rd : Int) - (N : Int)
      ∧ (Qq : Int) * (rd : Int) - (N : Int) ≤ (rd : Int) := by
  have hcast : (rd : Int) * (Qq : Int) + (R : Int) = (N : Int) := by exact_mod_cast heq
  have hcomm : (Qq : Int) * (rd : Int) = (rd : Int) * (Qq : Int) := Int.mul_comm _ _
  have hRI : (R : Int) < (rd : Int) := by exact_mod_cast hR
  have hRnn : (0 : Int) ≤ (R : Int) := Int.ofNat_nonneg _
  constructor <;> omega

/-- **The clamped floor gives an index within one unit**: for `rn ≤ rd` and `P ≥ 1`, the index
    `j = min ⌊rn·P/rd⌋ (P−1)` satisfies `j < P` and `|j·rd − rn·P| ≤ rd`. Pure `ℕ`/`ℤ`: the floor's
    div/mod equation gives `j·rd − rn·P = −(rn·P % rd) ∈ [−rd, 0]`; the clamp only triggers when the
    quotient reaches `P`, which (with `rn ≤ rd`) forces `rn = rd`, making `(P−1)·rd − rd·P = −rd`. -/
private theorem clamped_floor_bound (rn rd P : Nat) (hd : 0 < rd) (hle : rn ≤ rd) (hP : 0 < P) :
    ∃ j : Nat, j < P ∧
      -(rd : Int) ≤ (j : Int) * (rd : Int) - (rn : Int) * (P : Int) ∧
      (j : Int) * (rd : Int) - (rn : Int) * (P : Int) ≤ (rd : Int) := by
  -- abstract the quotient/remainder so no `omega` call ever meets a division term
  obtain ⟨Qq, R, hR, hdm⟩ : ∃ Qq R, R < rd ∧ rd * Qq + R = rn * P :=
    ⟨rn * P / rd, rn * P % rd, Nat.mod_lt _ hd, Nat.div_add_mod _ _⟩
  have hb : ((rn * P : Nat) : Int) = (rn : Int) * (P : Int) := by push_cast; ring_uor
  by_cases hc : Qq < P
  · obtain ⟨hlo, hhi⟩ := floor_val_bound Qq R (rn * P) rd hdm hR
    rw [hb] at hlo hhi
    exact ⟨Qq, hc, hlo, hhi⟩
  · -- clamp branch: `Qq ≥ P` with `rn ≤ rd` forces `Qq = P`, `rn = rd`, `j = P − 1`
    have hQgeP : P ≤ Qq := by omega
    have hrnP_le : rn * P ≤ rd * P := Nat.mul_le_mul_right P hle
    have hrdQ_le : rd * Qq ≤ rd * P := by omega
    have hQleP : Qq ≤ P := Nat.le_of_mul_le_mul_left hrdQ_le hd
    have hQeqP : Qq = P := Nat.le_antisymm hQleP hQgeP
    rw [hQeqP] at hdm
    -- hdm : rd * P + R = rn * P
    have hrnPeq : rn * P = rd * P := by omega
    have hrneq : rn = rd := Nat.eq_of_mul_eq_mul_right hP hrnPeq
    refine ⟨P - 1, by omega, ?_, ?_⟩ <;>
    · have hpm : ((P - 1 : Nat) : Int) = (P : Int) - 1 := by
        have := Nat.succ_pred_eq_of_pos hP; omega
      have hrI : (rn : Int) = (rd : Int) := by exact_mod_cast hrneq
      have hval : ((P - 1 : Nat) : Int) * (rd : Int) - (rn : Int) * (P : Int) = -(rd : Int) := by
        rw [hpm, hrI]; ring_uor
      rw [hval]; omega

/-- **Existence of an enclosing dyadic point for a rational** `r ∈ [0,1]`: at depth `m` there is an
    index `j < 2^m` whose dyadic point `j/2^m` is within the width `1/2^m` of `r`. The index is the
    clamped floor `min ⌊r·2^m⌋ (2^m − 1)` (`clamped_floor_bound`), and the goal is reached by
    transporting the clean-form nearness along the `dyadA`/`dyadW` values. -/
private theorem exists_dyadic_near (r : Q) (hr : 0 < r.den) (h0 : Qle (⟨0, 1⟩ : Q) r)
    (h1 : Qle r (⟨1, 1⟩ : Q)) (m : Nat) :
    ∃ j : Nat, j < 2 ^ m ∧
      Qle (Qabs (Qsub (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) r)) (dyadW (⟨1, 1⟩ : Q) m) := by
  have hrn0 : 0 ≤ r.num := by
    have := h0; simp only [Qle] at this; push_cast at this; omega
  have hrle : r.num ≤ (r.den : Int) := by
    have := h1; simp only [Qle] at this; push_cast at this; omega
  have hPpos : 0 < 2 ^ m := Nat.pos_pow_of_pos m (by decide)
  have hPI0 : (0 : Int) ≤ ((2 ^ m : Nat) : Int) := Int.ofNat_nonneg _
  have hP0I : (0 : Int) ≤ (2 : Int) ^ m := by
    have he : ((2 ^ m : Nat) : Int) = (2 : Int) ^ m := by push_cast; ring_uor
    rw [← he]; exact Int.ofNat_nonneg _
  have hrncast : ((r.num.toNat : Nat) : Int) = r.num := Int.toNat_of_nonneg hrn0
  have hrleN : r.num.toNat ≤ r.den := by omega
  obtain ⟨j, hj, hlo, hhi⟩ := clamped_floor_bound r.num.toNat r.den (2 ^ m) hr hrleN hPpos
  rw [hrncast] at hlo hhi
  push_cast at hlo hhi
  -- transport the clean-form nearness `|⟨j,2^m⟩ − r| ≤ ⟨1,2^m⟩` to the `dyadA`/`dyadW` goal
  refine ⟨j, hj, ?_⟩
  have heA : Qeq (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) (⟨(j : Int), 2 ^ m⟩ : Q) := by
    simp only [Qeq, dyadA, add, mul]; push_cast; ring_uor
  have heW : Qeq (dyadW (⟨1, 1⟩ : Q) m) (⟨1, 2 ^ m⟩ : Q) := by
    simp only [Qeq, dyadW, mul]; push_cast; ring_uor
  have hAcleanDen : 0 < (⟨(j : Int), 2 ^ m⟩ : Q).den := hPpos
  have hWcleanDen : 0 < (⟨1, 2 ^ m⟩ : Q).den := hPpos
  have habsEq : Qeq (Qabs (Qsub (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) r))
      (Qabs (Qsub (⟨(j : Int), 2 ^ m⟩ : Q) r)) := Qabs_Qeq (Qsub_congr heA (Qeq_refl r))
  refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos hAcleanDen hr)) (Qeq_symm habsEq) ?_
  refine Qle_congr_right hWcleanDen (Qeq_symm heW) ?_
  refine Qabs_le_of_both ?_ ?_
  · simp only [Qle, Qsub, add, neg]
    push_cast
    exact near_side_hi (j : Int) (r.den : Int) r.num ((2 : Int) ^ m) hP0I hhi
  · simp only [Qle, Qsub, add, neg]
    push_cast
    exact near_side_lo (j : Int) (r.den : Int) r.num ((2 : Int) ^ m) hP0I
      (by omega)

-- ===========================================================================
-- Definiteness at a rational point.
-- ===========================================================================

/-- **★ THE L² INNER PRODUCT IS DEFINITE AT A RATIONAL POINT**: `φ(ofQ r)² > 0 ⟹ ∫₀¹ φ² > 0` for a
    rational `r ∈ [0,1]`. The density strengthening of `innerI_self_pos_of_dyadic`: the enclosing
    dyadic piece `[j/2^m, (j+1)/2^m]` — whose index `j = ⌊r·2^m⌋` is computed in `ℕ` — has `r` within
    one width of its endpoint, so `sq_ge_on_piece_near` carries the positive value across it, and
    brick 73's piece-to-whole descent finishes. -/
theorem innerI_self_pos_of_ratpoint (φ : L2Test) (r : Q) (hr : 0 < r.den)
    (h0 : Qle (⟨0, 1⟩ : Q) r) (h1 : Qle r (⟨1, 1⟩ : Q))
    (hpos : Pos (Rmul (φ.f (ofQ r hr)) (φ.f (ofQ r hr)))) :
    Pos (innerI φ φ) := by
  obtain ⟨a, had, han, hale⟩ := Pos_imp_ofQ_le hpos
  have hhd : 0 < (mul a (⟨1, 2⟩ : Q)).den := Qmul_den_pos had (by decide)
  have hhn : 0 < (mul a (⟨1, 2⟩ : Q)).num := by show (0 : Int) < a.num * 1; omega
  obtain ⟨m, hm⟩ := exists_depth (mul (l2L φ φ) (⟨2, 1⟩ : Q)) (mul a (⟨1, 2⟩ : Q))
      (Qmul_den_pos (l2L_den φ φ) (by decide)) hhd hhn
  obtain ⟨j, hj, hnearQ⟩ := exists_dyadic_near r hr h0 h1 m
  refine riemannIntegral_pos_of_piece (l2L_den φ φ) (l2L_num φ φ) (l2lip φ φ) (l2fc φ φ)
    (fun x => sq_nonneg_pt φ x) m j hj (ofQ (mul a (⟨1, 2⟩ : Q)) hhd)
    (Pos_of_Rle_ofQ hhn hhd (Rle_refl _)) (fun x hx0 hx1 => ?_)
  refine sq_ge_on_piece_near φ (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) (dyadW (⟨1, 1⟩ : Q) m)
    (dyadA_den (by decide) (by decide) m j) (dyadW_den (by decide) m) (dyadW_num (by decide) m)
    (ofQ r hr) ?_ a had hale ?_ x hx0 hx1
  · -- the nearness hypothesis, reduced to the rational bound `hnearQ`
    refine Rle_trans (Rle_of_Req (Rabs_congr
      (ofQ_sub_loc (dyadA_den (by decide) (by decide) m j) hr))) ?_
    refine Rle_trans (Rle_of_Req (Rabs_ofQ _)) ?_
    exact Rle_ofQ_ofQ (Qabs_den_pos (Qsub_den_pos (dyadA_den (by decide) (by decide) m j) hr))
      (dyadW_den (by decide) m) hnearQ
  · -- the Lipschitz-drop budget: `l2L · 2 · (1/2^m) ≤ a/2`, from `exists_depth`
    refine Qle_trans (Qmul_den_pos (Qmul_den_pos (l2L_den φ φ) (by decide)) (two_pow_pos m))
      (Qeq_le ?_) hm
    simp only [Qeq, mul, dyadW]; push_cast; ring_uor

-- ===========================================================================
-- The Hilbert form is positive-definite.
-- ===========================================================================

/-- **★ THE RATIONAL HILBERT FORM IS POSITIVE-DEFINITE**: a coefficient vector with some nonzero entry
    (`∃ j < d, c j ≉ 0`) gives `qHil c c d > 0`. The nonzero polynomial is apart from `0` at a rational
    point `1/M` (`poly_nonzero_evalP`), where its value is a nonzero rational `v` so `v² > 0`; hence
    `φ(1/M)² > 0`, hence `∫₀¹ φ² > 0` by rational-point definiteness, hence `qHil c c d > 0` through the
    `⟨qPolyTest c, qPolyTest c⟩ = ofQ (qHil c c d)` bridge. -/
theorem qHil_self_pos (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d : Nat)
    (hnz : ∃ j, j < d ∧ ¬ Qeq (c j) (⟨0, 1⟩ : Q)) :
    Qlt (⟨0, 1⟩ : Q) (qHil c c d) := by
  obtain ⟨M, hM1, hMnz⟩ := poly_nonzero_evalP d c hc hnz
  have hr : 0 < (⟨1, M⟩ : Q).den := hM1
  have h0r : Qle (⟨0, 1⟩ : Q) (⟨1, M⟩ : Q) := q0M M hM1
  have h1r : Qle (⟨1, M⟩ : Q) (⟨1, 1⟩ : Q) := qM1 M hM1
  -- the value of the polynomial at `1/M` is a nonzero rational `v`
  have hvd : 0 < (qPolyEval c (⟨1, M⟩ : Q) d).den := qPolyEval_den c hc (⟨1, M⟩ : Q) hr d
  have hMnz' : ¬ Qeq (qPolyEval c (⟨1, M⟩ : Q) d) (⟨0, 1⟩ : Q) := fun h =>
    hMnz (Qeq_trans hvd (Qeq_symm (qPolyEval_eq_evalP (⟨1, M⟩ : Q) hr d c hc)) h)
  have hvn : (qPolyEval c (⟨1, M⟩ : Q) d).num ≠ 0 := num_ne_zero_of_Qne hMnz'
  have hmulpos : 0 < (mul (qPolyEval c (⟨1, M⟩ : Q) d) (qPolyEval c (⟨1, M⟩ : Q) d)).num :=
    Int_mul_self_pos hvn
  -- `Pos (φ(1/M)²)` via the rational value
  have heval : Req ((qPolyTest c hc d).f (ofQ (⟨1, M⟩ : Q) hr))
      (ofQ (qPolyEval c (⟨1, M⟩ : Q) d) hvd) := qPolyTest_eval_ofQ c hc d (⟨1, M⟩ : Q) hr h0r h1r
  have hsqeq : Req (Rmul ((qPolyTest c hc d).f (ofQ (⟨1, M⟩ : Q) hr))
        ((qPolyTest c hc d).f (ofQ (⟨1, M⟩ : Q) hr)))
      (ofQ (mul (qPolyEval c (⟨1, M⟩ : Q) d) (qPolyEval c (⟨1, M⟩ : Q) d)) (Qmul_den_pos hvd hvd)) :=
    Req_trans (Rmul_congr heval heval) (Rmul_ofQ_ofQ hvd hvd)
  have hposSq : Pos (Rmul ((qPolyTest c hc d).f (ofQ (⟨1, M⟩ : Q) hr))
      ((qPolyTest c hc d).f (ofQ (⟨1, M⟩ : Q) hr))) :=
    Pos_congr (Req_symm hsqeq) (Pos_of_Rle_ofQ hmulpos (Qmul_den_pos hvd hvd) (Rle_refl _))
  -- rational-point definiteness, then the bridge
  have hInner : Pos (innerI (qPolyTest c hc d) (qPolyTest c hc d)) :=
    innerI_self_pos_of_ratpoint (qPolyTest c hc d) (⟨1, M⟩ : Q) hr h0r h1r hposSq
  have hbridge : Req (innerI (qPolyTest c hc d) (qPolyTest c hc d))
      (ofQ (qHil c c d) (qHil_den_pos c c hc hc d)) :=
    innerI_qPolyTest_qPolyTest c c hc hc d
  exact Qlt_zero_of_Pos_ofQ (qHil_den_pos c c hc hc d) (Pos_congr hbridge hInner)

end Multiplicity.UOR.Bridge.F1Square.Square
