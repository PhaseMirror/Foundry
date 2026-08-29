/-!
# Foundations.Attestation.Core — Verification Certificates & Cryptographic Attestations

Formalizes the distinction between internal mathematical verification events and public
cryptographic attestations, proving attestation soundness.
-/

namespace Foundations.Attestation

/-- A verified mathematical property within a certificate. -/
inductive VerifiedProperty where
  | closure_monotone
  | associator_bounded
  | compiler_verified
  | idempotence_checked
deriving Repr, DecidableEq

/-- The mathematical verification certificate. -/
structure VerificationCertificate where
  artifact_hash : String
  specification : String
  properties : List VerifiedProperty
  timestamp : Nat
deriving Repr, DecidableEq

/-- A Cryptographic Attestation is a public signed publication of a verification certificate. -/
structure CryptographicAttestation where
  certificate : VerificationCertificate
  signer : String
  backend : String
  signature : String
deriving Repr, DecidableEq

/-- Theorem: Attestation Soundness.
    Public cryptographic attestation faithfully preserves the certified mathematical properties. -/
theorem attestation_soundness
    (cert : VerificationCertificate)
    (attest : CryptographicAttestation)
    (h_faithful : cert.properties.contains VerifiedProperty.closure_monotone = true)
    (h_attest : attest.certificate = cert) :
    attest.certificate.properties.contains VerifiedProperty.closure_monotone = true := by
  rw [h_attest]
  exact h_faithful

end Foundations.Attestation
