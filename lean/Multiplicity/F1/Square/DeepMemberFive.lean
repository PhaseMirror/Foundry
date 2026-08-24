/-
F1 square — **the pre-Hilbert layer, brick 54** (`DeepMemberFive.lean`): **THE `K = 5`
CO-SUPPORT MEMBER**, extending the strict chain to `HatVanishes · 5 ⊋ HatVanishes · 6`.

Over brick 34's Gram closed form `⟨xⁱ, xʲ⟩ = 1/(i+j+1)` a depth-`K` member is a finite rational
linear system — `Σᵢ aᵢ/(i+n+1) = 0` for `n < K` together with the support condition `Σᵢ aᵢ = 0`.
At `K = 5`, over `i = 1..7`, the solution is `a = (1, −21, 140, −420, 630, −462, 132)`:

    `deep5 = x − 21x² + 140x³ − 420x⁴ + 630x⁵ − 462x⁶ + 132x⁷`.

Its first non-vanishing moment is read off the same Gram matrix — no new integration —

    `⟨deep5, x⁵⟩ = 748873/9009 − 665/8 = −1/72072 ≠ 0`,

so `deep5 ∈ HatVanishes · 5` and `deep5 ∉ HatVanishes · 6` (`cosupport_strict_at_five`), and with
bricks 37 and 41 the chain reads `0 ⊋ 1 ⊋ 2 ⊋ 3 ⊋ 4 ⊋ 5 ⊋ 6` (`cosupport_chain_strict_six`).
The member is apart from zero — `deep5(1/10) = −3843/625000`, so the APARTNESS witness is on the
negation, unlike every earlier member — and the capstone fires the skeleton's unconditional
positivity on it.

HONEST SCOPE. One more member, one more strict level. NOT a proof that every level is inhabited
or strict (that needs invertibility of the Hilbert sections in general), and the positivity is
still the skeleton's diagonal multiplier form on moment data — not the Weil functional on the
test space, and not positivity beyond the complement. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DeepMemberFour

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 40000

/-- The positive part `x + 140x³ + 630x⁵ + 132x⁷`. -/
def deep5P : L2Test :=
  L2Test.add (L2Test.add (L2Test.add (powTest 1) (natScale 140 (powTest 3)))
    (natScale 630 (powTest 5))) (natScale 132 (powTest 7))

/-- The negative part `21x² + 420x⁴ + 462x⁶`. -/
def deep5N : L2Test :=
  L2Test.add (L2Test.add (natScale 21 (powTest 2)) (natScale 420 (powTest 4)))
    (natScale 462 (powTest 6))

/-- **THE `K = 5` MEMBER**: `x − 21x² + 140x³ − 420x⁴ + 630x⁵ − 462x⁶ + 132x⁷`, built as
    `P − N` (keeping a `L2Test.neg` off the head of the tree, where it would send `innerI`
    unification into a whnf blowup). -/
def deep5 : L2Test := L2Test.sub deep5P deep5N

/-- **The member is `[0,1]`-supported**: the coefficients sum to `903 − 903 = 0`. -/
theorem deep5_supp : UnitSupported deep5 := by
  intro m x h0 h1
  have hp : ∀ i, Req ((powTest i).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    fun i => powTest_window_one m h0 i
  have h140 := fv_scale 140 (a := (⟨1, 1⟩ : Q)) (v := (⟨140, 1⟩ : Q)) (by decide) (by decide)
    (hp 3) (by decide)
  have h630 := fv_scale 630 (a := (⟨1, 1⟩ : Q)) (v := (⟨630, 1⟩ : Q)) (by decide) (by decide)
    (hp 5) (by decide)
  have h132 := fv_scale 132 (a := (⟨1, 1⟩ : Q)) (v := (⟨132, 1⟩ : Q)) (by decide) (by decide)
    (hp 7) (by decide)
  have h21 := fv_scale 21 (a := (⟨1, 1⟩ : Q)) (v := (⟨21, 1⟩ : Q)) (by decide) (by decide)
    (hp 2) (by decide)
  have h420 := fv_scale 420 (a := (⟨1, 1⟩ : Q)) (v := (⟨420, 1⟩ : Q)) (by decide) (by decide)
    (hp 4) (by decide)
  have h462 := fv_scale 462 (a := (⟨1, 1⟩ : Q)) (v := (⟨462, 1⟩ : Q)) (by decide) (by decide)
    (hp 6) (by decide)
  have hA := fv_add (v := (⟨141, 1⟩ : Q)) (by decide) (by decide) (by decide) (hp 1) h140 (by decide)
  have hA2 := fv_add (v := (⟨771, 1⟩ : Q)) (by decide) (by decide) (by decide) hA h630 (by decide)
  have hP := fv_add (v := (⟨903, 1⟩ : Q)) (by decide) (by decide) (by decide) hA2 h132 (by decide)
  have hB := fv_add (v := (⟨441, 1⟩ : Q)) (by decide) (by decide) (by decide) h21 h420 (by decide)
  have hN := fv_add (v := (⟨903, 1⟩ : Q)) (by decide) (by decide) (by decide) hB h462 (by decide)
  show Req (Rsub (deep5P.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))
    (deep5N.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) zero
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

-- ===========================================================================
-- The five vanishing moments.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- The member's `n`-th moment as one rational identity over the Hilbert entries: both parts hit
    the common value `w`, so the difference vanishes. -/
private theorem deep5_moment_gen (n : Nat) {q1 q2 q3 q4 q5 q6 q7 w : Q}
    (h1d : 0 < q1.den) (h2d : 0 < q2.den) (h3d : 0 < q3.den) (h4d : 0 < q4.den)
    (h5d : 0 < q5.den) (h6d : 0 < q6.den) (h7d : 0 < q7.den) (hwd : 0 < w.den)
    (e1 : Req (innerI (powTest 1) (powTest n)) (ofQ q1 h1d))
    (e2 : Req (innerI (powTest 2) (powTest n)) (ofQ q2 h2d))
    (e3 : Req (innerI (powTest 3) (powTest n)) (ofQ q3 h3d))
    (e4 : Req (innerI (powTest 4) (powTest n)) (ofQ q4 h4d))
    (e5 : Req (innerI (powTest 5) (powTest n)) (ofQ q5 h5d))
    (e6 : Req (innerI (powTest 6) (powTest n)) (ofQ q6 h6d))
    (e7 : Req (innerI (powTest 7) (powTest n)) (ofQ q7 h7d))
    (hqP : Qeq (add (add (add q1 (mul (⟨140, 1⟩ : Q) q3)) (mul (⟨630, 1⟩ : Q) q5))
      (mul (⟨132, 1⟩ : Q) q7)) w)
    (hqN : Qeq (add (add (mul (⟨21, 1⟩ : Q) q2) (mul (⟨420, 1⟩ : Q) q4))
      (mul (⟨462, 1⟩ : Q) q6)) w) :
    Req (innerI deep5 (powTest n)) zero := by
  have h140 := pv_scale 140 (v := mul (⟨140, 1⟩ : Q) q3) h3d
    (Qmul_den_pos (by decide) h3d) e3 (Qeq_refl _)
  have h630 := pv_scale 630 (v := mul (⟨630, 1⟩ : Q) q5) h5d
    (Qmul_den_pos (by decide) h5d) e5 (Qeq_refl _)
  have h132 := pv_scale 132 (v := mul (⟨132, 1⟩ : Q) q7) h7d
    (Qmul_den_pos (by decide) h7d) e7 (Qeq_refl _)
  have h21 := pv_scale 21 (v := mul (⟨21, 1⟩ : Q) q2) h2d
    (Qmul_den_pos (by decide) h2d) e2 (Qeq_refl _)
  have h420 := pv_scale 420 (v := mul (⟨420, 1⟩ : Q) q4) h4d
    (Qmul_den_pos (by decide) h4d) e4 (Qeq_refl _)
  have h462 := pv_scale 462 (v := mul (⟨462, 1⟩ : Q) q6) h6d
    (Qmul_den_pos (by decide) h6d) e6 (Qeq_refl _)
  have hA := pv_add (v := add q1 (mul (⟨140, 1⟩ : Q) q3)) h1d
    (Qmul_den_pos (by decide) h3d) (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
    e1 h140 (Qeq_refl _)
  have hA2 := pv_add (v := add (add q1 (mul (⟨140, 1⟩ : Q) q3)) (mul (⟨630, 1⟩ : Q) q5))
    (add_den_pos h1d (Qmul_den_pos (by decide) h3d)) (Qmul_den_pos (by decide) h5d)
    (add_den_pos (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
      (Qmul_den_pos (by decide) h5d)) hA h630 (Qeq_refl _)
  have hP := pv_add (v := w)
    (add_den_pos (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
      (Qmul_den_pos (by decide) h5d))
    (Qmul_den_pos (by decide) h7d) hwd hA2 h132 hqP
  have hB := pv_add (v := add (mul (⟨21, 1⟩ : Q) q2) (mul (⟨420, 1⟩ : Q) q4))
    (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d)
    (add_den_pos (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d))
    h21 h420 (Qeq_refl _)
  have hN := pv_add (v := w)
    (add_den_pos (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d))
    (Qmul_den_pos (by decide) h6d) hwd hB h462 hqN
  exact Req_trans (innerI_sub_left deep5P deep5N (powTest n))
    (Req_trans (Rsub_congr hP hN) (Radd_neg _))

/-- `∫₀¹ p = (1/2 + 140/4 + 630/6 + 132/8) − (21/3 + 420/5 + 462/7) = 157 − 157 = 0`. -/
theorem deep5_moment_zero : Req (innerI deep5 (powTest 0)) zero :=
  deep5_moment_gen 0 (w := (⟨157, 1⟩ : Q)) (Nat.succ_pos 1) (Nat.succ_pos 2) (Nat.succ_pos 3)
    (Nat.succ_pos 4) (Nat.succ_pos 5) (Nat.succ_pos 6) (Nat.succ_pos 7) (by decide)
    (innerI_powTest_hilbert 1 0) (innerI_powTest_hilbert 2 0) (innerI_powTest_hilbert 3 0)
    (innerI_powTest_hilbert 4 0) (innerI_powTest_hilbert 5 0) (innerI_powTest_hilbert 6 0)
    (innerI_powTest_hilbert 7 0) (by decide) (by decide)

/-- `∫₀¹ x·p = 133 − 133 = 0`. -/
theorem deep5_moment_one : Req (innerI deep5 (powTest 1)) zero :=
  deep5_moment_gen 1 (w := (⟨133, 1⟩ : Q)) (Nat.succ_pos 2) (Nat.succ_pos 3) (Nat.succ_pos 4)
    (Nat.succ_pos 5) (Nat.succ_pos 6) (Nat.succ_pos 7) (Nat.succ_pos 8) (by decide)
    (innerI_powTest_hilbert 1 1) (innerI_powTest_hilbert 2 1) (innerI_powTest_hilbert 3 1)
    (innerI_powTest_hilbert 4 1) (innerI_powTest_hilbert 5 1) (innerI_powTest_hilbert 6 1)
    (innerI_powTest_hilbert 7 1) (by decide) (by decide)

/-- `∫₀¹ x²·p = 1733/15 − 1733/15 = 0`. -/
theorem deep5_moment_two : Req (innerI deep5 (powTest 2)) zero :=
  deep5_moment_gen 2 (w := (⟨1733, 15⟩ : Q)) (Nat.succ_pos 3) (Nat.succ_pos 4) (Nat.succ_pos 5)
    (Nat.succ_pos 6) (Nat.succ_pos 7) (Nat.succ_pos 8) (Nat.succ_pos 9) (by decide)
    (innerI_powTest_hilbert 1 2) (innerI_powTest_hilbert 2 2) (innerI_powTest_hilbert 3 2)
    (innerI_powTest_hilbert 4 2) (innerI_powTest_hilbert 5 2) (innerI_powTest_hilbert 6 2)
    (innerI_powTest_hilbert 7 2) (by decide) (by decide)

/-- `∫₀¹ x³·p = 511/5 − 511/5 = 0`. -/
theorem deep5_moment_three : Req (innerI deep5 (powTest 3)) zero :=
  deep5_moment_gen 3 (w := (⟨511, 5⟩ : Q)) (Nat.succ_pos 4) (Nat.succ_pos 5) (Nat.succ_pos 6)
    (Nat.succ_pos 7) (Nat.succ_pos 8) (Nat.succ_pos 9) (Nat.succ_pos 10) (by decide)
    (innerI_powTest_hilbert 1 3) (innerI_powTest_hilbert 2 3) (innerI_powTest_hilbert 3 3)
    (innerI_powTest_hilbert 4 3) (innerI_powTest_hilbert 5 3) (innerI_powTest_hilbert 6 3)
    (innerI_powTest_hilbert 7 3) (by decide) (by decide)

/-- `∫₀¹ x⁴·p = 275/3 − 275/3 = 0`. -/
theorem deep5_moment_four : Req (innerI deep5 (powTest 4)) zero :=
  deep5_moment_gen 4 (w := (⟨275, 3⟩ : Q)) (Nat.succ_pos 5) (Nat.succ_pos 6) (Nat.succ_pos 7)
    (Nat.succ_pos 8) (Nat.succ_pos 9) (Nat.succ_pos 10) (Nat.succ_pos 11) (by decide)
    (innerI_powTest_hilbert 1 4) (innerI_powTest_hilbert 2 4) (innerI_powTest_hilbert 3 4)
    (innerI_powTest_hilbert 4 4) (innerI_powTest_hilbert 5 4) (innerI_powTest_hilbert 6 4)
    (innerI_powTest_hilbert 7 4) (by decide) (by decide)

/-- **THE `K = 5` CO-SUPPORT MEMBER**: the transform vanishes at `0,1,2,3,4`. -/
theorem deep5_hatVanishes :
    HatVanishes deep5 5 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep5 deep5_supp) :=
  hatVanishes_of_moments deep5 5 deep5_supp (fun n hn => by
    match n with
    | 0 => exact deep5_moment_zero
    | 1 => exact deep5_moment_one
    | 2 => exact deep5_moment_two
    | 3 => exact deep5_moment_three
    | 4 => exact deep5_moment_four
    | (k + 5) => exact absurd hn (by omega))

-- ===========================================================================
-- The first non-vanishing moment, and strictness at level 5.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- **The member's FIFTH moment is nonzero**: `748873/9009 − 665/8 = −1/72072`. -/
theorem deep5_moment_five :
    Req (innerI deep5 (powTest 5)) (ofQ (⟨-1, 72072⟩ : Q) (by decide)) := by
  have e1 := innerI_powTest_hilbert 1 5
  have e2 := innerI_powTest_hilbert 2 5
  have e3 := innerI_powTest_hilbert 3 5
  have e4 := innerI_powTest_hilbert 4 5
  have e5 := innerI_powTest_hilbert 5 5
  have e6 := innerI_powTest_hilbert 6 5
  have e7 := innerI_powTest_hilbert 7 5
  have h140 := pv_scale 140 (v := (⟨140, 9⟩ : Q)) (Nat.succ_pos 8) (by decide) e3 (by decide)
  have h630 := pv_scale 630 (v := (⟨630, 11⟩ : Q)) (Nat.succ_pos 10) (by decide) e5 (by decide)
  have h132 := pv_scale 132 (v := (⟨132, 13⟩ : Q)) (Nat.succ_pos 12) (by decide) e7 (by decide)
  have h21 := pv_scale 21 (v := (⟨21, 8⟩ : Q)) (Nat.succ_pos 7) (by decide) e2 (by decide)
  have h420 := pv_scale 420 (v := (⟨420, 10⟩ : Q)) (Nat.succ_pos 9) (by decide) e4 (by decide)
  have h462 := pv_scale 462 (v := (⟨462, 12⟩ : Q)) (Nat.succ_pos 11) (by decide) e6 (by decide)
  have hA := pv_add (v := (⟨989, 63⟩ : Q)) (Nat.succ_pos 6) (by decide) (by decide)
    e1 h140 (by decide)
  have hA2 := pv_add (v := (⟨50569, 693⟩ : Q)) (by decide) (by decide) (by decide)
    hA h630 (by decide)
  have hP := pv_add (v := (⟨748873, 9009⟩ : Q)) (by decide) (by decide) (by decide)
    hA2 h132 (by decide)
  have hB := pv_add (v := (⟨357, 8⟩ : Q)) (by decide) (by decide) (by decide)
    h21 h420 (by decide)
  have hN := pv_add (v := (⟨665, 8⟩ : Q)) (by decide) (by decide) (by decide)
    hB h462 (by decide)
  refine Req_trans (innerI_sub_left deep5P deep5N (powTest 5)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

/-- **The `K = 5` member is NOT in level 6**. -/
theorem deep5_not_hatVanishes_six :
    ¬ HatVanishes deep5 6 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep5 deep5_supp) := by
  intro h
  have hz : Req (innerI deep5 (powTest 5)) zero :=
    Req_trans (Req_symm (mellinHat_compact deep5 5 deep5_supp)) (h 5 (by decide))
  have hv : Req (ofQ (⟨-1, 72072⟩ : Q) (by decide)) zero :=
    Req_trans (Req_symm deep5_moment_five) hz
  have hpos : Pos (Rneg (ofQ (⟨-1, 72072⟩ : Q) (by decide))) := ⟨144144, by decide⟩
  obtain ⟨n, hn⟩ := Pos_congr (Rneg_congr hv) hpos
  have hlt : (1 : Int) * ((1 : Nat) : Int) < (-0 : Int) * ((n + 1 : Nat) : Int) := hn
  push_cast at hlt
  omega

/-- **STRICTNESS AT LEVEL 5**. -/
theorem cosupport_strict_at_five :
    HatVanishes deep5 5 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep5 deep5_supp)
    ∧ ¬ HatVanishes deep5 6 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep5 deep5_supp) :=
  ⟨deep5_hatVanishes, deep5_not_hatVanishes_six⟩

/-- **THE STRICT CHAIN THROUGH DEPTH 6**: every level from `0` to `6` properly contains the
    next, each witnessed by an explicit constructed test. (Strictness at the REALIZED levels;
    not a proof that every level is strict.) -/
theorem cosupport_chain_strict_six :
    (¬ HatVanishes bumpU 1 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp bumpU bumpU_supp))
    ∧ (¬ HatVanishes lin1 2 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp lin1 lin1_supp))
    ∧ (¬ HatVanishes lin2 3 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp lin2 lin2_supp))
    ∧ (¬ HatVanishes deep3 4 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep3 deep3_supp))
    ∧ (¬ HatVanishes deep4 5 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep4 deep4_supp))
    ∧ (¬ HatVanishes deep5 6 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep5 deep5_supp)) :=
  ⟨bumpU_not_hatVanishes, lin1_not_hatVanishes_two, lin2_not_hatVanishes_three,
   deep3_not_hatVanishes_four, deep4_not_hatVanishes_five, deep5_not_hatVanishes_six⟩

-- ===========================================================================
-- Apartness and the capstone.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- **The member is not the zero function**: `deep5(1/10) = −3843/625000`. Note the sign: this
    is the first constructed member whose sample value is NEGATIVE, so apartness is witnessed on
    the negation. -/
theorem deep5_value_tenth :
    Req (deep5.f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨-3843, 625000⟩ : Q) (by decide)) := by
  have hc : Req (clamp01 (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨1, 10⟩ : Q) (by decide)) :=
    clamp01_ofQ (by decide) (by decide) (by decide)
  have p0 : Req ((powTest 0).f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨1, 1⟩ : Q) (by decide)) := Req_refl one
  have step : ∀ {i : Nat} {u : Q} (hud : 0 < u.den) {w : Q} (hwd : 0 < w.den),
      Req ((powTest i).f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ u hud) →
      Qeq (mul u (⟨1, 10⟩ : Q)) w →
      Req ((powTest (i + 1)).f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ w hwd) := by
    intro i u hud w hwd hu hq
    refine Req_trans (Rmul_congr hu hc) ?_
    exact Req_trans (Rmul_ofQ_ofQ hud (by decide)) (Req_of_seq_Qeq (fun _ => hq))
  have p1 := step (i := 0) (by decide) (w := (⟨1, 10⟩ : Q)) (by decide) p0 (by decide)
  have p2 := step (i := 1) (by decide) (w := (⟨1, 100⟩ : Q)) (by decide) p1 (by decide)
  have p3 := step (i := 2) (by decide) (w := (⟨1, 1000⟩ : Q)) (by decide) p2 (by decide)
  have p4 := step (i := 3) (by decide) (w := (⟨1, 10000⟩ : Q)) (by decide) p3 (by decide)
  have p5 := step (i := 4) (by decide) (w := (⟨1, 100000⟩ : Q)) (by decide) p4 (by decide)
  have p6 := step (i := 5) (by decide) (w := (⟨1, 1000000⟩ : Q)) (by decide) p5 (by decide)
  have p7 := step (i := 6) (by decide) (w := (⟨1, 10000000⟩ : Q)) (by decide) p6 (by decide)
  have h140 := fv_scale 140 (v := (⟨140, 1000⟩ : Q)) (by decide) (by decide) p3 (by decide)
  have h630 := fv_scale 630 (v := (⟨630, 100000⟩ : Q)) (by decide) (by decide) p5 (by decide)
  have h132 := fv_scale 132 (v := (⟨132, 10000000⟩ : Q)) (by decide) (by decide) p7 (by decide)
  have h21 := fv_scale 21 (v := (⟨21, 100⟩ : Q)) (by decide) (by decide) p2 (by decide)
  have h420 := fv_scale 420 (v := (⟨420, 10000⟩ : Q)) (by decide) (by decide) p4 (by decide)
  have h462 := fv_scale 462 (v := (⟨462, 1000000⟩ : Q)) (by decide) (by decide) p6 (by decide)
  have hA := fv_add (v := (⟨6, 25⟩ : Q)) (by decide) (by decide) (by decide) p1 h140 (by decide)
  have hA2 := fv_add (v := (⟨2463, 10000⟩ : Q)) (by decide) (by decide) (by decide)
    hA h630 (by decide)
  have hP := fv_add (v := (⟨615783, 2500000⟩ : Q)) (by decide) (by decide) (by decide)
    hA2 h132 (by decide)
  have hB := fv_add (v := (⟨63, 250⟩ : Q)) (by decide) (by decide) (by decide) h21 h420 (by decide)
  have hN := fv_add (v := (⟨126231, 500000⟩ : Q)) (by decide) (by decide) (by decide)
    hB h462 (by decide)
  show Req (Rsub (deep5P.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
    (deep5N.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) (ofQ (⟨-3843, 625000⟩ : Q) (by decide))
  exact Req_trans (Rsub_congr hP hN) (sub_ofQ_val (by decide) (by decide) (by decide) (by decide))

/-- **Apartness**: `Pos (−deep5(1/10))`. -/
theorem deep5_apart : Pos (Rneg (deep5.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) :=
  Pos_congr (Rneg_congr (Req_symm deep5_value_tenth))
    (Pos_congr (Req_symm (Rneg_ofQ (⟨-3843, 625000⟩ : Q) (by decide))) ⟨163, by decide⟩)

/-- **THE CAPSTONE AT DEPTH 5**: the skeleton's unconditional complement-positivity on the moment
    sequence of a certified NONZERO test whose transform vanishes at FIVE integer points. -/
theorem weil_psd_deep5 (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq deep5) N) :=
  weil_psd_on_cosupport deep5 deep5_supp
    (hatVanishes_mono (by decide) deep5_hatVanishes) N

end Multiplicity.UOR.Bridge.F1Square.Square
