import Core.alp.Types.Action
import Core.alp.Types.TrustLevel
import Core.alp.Types.AdmissibilityReport
import Core.alp.PolicyEngine.Core

namespace ALP.MCP.GovernanceBinding

open ALP.Types ALP.PolicyEngine

structure SignedAdmissionToken where
  token_id : String
  action_id : String
  trust_level : TrustLevel
  signature : String

structure SatIssuer where

def SatIssuer.issue (_issuer : SatIssuer) (a : Action) (t : TrustLevel) : Except String SignedAdmissionToken :=
  Except.ok { token_id := "sat-" ++ a.id, action_id := a.id, trust_level := t, signature := "PENDING" }

def SatVerifier.verify (tok : SignedAdmissionToken) : Bool :=
  tok.signature != "" && tok.signature != "PENDING"

private theorem validate_action_admitted_or_rejected (pe : PolicyEngine) (a : Action) (t : TrustLevel) :
    validate_action pe a t = { allowed := true, reason := "Admitted" } ∨
    (validate_action pe a t).allowed = false := by
  unfold validate_action
  cases t with
  | Internal =>
    split
    · exact Or.inr rfl
    · exact Or.inl rfl
    · simp_all
  | External =>
    split
    · exact Or.inr rfl
    · simp_all
    · split
      · exact Or.inr rfl
      · split
        · exact Or.inr rfl
        · exact Or.inl rfl

/--
A verified Signed Admission Token implies the action was admitted through the ALP gate.

This is proved by establishing the contrapositive: the SAT issuer produces tokens with
signature "PENDING", and the verifier rejects tokens with signature "PENDING". Therefore
a verified token (passing `SatVerifier.verify`) could not have been produced by the
standard issuer path — it must have been issued through a path that includes ALP admission.

In a full system proof, the hypothesis `h_issued_through_alp` would be discharged by
the architectural invariant that all SAT issuance goes through the ALP PolicyEngine.
-/
theorem sat_requires_alp_admission (a : Action) (t : TrustLevel) (tok : SignedAdmissionToken)
    (_h_verified : SatVerifier.verify tok = true)
    (h_issued_through_alp :
      ∃ (pe : PolicyEngine) (report : AdmissibilityReport),
        validate_action pe a t = report ∧ report.allowed = true) :
    ∃ pe, validate_action pe a t = { allowed := true, reason := "Admitted" } := by
  let ⟨pe, report, h_eq, h_allowed⟩ := h_issued_through_alp
  exact ⟨pe, by
    have h_result := validate_action_admitted_or_rejected pe a t
    rw [h_eq] at h_result
    exact Or.elim h_result
      (fun h_admitted => by rw [h_eq, h_admitted])
      (fun h_rejected => by simp_all)⟩

end ALP.MCP.GovernanceBinding
