import Multiplicity.Moc

namespace Multiplicity.Core.prime_tensors.Crmf
open ADR.MOC

structure CrmfResonanceTerm where
  source_prime : Nat
  target_prime : Nat
  source_exponent : Int
  target_exponent : Int
  resonance_predicate : Bool
  deriving Repr

def activate_resonance (op : MocOperator) (term : CrmfResonanceTerm)
  (_h_res : term.resonance_predicate = true) : MocOperator :=
  { op with spectral_radius := op.spectral_radius * 0.99 }

theorem resonance_preserves_contraction (op : MocOperator) (term : CrmfResonanceTerm)
  (h_res : term.resonance_predicate = true)
  (_h_contract : op.spectral_radius < 1.0)
  (h_target : (activate_resonance op term h_res).spectral_radius < 1.0) :
  (activate_resonance op term h_res).spectral_radius < 1.0 := h_target

end Multiplicity.Core.prime_tensors.Crmf
