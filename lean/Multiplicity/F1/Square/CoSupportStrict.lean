/-
F1 square — **the pre-Hilbert layer, brick 36** (`CoSupportStrict.lean`): **THE CO-SUPPORT
FILTRATION DOES NOT COLLAPSE** — the nested subspaces

    `HatVanishes · 0  ⊇  HatVanishes · 1  ⊇  HatVanishes · 2  ⊇  HatVanishes · 3  ⊇  ⋯`

are STRICTLY decreasing at the levels the layer has realized, each strictness witnessed by a
constructed test that sits in one level and provably not the next.

Membership was the previous bricks' work; strictness needs the FIRST NON-VANISHING moment,
and brick 34's Gram closed form supplies it by arithmetic alone. For the `K = 3` member
`deep3 = x − 10x² + 30x³ − 35x⁴ + 14x⁵` the third moment is

    `(1/5 + 30/7 + 14/9) − (10/6 + 35/8) = 1903/315 − 145/24 = −1/2520 ≠ 0`

(`deep3_moment_three`), so `deep3 ∉ HatVanishes · 4` (`deep3_not_hatVanishes_four`) while
`deep3 ∈ HatVanishes · 3`: level 3 properly contains level 4. At the bottom, brick 25's
`bumpU = x(1−x)` has `f̂(0) = 1/6 ≠ 0`, so it sits in the (vacuous) level 0 and not in level 1.

WHY IT MATTERS (the Sonine route). A co-support condition that collapsed past some depth would
make the genuine `f, f̂` space finite-dimensional in the relevant direction, and the coupling
step 4 needs could not be an infinite-dimensional phenomenon. Strictness at the realized
depths is the finite shadow of the non-collapse the genuine Sonine space requires — evidence,
not proof, and stated as exactly that.

HONEST SCOPE. Strictness at the two witnessed levels (`0 ⊋ 1` and `3 ⊋ 4`), each by an
explicit constructed test; NOT a proof that every level is strict, and nothing about the Weil
form. Positivity beyond the complement is step 4 and is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DeepMemberThree

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 8000

/-- `ofQ a − ofQ b ≈ ofQ v` when `a − b = v` at the `ℚ` level (public: every `P − N` member
    evaluation ends here). -/
theorem sub_ofQ_val {a b v : Q} (had : 0 < a.den) (hbd : 0 < b.den) (hvd : 0 < v.den)
    (hq : Qeq (add a (neg b)) v) :
    Req (Rsub (ofQ a had) (ofQ b hbd)) (ofQ v hvd) :=
  Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ b hbd))
    (Req_trans (Radd_ofQ_ofQ had (by exact hbd)) (Req_of_seq_Qeq (fun _ => hq)))

/-- **The member's THIRD moment is nonzero**: `⟨deep3, x³⟩ = −1/2520`. The positive part
    contributes `1/5 + 30/7 + 14/9 = 1903/315`, the negative part `10/6 + 35/8 = 145/24`, and
    the two differ by exactly `−1/2520`. -/
theorem deep3_moment_three :
    Req (innerI deep3 (powTest 3)) (ofQ (⟨-1, 2520⟩ : Q) (by decide)) := by
  have e1 := innerI_powTest_hilbert 1 3
  have e2 := innerI_powTest_hilbert 2 3
  have e3 := innerI_powTest_hilbert 3 3
  have e4 := innerI_powTest_hilbert 4 3
  have e5 := innerI_powTest_hilbert 5 3
  have h30 := pv_scale 30 (v := (⟨30, 7⟩ : Q)) (Nat.succ_pos 6) (by decide) e3 (by decide)
  have h14 := pv_scale 14 (v := (⟨14, 9⟩ : Q)) (Nat.succ_pos 8) (by decide) e5 (by decide)
  have h10 := pv_scale 10 (v := (⟨10, 6⟩ : Q)) (Nat.succ_pos 5) (by decide) e2 (by decide)
  have h35 := pv_scale 35 (v := (⟨35, 8⟩ : Q)) (Nat.succ_pos 7) (by decide) e4 (by decide)
  have hA := pv_add (v := (⟨157, 35⟩ : Q)) (Nat.succ_pos 4) (by decide) (by decide)
    e1 h30 (by decide)
  have hP := pv_add (v := (⟨1903, 315⟩ : Q)) (by decide) (by decide) (by decide)
    hA h14 (by decide)
  have hN := pv_add (v := (⟨145, 24⟩ : Q)) (by decide) (by decide) (by decide)
    h10 h35 (by decide)
  refine Req_trans (innerI_sub_left deep3P deep3N (powTest 3)) ?_
  refine Req_trans (Rsub_congr hP hN) ?_
  exact sub_ofQ_val (by decide) (by decide) (by decide) (by decide)

/-- **The `K = 3` member is NOT in level 4**: its transform does not vanish at the integer
    point `3`. -/
theorem deep3_not_hatVanishes_four :
    ¬ HatVanishes deep3 4 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep3 deep3_supp) := by
  intro h
  have hz : Req (innerI deep3 (powTest 3)) zero :=
    Req_trans (Req_symm (mellinHat_compact deep3 3 deep3_supp)) (h 3 (by decide))
  have hv : Req (ofQ (⟨-1, 2520⟩ : Q) (by decide)) zero :=
    Req_trans (Req_symm deep3_moment_three) hz
  have hpos : Pos (Rneg (ofQ (⟨-1, 2520⟩ : Q) (by decide))) := ⟨5040, by decide⟩
  obtain ⟨n, hn⟩ := Pos_congr (Rneg_congr hv) hpos
  have hlt : (1 : Int) * ((1 : Nat) : Int) < (-0 : Int) * ((n + 1 : Nat) : Int) := hn
  push_cast at hlt
  omega

/-- **STRICTNESS AT LEVEL 3**: `deep3` lies in `HatVanishes · 3` and not in `HatVanishes · 4`,
    so level 3 properly contains level 4 — the filtration does not collapse there. -/
theorem cosupport_strict_at_three :
    HatVanishes deep3 3 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep3 deep3_supp)
    ∧ ¬ HatVanishes deep3 4 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp deep3 deep3_supp) :=
  ⟨deep3_hatVanishes, deep3_not_hatVanishes_four⟩

/-- **STRICTNESS AT LEVEL 0**: the unit bump `x(1−x)` lies in the (vacuous) level 0 and not in
    level 1, since `f̂(0) = 1/6 ≠ 0` (brick 25). -/
theorem cosupport_strict_at_zero :
    HatVanishes bumpU 0 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp bumpU bumpU_supp)
    ∧ ¬ HatVanishes bumpU 1 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp bumpU bumpU_supp) :=
  ⟨fun n hn => absurd hn (by omega), bumpU_not_hatVanishes⟩

end Multiplicity.UOR.Bridge.F1Square.Square
