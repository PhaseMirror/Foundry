import MetaRelativityFormalized.Axioms

namespace MetaRelativity

/-- Multiplicity Functor: M(e) = ∏ p^e_p -/
axiom multiplicity : (Nat → Int) → Int

/-- Spectral Invariants check. -/
class SpectralInvariants (H : Type) where
  spectrum : H → List ℝ

end MetaRelativity
