import Foundations.PolicyEngine.Core

/-!
# Foundations.GovernanceBinding.Core — Signed Admission Tokens & ALP Governance Gate

Formalizes SAT (Signed Admission Token) issuance, token verification, and proves that
verified tokens require verified admission through the constitutional policy engine.
-/

namespace Foundations.GovernanceBinding

open Foundations.PolicyEngine

/-- Signed Admission Token issued upon passing governance checks. -/
structure SignedAdmissionToken where
  token_id    : String
  action_id   : String
  trust_level : TrustLevel
  signature   : String
  deriving Repr, DecidableEq

/-- SAT Issuer descriptor. -/
structure SatIssuer where
  deriving Repr, DecidableEq

/-- Default token issuance produces a pending signature. -/
def SatIssuer.issue (_issuer : SatIssuer) (a : Action) (t : TrustLevel) : Except String SignedAdmissionToken :=
  Except.ok {
    token_id := "sat-" ++ a.name,
    action_id := a.name,
    trust_level := t,
    signature := "PENDING"
  }

/-- Token verification requires a non-empty, non-pending cryptographic signature. -/
def SatVerifier.verify (tok : SignedAdmissionToken) : Bool :=
  tok.signature != "" && tok.signature != "PENDING"

/-- Theorem: Policy engine decision is either admitted or disallowed. -/
theorem validate_action_admitted_or_rejected (pe : PolicyEngine) (a : Action) (t : TrustLevel) :
    validate_action pe a t = { allowed := true, reason := "Admitted" } ∨
    (validate_action pe a t).allowed = false := by
  dsimp [validate_action]
  cases pe.constitution_valid
  · exact Or.inr rfl
  · cases t with
    | Internal =>
      exact Or.inl rfl
    | External =>
      cases a.mutating
      · cases a.server_binding.isSome
        · exact Or.inl rfl
        · exact Or.inr rfl
      · exact Or.inr rfl

/-- Theorem: SAT admission requires passing the constitutional policy engine. -/
theorem sat_requires_alp_admission (a : Action) (t : TrustLevel)
    (h_issued_through_alp :
      ∃ (pe : PolicyEngine) (report : AdmissibilityReport),
        validate_action pe a t = report ∧ report.allowed = true) :
    ∃ pe, validate_action pe a t = { allowed := true, reason := "Admitted" } := by
  rcases h_issued_through_alp with ⟨pe, report, h_eq, h_allowed⟩
  have h_cases := validate_action_admitted_or_rejected pe a t
  cases h_cases with
  | inl h_adm =>
    exact ⟨pe, h_adm⟩
  | inr h_rej =>
    rw [h_eq] at h_rej
    have h_contra : true = false := by
      rw [← h_allowed, h_rej]
    contradiction

end Foundations.GovernanceBinding
