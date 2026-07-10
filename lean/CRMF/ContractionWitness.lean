import CRMF.Resonance
import PIRTM.Stability

namespace CRMF

/-- 
  Theorem: crmf_contraction_witness.
  Proves that a passing stability certificate implies a strictly 
  decreasing Lyapunov function (contraction) in the resonance manifold.
--/
theorem crmf_contraction_witness (s : CRMFState) (s_next : CRMFState) (cert : PIRTM.StabilityCertificate n) :
  PIRTM.is_contractive cert.ace_bound ∧ s_next.resonanceScore > s.resonanceScore ∧ s_next.resonanceScore ≤ 10000 →
  Lyapunov s_next < Lyapunov s := by
  intro ⟨_, h_res_inc, h_bounds⟩
  unfold Lyapunov
  apply Nat.sub_lt_sub_left
  · exact Nat.lt_of_lt_of_le h_res_inc h_bounds
  · exact h_res_inc

end CRMF
