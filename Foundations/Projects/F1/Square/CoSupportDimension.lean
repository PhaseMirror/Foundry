/-
F1 square — **the pre-Hilbert layer, brick 55** (`CoSupportDimension.lean`): **THE CO-SUPPORT
LEVELS ARE NOT ONE-DIMENSIONAL** — the level `HatVanishes · 3` carries a family of at least
dimension two, so its inhabitation is not the accident of a single witness and its multiples.

`deep3`, `deep4`, `deep5` all lie in level `3` (`deep345_in_level_three`), and the moment
functionals at `3, 4, 5` separate them in a TRIANGULAR pattern, every entry read off brick 34's
Hilbert matrix with no new integration:

    ⟨deep3,x³⟩ = −1/2520   ⟨deep4,x³⟩ = 0          ⟨deep5,x³⟩ = 0
    ⟨deep3,x⁴⟩ = −1/1260   ⟨deep4,x⁴⟩ = 1/13860    ⟨deep5,x⁴⟩ = 0
    ⟨deep3,x⁵⟩ = −1/924    ⟨deep4,x⁵⟩ = 1/5544     ⟨deep5,x⁵⟩ = −1/72072

(`cosupport_triangular_table`). Lower-triangular with nonzero diagonal, so coefficients can be
read off one at a time: `deep34_independent` does the first two — the `x³` moment sees only
`deep3`, and then the `x⁴` moment only `deep4`.

The extraction step is the reusable half. `nat_eq_zero_of_ofQ_zero` turns a vanishing constructed
real `ofQ ⟨a, d⟩ ≈ 0` back into the arithmetic fact `a = 0`: the substrate has no `ofQ`
injectivity lemma, so the honest route is to exhibit the `Pos` witness a nonzero `a` would supply
and collide it with `not_Pos_zero`. Its companion `nat_eq_zero_of_ofQ_neg_zero` handles the
negative entries, which here are most of them.

HONEST SCOPE. Independence over NATURAL-number coefficients, and here only for the first TWO of
the three members. (The third step is NOT blocked: brick 67 closes it in
`CoSupportDimThree.lean`, at the default elaboration budget. The claim previously recorded here —
that the `x⁵` identity's denominators `924·5544·72072` overrun the elaborator — was simply
wrong, and is retracted; the identity is linear in the coefficients, so `ring_uor` normalises it
in one pass.) So this file is a two-dimensionality result plus the full table, not a dimension
formula, not a basis, and nothing about levels the layer has not constructed. Step 4 is RH. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DeepMemberFive
import Foundations.F1.Analysis.LambdaGap
import Foundations.F1.Square.CoSupportStrict

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 40000

/-- **A vanishing constructed rational is arithmetically zero**: if `ofQ ⟨a, d⟩ ≈ 0` for a
    natural numerator `a`, then `a = 0`. (The substrate has no `ofQ` injectivity lemma; a nonzero
    `a` supplies a `Pos` witness that collides with `not_Pos_zero`.) -/
theorem nat_eq_zero_of_ofQ_zero {a d : Nat} (hd : 0 < d)
    (h : Req (ofQ (⟨(a : Int), d⟩ : Q) hd) zero) : a = 0 := by
  cases a with
  | zero => rfl
  | succ k =>
    refine absurd (Pos_congr h ⟨d, ?_⟩) not_Pos_zero
    show (1 : Int) * ((d : Nat) : Int) < ((k + 1 : Nat) : Int) * ((d + 1 : Nat) : Int)
    have hd' : (1 : Int) ≤ ((d : Nat) : Int) := by exact_mod_cast hd
    have hk : (1 : Int) ≤ ((k + 1 : Nat) : Int) := by push_cast; omega
    have hstep : (1 : Int) * ((d : Nat) : Int) ≤ ((k + 1 : Nat) : Int) * ((d : Nat) : Int) :=
      Int.mul_le_mul_of_nonneg_right hk (by omega)
    have he : ((k + 1 : Nat) : Int) * ((d + 1 : Nat) : Int)
        = ((k + 1 : Nat) : Int) * ((d : Nat) : Int) + ((k + 1 : Nat) : Int) := by
      push_cast; ring_uor
    omega

/-- The negated companion: `ofQ ⟨−a, d⟩ ≈ 0` also forces `a = 0`. -/
theorem nat_eq_zero_of_ofQ_neg_zero {a d : Nat} (hd : 0 < d)
    (h : Req (ofQ (⟨-(a : Int), d⟩ : Q) hd) zero) : a = 0 := by
  refine nat_eq_zero_of_ofQ_zero (a := a) (d := d) hd ?_
  refine Req_trans ?_ (Req_trans (Rneg_congr h) Rneg_zero)
  refine Req_trans ?_ (Req_symm (Rneg_ofQ (⟨-(a : Int), d⟩ : Q) hd))
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (⟨((a : Nat) : Int), d⟩ : Q) (neg (⟨-(a : Int), d⟩ : Q))
    simp only [Qeq, neg]
    ring_uor)

-- ===========================================================================
-- The two remaining table entries.
-- ===========================================================================

set_option maxHeartbeats 2000000 in
/-- `⟨deep3, x⁴⟩ = 319/60 − 335/63 = −1/1260`. -/
theorem deep3_moment_four :
    Req (innerI deep3 (powTest 4)) (ofQ (⟨-1, 1260⟩ : Q) (by decide)) := by
  have e1 := innerI_powTest_hilbert 1 4
  have e2 := innerI_powTest_hilbert 2 4
  have e3 := innerI_powTest_hilbert 3 4
  have e4 := innerI_powTest_hilbert 4 4
  have e5 := innerI_powTest_hilbert 5 4
  have h30 := pv_scale 30 (v := (⟨30, 8⟩ : Q)) (Nat.succ_pos 7) (by decide) e3 (by decide)
  have h14 := pv_scale 14 (v := (⟨14, 10⟩ : Q)) (Nat.succ_pos 9) (by decide) e5 (by decide)
  have h10 := pv_scale 10 (v := (⟨10, 7⟩ : Q)) (Nat.succ_pos 6) (by decide) e2 (by decide)
  have h35 := pv_scale 35 (v := (⟨35, 9⟩ : Q)) (Nat.succ_pos 8) (by decide) e4 (by decide)
  have hA := pv_add (v := (⟨47, 12⟩ : Q)) (Nat.succ_pos 5) (by decide) (by decide)
    e1 h30 (by decide)
  have hP := pv_add (v := (⟨319, 60⟩ : Q)) (by decide) (by decide) (by decide)
    hA h14 (by decide)
  have hN := pv_add (v := (⟨335, 63⟩ : Q)) (by decide) (by decide) (by decide)
    h10 h35 (by decide)
  refine Req_trans (innerI_sub_left deep3P deep3N (powTest 4)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

set_option maxHeartbeats 4000000 in
/-- `⟨deep4, x⁵⟩ = 13427/693 − 155/8 = 1/5544`. -/
theorem deep4_moment_five :
    Req (innerI deep4 (powTest 5)) (ofQ (⟨1, 5544⟩ : Q) (by decide)) := by
  have e1 := innerI_powTest_hilbert 1 5
  have e2 := innerI_powTest_hilbert 2 5
  have e3 := innerI_powTest_hilbert 3 5
  have e4 := innerI_powTest_hilbert 4 5
  have e5 := innerI_powTest_hilbert 5 5
  have e6 := innerI_powTest_hilbert 6 5
  have h70 := pv_scale 70 (v := (⟨70, 9⟩ : Q)) (Nat.succ_pos 8) (by decide) e3 (by decide)
  have h126 := pv_scale 126 (v := (⟨126, 11⟩ : Q)) (Nat.succ_pos 10) (by decide) e5 (by decide)
  have h15 := pv_scale 15 (v := (⟨15, 8⟩ : Q)) (Nat.succ_pos 7) (by decide) e2 (by decide)
  have h140 := pv_scale 140 (v := (⟨140, 10⟩ : Q)) (Nat.succ_pos 9) (by decide) e4 (by decide)
  have h42 := pv_scale 42 (v := (⟨42, 12⟩ : Q)) (Nat.succ_pos 11) (by decide) e6 (by decide)
  have hA := pv_add (v := (⟨499, 63⟩ : Q)) (Nat.succ_pos 6) (by decide) (by decide)
    e1 h70 (by decide)
  have hP := pv_add (v := (⟨13427, 693⟩ : Q)) (by decide) (by decide) (by decide)
    hA h126 (by decide)
  have hB := pv_add (v := (⟨127, 8⟩ : Q)) (by decide) (by decide) (by decide)
    h15 h140 (by decide)
  have hN := pv_add (v := (⟨155, 8⟩ : Q)) (by decide) (by decide) (by decide)
    hB h42 (by decide)
  refine Req_trans (innerI_sub_left deep4P deep4N (powTest 5)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

set_option maxHeartbeats 2000000 in
/-- `⟨deep3, x⁵⟩ = 1097/231 − 19/4 = −1/924`. -/
theorem deep3_moment_five :
    Req (innerI deep3 (powTest 5)) (ofQ (⟨-1, 924⟩ : Q) (by decide)) := by
  have e1 := innerI_powTest_hilbert 1 5
  have e2 := innerI_powTest_hilbert 2 5
  have e3 := innerI_powTest_hilbert 3 5
  have e4 := innerI_powTest_hilbert 4 5
  have e5 := innerI_powTest_hilbert 5 5
  have h30 := pv_scale 30 (v := (⟨30, 9⟩ : Q)) (Nat.succ_pos 8) (by decide) e3 (by decide)
  have h14 := pv_scale 14 (v := (⟨14, 11⟩ : Q)) (Nat.succ_pos 10) (by decide) e5 (by decide)
  have h10 := pv_scale 10 (v := (⟨10, 8⟩ : Q)) (Nat.succ_pos 7) (by decide) e2 (by decide)
  have h35 := pv_scale 35 (v := (⟨35, 10⟩ : Q)) (Nat.succ_pos 9) (by decide) e4 (by decide)
  have hA := pv_add (v := (⟨73, 21⟩ : Q)) (Nat.succ_pos 6) (by decide) (by decide)
    e1 h30 (by decide)
  have hP := pv_add (v := (⟨1097, 231⟩ : Q)) (by decide) (by decide) (by decide)
    hA h14 (by decide)
  have hN := pv_add (v := (⟨19, 4⟩ : Q)) (by decide) (by decide) (by decide)
    h10 h35 (by decide)
  refine Req_trans (innerI_sub_left deep3P deep3N (powTest 5)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

-- ===========================================================================
-- The triangular table.
-- ===========================================================================

/-- `zero` as a rational constant. -/
private theorem zero_as_ofQ : Req zero (ofQ (⟨0, 1⟩ : Q) (by decide)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- **THE TRIANGULAR TABLE**: the moment functionals at `3, 4, 5` separate the three members,
    lower-triangular with nonzero diagonal. -/
theorem cosupport_triangular_table :
    Req (innerI deep3 (powTest 3)) (ofQ (⟨-1, 2520⟩ : Q) (by decide))
    ∧ Req (innerI deep4 (powTest 3)) zero
    ∧ Req (innerI deep5 (powTest 3)) zero
    ∧ Req (innerI deep3 (powTest 4)) (ofQ (⟨-1, 1260⟩ : Q) (by decide))
    ∧ Req (innerI deep4 (powTest 4)) (ofQ (⟨1, 13860⟩ : Q) (by decide))
    ∧ Req (innerI deep5 (powTest 4)) zero
    ∧ Req (innerI deep3 (powTest 5)) (ofQ (⟨-1, 924⟩ : Q) (by decide))
    ∧ Req (innerI deep4 (powTest 5)) (ofQ (⟨1, 5544⟩ : Q) (by decide))
    ∧ Req (innerI deep5 (powTest 5)) (ofQ (⟨-1, 72072⟩ : Q) (by decide)) :=
  ⟨deep3_moment_three, deep4_moment_three, deep5_moment_three, deep3_moment_four,
   deep4_moment_four, deep5_moment_four, deep3_moment_five, deep4_moment_five,
   deep5_moment_five⟩

/-- All three members lie in level `3`. -/
theorem deep345_in_level_three :
    HatVanishes deep3 3 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep3 deep3_supp)
    ∧ HatVanishes deep4 3 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep4 deep4_supp)
    ∧ HatVanishes deep5 3 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep5 deep5_supp) :=
  ⟨deep3_hatVanishes, hatVanishes_mono (by decide) deep4_hatVanishes,
   hatVanishes_mono (by decide) deep5_hatVanishes⟩

-- ===========================================================================
-- Independence.
-- ===========================================================================

/-- The combination `a·deep3 + b·deep4 + c·deep5`. -/
def combo345 (a b c : Nat) : L2Test :=
  L2Test.add (L2Test.add (natScale a deep3) (natScale b deep4)) (natScale c deep5)

/-- The `n`-th moment of the combination, from the three component values. -/
theorem combo345_moment (a b c : Nat) (n : Nat) {q3 q4 q5 w : Q}
    (h3d : 0 < q3.den) (h4d : 0 < q4.den) (h5d : 0 < q5.den) (hwd : 0 < w.den)
    (e3 : Req (innerI deep3 (powTest n)) (ofQ q3 h3d))
    (e4 : Req (innerI deep4 (powTest n)) (ofQ q4 h4d))
    (e5 : Req (innerI deep5 (powTest n)) (ofQ q5 h5d))
    (hq : Qeq (add (add (mul (⟨(a : Int), 1⟩ : Q) q3) (mul (⟨(b : Int), 1⟩ : Q) q4))
      (mul (⟨(c : Int), 1⟩ : Q) q5)) w) :
    Req (innerI (combo345 a b c) (powTest n)) (ofQ w hwd) := by
  have ha := pv_scale a (v := mul (⟨(a : Int), 1⟩ : Q) q3) h3d
    (Qmul_den_pos Nat.one_pos h3d) e3 (Qeq_refl _)
  have hb := pv_scale b (v := mul (⟨(b : Int), 1⟩ : Q) q4) h4d
    (Qmul_den_pos Nat.one_pos h4d) e4 (Qeq_refl _)
  have hc := pv_scale c (v := mul (⟨(c : Int), 1⟩ : Q) q5) h5d
    (Qmul_den_pos Nat.one_pos h5d) e5 (Qeq_refl _)
  have hab := pv_add (v := add (mul (⟨(a : Int), 1⟩ : Q) q3) (mul (⟨(b : Int), 1⟩ : Q) q4))
    (Qmul_den_pos Nat.one_pos h3d) (Qmul_den_pos Nat.one_pos h4d)
    (add_den_pos (Qmul_den_pos Nat.one_pos h3d) (Qmul_den_pos Nat.one_pos h4d))
    ha hb (Qeq_refl _)
  exact pv_add (v := w)
    (add_den_pos (Qmul_den_pos Nat.one_pos h3d) (Qmul_den_pos Nat.one_pos h4d))
    (Qmul_den_pos Nat.one_pos h5d) hwd hab hc hq

set_option maxHeartbeats 2000000 in
/-- The `x³` moment of the combination sees only `deep3`: its value is `−a/2520`. -/
theorem combo345_moment_three (a b c : Nat) :
    Req (innerI (combo345 a b c) (powTest 3))
      (ofQ (⟨-(a : Int), 2520⟩ : Q) (by show (0:Nat) < 2520; decide)) :=
  combo345_moment (q3 := (⟨-1, 2520⟩ : Q)) (q4 := (⟨0, 1⟩ : Q)) (q5 := (⟨0, 1⟩ : Q))
    (w := (⟨-(a : Int), 2520⟩ : Q)) a b c 3 (by decide) (by decide) (by decide)
    (by show (0:Nat) < 2520; decide)
    deep3_moment_three (Req_trans deep4_moment_three zero_as_ofQ)
    (Req_trans deep5_moment_three zero_as_ofQ)
    (by simp only [Qeq, add, mul]; push_cast; ring_uor)

set_option maxHeartbeats 2000000 in
/-- With the first coefficient gone, the `x⁴` moment sees only `deep4`: its value is `b/13860`. -/
theorem combo345_moment_four (b c : Nat) :
    Req (innerI (combo345 0 b c) (powTest 4))
      (ofQ (⟨(b : Int), 13860⟩ : Q) (by show (0:Nat) < 13860; decide)) :=
  combo345_moment (q3 := (⟨-1, 1260⟩ : Q)) (q4 := (⟨1, 13860⟩ : Q)) (q5 := (⟨0, 1⟩ : Q))
    (w := (⟨(b : Int), 13860⟩ : Q)) 0 b c 4 (by decide) (by decide) (by decide)
    (by show (0:Nat) < 13860; decide)
    deep3_moment_four deep4_moment_four (Req_trans deep5_moment_four zero_as_ofQ)
    (by simp only [Qeq, add, mul]; push_cast; ring_uor)

/-- **THE FIRST TWO MEMBERS ARE INDEPENDENT**: if `a·deep3 + b·deep4 + c·deep5` has vanishing
    moments at `3` and `4`, then `a = b = 0`. The triangular table reads the coefficients off one
    at a time — the `x³` moment sees only `deep3`, and then the `x⁴` moment only `deep4`. So the
    level-`3` family is at least TWO-dimensional. The third coefficient is taken in brick 67
    (`deep345_independent`); the note that once stood here, claiming the `x⁵` step's denominators
    overrun the elaborator, was wrong and is retracted. -/
theorem deep34_independent (a b c : Nat)
    (h3 : Req (innerI (combo345 a b c) (powTest 3)) zero)
    (h4 : Req (innerI (combo345 0 b c) (powTest 4)) zero) :
    a = 0 ∧ b = 0 := by
  have ha : a = 0 :=
    nat_eq_zero_of_ofQ_neg_zero (by show (0:Nat) < 2520; decide)
      (Req_trans (Req_symm (combo345_moment_three a b c)) h3)
  refine ⟨ha, ?_⟩
  exact nat_eq_zero_of_ofQ_zero (by show (0:Nat) < 13860; decide)
    (Req_trans (Req_symm (combo345_moment_four b c)) h4)

end Multiplicity.UOR.Bridge.F1Square.Square
