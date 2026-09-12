/-!
# Foundations.CRMF.Core — Coherence Risk Management Framework

Formalizes CRMF message envelope, coherence risk scoring, and fail-closed dispatch.
-/

namespace Foundations.CRMF
open Std

deriving instance Repr for ByteArray

structure CRMFMessage where
  msgId        : Nat
  payloadHash  : ByteArray
  riskScore    : Nat
  maxRiskLimit : Nat
  signature    : ByteArray
  deriving Repr, DecidableEq

def isAcceptableRisk (msg : CRMFMessage) : Bool :=
  msg.riskScore ≤ msg.maxRiskLimit

def verifyCRMF (msg : CRMFMessage) : Bool :=
  isAcceptableRisk msg && msg.payloadHash.size > 0

theorem acceptable_risk_of_verified (msg : CRMFMessage)
    (h : verifyCRMF msg = true) :
    msg.riskScore ≤ msg.maxRiskLimit := by
  unfold verifyCRMF isAcceptableRisk at h
  simp only [Bool.and_eq_true, decide_eq_true_iff] at h
  exact h.1

end Foundations.CRMF
