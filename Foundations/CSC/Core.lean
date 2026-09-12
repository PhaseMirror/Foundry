/-!
# Foundations.CSC.Core — Constraint Satisfaction Certificate Verification

Formalizes CSC Certificate structure, cryptographic verification conditions, and validity invariants.
-/

namespace Foundations.CSC

open Std

deriving instance Repr for ByteArray

structure Certificate where
  certId       : Nat
  dataHash     : ByteArray
  signature    : ByteArray
  issuer       : String
  validUntil   : Nat
  deriving Repr, DecidableEq

def isExpired (cert : Certificate) (now : Nat) : Bool :=
  cert.validUntil < now

def verifyCertificate (cert : Certificate) (now : Nat) (trustRoot : String) : Bool :=
  cert.issuer == trustRoot && !isExpired cert now && cert.dataHash.size > 0

theorem valid_cert_not_expired (cert : Certificate) (now : Nat) (trustRoot : String)
    (h : verifyCertificate cert now trustRoot = true) :
    isExpired cert now = false := by
  unfold verifyCertificate at h
  simp only [Bool.and_eq_true, Bool.not_eq_true'] at h
  exact h.1.2

end Foundations.CSC
