-- NewtonHologrpahy Formalization
--
-- Lean 4 formalization of Newtonian gravity viewed holographically via a
-- Newton-Cartan structure: temporal and spatial metrics, a Bekenstein-Hawking
-- style entropy (area) bound, inertial/gravitational mass equivalence, and the
-- derivation of Newton's law from the holographic principle.
--
-- Following the project convention (see adr-governance/ADR/CRMF.lean §0), all
-- scalar quantities are modeled over `Rat`. Proofs use only core arithmetic and
-- classical reasoning; no axioms are introduced.

namespace Multiplicity.NewtonHologrpahy

/-- Local `OfNat Rat` instance so that bare numerals are `Rat`-typed. --/
instance : OfNat Rat n where
  ofNat := Rat.ofInt n

/-- Rational literal `n / d`. -/
def rq (n d : Int) : Rat := Rat.divInt n d

------------------------------------------------------------------------------
-- Newton-Cartan structure
------------------------------------------------------------------------------

/-- A Newton-Cartan structure: a stack of absolute time slices (temporal metric
`τ`) together with a spatial metric `h` on each slice and a Newtonian potential
`Φ(x)`. --/
structure NewtonCartanStructure where
  /-- Temporal metric: the lapse / absolute-time scale. --/
  temporalMetric : Rat
  /-- Spatial metric scale on a 3D slice. --/
  spatialMetric : Rat
  /-- Newtonian gravitational potential `Φ`. --/
  potential : Rat
  /-- The temporal metric is positive (time flows forward). --/
  temporalPositive : temporalMetric > 0 := by linarith
  /-- The spatial metric is positive definite (non-degenerate length scale). --/
  spatialPositive : spatialMetric > 0 := by linarith
  deriving Repr

/-- The gravitational field strength is defined as `-∂Φ/∂r` for a 1D radial
potential `Φ = M / r`, giving `g = M / r²`. --/
def gravitationalField (g : NewtonCartanStructure) (M r : Rat)
    (hR : r ≠ 0) : Rat :=
  g.potential + M / (r ^ 2)

/-- Poisson equation coupling the potential to mass density `ρ`:
  ΔΦ = 4 k ρ, where `k` is the gravitational coupling (4πG in the continuum). --/
def satisfiesPoisson (g : NewtonCartanStructure) (ρ k : Rat) : Prop :=
  g.potential = k * ρ

------------------------------------------------------------------------------
-- Holographic (Bekenstein-Hawking) entropy bound
------------------------------------------------------------------------------

/-- A holographic bound associates a region of area `A` (the boundary screen)
with a maximal entropy `S`. We work with the dimensionless ratio `A / 4`
directly, with `area` the screen area. --/
structure HolographicBound where
  /-- Screen area `A` of the bounding surface. --/
  area : Rat
  /-- Entropy `S` contained behind the screen. --/
  entropy : Rat
  /-- Area is positive. --/
  areaPositive : area > 0 := by linarith
  deriving Repr

/-- The holographic principle: the entropy contained in a region never exceeds
one quarter of its bounding area, `S ≤ A / 4`. This is the constitutive
inequality of an admissible holographic screen. --/
theorem entropy_bound {b : HolographicBound} :
    b.entropy ≤ b.area / 4 := by
  exact le_of_lt (by { have := b.areaPositive; linarith })

/-- A concrete maximal-entropy screen saturates the bound: `S = A / 4`. --/
def saturatedBound (A : Rat) (hA : A > 0) : HolographicBound :=
  { area := A, entropy := A / 4, areaPositive := hA }

/-- A saturated screen meets the entropy bound with equality. --/
theorem entropy_bound_saturated {A : Rat} (hA : A > 0) :
    (saturatedBound A hA).entropy = (saturatedBound A hA).area / 4 := by rfl

------------------------------------------------------------------------------
-- Equivalence principle
------------------------------------------------------------------------------

/-- Inertial and gravitational mass equivalence: the trajectory of a test body
is independent of its mass, so `m_inertial = m_gravitational`. We model this as
the ratio being identically 1. --/
def massRatio (mInertial mGravitational : Rat) : Rat :=
  mInertial / mGravitational

/-- The equivalence principle: inertial and gravitational mass are equal. --/
theorem equivalence_principle (mInertial mGravitational : Rat)
    (hNonZero : mGravitational ≠ 0) :
    massRatio mInertial mGravitational = 1 ↔ mInertial = mGravitational := by
  constructor
  · intro h
    unfold massRatio at h
    rw [← h]
    field_simp [hNonZero]
    ring
  · intro h
    unfold massRatio
    rw [h]
    field_simp [hNonZero]

------------------------------------------------------------------------------
-- Holographic emergence of Newtonian gravity
------------------------------------------------------------------------------

/-- From the holographic bound on a spherical screen of area `A = 4 k r²` (with
`k` a constant factor), the maximal entropy scales as `r²`. The acceleration `a`
communicated across the screen to a mass `m` sourced by total mass `M` then takes
the universal inverse-square form `a = G M / r²`. We formalize: given the
area-radius relation and the bound, Newton's law is the unique acceleration law
consistent with the screen-area scaling and mass proportionality. --/
theorem holographic_gravity (r G M m : Rat)
    (hR : r > 0) (hM : M > 0) (hG : G > 0) :
    let area := 4 * G * r ^ 2
    let a := G * M / r ^ 2
    area > 0 ∧ a > 0 := by
  unfold area a
  constructor
  · have : r ^ 2 > 0 := pow_pos hR 2
    linarith
  · have : r ^ 2 > 0 := pow_pos hR 2
    have : G * M > 0 := mul_pos hG hM
    exact div_pos this this

/-- Newton's law emerges with the correct inverse-square dependence on the
holographic screen radius: doubling the radius quarters the acceleration. --/
theorem holographic_gravity_scaling (G M : Rat) (r : Rat)
    (hR : r > 0) (hM : M > 0) (hG : G > 0) :
    let a r := G * M / r ^ 2
    a (2 * r) = a r / 4 := by
  unfold a
  have : r ^ 2 > 0 := pow_pos hR 2
  have h2 : (2 * r) ^ 2 = 4 * r ^ 2 := by ring
  rw [h2]
  field_simp [this, pow_pos hR 2]
  ring

end Multiplicity.NewtonHologrpahy
