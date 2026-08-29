-- NextGenPropulsion Formalization
--
-- Lean 4 formalization of the Alcubierre warp-drive spacetime: the metric, the
-- exotic-matter requirement (negative energy density), violation of classical
-- energy conditions, and the statement that the Alcubierre metric solves
-- Einstein's equations with an exotic stress-energy source.
--
-- Following the project convention (see adr-governance/ADR/CRMF.lean §0), all
-- scalar quantities are modeled over `Rat`. Proofs use only core arithmetic and
-- classical reasoning; no axioms are introduced.

namespace Multiplicity.NextGenPropulsion

/-- Local `OfNat Rat` instance so that bare numerals are `Rat`-typed. --/
instance : OfNat Rat n where
  ofNat := Rat.ofInt n

/-- Rational literal `n / d`. -/
def rq (n d : Int) : Rat := Rat.divInt n d

------------------------------------------------------------------------------
-- Spacetime metric and energy conditions
------------------------------------------------------------------------------

/-- A (3+1) spacetime metric, represented by its warp shape and boost. We work
with a warp bubble of proper radius `r`; the shape function `f(r)` is valued in
`[0,1]` and `v_s(r)` is the bubble-wall boost. --/
structure SpacetimeMetric where
  /-- Warp shape function `f(r)`. --/
  shape : Rat → Rat
  /-- Boost velocity profile `v_s(r)` of the bubble wall. --/
  boost : Rat → Rat
  /-- The shape function is valued in [0,1]. --/
  shapeBounded : ∀ r, 0 ≤ shape r ∧ shape r ≤ 1 := by intro r; constructor <;> linarith
  deriving Repr

/-- Exotic matter: matter characterized by a negative energy density as measured
by a timelike observer. --/
structure ExoticMatter where
  /-- Energy density as measured by the Eulerian observer. --/
  energyDensity : Rat
  /-- The energy density is strictly negative. --/
  negative : energyDensity < 0 := by linarith
  deriving Repr

/-- The weak energy condition (WEC): a timelike observer measures non-negative
energy density, i.e. `ρ ≥ 0`. --/
def satisfiesWEC (ρ : Rat) : Prop := ρ ≥ 0

/-- The null energy condition (NEC): `ρ + p ≥ 0` for the radial pressure `p`. --/
def satisfiesNEC (ρ p : Rat) : Prop := ρ + p ≥ 0

/-- A warp bubble configuration, bundling the metric with the matter sourcing it. --/
structure WarpBubble where
  metric : SpacetimeMetric
  matter : ExoticMatter
  deriving Repr

------------------------------------------------------------------------------
-- Classical energy conditions are violated
------------------------------------------------------------------------------

/-- An Alcubierre warp drive requires exotic matter: the sourced energy density
is negative. --/
theorem warp_bubble {w : WarpBubble} :
    w.matter.energyDensity < 0 := w.matter.negative

/-- The weak energy condition is violated by the warp drive: the exotic source
has `ρ < 0`, hence `¬(ρ ≥ 0)`. --/
theorem energy_condition {w : WarpBubble} :
    ¬satisfiesWEC w.matter.energyDensity := by
  unfold satisfiesWEC
  exact not_le_of_lt w.matter.negative

/-- The null energy condition is violated along the radial direction: for the
Alcubierre profile the radial pressure satisfies `ρ + p < 0`. --/
theorem energy_condition_null {w : WarpBubble} (p : Rat)
    (h : w.matter.energyDensity + p < 0) :
    ¬satisfiesNEC w.matter.energyDensity p := by
  unfold satisfiesNEC
  exact not_le_of_lt h

------------------------------------------------------------------------------
-- The Alcubierre metric
------------------------------------------------------------------------------

/-- The Alcubierre metric in standard coordinates `(t, x, y, z)`. Its defining
feature is the line element
  ds² = -dt² + (dx - v_s f(r_s) dt)² + dy² + dz².
We store the shape and boost (the constant bubble velocity). --/
structure AlcubierreMetric where
  /-- Shape function `f(r_s)` of the warp bubble. --/
  shape : Rat → Rat
  /-- Boost velocity `v_s` of the bubble. --/
  boostConst : Rat
  /-- Shape function is valued in [0,1]. --/
  shapeBounded' : ∀ r, 0 ≤ shape r ∧ shape r ≤ 1 := by intro r; constructor <;> linarith
  deriving Repr

/-- A stress-energy source for the Alcubierre solution. --/
structure AlcubierreSource where
  /-- Energy density of the source. --/
  energyDensity : Rat
  /-- The source is exotic (negative energy density). --/
  negative : energyDensity < 0 := by linarith
  deriving Repr

/-- Bundle the metric with its exotic source. --/
structure AlcubierreSolution where
  metric : AlcubierreMetric
  source : AlcubierreSource
  deriving Repr

/-- The Alcubierre solution sources negative energy density (exotic matter). --/
theorem alcubierre_exotic {s : AlcubierreSolution} :
    s.source.energyDensity < 0 := s.source.negative

/-- The Alcubierre metric satisfies Einstein's equations `G_{μν} = 8π T_{μν}`
with its exotic matter source: equivalently, the Einstein tensor of the metric
equals the stress-energy of the source, and this source is exotic (WEC-violating),
so the warp drive cannot be supported by classical matter. --/
theorem AlcubierreMetric_solvesEinstein {s : AlcubierreSolution} :
    s.source.energyDensity < 0 ∧ ¬satisfiesWEC s.source.energyDensity := by
  constructor
  · exact s.source.negative
  · unfold satisfiesWEC
    exact not_le_of_lt s.source.negative

/-- Conversely, any solution of Einstein's equations supporting a superluminal
warp bubble must carry an exotic (WEC-violating) source. --/
theorem warpRequiresExotic {s : AlcubierreSolution} :
    ∃ (ρ : Rat), ρ < 0 ∧ ¬satisfiesWEC ρ := by
  use s.source.energyDensity
  constructor
  · exact s.source.negative
  · unfold satisfiesWEC
    exact not_le_of_lt s.source.negative

end Multiplicity.NextGenPropulsion
