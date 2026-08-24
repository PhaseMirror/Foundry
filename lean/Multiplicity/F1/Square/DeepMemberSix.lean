/-
F1 square — **the pre-Hilbert layer, brick 60** (`DeepMemberSix.lean`): **THE `K = 6` CO-SUPPORT
MEMBER**, extending the strict chain to `HatVanishes · 6 ⊋ HatVanishes · 7`.

Over brick 34's Gram closed form `⟨xⁱ, xʲ⟩ = 1/(i+j+1)` a depth-`K` member is a finite rational
linear system — `Σᵢ aᵢ/(i+n+1) = 0` for `n < K`, plus the support condition `Σᵢ aᵢ = 0`. At
`K = 6`, over `i = 1..8`, the solution is `a = (1, −28, 252, −1050, 2310, −2772, 1716, −429)`:

    `deep6 = x − 28x² + 252x³ − 1050x⁴ + 2310x⁵ − 2772x⁶ + 1716x⁷ − 429x⁸`.

Its first non-vanishing moment is read off the same Gram matrix — no new integration —

    `⟨deep6, x⁶⟩ = 95311/280 − 2190451/6435 = 1/360360 ≠ 0`,

so `deep6 ∈ HatVanishes · 6` and `deep6 ∉ HatVanishes · 7` (`cosupport_strict_at_six`), and with
bricks 37, 41 and 54 the chain reads `0 ⊋ 1 ⊋ 2 ⊋ 3 ⊋ 4 ⊋ 5 ⊋ 6 ⊋ 7`
(`cosupport_chain_strict_seven`). The member is apart from zero at
`deep6(1/10) = −1250469/100000000` (negative, as at `deep5`, so apartness is witnessed on the
negation), and the capstone fires the skeleton's unconditional positivity on it.

HONEST SCOPE. One more member, one more strict level. NOT a proof that every level is inhabited
or strict — that needs invertibility of the Hilbert sections in general — and the positivity is
still the skeleton's diagonal multiplier form on moment data, not the Weil functional on the test
space. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DeepMemberFive

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 40000

/-- The positive part `x + 252x³ + 2310x⁵ + 1716x⁷`. -/
def deep6P : L2Test :=
  L2Test.add (L2Test.add (L2Test.add (powTest 1) (natScale 252 (powTest 3)))
    (natScale 2310 (powTest 5))) (natScale 1716 (powTest 7))

/-- The negative part `28x² + 1050x⁴ + 2772x⁶ + 429x⁸`. -/
def deep6N : L2Test :=
  L2Test.add (L2Test.add (L2Test.add (natScale 28 (powTest 2)) (natScale 1050 (powTest 4)))
    (natScale 2772 (powTest 6))) (natScale 429 (powTest 8))

/-- **THE `K = 6` MEMBER**, built as `P − N`. -/
def deep6 : L2Test := L2Test.sub deep6P deep6N

/-- **The member is `[0,1]`-supported**: the coefficients sum to `4279 − 4279 = 0`. -/
theorem deep6_supp : UnitSupported deep6 := by
  intro m x h0 h1
  have hp : ∀ i, Req ((powTest i).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    fun i => powTest_window_one m h0 i
  have h252 := fv_scale 252 (a := (⟨1, 1⟩ : Q)) (v := (⟨252, 1⟩ : Q)) (by decide) (by decide)
    (hp 3) (by decide)
  have h2310 := fv_scale 2310 (a := (⟨1, 1⟩ : Q)) (v := (⟨2310, 1⟩ : Q)) (by decide) (by decide)
    (hp 5) (by decide)
  have h1716 := fv_scale 1716 (a := (⟨1, 1⟩ : Q)) (v := (⟨1716, 1⟩ : Q)) (by decide) (by decide)
    (hp 7) (by decide)
  have h28 := fv_scale 28 (a := (⟨1, 1⟩ : Q)) (v := (⟨28, 1⟩ : Q)) (by decide) (by decide)
    (hp 2) (by decide)
  have h1050 := fv_scale 1050 (a := (⟨1, 1⟩ : Q)) (v := (⟨1050, 1⟩ : Q)) (by decide) (by decide)
    (hp 4) (by decide)
  have h2772 := fv_scale 2772 (a := (⟨1, 1⟩ : Q)) (v := (⟨2772, 1⟩ : Q)) (by decide) (by decide)
    (hp 6) (by decide)
  have h429 := fv_scale 429 (a := (⟨1, 1⟩ : Q)) (v := (⟨429, 1⟩ : Q)) (by decide) (by decide)
    (hp 8) (by decide)
  have hA := fv_add (v := (⟨253, 1⟩ : Q)) (by decide) (by decide) (by decide)
    (hp 1) h252 (by decide)
  have hA2 := fv_add (v := (⟨2563, 1⟩ : Q)) (by decide) (by decide) (by decide)
    hA h2310 (by decide)
  have hP := fv_add (v := (⟨4279, 1⟩ : Q)) (by decide) (by decide) (by decide)
    hA2 h1716 (by decide)
  have hB := fv_add (v := (⟨1078, 1⟩ : Q)) (by decide) (by decide) (by decide)
    h28 h1050 (by decide)
  have hB2 := fv_add (v := (⟨3850, 1⟩ : Q)) (by decide) (by decide) (by decide)
    hB h2772 (by decide)
  have hN := fv_add (v := (⟨4279, 1⟩ : Q)) (by decide) (by decide) (by decide)
    hB2 h429 (by decide)
  show Req (Rsub (deep6P.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))
    (deep6N.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) zero
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

-- ===========================================================================
-- The six vanishing moments.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- The member's `n`-th moment as one rational identity over the Hilbert entries. -/
private theorem deep6_moment_gen (n : Nat) {q1 q2 q3 q4 q5 q6 q7 q8 w : Q}
    (h1d : 0 < q1.den) (h2d : 0 < q2.den) (h3d : 0 < q3.den) (h4d : 0 < q4.den)
    (h5d : 0 < q5.den) (h6d : 0 < q6.den) (h7d : 0 < q7.den) (h8d : 0 < q8.den)
    (hwd : 0 < w.den)
    (e1 : Req (innerI (powTest 1) (powTest n)) (ofQ q1 h1d))
    (e2 : Req (innerI (powTest 2) (powTest n)) (ofQ q2 h2d))
    (e3 : Req (innerI (powTest 3) (powTest n)) (ofQ q3 h3d))
    (e4 : Req (innerI (powTest 4) (powTest n)) (ofQ q4 h4d))
    (e5 : Req (innerI (powTest 5) (powTest n)) (ofQ q5 h5d))
    (e6 : Req (innerI (powTest 6) (powTest n)) (ofQ q6 h6d))
    (e7 : Req (innerI (powTest 7) (powTest n)) (ofQ q7 h7d))
    (e8 : Req (innerI (powTest 8) (powTest n)) (ofQ q8 h8d))
    (hqP : Qeq (add (add (add q1 (mul (⟨252, 1⟩ : Q) q3)) (mul (⟨2310, 1⟩ : Q) q5))
      (mul (⟨1716, 1⟩ : Q) q7)) w)
    (hqN : Qeq (add (add (add (mul (⟨28, 1⟩ : Q) q2) (mul (⟨1050, 1⟩ : Q) q4))
      (mul (⟨2772, 1⟩ : Q) q6)) (mul (⟨429, 1⟩ : Q) q8)) w) :
    Req (innerI deep6 (powTest n)) zero := by
  have h252 := pv_scale 252 (v := mul (⟨252, 1⟩ : Q) q3) h3d
    (Qmul_den_pos (by decide) h3d) e3 (Qeq_refl _)
  have h2310 := pv_scale 2310 (v := mul (⟨2310, 1⟩ : Q) q5) h5d
    (Qmul_den_pos (by decide) h5d) e5 (Qeq_refl _)
  have h1716 := pv_scale 1716 (v := mul (⟨1716, 1⟩ : Q) q7) h7d
    (Qmul_den_pos (by decide) h7d) e7 (Qeq_refl _)
  have h28 := pv_scale 28 (v := mul (⟨28, 1⟩ : Q) q2) h2d
    (Qmul_den_pos (by decide) h2d) e2 (Qeq_refl _)
  have h1050 := pv_scale 1050 (v := mul (⟨1050, 1⟩ : Q) q4) h4d
    (Qmul_den_pos (by decide) h4d) e4 (Qeq_refl _)
  have h2772 := pv_scale 2772 (v := mul (⟨2772, 1⟩ : Q) q6) h6d
    (Qmul_den_pos (by decide) h6d) e6 (Qeq_refl _)
  have h429 := pv_scale 429 (v := mul (⟨429, 1⟩ : Q) q8) h8d
    (Qmul_den_pos (by decide) h8d) e8 (Qeq_refl _)
  have hA := pv_add (v := add q1 (mul (⟨252, 1⟩ : Q) q3)) h1d
    (Qmul_den_pos (by decide) h3d) (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
    e1 h252 (Qeq_refl _)
  have hA2 := pv_add (v := add (add q1 (mul (⟨252, 1⟩ : Q) q3)) (mul (⟨2310, 1⟩ : Q) q5))
    (add_den_pos h1d (Qmul_den_pos (by decide) h3d)) (Qmul_den_pos (by decide) h5d)
    (add_den_pos (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
      (Qmul_den_pos (by decide) h5d)) hA h2310 (Qeq_refl _)
  have hP := pv_add (v := w)
    (add_den_pos (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
      (Qmul_den_pos (by decide) h5d))
    (Qmul_den_pos (by decide) h7d) hwd hA2 h1716 hqP
  have hB := pv_add (v := add (mul (⟨28, 1⟩ : Q) q2) (mul (⟨1050, 1⟩ : Q) q4))
    (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d)
    (add_den_pos (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d))
    h28 h1050 (Qeq_refl _)
  have hB2 := pv_add
    (v := add (add (mul (⟨28, 1⟩ : Q) q2) (mul (⟨1050, 1⟩ : Q) q4)) (mul (⟨2772, 1⟩ : Q) q6))
    (add_den_pos (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d))
    (Qmul_den_pos (by decide) h6d)
    (add_den_pos (add_den_pos (Qmul_den_pos (by decide) h2d)
      (Qmul_den_pos (by decide) h4d)) (Qmul_den_pos (by decide) h6d))
    hB h2772 (Qeq_refl _)
  have hN := pv_add (v := w)
    (add_den_pos (add_den_pos (Qmul_den_pos (by decide) h2d)
      (Qmul_den_pos (by decide) h4d)) (Qmul_den_pos (by decide) h6d))
    (Qmul_den_pos (by decide) h8d) hwd hB2 h429 hqN
  exact Req_trans (innerI_sub_left deep6P deep6N (powTest n))
    (Req_trans (Rsub_congr hP hN) (Radd_neg _))

/-- `∫₀¹ p = 663 − 663 = 0`. -/
theorem deep6_moment_zero : Req (innerI deep6 (powTest 0)) zero :=
  deep6_moment_gen 0 (w := (⟨663, 1⟩ : Q)) (Nat.succ_pos 1) (Nat.succ_pos 2) (Nat.succ_pos 3)
    (Nat.succ_pos 4) (Nat.succ_pos 5) (Nat.succ_pos 6) (Nat.succ_pos 7) (Nat.succ_pos 8)
    (by decide) (innerI_powTest_hilbert 1 0) (innerI_powTest_hilbert 2 0)
    (innerI_powTest_hilbert 3 0) (innerI_powTest_hilbert 4 0) (innerI_powTest_hilbert 5 0)
    (innerI_powTest_hilbert 6 0) (innerI_powTest_hilbert 7 0) (innerI_powTest_hilbert 8 0)
    (by decide) (by decide)

/-- `∫₀¹ x·p = 2857/5 − 2857/5 = 0`. -/
theorem deep6_moment_one : Req (innerI deep6 (powTest 1)) zero :=
  deep6_moment_gen 1 (w := (⟨2857, 5⟩ : Q)) (Nat.succ_pos 2) (Nat.succ_pos 3) (Nat.succ_pos 4)
    (Nat.succ_pos 5) (Nat.succ_pos 6) (Nat.succ_pos 7) (Nat.succ_pos 8) (Nat.succ_pos 9)
    (by decide) (innerI_powTest_hilbert 1 1) (innerI_powTest_hilbert 2 1)
    (innerI_powTest_hilbert 3 1) (innerI_powTest_hilbert 4 1) (innerI_powTest_hilbert 5 1)
    (innerI_powTest_hilbert 6 1) (innerI_powTest_hilbert 7 1) (innerI_powTest_hilbert 8 1)
    (by decide) (by decide)

/-- `∫₀¹ x²·p = 2513/5 − 2513/5 = 0`. -/
theorem deep6_moment_two : Req (innerI deep6 (powTest 2)) zero :=
  deep6_moment_gen 2 (w := (⟨2513, 5⟩ : Q)) (Nat.succ_pos 3) (Nat.succ_pos 4) (Nat.succ_pos 5)
    (Nat.succ_pos 6) (Nat.succ_pos 7) (Nat.succ_pos 8) (Nat.succ_pos 9) (Nat.succ_pos 10)
    (by decide) (innerI_powTest_hilbert 1 2) (innerI_powTest_hilbert 2 2)
    (innerI_powTest_hilbert 3 2) (innerI_powTest_hilbert 4 2) (innerI_powTest_hilbert 5 2)
    (innerI_powTest_hilbert 6 2) (innerI_powTest_hilbert 7 2) (innerI_powTest_hilbert 8 2)
    (by decide) (by decide)

/-- `∫₀¹ x³·p = 6733/15 − 6733/15 = 0`. -/
theorem deep6_moment_three : Req (innerI deep6 (powTest 3)) zero :=
  deep6_moment_gen 3 (w := (⟨6733, 15⟩ : Q)) (Nat.succ_pos 4) (Nat.succ_pos 5) (Nat.succ_pos 6)
    (Nat.succ_pos 7) (Nat.succ_pos 8) (Nat.succ_pos 9) (Nat.succ_pos 10) (Nat.succ_pos 11)
    (by decide) (innerI_powTest_hilbert 1 3) (innerI_powTest_hilbert 2 3)
    (innerI_powTest_hilbert 3 3) (innerI_powTest_hilbert 4 3) (innerI_powTest_hilbert 5 3)
    (innerI_powTest_hilbert 6 3) (innerI_powTest_hilbert 7 3) (innerI_powTest_hilbert 8 3)
    (by decide) (by decide)

/-- `∫₀¹ x⁴·p = 1217/3 − 1217/3 = 0`. -/
theorem deep6_moment_four : Req (innerI deep6 (powTest 4)) zero :=
  deep6_moment_gen 4 (w := (⟨1217, 3⟩ : Q)) (Nat.succ_pos 5) (Nat.succ_pos 6) (Nat.succ_pos 7)
    (Nat.succ_pos 8) (Nat.succ_pos 9) (Nat.succ_pos 10) (Nat.succ_pos 11) (Nat.succ_pos 12)
    (by decide) (innerI_powTest_hilbert 1 4) (innerI_powTest_hilbert 2 4)
    (innerI_powTest_hilbert 3 4) (innerI_powTest_hilbert 4 4) (innerI_powTest_hilbert 5 4)
    (innerI_powTest_hilbert 6 4) (innerI_powTest_hilbert 7 4) (innerI_powTest_hilbert 8 4)
    (by decide) (by decide)

/-- `∫₀¹ x⁵·p = 2591/7 − 2591/7 = 0`. -/
theorem deep6_moment_five : Req (innerI deep6 (powTest 5)) zero :=
  deep6_moment_gen 5 (w := (⟨2591, 7⟩ : Q)) (Nat.succ_pos 6) (Nat.succ_pos 7) (Nat.succ_pos 8)
    (Nat.succ_pos 9) (Nat.succ_pos 10) (Nat.succ_pos 11) (Nat.succ_pos 12) (Nat.succ_pos 13)
    (by decide) (innerI_powTest_hilbert 1 5) (innerI_powTest_hilbert 2 5)
    (innerI_powTest_hilbert 3 5) (innerI_powTest_hilbert 4 5) (innerI_powTest_hilbert 5 5)
    (innerI_powTest_hilbert 6 5) (innerI_powTest_hilbert 7 5) (innerI_powTest_hilbert 8 5)
    (by decide) (by decide)

/-- **THE `K = 6` CO-SUPPORT MEMBER**: the transform vanishes at `0,1,2,3,4,5`. -/
theorem deep6_hatVanishes :
    HatVanishes deep6 6 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep6 deep6_supp) :=
  hatVanishes_of_moments deep6 6 deep6_supp (fun n hn => by
    match n with
    | 0 => exact deep6_moment_zero
    | 1 => exact deep6_moment_one
    | 2 => exact deep6_moment_two
    | 3 => exact deep6_moment_three
    | 4 => exact deep6_moment_four
    | 5 => exact deep6_moment_five
    | (k + 6) => exact absurd hn (by omega))

-- ===========================================================================
-- The first non-vanishing moment, and strictness at level 6.
-- ===========================================================================

set_option maxHeartbeats 8000000 in
/-- **The member's SIXTH moment is nonzero**: `95311/280 − 2190451/6435 = 1/360360`. -/
theorem deep6_moment_six :
    Req (innerI deep6 (powTest 6)) (ofQ (⟨1, 360360⟩ : Q) (by decide)) := by
  have e1 := innerI_powTest_hilbert 1 6
  have e2 := innerI_powTest_hilbert 2 6
  have e3 := innerI_powTest_hilbert 3 6
  have e4 := innerI_powTest_hilbert 4 6
  have e5 := innerI_powTest_hilbert 5 6
  have e6 := innerI_powTest_hilbert 6 6
  have e7 := innerI_powTest_hilbert 7 6
  have e8 := innerI_powTest_hilbert 8 6
  have h252 := pv_scale 252 (v := (⟨252, 10⟩ : Q)) (Nat.succ_pos 9) (by decide) e3 (by decide)
  have h2310 := pv_scale 2310 (v := (⟨2310, 12⟩ : Q)) (Nat.succ_pos 11) (by decide) e5 (by decide)
  have h1716 := pv_scale 1716 (v := (⟨1716, 14⟩ : Q)) (Nat.succ_pos 13) (by decide) e7 (by decide)
  have h28 := pv_scale 28 (v := (⟨28, 9⟩ : Q)) (Nat.succ_pos 8) (by decide) e2 (by decide)
  have h1050 := pv_scale 1050 (v := (⟨1050, 11⟩ : Q)) (Nat.succ_pos 10) (by decide) e4 (by decide)
  have h2772 := pv_scale 2772 (v := (⟨2772, 13⟩ : Q)) (Nat.succ_pos 12) (by decide) e6 (by decide)
  have h429 := pv_scale 429 (v := (⟨429, 15⟩ : Q)) (Nat.succ_pos 14) (by decide) e8 (by decide)
  have hA := pv_add (v := (⟨1013, 40⟩ : Q)) (Nat.succ_pos 7) (by decide) (by decide)
    e1 h252 (by decide)
  have hA2 := pv_add (v := (⟨8713, 40⟩ : Q)) (by decide) (by decide) (by decide)
    hA h2310 (by decide)
  have hP := pv_add (v := (⟨95311, 280⟩ : Q)) (by decide) (by decide) (by decide)
    hA2 h1716 (by decide)
  have hB := pv_add (v := (⟨9758, 99⟩ : Q)) (by decide) (by decide) (by decide)
    h28 h1050 (by decide)
  have hB2 := pv_add (v := (⟨401282, 1287⟩ : Q)) (by decide) (by decide) (by decide)
    hB h2772 (by decide)
  have hN := pv_add (v := (⟨2190451, 6435⟩ : Q)) (by decide) (by decide) (by decide)
    hB2 h429 (by decide)
  refine Req_trans (innerI_sub_left deep6P deep6N (powTest 6)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

/-- **The `K = 6` member is NOT in level 7**. -/
theorem deep6_not_hatVanishes_seven :
    ¬ HatVanishes deep6 7 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep6 deep6_supp) := by
  intro h
  have hz : Req (innerI deep6 (powTest 6)) zero :=
    Req_trans (Req_symm (mellinHat_compact deep6 6 deep6_supp)) (h 6 (by decide))
  have hv : Req (ofQ (⟨1, 360360⟩ : Q) (by decide)) zero :=
    Req_trans (Req_symm deep6_moment_six) hz
  obtain ⟨n, hn⟩ := Pos_congr hv (⟨360360, by decide⟩ : Pos (ofQ (⟨1, 360360⟩ : Q) (by decide)))
  have hlt : (1 : Int) * ((1 : Nat) : Int) < (0 : Int) * ((n + 1 : Nat) : Int) := hn
  push_cast at hlt
  omega

/-- **STRICTNESS AT LEVEL 6**. -/
theorem cosupport_strict_at_six :
    HatVanishes deep6 6 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep6 deep6_supp)
    ∧ ¬ HatVanishes deep6 7 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep6 deep6_supp) :=
  ⟨deep6_hatVanishes, deep6_not_hatVanishes_seven⟩

/-- **THE STRICT CHAIN THROUGH DEPTH 7**: every level from `0` to `7` properly contains the
    next, each witnessed by an explicit constructed test. (Strictness at the REALIZED levels;
    not a proof that every level is strict.) -/
theorem cosupport_chain_strict_seven :
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
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep5 deep5_supp))
    ∧ (¬ HatVanishes deep6 7 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep6 deep6_supp)) :=
  ⟨bumpU_not_hatVanishes, lin1_not_hatVanishes_two, lin2_not_hatVanishes_three,
   deep3_not_hatVanishes_four, deep4_not_hatVanishes_five, deep5_not_hatVanishes_six,
   deep6_not_hatVanishes_seven⟩

/-- **THE CAPSTONE AT DEPTH 6**: the skeleton's unconditional complement-positivity on the moment
    sequence of a test whose transform vanishes at SIX integer points. -/
theorem weil_psd_deep6 (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq deep6) N) :=
  weil_psd_on_cosupport deep6 deep6_supp
    (hatVanishes_mono (by decide) deep6_hatVanishes) N

end Multiplicity.UOR.Bridge.F1Square.Square
