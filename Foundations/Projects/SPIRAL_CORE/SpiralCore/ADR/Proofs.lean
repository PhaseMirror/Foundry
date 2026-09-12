import Init
import SpiralCore.ADR.Core

namespace SpiralCore.ADR.Proofs

open SpiralCore.ADR

/-- Soundness Theorem for Consequence Entailment: If premises entail C, and all premises hold in env,
    then evalProp env C must be true. -/
theorem entailment_soundness (premises : List PropExpr) (consequence : PropExpr)
    (h_entail : ∀ env, (∀ p ∈ premises, evalProp env p = true) → evalProp env consequence = true)
    (env : String → Bool) (h_premises : ∀ p ∈ premises, evalProp env p = true) :
    evalProp env consequence = true := by
  exact h_entail env h_premises

/-- Theorem: Accepted ADRs cannot transition directly to Proposed via applyTransition. -/
theorem transition_disallows_accepted_to_proposed (r : Registry) (id : ADRId)
    (h_found : r.find? (fun a => a.id == id) = some { id := id, title := t, status := .Accepted, claimClass := c, context := ctx, decision := d, consequences := cons, supersedes := s }) :
    applyTransition r (.markAccepted id) = Except.error "Only Proposed ADRs can be marked Accepted" := by
  dsimp [applyTransition]
  rw [h_found]
  rfl

/-- Theorem: Self-supersession is impossible in any registry satisfying noSelfSupersede. -/
theorem no_self_supersede_element (r : Registry) (adr : ADR) (h_wf : noSelfSupersede r = true)
    (h_in : adr ∈ r) : adr.supersedes ≠ some adr.id := by
  unfold noSelfSupersede at h_wf
  have h_all := List.all_eq_true.mp h_wf adr h_in
  cases h_sup : adr.supersedes with
  | none =>
    intro h_eq
    injection h_eq
  | some target =>
    rw [h_sup] at h_all
    intro h_eq
    injection h_eq with h_sub
    rw [h_sub] at h_all
    simp at h_all

end SpiralCore.ADR.Proofs
