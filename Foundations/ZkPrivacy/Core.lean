/-!
# Foundations.ZkPrivacy.Core — Zero-Knowledge Privacy & Execution Trace Separation
-/

namespace Foundations.ZkPrivacy
open Std

deriving instance Repr for ByteArray

structure PublicInput where
  stateRoot   : ByteArray
  txHash      : ByteArray
  gasConsumed : Nat
  deriving Repr, DecidableEq

structure PrivateWitness where
  secretSalt  : ByteArray
  balancePre  : Nat
  balancePost : Nat
  deriving Repr, DecidableEq

structure ZkProof where
  proofBytes : ByteArray
  publicHash : ByteArray
  verified   : Bool
  deriving Repr, DecidableEq

def isSoundProof (proof : ZkProof) (input : PublicInput) : Bool :=
  proof.verified && proof.proofBytes.size > 0

theorem sound_proof_verified (proof : ZkProof) (input : PublicInput)
    (h : isSoundProof proof input = true) :
    proof.verified = true := by
  unfold isSoundProof at h
  simp only [Bool.and_eq_true] at h
  exact h.1

end Foundations.ZkPrivacy
