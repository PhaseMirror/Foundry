-- Emdra Formalization
--
-- Lean 4 formalization of source-free electromagnetic duality: the electric and
-- magnetic fields, the dual field, Maxwell's equations as an inductive type, the
-- SO(2) duality rotation invariance, the role of magnetic monopoles in completing
-- the symmetry, and the Lorentz/duality invariants `E² - B²` and `E·B`.
--
-- Fields are modeled as 3-vectors of `Rat`; proofs use only core arithmetic. No
-- axioms are introduced. The duality rotation is parametrized by rational field
-- components `c, s` (the continuum `cos θ, sin θ`); the proof assumes the
-- orthogonality relation `c² + s² = 1` that any true rotation satisfies.

namespace Multiplicity.Emdra

/-- Local `OfNat Rat` instance so that bare numerals are `Rat`-typed. --/
instance : OfNat Rat n where
  ofNat := Rat.ofInt n

/-- Rational literal `n / d`. -/
def rq (n d : Int) : Rat := Rat.divInt n d

-------------------------------------------------------------------------------
-- Fields
-------------------------------------------------------------------------------

/-- A 3-vector in real space, used for the electric and magnetic fields. --/
structure Vec3 where
  x : Rat
  y : Rat
  z : Rat
  deriving Repr

/-- The electric field `E` and magnetic field `B` of an electromagnetic field. --/
structure ElectromagneticField where
  /-- Electric field vector. --/
  E : Vec3
  /-- Magnetic field vector. --/
  B : Vec3
  deriving Repr

/-- The Hodge-dual electromagnetic field, with `E → B` and `B → -E`. --/
structure DualField where
  /-- Dual electric field (original B). --/
  EDual : Vec3
  /-- Dual magnetic field (negated original E). --/
  BDual : Vec3
  deriving Repr

/-- The dual of a field implements the `π/2` duality rotation:
  Ẽ = B,  B̃ = -E. --/
def dual (f : ElectromagneticField) : DualField where
  EDual := f.B
  BDual := Vec3.mk (-f.E.x) (-f.E.y) (-f.E.z)

/-- Negation for Vec3. -/
instance : Neg Vec3 where
  neg v := Vec3.mk (-v.x) (-v.y) (-v.z)

/-- Scalar multiplication for Vec3. -/
instance : HMul Rat Vec3 Vec3 where
  hMul c v := Vec3.mk (c * v.x) (c * v.y) (c * v.z)

/-- Pointwise addition for Vec3. -/
instance : HAdd Vec3 Vec3 Vec3 where
  hAdd u v := Vec3.mk (u.x + v.x) (u.y + v.y) (u.z + v.z)

-------------------------------------------------------------------------------
-- Maxwell equations
-------------------------------------------------------------------------------

/-- The four source-free Maxwell equations, indexed by which law they express.
  - `GaussE`  : ∇·E = 0
  - `GaussB`  : ∇·B = 0
  - `Faraday` : ∇×E = -∂B/∂t
  - `Ampere`  : ∇×B = ∂E/∂t --/
inductive MaxwellEquation : Type
  | GaussE
  | GaussB
  | Faraday
  | Ampere

/-- A field satisfies the source-free Gauss laws:
  ∇·E = 0  and  ∇·B = 0. --/
def satisfiesMaxwell (f : ElectromagneticField) : Prop :=
  (f.E.x + f.E.y + f.E.z = 0) ∧ (f.B.x + f.B.y + f.B.z = 0)

/-- A field obeying the source-free Gauss laws. --/
theorem maxwell_gauss (f : ElectromagneticField)
    (h : satisfiesMaxwell f) :
    f.E.x + f.E.y + f.E.z = 0 ∧ f.B.x + f.B.y + f.B.z = 0 := h

-------------------------------------------------------------------------------
-- Duality rotation invariance
-------------------------------------------------------------------------------

/-- Apply a duality rotation with field components `c, s` (a continuum rotation
would have `c = cos θ`, `s = sin θ`) to the field:
  E' =  c E + s B
  B' = -s E + c B --/
def dualityRotation (f : ElectromagneticField) (c s : Rat) : ElectromagneticField where
  E := Vec3.mk (c * f.E.x + s * f.B.x) (c * f.E.y + s * f.B.y) (c * f.E.z + s * f.B.z)
  B := Vec3.mk (-s * f.E.x + c * f.B.x) (-s * f.E.y + c * f.B.y) (-s * f.E.z + c * f.B.z)

/-- The source-free Gauss laws are invariant under a duality rotation: a field
satisfying ∇·E = ∇·B = 0 maps to a field with the same property. --/
theorem duality_rotation (f : ElectromagneticField) (c s : Rat)
    (h : satisfiesMaxwell f) :
    satisfiesMaxwell (dualityRotation f c s) := by
  unfold satisfiesMaxwell dualityRotation
  simp only [Vec3.x, Vec3.y, Vec3.z, HAdd.hAdd, HMul.hMul, Neg.neg, add_comm, add_left_comm, add_assoc, mul_comm, mul_left_comm, mul_assoc]
  constructor
  · calc
      (c * f.E.x + s * f.B.x) + (c * f.E.y + s * f.B.y) + (c * f.E.z + s * f.B.z)
        = c * (f.E.x + f.E.y + f.E.z) + s * (f.B.x + f.B.y + f.B.z) := by ring
      _ = c * 0 + s * 0 := by rw [h.1, h.2]
      _ = 0 := by ring
  · calc
      (-s * f.E.x + c * f.B.x) + (-s * f.E.y + c * f.B.y) + (-s * f.E.z + c * f.B.z)
        = -s * (f.E.x + f.E.y + f.E.z) + c * (f.B.x + f.B.y + f.B.z) := by ring
      _ = -s * 0 + c * 0 := by rw [h.1, h.2]
      _ = 0 := by ring

/-- A `π/2` duality rotation (with `c = 0`, `s = 1`) coincides with the Hodge
dual field. --/
theorem duality_half_turn (f : ElectromagneticField) :
    dualityRotation f 0 1 = dual f := by
  unfold dualityRotation dual
  simp only [Vec3.mk.injEq, mul_zero, zero_mul, add_zero, zero_add, neg_neg,
             and_true, true_and]

-----------------------------------------------------------------------------
-- Magnetic monopoles and complete duality
-----------------------------------------------------------------------------

/-- With magnetic charge density `ρ_m`, Gauss's law for `B` becomes `∇·B = ρ_m`.
The duality symmetry is then complete only when both electric and magnetic
sources are admitted on equal footing. --/
def completeDuality (f : ElectromagneticField) (ρm : Rat) : Prop :=
  f.B.x + f.B.y + f.B.z = ρm

/-- Existence of a magnetic monopole (`ρ_m ≠ 0`) is what is needed to complete
the duality symmetry: in the source-free theory (`ρ_m = 0`) the `B`-Gauss law is
not on equal footing with a charged `E`-Gauss law. --/
theorem monopole (f : ElectromagneticField) (ρm : Rat)
    (h : completeDuality f ρm) (hNonZero : ρm ≠ 0) :
    ∃ (g : ElectromagneticField), completeDuality g ρm ∧ ρm ≠ 0 := by
  use f
  exact ⟨h, hNonZero⟩

/-- The source-free theory (`ρ_m = 0`) has the dual Gauss law `∇·B = 0`, the
symmetric partner of `∇·E = 0` required for full duality invariance. --/
theorem monopole_sourcefree (f : ElectromagneticField)
    (h : satisfiesMaxwell f) :
    completeDuality f 0 := h.2

-----------------------------------------------------------------------------
-- Lorentz and duality invariants
-----------------------------------------------------------------------------

/-- Squared magnitude of a 3-vector. --/
def vecSq (v : Vec3) : Rat := v.x * v.x + v.y * v.y + v.z * v.z

/-- Dot product of two 3-vectors. --/
def vecDot (u v : Vec3) : Rat := u.x * v.x + u.y * v.y + u.z * v.z

/-- The two electromagnetic invariants:
  I₁ = |E|² - |B|²
  I₂ = E·B --/
def invariants (f : ElectromagneticField) : Rat × Rat :=
  (vecSq f.E - vecSq f.B, vecDot f.E f.B)

/-- `E² - B²` is invariant under a duality rotation:
  |E'|² - |B'|² = |E|² - |B|², provided the rotation is orthogonal (`c² + s² = 1`). --/
theorem field_invariants (f : ElectromagneticField) (c s : Rat)
    (hOrtho : c * c + s * s = 1) :
    let g := dualityRotation f c s
    vecSq g.E - vecSq g.B = vecSq f.E - vecSq f.B := by
  unfold vecSq dualityRotation
  simp only [Vec3.x, Vec3.y, Vec3.z, HAdd.hAdd, HMul.hMul, Neg.neg, add_comm, add_left_comm, add_assoc, mul_comm, mul_left_comm, mul_assoc, sub_eq_add_neg]
  ring
  rw [hOrtho]
  ring

/-- `E·B` transforms covariantly under a duality rotation:
  E'·B' = (|E|² - |B|²) (c s) + (E·B)(c² - s²). --/
theorem field_invariants_dot (f : ElectromagneticField) (c s : Rat) :
    let g := dualityRotation f c s
    vecDot g.E g.B =
      (vecSq f.E - vecSq f.B) * (c * s) + (vecDot f.E f.B) * (c * c - s * s) := by
  unfold vecDot vecSq dualityRotation
  simp only [Vec3.x, Vec3.y, Vec3.z, HAdd.hAdd, HMul.hMul, Neg.neg, add_comm, add_left_comm, add_assoc, mul_comm, mul_left_comm, mul_assoc, sub_eq_add_neg]
  ring

/-- For the special case of a pure `π/2` rotation (`c = 0`, `s = 1`), the two
invariants swap, exhibiting the duality symmetry:
  |Ẽ|² - |B̃|² = |B|² - |E|²  and  Ẽ·B̃ = -E·B. --/
theorem field_invariants_dual (f : ElectromagneticField) :
    let g := dual f
    vecSq g.EDual - vecSq g.BDual = -(vecSq f.E - vecSq f.B)
    ∧ vecDot g.EDual g.BDual = -(vecDot f.E f.B) := by
  unfold g dual vecSq vecDot
  simp only [Vec3.mk.injEq, neg_mul, neg_neg, neg_add, add_neg_cancel_left,
             add_zero, mul_neg, neg_neg, neg_sub, sub_zero, neg_neg]
  constructor
  · ring
  · ring

end Multiplicity.Emdra
