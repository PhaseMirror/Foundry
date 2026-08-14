/-
F1 square — **the pre-Hilbert layer, brick 37** (`CoSupportChain.lean`): **THE STRICT CHAIN
THROUGH DEPTH 4** — the co-support filtration is strictly decreasing at every level the layer
has reached:

    `HatVanishes · 0  ⊋  HatVanishes · 1  ⊋  HatVanishes · 2  ⊋  HatVanishes · 3  ⊋  HatVanishes · 4`

Brick 36 witnessed the two ends (`bumpU` at level 0, `deep3` at level 3). This brick fills the
middle with the two members the Hilbert system supplies at depths 1 and 2, both in the
`P − N` linear form that brick 35's helpers evaluate mechanically:

- `lin1 = x − 3x² + 2x³` — moment `0` vanishes (`1 − 1`), moment `1` is `11/15 − 3/4 = −1/60`;
- `lin2 = x − 6x² + 10x³ − 5x⁴` — moments `0, 1` vanish (`3 − 3`, `7/3 − 7/3`), moment `2` is
  `23/12 − 67/35 = 1/420`.

Each is unit-supported (coefficients sum to zero) and apart from zero (`lin1(1/10) = 9/125`,
`lin2(1/10) = 99/2000`), so each sits in its level and provably not the next. Every moment is
read straight off `⟨xⁱ, xʲ⟩ = 1/(i+j+1)`; no new integration.

HONEST SCOPE. Strictness at the four realized levels, each by an explicit constructed test;
NOT a proof that every level is strict — that would need the Hilbert sections' invertibility
in general — and nothing about the Weil form. Positivity beyond the complement is step 4 and
is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CoSupportStrict

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 8000

-- ===========================================================================
-- The depth-1 member `x − 3x² + 2x³`.
-- ===========================================================================

/-- The positive part `x + 2x³`. -/
def lin1P : L2Test := L2Test.add (powTest 1) (natScale 2 (powTest 3))

/-- The negative part `3x²`. -/
def lin1N : L2Test := natScale 3 (powTest 2)

/-- **The depth-1 member**: `x − 3x² + 2x³`. -/
def lin1 : L2Test := L2Test.sub lin1P lin1N

theorem lin1_supp : UnitSupported lin1 := by
  intro m x h0 h1
  have hp : ∀ i, Req ((powTest i).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    fun i => powTest_window_one m h0 i
  have h2 := fv_scale 2 (a := (⟨1, 1⟩ : Q)) (v := (⟨2, 1⟩ : Q)) (by decide) (by decide)
    (hp 3) (by decide)
  have h3 := fv_scale 3 (a := (⟨1, 1⟩ : Q)) (v := (⟨3, 1⟩ : Q)) (by decide) (by decide)
    (hp 2) (by decide)
  have hP := fv_add (v := (⟨3, 1⟩ : Q)) (by decide) (by decide) (by decide) (hp 1) h2 (by decide)
  show Req (Rsub (lin1P.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))
    (lin1N.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) zero
  exact Req_trans (Rsub_congr hP h3) (Radd_neg _)

/-- `∫₀¹ lin1 = (1/2 + 2/4) − 3/3 = 0`. -/
theorem lin1_moment_zero : Req (innerI lin1 (powTest 0)) zero := by
  have h2 := pv_scale 2 (v := (⟨2, 4⟩ : Q)) (Nat.succ_pos 3) (by decide)
    (innerI_powTest_hilbert 3 0) (by decide)
  have h3 := pv_scale 3 (v := (⟨3, 3⟩ : Q)) (Nat.succ_pos 2) (by decide)
    (innerI_powTest_hilbert 2 0) (by decide)
  have hP := pv_add (v := (⟨1, 1⟩ : Q)) (Nat.succ_pos 1) (by decide) (by decide)
    (innerI_powTest_hilbert 1 0) h2 (by decide)
  have hN : Req (innerI lin1N (powTest 0)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    Req_trans h3 (Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨3, 3⟩ : Q) (⟨1, 1⟩ : Q)
      decide))
  refine Req_trans (innerI_sub_left lin1P lin1N (powTest 0)) ?_
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

/-- `∫₀¹ x·lin1 = (1/3 + 2/5) − 3/4 = −1/60 ≠ 0`. -/
theorem lin1_moment_one : Req (innerI lin1 (powTest 1)) (ofQ (⟨-1, 60⟩ : Q) (by decide)) := by
  have h2 := pv_scale 2 (v := (⟨2, 5⟩ : Q)) (Nat.succ_pos 4) (by decide)
    (innerI_powTest_hilbert 3 1) (by decide)
  have h3 := pv_scale 3 (v := (⟨3, 4⟩ : Q)) (Nat.succ_pos 3) (by decide)
    (innerI_powTest_hilbert 2 1) (by decide)
  have hP := pv_add (v := (⟨11, 15⟩ : Q)) (Nat.succ_pos 2) (by decide) (by decide)
    (innerI_powTest_hilbert 1 1) h2 (by decide)
  refine Req_trans (innerI_sub_left lin1P lin1N (powTest 1)) ?_
  refine Req_trans (Rsub_congr hP h3) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

theorem lin1_hatVanishes :
    HatVanishes lin1 1 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp lin1 lin1_supp) :=
  hatVanishes_of_moments lin1 1 lin1_supp (fun n hn => by
    match n with
    | 0 => exact lin1_moment_zero
    | (k + 1) => exact absurd hn (by omega))

theorem lin1_not_hatVanishes_two :
    ¬ HatVanishes lin1 2 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp lin1 lin1_supp) := by
  intro h
  have hz : Req (innerI lin1 (powTest 1)) zero :=
    Req_trans (Req_symm (mellinHat_compact lin1 1 lin1_supp)) (h 1 (by decide))
  have hv : Req (ofQ (⟨-1, 60⟩ : Q) (by decide)) zero :=
    Req_trans (Req_symm lin1_moment_one) hz
  have hpos : Pos (Rneg (ofQ (⟨-1, 60⟩ : Q) (by decide))) := ⟨120, by decide⟩
  obtain ⟨n, hn⟩ := Pos_congr (Rneg_congr hv) hpos
  have hlt : (1 : Int) * ((1 : Nat) : Int) < (-0 : Int) * ((n + 1 : Nat) : Int) := hn
  push_cast at hlt
  omega

/-- `lin1(1/10) = 102/1000 − 3/100 = 9/125 > 0`. -/
theorem lin1_apart : Pos (lin1.f (ofQ (⟨1, 10⟩ : Q) (by decide))) := by
  have hc : Req (clamp01 (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨1, 10⟩ : Q) (by decide)) :=
    clamp01_ofQ (by decide) (by decide) (by decide)
  have step : ∀ {i : Nat} {u : Q} (hud : 0 < u.den) {w : Q} (hwd : 0 < w.den),
      Req ((powTest i).f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ u hud) →
      Qeq (mul u (⟨1, 10⟩ : Q)) w →
      Req ((powTest (i + 1)).f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ w hwd) := by
    intro i u hud w hwd hu hq
    refine Req_trans (Rmul_congr hu hc) ?_
    exact Req_trans (Rmul_ofQ_ofQ hud (by decide)) (Req_of_seq_Qeq (fun _ => hq))
  have p0 : Req ((powTest 0).f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨1, 1⟩ : Q) (by decide)) := Req_refl one
  have p1 := step (i := 0) (by decide) (w := (⟨1, 10⟩ : Q)) (by decide) p0 (by decide)
  have p2 := step (i := 1) (by decide) (w := (⟨1, 100⟩ : Q)) (by decide) p1 (by decide)
  have p3 := step (i := 2) (by decide) (w := (⟨1, 1000⟩ : Q)) (by decide) p2 (by decide)
  have h2 := fv_scale 2 (v := (⟨2, 1000⟩ : Q)) (by decide) (by decide) p3 (by decide)
  have h3 := fv_scale 3 (v := (⟨3, 100⟩ : Q)) (by decide) (by decide) p2 (by decide)
  have hP := fv_add (v := (⟨102, 1000⟩ : Q)) (by decide) (by decide) (by decide)
    p1 h2 (by decide)
  have hval : Req (lin1.f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨9, 125⟩ : Q) (by decide)) := by
    show Req (Rsub (lin1P.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (lin1N.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) (ofQ (⟨9, 125⟩ : Q) (by decide))
    exact Req_trans (Rsub_congr hP h3)
      (sub_ofQ_val (by decide) (by decide) (by decide) (by decide))
  exact Pos_congr (Req_symm hval) ⟨20, by decide⟩

-- ===========================================================================
-- The depth-2 member `x − 6x² + 10x³ − 5x⁴`.
-- ===========================================================================

/-- The positive part `x + 10x³`. -/
def lin2P : L2Test := L2Test.add (powTest 1) (natScale 10 (powTest 3))

/-- The negative part `6x² + 5x⁴`. -/
def lin2N : L2Test := L2Test.add (natScale 6 (powTest 2)) (natScale 5 (powTest 4))

/-- **The depth-2 member**: `x − 6x² + 10x³ − 5x⁴`. -/
def lin2 : L2Test := L2Test.sub lin2P lin2N

theorem lin2_supp : UnitSupported lin2 := by
  intro m x h0 h1
  have hp : ∀ i, Req ((powTest i).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    fun i => powTest_window_one m h0 i
  have h10 := fv_scale 10 (a := (⟨1, 1⟩ : Q)) (v := (⟨10, 1⟩ : Q)) (by decide) (by decide)
    (hp 3) (by decide)
  have h6 := fv_scale 6 (a := (⟨1, 1⟩ : Q)) (v := (⟨6, 1⟩ : Q)) (by decide) (by decide)
    (hp 2) (by decide)
  have h5 := fv_scale 5 (a := (⟨1, 1⟩ : Q)) (v := (⟨5, 1⟩ : Q)) (by decide) (by decide)
    (hp 4) (by decide)
  have hP := fv_add (v := (⟨11, 1⟩ : Q)) (by decide) (by decide) (by decide)
    (hp 1) h10 (by decide)
  have hN := fv_add (v := (⟨11, 1⟩ : Q)) (by decide) (by decide) (by decide) h6 h5 (by decide)
  show Req (Rsub (lin2P.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))
    (lin2N.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) zero
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

/-- `∫₀¹ lin2 = (1/2 + 10/4) − (6/3 + 5/5) = 3 − 3 = 0`. -/
theorem lin2_moment_zero : Req (innerI lin2 (powTest 0)) zero := by
  have h10 := pv_scale 10 (v := (⟨10, 4⟩ : Q)) (Nat.succ_pos 3) (by decide)
    (innerI_powTest_hilbert 3 0) (by decide)
  have h6 := pv_scale 6 (v := (⟨6, 3⟩ : Q)) (Nat.succ_pos 2) (by decide)
    (innerI_powTest_hilbert 2 0) (by decide)
  have h5 := pv_scale 5 (v := (⟨5, 5⟩ : Q)) (Nat.succ_pos 4) (by decide)
    (innerI_powTest_hilbert 4 0) (by decide)
  have hP := pv_add (v := (⟨3, 1⟩ : Q)) (Nat.succ_pos 1) (by decide) (by decide)
    (innerI_powTest_hilbert 1 0) h10 (by decide)
  have hN := pv_add (v := (⟨3, 1⟩ : Q)) (by decide) (by decide) (by decide) h6 h5 (by decide)
  refine Req_trans (innerI_sub_left lin2P lin2N (powTest 0)) ?_
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

/-- `∫₀¹ x·lin2 = (1/3 + 10/5) − (6/4 + 5/6) = 7/3 − 7/3 = 0`. -/
theorem lin2_moment_one : Req (innerI lin2 (powTest 1)) zero := by
  have h10 := pv_scale 10 (v := (⟨10, 5⟩ : Q)) (Nat.succ_pos 4) (by decide)
    (innerI_powTest_hilbert 3 1) (by decide)
  have h6 := pv_scale 6 (v := (⟨6, 4⟩ : Q)) (Nat.succ_pos 3) (by decide)
    (innerI_powTest_hilbert 2 1) (by decide)
  have h5 := pv_scale 5 (v := (⟨5, 6⟩ : Q)) (Nat.succ_pos 5) (by decide)
    (innerI_powTest_hilbert 4 1) (by decide)
  have hP := pv_add (v := (⟨7, 3⟩ : Q)) (Nat.succ_pos 2) (by decide) (by decide)
    (innerI_powTest_hilbert 1 1) h10 (by decide)
  have hN := pv_add (v := (⟨7, 3⟩ : Q)) (by decide) (by decide) (by decide) h6 h5 (by decide)
  refine Req_trans (innerI_sub_left lin2P lin2N (powTest 1)) ?_
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

/-- `∫₀¹ x²·lin2 = (1/4 + 10/6) − (6/5 + 5/7) = 23/12 − 67/35 = 1/420 ≠ 0`. -/
theorem lin2_moment_two :
    Req (innerI lin2 (powTest 2)) (ofQ (⟨1, 420⟩ : Q) (by decide)) := by
  have h10 := pv_scale 10 (v := (⟨10, 6⟩ : Q)) (Nat.succ_pos 5) (by decide)
    (innerI_powTest_hilbert 3 2) (by decide)
  have h6 := pv_scale 6 (v := (⟨6, 5⟩ : Q)) (Nat.succ_pos 4) (by decide)
    (innerI_powTest_hilbert 2 2) (by decide)
  have h5 := pv_scale 5 (v := (⟨5, 7⟩ : Q)) (Nat.succ_pos 6) (by decide)
    (innerI_powTest_hilbert 4 2) (by decide)
  have hP := pv_add (v := (⟨23, 12⟩ : Q)) (Nat.succ_pos 3) (by decide) (by decide)
    (innerI_powTest_hilbert 1 2) h10 (by decide)
  have hN := pv_add (v := (⟨67, 35⟩ : Q)) (by decide) (by decide) (by decide) h6 h5 (by decide)
  refine Req_trans (innerI_sub_left lin2P lin2N (powTest 2)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

theorem lin2_hatVanishes :
    HatVanishes lin2 2 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp lin2 lin2_supp) :=
  hatVanishes_of_moments lin2 2 lin2_supp (fun n hn => by
    match n with
    | 0 => exact lin2_moment_zero
    | 1 => exact lin2_moment_one
    | (k + 2) => exact absurd hn (by omega))

theorem lin2_not_hatVanishes_three :
    ¬ HatVanishes lin2 3 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp lin2 lin2_supp) := by
  intro h
  have hz : Req (innerI lin2 (powTest 2)) zero :=
    Req_trans (Req_symm (mellinHat_compact lin2 2 lin2_supp)) (h 2 (by decide))
  have hv : Req (ofQ (⟨1, 420⟩ : Q) (by decide)) zero :=
    Req_trans (Req_symm lin2_moment_two) hz
  obtain ⟨n, hn⟩ := Pos_congr hv (⟨840, by decide⟩ : Pos (ofQ (⟨1, 420⟩ : Q) (by decide)))
  have hlt : (1 : Int) * ((1 : Nat) : Int) < (0 : Int) * ((n + 1 : Nat) : Int) := hn
  push_cast at hlt
  omega

-- ===========================================================================
-- The chain.
-- ===========================================================================

/-- **THE STRICT CHAIN THROUGH DEPTH 4**: at each realized level a constructed test sits in
    that level and provably not the next — `0 ⊋ 1 ⊋ 2 ⊋ 3 ⊋ 4`. The co-support filtration
    does not collapse anywhere the layer has reached. -/
theorem cosupport_chain_strict :
    (¬ HatVanishes bumpU 1 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp bumpU bumpU_supp))
    ∧ (¬ HatVanishes lin1 2 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp lin1 lin1_supp))
    ∧ (¬ HatVanishes lin2 3 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp lin2 lin2_supp))
    ∧ (¬ HatVanishes deep3 4 (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp deep3 deep3_supp)) :=
  ⟨bumpU_not_hatVanishes, lin1_not_hatVanishes_two, lin2_not_hatVanishes_three,
   deep3_not_hatVanishes_four⟩

end Multiplicity.UOR.Bridge.F1Square.Square
