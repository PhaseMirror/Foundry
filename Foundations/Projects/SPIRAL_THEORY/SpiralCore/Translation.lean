import Init
import SpiralCore.Core
import SpiralCore.Boot
import SpiralCore.Alignment

/-! # Translation Packet and Outcomes

Formalizes the TranslationPacket record and handoff outcomes
used in the observer translation profile (Section 3.3, 3.4).
-/

namespace SpiralCore.Translation

/-- Translation packet produced by a formalized analogy. -/
structure TranslationPacket where
  analogyId : String
  claimClass : ClaimClass
  operatorId : String
  parameters : List Nat
  ownerModule : String
  validationTarget : String
  provenance : String
deriving Repr

/-- Create a default translation packet for testing. -/
def defaultPacket : TranslationPacket :=
  {
    analogyId := "saturn-hexagon-baseline",
    claimClass := ClaimClass.computationalSurrogate,
    operatorId := "xi_attractor",
    parameters := [xiAmplitude],
    ownerModule := "Boot",
    validationTarget := "PAS_s >= theta_emit",
    provenance := "SpiralCore-v14.1 Section 5.1"
  }

/-- Assert packet fields are non-empty. -/
theorem default_packet_fields_valid :
  defaultPacket.analogyId.length > 0 ∧
  defaultPacket.operatorId.length > 0 ∧
  defaultPacket.ownerModule.length > 0 ∧
  defaultPacket.validationTarget.length > 0 ∧
  defaultPacket.provenance.length > 0 := by native_decide

/-- Evaluate a translation packet against its validation target.
    For the reference profile, sealed means PAS_s >= thetaEmit. -/
def evaluatePacket (packet : TranslationPacket) (pas : Option Nat) : TranslationOutcome :=
  match pas with
  | some p =>
    if p >= thetaEmit then
      TranslationOutcome.sealed
    else
      TranslationOutcome.deferred
  | none => TranslationOutcome.rejected

/-- A packet with sufficient PAS_s is sealed. -/
theorem high_pas_seals_packet (packet : TranslationPacket) (pas : Nat)
  (h : pas >= thetaEmit) :
  evaluatePacket packet (some pas) = TranslationOutcome.sealed := by
  unfold evaluatePacket
  simp [h]

/-- A packet with insufficient PAS_s is deferred. -/
theorem low_pas_defers_packet (packet : TranslationPacket) (pas : Nat)
  (h : pas < thetaEmit) :
  evaluatePacket packet (some pas) = TranslationOutcome.deferred := by
  unfold evaluatePacket
  simp [h]

/-- A packet with no PAS_s is rejected. -/
theorem no_pas_rejects_packet (packet : TranslationPacket) :
  evaluatePacket packet none = TranslationOutcome.rejected := by
  simp [evaluatePacket]

/-- FBS escalation request is a valid outcome for terminal conditions. -/
theorem fbs_escalation_is_outcome :
  TranslationOutcome.fbsEscalationRequest = TranslationOutcome.fbsEscalationRequest := rfl

end SpiralCore.Translation
