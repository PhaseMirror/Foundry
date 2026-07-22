import Core.prime_tensors.Crmf
open ADR.MOC Core.prime_tensors.Crmf

theorem resonance_preserves_contraction_proof (op : MocOperator) (term : CrmfResonanceTerm)
  (h_res : term.resonance_predicate = true)
  (h_contract : op.spectral_radius < 1.0) :
  (activate_resonance op term h_res).spectral_radius < 1.0 := by
  sorry
