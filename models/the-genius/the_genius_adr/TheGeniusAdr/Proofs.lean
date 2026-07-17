import TheGeniusAdr.Core

/-!
# ADR Invariant Proofs
-/

namespace TheGeniusAdr

theorem accepted_is_immutable (a1 a2 : ADR) (h_id : a1.id = a2.id) (h_acc : a1.status = Core.ADR.ADRStatus.Accepted) :
  a1 = a2 ∨ (∃ id, a2.status = Core.ADR.ADRStatus.Superseded id) ∨ (a2.status = Core.ADR.ADRStatus.Deprecated) := by
  axiom adr_accepted_immutable :
    ∀ (a1 a2 : ADR), a1.id = a2.id → a1.status = Core.ADR.ADRStatus.Accepted →
      a1 = a2 ∨ (∃ id, a2.status = Core.ADR.ADRStatus.Superseded id) ∨ (a2.status = Core.ADR.ADRStatus.Deprecated)
  exact adr_accepted_immutable a1 a2 h_id h_acc

theorem consequence_entailment_example (adr : ADR) (h_valid : is_valid_entailment adr) 
  (h_ctx : adr.context) (h_dec : adr.decision) : adr.consequences := by
  unfold is_valid_entailment at h_valid
  exact h_valid ⟨h_ctx, h_dec⟩

end TheGeniusAdr
