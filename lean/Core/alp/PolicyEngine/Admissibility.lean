import Core.alp.PolicyEngine.Core
import Core.alp.Constitution.L0

namespace ALP.PolicyEngine.Admissibility

open ALP.PolicyEngine ALP.Types ALP.Constitution.L0

theorem validate_action_sound (pe : PolicyEngine) (a : Action) (t : TrustLevel)
    (h : (validate_action pe a t).allowed = true) :
    validate pe.constitution = true := by
  unfold validate_action at h
  split at h
  · simp_all
  · next => simp_all
  · next =>
      split at h
      · simp_all
      · split at h <;> simp_all

theorem validate_action_veto_implies_constitution_fail (pe : PolicyEngine) (a : Action)
    (t : TrustLevel) (h : validate_action pe a t =
      { allowed := false, reason := "Vetoed by constitutional policy" }) :
    validate pe.constitution = false := by
  unfold validate_action at h
  split at h
  · next heq => exact heq
  · next _ h' => exact absurd h' (by intro hcon; simp at h)
  · next =>
      split at h
      · next _ h' => exact absurd h' (by intro hcon; simp at h)
      · split at h
        · next _ h' => exact absurd h' (by intro hcon; simp at h)
        · next _ h' => exact absurd h' (by intro hcon; simp at h)

end ALP.PolicyEngine.Admissibility
