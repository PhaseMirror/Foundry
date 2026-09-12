/-!
# Banach Space Foundations

Provides minimal definitions for normed and Banach spaces.
-/

namespace Multiplicity.foundations

/-- A normed vector space over a field . -/
class NormedSpace (K : Type*) (E : Type*) [Norm K] [Norm E] extends AddCommGroup E, Module K E :=
  (norm_smul : ∀ (c : K) (x : E), ‖c • x‖ = ‖c‖ * ‖x‖)

/-- A Banach space is a complete normed space. -/
class BanachSpace (K : Type*) (E : Type*) [NormedSpace K E] extends CompleteSpace E :=
  ()

end Multiplicity.foundations
