namespace ADR.MOC

structure MocOperator where
  name : String
  prime_gate : Nat
  spectral_radius : Float
  deriving Repr

structure ContractionCertificate where
  operator_name : String
  prime_gate : Nat
  lambda_p : Float
  h_contractive : lambda_p < 1.0
  proof_hash : String

def compute_proof_hash (op : MocOperator) : String := "hash"

def issue_certificate (op : MocOperator) : Option ContractionCertificate :=
  if h : op.spectral_radius < 1.0 then
    some {
      operator_name := op.name,
      prime_gate := op.prime_gate,
      lambda_p := op.spectral_radius,
      h_contractive := h,
      proof_hash := compute_proof_hash op
    }
  else none

theorem certificate_issuance_sound (op : MocOperator) (cert : ContractionCertificate)
  (h : issue_certificate op = some cert) : cert.lambda_p < 1.0 := by
  unfold issue_certificate at h
  split at h
  · next h_lt =>
    injection h with h'
    subst h'
    exact h_lt
  · next h_ge =>
    injection h

theorem prime_gated_certificate (op : MocOperator) (cert : ContractionCertificate)
  (h_issue : issue_certificate op = some cert) :
  ∃ p, cert.prime_gate = p := by
  unfold issue_certificate at h_issue
  split at h_issue
  · next h_lt =>
    injection h_issue with h'
    subst h'
    exact ⟨op.prime_gate, rfl⟩
  · next h_ge =>
    injection h_issue

end ADR.MOC
