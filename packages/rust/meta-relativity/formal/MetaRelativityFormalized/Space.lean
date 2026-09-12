import MetaRelativityFormalized.Axioms

namespace MetaRelativity

/-- Ambient Hilbert Space H := ℓ²(P) ⊗ L²(R) ⊗ ℂ^d -/
structure AmbientHilbertSpace where
  prime_dim : Nat
  time_dim : Nat
  internal_dim : Nat

/-- A state vector in the ambient Hilbert space. -/
axiom MRState : Type

/-- Frame transformation: A unitary map U: H -> H. -/
class FrameTransformation where
  transform : MRState → MRState

/-- Lawfulness Projector P_CSL. -/
class LawfulnessProjector where
  project : MRState → MRState

end MetaRelativity
