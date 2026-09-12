/-
F1 square — **the pre-Hilbert layer, brick 41** (`DeepMemberFour.lean`): **THE `K = 4`
CO-SUPPORT MEMBER**, and with it the strict chain extended one level further —
`HatVanishes · 4 ⊋ HatVanishes · 5`.

With brick 34's Gram closed form `⟨xⁱ, xʲ⟩ = 1/(i+j+1)` and brick 35's `natScale` helper, a
member at depth `K` is a finite rational linear-algebra problem: solve

    Σᵢ aᵢ/(i+n+1) = 0  (n = 0,1,2,3),   Σᵢ aᵢ = 0   (the support condition)

over `i = 1..6`. The solution is `a = (1, −15, 70, −140, 126, −42)`:

    `deep4 = x − 15x² + 70x³ − 140x⁴ + 126x⁵ − 42x⁶`.

Its first non-vanishing moment is read off the same Gram matrix, no new integration:

    `⟨deep4, x⁴⟩ = (1/6 + 70/8 + 126/10) − (15/7 + 140/9 + 42/11) = 1291/60 − 14911/693
                 = 1/13860 ≠ 0`,

so `deep4 ∈ HatVanishes · 4` and `deep4 ∉ HatVanishes · 5` (`cosupport_strict_at_four`),
extending brick 37's chain `0 ⊋ 1 ⊋ 2 ⊋ 3 ⊋ 4` to `0 ⊋ 1 ⊋ 2 ⊋ 3 ⊋ 4 ⊋ 5`. The member is
apart from zero (`deep4(1/10) = 3609/500000`), so the capstone `weil_psd_deep4` fires the
skeleton's unconditional positivity on genuinely nonzero `f, f̂` data whose transform vanishes
at FOUR integer points.

HONEST SCOPE. One more member, one more strict level — a deeper finite shadow of the
non-collapse the genuine Sonine space requires, NOT a proof that every level is inhabited or
strict (that needs invertibility of the Hilbert sections in general). The positivity delivered
is still the skeleton's diagonal multiplier form on moment data, not the Weil functional on the
test space, and not positivity beyond the complement — step 4, which is RH. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.CoSupportChain

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 40000

/-- The positive part `x + 70x³ + 126x⁵`. -/
def deep4P : L2Test :=
  L2Test.add (L2Test.add (powTest 1) (natScale 70 (powTest 3))) (natScale 126 (powTest 5))

/-- The negative part `15x² + 140x⁴ + 42x⁶`. -/
def deep4N : L2Test :=
  L2Test.add (L2Test.add (natScale 15 (powTest 2)) (natScale 140 (powTest 4)))
    (natScale 42 (powTest 6))

/-- **THE `K = 4` MEMBER**: `x − 15x² + 70x³ − 140x⁴ + 126x⁵ − 42x⁶`, built as `P − N` (the
    `L2Test.sub` route keeps a `L2Test.neg` off the head of the tree, where it would send
    `innerI` unification into a whnf blowup). -/
def deep4 : L2Test := L2Test.sub deep4P deep4N

/-- **The member is `[0,1]`-supported**: the coefficients sum to `(1+70+126) − (15+140+42) = 0`. -/
theorem deep4_supp : UnitSupported deep4 := by
  intro m x h0 h1
  have hp : ∀ i, Req ((powTest i).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    fun i => powTest_window_one m h0 i
  have h70 := fv_scale 70 (a := (⟨1, 1⟩ : Q)) (v := (⟨70, 1⟩ : Q)) (by decide) (by decide)
    (hp 3) (by decide)
  have h126 := fv_scale 126 (a := (⟨1, 1⟩ : Q)) (v := (⟨126, 1⟩ : Q)) (by decide) (by decide)
    (hp 5) (by decide)
  have h15 := fv_scale 15 (a := (⟨1, 1⟩ : Q)) (v := (⟨15, 1⟩ : Q)) (by decide) (by decide)
    (hp 2) (by decide)
  have h140 := fv_scale 140 (a := (⟨1, 1⟩ : Q)) (v := (⟨140, 1⟩ : Q)) (by decide) (by decide)
    (hp 4) (by decide)
  have h42 := fv_scale 42 (a := (⟨1, 1⟩ : Q)) (v := (⟨42, 1⟩ : Q)) (by decide) (by decide)
    (hp 6) (by decide)
  have hA := fv_add (v := (⟨71, 1⟩ : Q)) (by decide) (by decide) (by decide) (hp 1) h70 (by decide)
  have hP := fv_add (v := (⟨197, 1⟩ : Q)) (by decide) (by decide) (by decide) hA h126 (by decide)
  have hB := fv_add (v := (⟨155, 1⟩ : Q)) (by decide) (by decide) (by decide) h15 h140 (by decide)
  have hN := fv_add (v := (⟨197, 1⟩ : Q)) (by decide) (by decide) (by decide) hB h42 (by decide)
  show Req (Rsub (deep4P.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))
    (deep4N.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) zero
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

-- ===========================================================================
-- The four vanishing moments.
-- ===========================================================================

set_option maxHeartbeats 2000000 in
/-- The member's `n`-th moment as a single rational identity over the Hilbert entries: the two
    parts hit the common value `w`, so the difference vanishes. -/
private theorem deep4_moment_gen (n : Nat) {q1 q2 q3 q4 q5 q6 w : Q}
    (h1d : 0 < q1.den) (h2d : 0 < q2.den) (h3d : 0 < q3.den) (h4d : 0 < q4.den)
    (h5d : 0 < q5.den) (h6d : 0 < q6.den) (hwd : 0 < w.den)
    (e1 : Req (innerI (powTest 1) (powTest n)) (ofQ q1 h1d))
    (e2 : Req (innerI (powTest 2) (powTest n)) (ofQ q2 h2d))
    (e3 : Req (innerI (powTest 3) (powTest n)) (ofQ q3 h3d))
    (e4 : Req (innerI (powTest 4) (powTest n)) (ofQ q4 h4d))
    (e5 : Req (innerI (powTest 5) (powTest n)) (ofQ q5 h5d))
    (e6 : Req (innerI (powTest 6) (powTest n)) (ofQ q6 h6d))
    (hqP : Qeq (add (add q1 (mul (⟨70, 1⟩ : Q) q3)) (mul (⟨126, 1⟩ : Q) q5)) w)
    (hqN : Qeq (add (add (mul (⟨15, 1⟩ : Q) q2) (mul (⟨140, 1⟩ : Q) q4))
      (mul (⟨42, 1⟩ : Q) q6)) w) :
    Req (innerI deep4 (powTest n)) zero := by
  have h70 := pv_scale 70 (v := mul (⟨70, 1⟩ : Q) q3) h3d
    (Qmul_den_pos (by decide) h3d) e3 (Qeq_refl _)
  have h126 := pv_scale 126 (v := mul (⟨126, 1⟩ : Q) q5) h5d
    (Qmul_den_pos (by decide) h5d) e5 (Qeq_refl _)
  have h15 := pv_scale 15 (v := mul (⟨15, 1⟩ : Q) q2) h2d
    (Qmul_den_pos (by decide) h2d) e2 (Qeq_refl _)
  have h140 := pv_scale 140 (v := mul (⟨140, 1⟩ : Q) q4) h4d
    (Qmul_den_pos (by decide) h4d) e4 (Qeq_refl _)
  have h42 := pv_scale 42 (v := mul (⟨42, 1⟩ : Q) q6) h6d
    (Qmul_den_pos (by decide) h6d) e6 (Qeq_refl _)
  have hA := pv_add (v := add q1 (mul (⟨70, 1⟩ : Q) q3)) h1d
    (Qmul_den_pos (by decide) h3d) (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
    e1 h70 (Qeq_refl _)
  have hP := pv_add (v := w) (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
    (Qmul_den_pos (by decide) h5d) hwd hA h126 hqP
  have hB := pv_add (v := add (mul (⟨15, 1⟩ : Q) q2) (mul (⟨140, 1⟩ : Q) q4))
    (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d)
    (add_den_pos (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d))
    h15 h140 (Qeq_refl _)
  have hN := pv_add (v := w)
    (add_den_pos (Qmul_den_pos (by decide) h2d) (Qmul_den_pos (by decide) h4d))
    (Qmul_den_pos (by decide) h6d) hwd hB h42 hqN
  exact Req_trans (innerI_sub_left deep4P deep4N (powTest n))
    (Req_trans (Rsub_congr hP hN) (Radd_neg _))

/-- `∫₀¹ p = (1/2 + 70/4 + 126/6) − (15/3 + 140/5 + 42/7) = 39 − 39 = 0`. -/
theorem deep4_moment_zero : Req (innerI deep4 (powTest 0)) zero :=
  deep4_moment_gen 0 (w := (⟨39, 1⟩ : Q)) (Nat.succ_pos 1) (Nat.succ_pos 2) (Nat.succ_pos 3)
    (Nat.succ_pos 4) (Nat.succ_pos 5) (Nat.succ_pos 6) (by decide)
    (innerI_powTest_hilbert 1 0) (innerI_powTest_hilbert 2 0) (innerI_powTest_hilbert 3 0)
    (innerI_powTest_hilbert 4 0) (innerI_powTest_hilbert 5 0) (innerI_powTest_hilbert 6 0)
    (by decide) (by decide)

/-- `∫₀¹ x·p = (1/3 + 70/5 + 126/7) − (15/4 + 140/6 + 42/8) = 97/3 − 97/3 = 0`. -/
theorem deep4_moment_one : Req (innerI deep4 (powTest 1)) zero :=
  deep4_moment_gen 1 (w := (⟨97, 3⟩ : Q)) (Nat.succ_pos 2) (Nat.succ_pos 3) (Nat.succ_pos 4)
    (Nat.succ_pos 5) (Nat.succ_pos 6) (Nat.succ_pos 7) (by decide)
    (innerI_powTest_hilbert 1 1) (innerI_powTest_hilbert 2 1) (innerI_powTest_hilbert 3 1)
    (innerI_powTest_hilbert 4 1) (innerI_powTest_hilbert 5 1) (innerI_powTest_hilbert 6 1)
    (by decide) (by decide)

/-- `∫₀¹ x²·p = (1/4 + 70/6 + 126/8) − (15/5 + 140/7 + 42/9) = 83/3 − 83/3 = 0`. -/
theorem deep4_moment_two : Req (innerI deep4 (powTest 2)) zero :=
  deep4_moment_gen 2 (w := (⟨83, 3⟩ : Q)) (Nat.succ_pos 3) (Nat.succ_pos 4) (Nat.succ_pos 5)
    (Nat.succ_pos 6) (Nat.succ_pos 7) (Nat.succ_pos 8) (by decide)
    (innerI_powTest_hilbert 1 2) (innerI_powTest_hilbert 2 2) (innerI_powTest_hilbert 3 2)
    (innerI_powTest_hilbert 4 2) (innerI_powTest_hilbert 5 2) (innerI_powTest_hilbert 6 2)
    (by decide) (by decide)

/-- `∫₀¹ x³·p = (1/5 + 70/7 + 126/9) − (15/6 + 140/8 + 42/10) = 121/5 − 121/5 = 0`. -/
theorem deep4_moment_three : Req (innerI deep4 (powTest 3)) zero :=
  deep4_moment_gen 3 (w := (⟨121, 5⟩ : Q)) (Nat.succ_pos 4) (Nat.succ_pos 5) (Nat.succ_pos 6)
    (Nat.succ_pos 7) (Nat.succ_pos 8) (Nat.succ_pos 9) (by decide)
    (innerI_powTest_hilbert 1 3) (innerI_powTest_hilbert 2 3) (innerI_powTest_hilbert 3 3)
    (innerI_powTest_hilbert 4 3) (innerI_powTest_hilbert 5 3) (innerI_powTest_hilbert 6 3)
    (by decide) (by decide)

/-- **THE `K = 4` CO-SUPPORT MEMBER**: the transform vanishes at the integer points `0,1,2,3`. -/
theorem deep4_hatVanishes :
    HatVanishes deep4 4 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep4 deep4_supp) :=
  hatVanishes_of_moments deep4 4 deep4_supp (fun n hn => by
    match n with
    | 0 => exact deep4_moment_zero
    | 1 => exact deep4_moment_one
    | 2 => exact deep4_moment_two
    | 3 => exact deep4_moment_three
    | (k + 4) => exact absurd hn (by omega))

-- ===========================================================================
-- The first non-vanishing moment, and strictness at level 4.
-- ===========================================================================

set_option maxHeartbeats 2000000 in
/-- **The member's FOURTH moment is nonzero**: `⟨deep4, x⁴⟩ = 1291/60 − 14911/693 = 1/13860`. -/
theorem deep4_moment_four :
    Req (innerI deep4 (powTest 4)) (ofQ (⟨1, 13860⟩ : Q) (by decide)) := by
  have e1 := innerI_powTest_hilbert 1 4
  have e2 := innerI_powTest_hilbert 2 4
  have e3 := innerI_powTest_hilbert 3 4
  have e4 := innerI_powTest_hilbert 4 4
  have e5 := innerI_powTest_hilbert 5 4
  have e6 := innerI_powTest_hilbert 6 4
  have h70 := pv_scale 70 (v := (⟨70, 8⟩ : Q)) (Nat.succ_pos 7) (by decide) e3 (by decide)
  have h126 := pv_scale 126 (v := (⟨126, 10⟩ : Q)) (Nat.succ_pos 9) (by decide) e5 (by decide)
  have h15 := pv_scale 15 (v := (⟨15, 7⟩ : Q)) (Nat.succ_pos 6) (by decide) e2 (by decide)
  have h140 := pv_scale 140 (v := (⟨140, 9⟩ : Q)) (Nat.succ_pos 8) (by decide) e4 (by decide)
  have h42 := pv_scale 42 (v := (⟨42, 11⟩ : Q)) (Nat.succ_pos 10) (by decide) e6 (by decide)
  have hA := pv_add (v := (⟨107, 12⟩ : Q)) (Nat.succ_pos 5) (by decide) (by decide)
    e1 h70 (by decide)
  have hP := pv_add (v := (⟨1291, 60⟩ : Q)) (by decide) (by decide) (by decide)
    hA h126 (by decide)
  have hB := pv_add (v := (⟨1115, 63⟩ : Q)) (by decide) (by decide) (by decide)
    h15 h140 (by decide)
  have hN := pv_add (v := (⟨14911, 693⟩ : Q)) (by decide) (by decide) (by decide)
    hB h42 (by decide)
  refine Req_trans (innerI_sub_left deep4P deep4N (powTest 4)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

/-- **The `K = 4` member is NOT in level 5**: its transform does not vanish at the integer
    point `4`. -/
theorem deep4_not_hatVanishes_five :
    ¬ HatVanishes deep4 5 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep4 deep4_supp) := by
  intro h
  have hz : Req (innerI deep4 (powTest 4)) zero :=
    Req_trans (Req_symm (mellinHat_compact deep4 4 deep4_supp)) (h 4 (by decide))
  have hv : Req (ofQ (⟨1, 13860⟩ : Q) (by decide)) zero :=
    Req_trans (Req_symm deep4_moment_four) hz
  obtain ⟨n, hn⟩ := Pos_congr hv (⟨13860, by decide⟩ : Pos (ofQ (⟨1, 13860⟩ : Q) (by decide)))
  have hlt : (1 : Int) * ((1 : Nat) : Int) < (0 : Int) * ((n + 1 : Nat) : Int) := hn
  push_cast at hlt
  omega

/-- **STRICTNESS AT LEVEL 4**: `deep4` lies in `HatVanishes · 4` and not in `HatVanishes · 5`,
    so the chain of brick 37 extends one level: `0 ⊋ 1 ⊋ 2 ⊋ 3 ⊋ 4 ⊋ 5`. -/
theorem cosupport_strict_at_four :
    HatVanishes deep4 4 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep4 deep4_supp)
    ∧ ¬ HatVanishes deep4 5 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep4 deep4_supp) :=
  ⟨deep4_hatVanishes, deep4_not_hatVanishes_five⟩

-- ===========================================================================
-- Apartness and the capstone.
-- ===========================================================================

set_option maxHeartbeats 2000000 in
/-- **The member is not the zero function**: `deep4(1/10) = 3609/500000`. -/
theorem deep4_value_tenth :
    Req (deep4.f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨3609, 500000⟩ : Q) (by decide)) := by
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
  have h70 := fv_scale 70 (v := (⟨70, 1000⟩ : Q)) (by decide) (by decide) p3 (by decide)
  have h126 := fv_scale 126 (v := (⟨126, 100000⟩ : Q)) (by decide) (by decide) p5 (by decide)
  have h15 := fv_scale 15 (v := (⟨15, 100⟩ : Q)) (by decide) (by decide) p2 (by decide)
  have h140 := fv_scale 140 (v := (⟨140, 10000⟩ : Q)) (by decide) (by decide) p4 (by decide)
  have h42 := fv_scale 42 (v := (⟨42, 1000000⟩ : Q)) (by decide) (by decide) p6 (by decide)
  have hA := fv_add (v := (⟨17, 100⟩ : Q)) (by decide) (by decide) (by decide) p1 h70 (by decide)
  have hP := fv_add (v := (⟨17126, 100000⟩ : Q)) (by decide) (by decide) (by decide)
    hA h126 (by decide)
  have hB := fv_add (v := (⟨1640, 10000⟩ : Q)) (by decide) (by decide) (by decide)
    h15 h140 (by decide)
  have hN := fv_add (v := (⟨164042, 1000000⟩ : Q)) (by decide) (by decide) (by decide)
    hB h42 (by decide)
  show Req (Rsub (deep4P.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
    (deep4N.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) (ofQ (⟨3609, 500000⟩ : Q) (by decide))
  exact Req_trans (Rsub_congr hP hN) (sub_ofQ_val (by decide) (by decide) (by decide) (by decide))

/-- **Apartness**: `Pos (deep4(1/10))`. -/
theorem deep4_apart : Pos (deep4.f (ofQ (⟨1, 10⟩ : Q) (by decide))) :=
  Pos_congr (Req_symm deep4_value_tenth) ⟨200, by decide⟩

/-- **THE CAPSTONE AT DEPTH 4**: the skeleton's unconditional complement-positivity fires on
    the moment sequence of a certified NONZERO test whose constructed transform vanishes at
    FOUR integer points. No RH. -/
theorem weil_psd_deep4 (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq deep4) N) :=
  weil_psd_on_cosupport deep4 deep4_supp
    (hatVanishes_mono (by decide) deep4_hatVanishes) N

/-- **THE STRICT CHAIN, EXTENDED**: every level from `0` to `5` properly contains the next,
    each witnessed by a constructed test that sits in one level and provably not the next —
    `bumpU`, `lin1`, `lin2`, `deep3`, `deep4`. (Strictness at the REALIZED levels; not a proof
    that every level is strict.) -/
theorem cosupport_chain_strict_five :
    (¬ HatVanishes bumpU 1 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp bumpU bumpU_supp))
    ∧ (¬ HatVanishes lin1 2 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp lin1 lin1_supp))
    ∧ (¬ HatVanishes lin2 3 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp lin2 lin2_supp))
    ∧ (¬ HatVanishes deep3 4 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep3 deep3_supp))
    ∧ (¬ HatVanishes deep4 5 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep4 deep4_supp)) :=
  ⟨bumpU_not_hatVanishes, lin1_not_hatVanishes_two, lin2_not_hatVanishes_three,
   deep3_not_hatVanishes_four, deep4_not_hatVanishes_five⟩

end Multiplicity.UOR.Bridge.F1Square.Square
