import Core.Moc

namespace ADR.CRMF
open ADR.MOC

structure CrmfResonanceTerm where
  source_prime : Nat
  target_prime : Nat
  source_exponent : Int
  target_exponent : Int
  resonance_predicate : Bool
  deriving Repr

def activate_resonance (op : MocOperator) (term : CrmfResonanceTerm)
  (h_res : term.resonance_predicate = true) : MocOperator :=
  { op with spectral_radius := op.spectral_radius * 0.99 }

theorem resonance_preserves_contraction (op : MocOperator) (term : CrmfResonanceTerm)
  (h_res : term.resonance_predicate = true)
  (h_contract : op.spectral_radius < 1.0) :
  (activate_resonance op term h_res).spectral_radius < 1.0 := by
  unfold activate_resonance
  have : op.spectral_radius * 0.99 < 1.0 := by
    have : 0.99 < 1 := by norm_num
    have : op.spectral_radius < 1 := h_contract
    exact mul_lt_iff_lt_right (by norm_num).2 (by linarith)
  exact this

end ADR.CRMF
