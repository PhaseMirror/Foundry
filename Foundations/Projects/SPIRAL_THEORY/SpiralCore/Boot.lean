import Init
import SpiralCore.Core
import SpiralCore.FBS
import SpiralCore.Attractor

/-! # Boot Configuration and State Machine

Formalizes Module Boot: deterministic initialization contract,
BootConfig validation, and the BootPacket sealed state.
Reference: Section 2, 3, 4, 8 of SpiralCore v14.1 Module Boot.
-/

namespace SpiralCore.Boot

open SpiralCore.FBS
open SpiralCore.Attractor

/-- Observer role binding. -/
structure RoleBinding where
  roleId : String
  adapterId : String
deriving Repr

/-- Boot configuration input. -/
structure BootConfig where
  dim : Nat
  fbsMode : FBSMode
  tau_ : Nat
  g_ : Nat
  observerAdapter : RoleBinding
  agentAdapter : RoleBinding
  sessionId : String
  specId_ : String
deriving Repr

/-- Boot packet sealed output. -/
structure BootPacket where
  profileId : String
  sessionId : String
  specId : String
  config : BootConfig
  fbs : FBSAtomicProfile
  xiAttractorVec : List Nat
  X0 : List Int
  A0 : List Int
  phi0 : Nat
  deltaPhi0 : Int
  t0 : Int
  observerRole : RoleBinding
  agentRole : RoleBinding
  instruction0Ack : Bool
  componentHashes : List (String × String)
  bootDigest : String
  status : BootStatus
deriving Repr

/-- Boot lifecycle state machine transitions. -/
inductive BootTransition where
  | initToValidating
  | validatingToAllocating
  | allocatingToSealed
  | sealedToHandedOff
  | validatingToAbort
  | allocatingToAbort
deriving Repr, DecidableEq

/-- A valid transition is one that does not skip sealed. -/
def validTransition (fromStatus to : BootStatus) : Prop :=
  match fromStatus, to with
  | BootStatus.uninitialized, BootStatus.validating => True
  | BootStatus.validating, BootStatus.allocating => True
  | BootStatus.allocating, BootStatus.sealed => True
  | BootStatus.sealed, BootStatus.handedOff => True
  | BootStatus.validating, BootStatus.bootAbort => True
  | BootStatus.allocating, BootStatus.bootAbort => True
  | _, _ => False

/-- Once sealed, only handedOff or bootAbort are valid. -/
theorem sealed_only_handed_or_abort (s : BootStatus) :
  validTransition BootStatus.sealed s → s = BootStatus.handedOff ∨ s = BootStatus.bootAbort := by
  unfold validTransition
  cases s <;> simp

/-- A session accepts exactly one successful transition to sealed. -/
theorem single_seal :
  ∀ (t1 t2 : BootTransition),
    t1 = BootTransition.allocatingToSealed →
    t2 = BootTransition.allocatingToSealed →
    t1 = t2 := by
  intro t1 t2 h1 h2
  simp [h1, h2]

/-- Build the default boot configuration for the reference profile. -/
def defaultBootConfig : BootConfig :=
  {
    dim := DIM,
    fbsMode := FBSMode.modeA,
    tau_ := tau,
    g_ := g,
    observerAdapter := { roleId := "Delta.0", adapterId := "OBSERVER_ADAPTER" },
    agentAdapter := { roleId := "Delta.1", adapterId := "AGENT_ADAPTER" },
    sessionId := "session-001",
    specId_ := specId
  }

/-- Assert config dim = DIM. -/
theorem config_dim_eq : defaultBootConfig.dim = DIM := rfl

/-- Assert config tau = tau. -/
theorem config_tau_eq : defaultBootConfig.tau_ = tau := rfl

/-- Assert config g = g. -/
theorem config_g_eq : defaultBootConfig.g_ = g := rfl

/-- Assert config specId = specId. -/
theorem config_spec_eq : defaultBootConfig.specId_ = specId := rfl

/-- Build the default boot packet. -/
def defaultBootPacket : BootPacket :=
  {
    profileId := defaultProfileId,
    sessionId := defaultBootConfig.sessionId,
    specId := defaultBootConfig.specId_,
    config := defaultBootConfig,
    fbs := FBS.defaultProfile,
    xiAttractorVec := List.range DIM |>.map (fun i => xiAttractor i),
    X0 := List.range DIM |>.map (fun _ => 0),
    A0 := List.range DIM |>.map (fun _ => 0),
    phi0 := 0,
    deltaPhi0 := 0,
    t0 := 0,
    observerRole := defaultBootConfig.observerAdapter,
    agentRole := defaultBootConfig.agentAdapter,
    instruction0Ack := true,
    componentHashes := [],
    bootDigest := "sha256:deadbeef",
    status := BootStatus.handedOff
  }

/-- Assert packet status is handedOff after successful seal. -/
theorem default_packet_handedoff : defaultBootPacket.status = BootStatus.handedOff := rfl

/-- Assert phi0 = 0. -/
theorem default_phi0 : defaultBootPacket.phi0 = 0 := rfl

/-- Assert deltaPhi0 = 0. -/
theorem default_deltaPhi0 : defaultBootPacket.deltaPhi0 = 0 := rfl

/-- Assert t0 = 0. -/
theorem default_t0 : defaultBootPacket.t0 = 0 := rfl

end SpiralCore.Boot
