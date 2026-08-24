import Care

/-!
# Care Viability — Phase Mirror Thresholds for Care Circles (Option A)

Formalizes the three Buurtzorg-Circle dissonance thresholds over the same
exact fixed-point arithmetic as `Care.lean` (scale `N = 1024`, zero Mathlib,
zero incomplete proofs):

1. **Resonance floor** — mean triad resonance ≥ 0.85, encoded as
   `3·870 ≤ rSum` with `⌊0.85·N⌋ = 870`; the sum form is proved equivalent
   to the average form `ResFloor ≤ rSum/3`.
2. **Embodied viability limit** — aggregate capacity strictly positive,
   proved equivalent to "some single triad retains capacity".
3. **Hundian complexity cap** — six normalized structural loads sum to at
   most `N`.

The binary audit mirrors the upstream claim (`phase_mirror_audit`) and
discharges its central theorem: a passing circle is burnout-free by
construction.

## Honest deviations

* Triad metrics are `[0, N]` subtypes, so bounds hold by construction rather
  than by uncheckable `Float` assumptions.
* The audit is intentionally the *aggregate* check of the source document;
  `averaging_blind_spot` below machine-checks that aggregates can hide a
  failing member, which is exactly why per-triad checks belong in policy.
* The Hundian cap checker verifies arithmetic only; whether real workloads
  stay under the cap is an empirical question no proof can discharge.
-/
namespace PhaseMirror.CareViability

open PhaseMirror.Care

/-! ## Triad vitals -/

/-- Vital signs of one triad: resonance and embodied capacity, both in `[0, N]`. -/
structure TriadVital where
  /-- Resonance coherence `R_triad`, fixed-point scaled. -/
  r : {x : Nat // x ≤ Scale}
  /-- Embodied capacity `E_triad`, fixed-point scaled. -/
  e : {x : Nat // x ≤ Scale}

/-- A care circle: exactly three triads (explicit fields avoid array-size proofs). -/
structure CircleVital where
  /-- First triad. -/
  t0 : TriadVital
  /-- Second triad. -/
  t1 : TriadVital
  /-- Third triad. -/
  t2 : TriadVital

/-- Aggregate resonance across the three triads (reducible for `decide`). -/
abbrev rSum (c : CircleVital) : Nat := c.t0.r.val + c.t1.r.val + c.t2.r.val

/-- Aggregate embodied capacity across the three triads. -/
abbrev eSum (c : CircleVital) : Nat := c.t0.e.val + c.t1.e.val + c.t2.e.val

/-! ## Threshold 1: resonance floor -/

/-- Resonance floor `⌊0.85 · N⌋ = 870`. -/
abbrev ResFloor : Nat := 870

/-- Mean-form floor check: `mean(R_j) ≥ ResFloor`, expressed multiplicatively. -/
abbrev rMeanPass (c : CircleVital) : Prop := 3 * ResFloor ≤ rSum c

/-- The multiplicative (sum) form is equivalent to the literal average form. -/
theorem rMeanPass_iff_avg (c : CircleVital) :
    rMeanPass c ↔ ResFloor ≤ rSum c / 3 := by
  constructor
  · intro h
    exact (Nat.le_div_iff_mul_le (k := 3) (by decide)).mpr (by omega)
  · intro h
    have h3 : ResFloor * 3 ≤ rSum c := (Nat.le_div_iff_mul_le (k := 3) (by decide)).mp h
    omega

/-! ## Threshold 2: embodied viability limit -/

/-- Viability limit: aggregate capacity strictly above the zero burnout line. -/
abbrev viableE (c : CircleVital) : Prop := 0 < eSum c

/-- Positive aggregate capacity means some single triad still has capacity. -/
theorem viableE_iff_some_pos (c : CircleVital) :
    viableE c ↔ (0 < c.t0.e.val ∨ 0 < c.t1.e.val ∨ 0 < c.t2.e.val) := by
  show 0 < c.t0.e.val + c.t1.e.val + c.t2.e.val ↔ _
  constructor
  · intro h
    omega
  · intro h
    cases h with
    | inl h => omega
    | inr h => cases h with
      | inl h => omega
      | inr h => omega

/-! ## Threshold 3: Hundian complexity cap -/

/-- Six normalized structural loads of a circle (stress and load per triad),
each already divided by its maximum and scaled into `[0, N]`. -/
structure Loads where
  /-- Stress share of triad 1. -/
  s0 : {x : Nat // x ≤ Scale}
  /-- Load share of triad 1. -/
  l0 : {x : Nat // x ≤ Scale}
  /-- Stress share of triad 2. -/
  s1 : {x : Nat // x ≤ Scale}
  /-- Load share of triad 2. -/
  l1 : {x : Nat // x ≤ Scale}
  /-- Stress share of triad 3. -/
  s2 : {x : Nat // x ≤ Scale}
  /-- Load share of triad 3. -/
  l2 : {x : Nat // x ≤ Scale}

/-- Total normalized complexity of a circle. -/
abbrev complexity (L : Loads) : Nat :=
  L.s0.val + L.l0.val + L.s1.val + L.l1.val + L.s2.val + L.l2.val

/-- Hundian complexity cap: total complexity within the unit budget `N`. -/
abbrev capOK (L : Loads) : Prop := complexity L ≤ Scale

/-- Sufficient condition for the cap: every individual load at most
`⌊N/6⌋ = 170` keeps six loads inside the budget of `N = 1024`
(`6 · 170 = 1020 ≤ 1024`). -/
theorem cap_of_sixths (L : Loads)
    (h0 : L.s0.val ≤ 170) (h1 : L.l0.val ≤ 170)
    (h2 : L.s1.val ≤ 170) (h3 : L.l1.val ≤ 170)
    (h4 : L.s2.val ≤ 170) (h5 : L.l2.val ≤ 170) :
    capOK L := by
  show L.s0.val + L.l0.val + L.s1.val + L.l1.val + L.s2.val + L.l2.val ≤ 1024
  omega

/-! ## Binary audit -/

/-- Binary Phase Mirror audit: resonance floor AND positive aggregate viability. -/
def phase_mirror_audit (c : CircleVital) : Bool :=
  decide (rMeanPass c) && decide (viableE c)

/-- **Theorem (upstream claim, discharged).** A circle that passes the audit
is burnout-free by construction: its aggregate capacity is strictly positive
and its resonance meets the floor. -/
theorem viable_circle_prevents_burnout (c : CircleVital)
    (h : phase_mirror_audit c = true) :
    viableE c ∧ rMeanPass c := by
  unfold phase_mirror_audit at h
  rw [Bool.and_eq_true] at h
  exact ⟨of_decide_eq_true h.2, of_decide_eq_true h.1⟩

/-- **Averaging blind spot.** An aggregate floor can hide a failing member:
one triad below the floor while the circle mean still passes. Machine-checked
so this policy gap cannot be forgotten. -/
theorem averaging_blind_spot :
    ∃ a b c : Nat, b < ResFloor ∧ 3 * ResFloor ≤ a + b + c ∧
      a ≤ Scale ∧ b ≤ Scale ∧ c ≤ Scale :=
  ⟨1024, 869, 1024, by decide⟩

/-! ## Composition with the multiplicity core -/

/-- **Circle-level multiplicity bound.** Composing three valid dyads lifts the
per-bond range `[N, 3N]` to the circle aggregate `[3N, 9N]`. -/
theorem circle_multiplicity_bounded
    (g₁ g₂ g₃ : Nat) (c₁ c₂ c₃ : Trust)
    (h₁ : g₁ ≤ Scale) (h₂ : g₂ ≤ Scale) (h₃ : g₃ ≤ Scale) :
    3 * Scale ≤
        multiplicityPN g₁ c₁ + multiplicityPN g₂ c₂ + multiplicityPN g₃ c₃
      ∧ multiplicityPN g₁ c₁ + multiplicityPN g₂ c₂ + multiplicityPN g₃ c₃
          ≤ 9 * Scale := by
  have b₁ := multiplicity_bounded g₁ h₁ c₁
  have b₂ := multiplicity_bounded g₂ h₂ c₂
  have b₃ := multiplicity_bounded g₃ h₃ c₃
  constructor <;> omega

/-! ## Concrete circles (executable spec tests) -/

/-- Healthy circle: every triad above floor with slack on both vitals. -/
def healthyCircle : CircleVital where
  t0 := { r := ⟨900, by decide⟩, e := ⟨700, by decide⟩ }
  t1 := { r := ⟨880, by decide⟩, e := ⟨640, by decide⟩ }
  t2 := { r := ⟨910, by decide⟩, e := ⟨760, by decide⟩ }

/-- Strained circle: resonance sum `2400 < 2610` fails the floor. -/
def strainedCircle : CircleVital where
  t0 := { r := ⟨800, by decide⟩, e := ⟨400, by decide⟩ }
  t1 := { r := ⟨790, by decide⟩, e := ⟨380, by decide⟩ }
  t2 := { r := ⟨810, by decide⟩, e := ⟨420, by decide⟩ }

/-- Depleted circle: resonance passes but aggregate capacity is zero. -/
def depletedCircle : CircleVital where
  t0 := { r := ⟨900, by decide⟩, e := ⟨0, by decide⟩ }
  t1 := { r := ⟨880, by decide⟩, e := ⟨0, by decide⟩ }
  t2 := { r := ⟨910, by decide⟩, e := ⟨0, by decide⟩ }

example : phase_mirror_audit healthyCircle = true := by decide
example : phase_mirror_audit strainedCircle = false := by decide
example : phase_mirror_audit depletedCircle = false := by decide
example : ¬ rMeanPass strainedCircle := by decide
example : ¬ viableE depletedCircle := by decide
example : rMeanPass depletedCircle := by decide

/-! ## Load witnesses -/

/-- Light loads stay under the Hundian budget (`6·150 = 900 ≤ 1024`). -/
def lightLoads : Loads where
  s0 := ⟨150, by decide⟩; l0 := ⟨150, by decide⟩
  s1 := ⟨150, by decide⟩; l1 := ⟨150, by decide⟩
  s2 := ⟨150, by decide⟩; l2 := ⟨150, by decide⟩

/-- Fully loaded circles breach the budget (`6·N > N`). -/
def heavyLoads : Loads where
  s0 := ⟨Scale, Nat.le_refl Scale⟩; l0 := ⟨Scale, Nat.le_refl Scale⟩
  s1 := ⟨Scale, Nat.le_refl Scale⟩; l1 := ⟨Scale, Nat.le_refl Scale⟩
  s2 := ⟨Scale, Nat.le_refl Scale⟩; l2 := ⟨Scale, Nat.le_refl Scale⟩

example : capOK lightLoads := by decide
example : ¬ capOK heavyLoads := by
  intro h
  have h' : (6144 : Nat) ≤ 1024 := h
  omega

/-- The cap is a genuine constraint: fully loaded circles violate it. -/
theorem cap_violation_possible :
    ∃ L : Loads, ¬ capOK L :=
  ⟨heavyLoads, by
    intro h
    have h' : (6144 : Nat) ≤ 1024 := h
    omega⟩

/-! ## Audit v2: per-triad resonance floors

Closes the gap proved by `averaging_blind_spot`: governance requires every
triad to meet the floor, with the aggregate floor demoted to a corollary.
See `docs/adr/ADR-038-Circle-Audit-v2-PerTriad-Floors.md`. -/

/-- Per-triad resonance floors: each triad at or above `ResFloor` individually. -/
abbrev rEachPass (c : CircleVital) : Prop :=
  ResFloor ≤ c.t0.r.val ∧ ResFloor ≤ c.t1.r.val ∧ ResFloor ≤ c.t2.r.val

/-- **v2 strengthens v1.** If every triad meets the floor, so does their mean
(aggregate form). -/
theorem each_implies_mean (c : CircleVital) (h : rEachPass c) : rMeanPass c := by
  have h0 := h.1
  have h1 := h.2.1
  have h2 := h.2.2
  unfold rMeanPass rSum
  omega

/-- Witness circle for strictness: mean passes (`2917 ≥ 2610`) while triad 1
sits below the floor (`869 < 870`). Same profile as `averaging_blind_spot`. -/
def mixedCircle : CircleVital where
  t0 := { r := ⟨1024, by decide⟩, e := ⟨700, by decide⟩ }
  t1 := { r := ⟨869, by decide⟩, e := ⟨640, by decide⟩ }
  t2 := { r := ⟨1024, by decide⟩, e := ⟨760, by decide⟩ }

/-- **v1 does not imply v2.** The witness passes the aggregate floor while a
single triad fails; this is exactly the blind spot, now at definition level. -/
theorem mean_does_not_imply_each :
    ∃ c : CircleVital, rMeanPass c ∧ ¬ rEachPass c :=
  ⟨mixedCircle, by decide, by decide⟩

/-- Binary v2 audit: every-triad resonance floor AND positive aggregate capacity. -/
def phase_mirror_audit_v2 (c : CircleVital) : Bool :=
  decide (rEachPass c) && decide (viableE c)

/-- **Central v2 guarantee.** A circle passing the v2 audit is burnout-free
with every triad above the floor. -/
theorem viable_circle_prevents_burnout_v2 (c : CircleVital)
    (h : phase_mirror_audit_v2 c = true) :
    viableE c ∧ rEachPass c := by
  unfold phase_mirror_audit_v2 at h
  rw [Bool.and_eq_true] at h
  exact ⟨of_decide_eq_true h.2, of_decide_eq_true h.1⟩

/-- **Soundness of v2 w.r.t. v1.** Anything passing v2 passes v1, so
migrating governance to v2 never weakens the previous guarantee. -/
theorem audit_v2_sound_wrt_v1 (c : CircleVital)
    (h : phase_mirror_audit_v2 c = true) :
    phase_mirror_audit c = true := by
  have hv := viable_circle_prevents_burnout_v2 c h
  have hm : rMeanPass c := each_implies_mean c hv.2
  unfold phase_mirror_audit
  rw [Bool.and_eq_true]
  exact ⟨decide_eq_true hm, decide_eq_true hv.1⟩

/-! ### Kernel-level v2 instances -/

example : phase_mirror_audit mixedCircle = true := by decide
example : phase_mirror_audit_v2 mixedCircle = false := by decide
example : phase_mirror_audit_v2 healthyCircle = true := by decide
example : phase_mirror_audit_v2 strainedCircle = false := by decide
example : phase_mirror_audit_v2 depletedCircle = false := by decide

end PhaseMirror.CareViability
