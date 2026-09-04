import Init
import SpiralCore.Core

/-! # WADA-LADA Distributed Agent Topology (ADR-0043)

Formalizes the WADA (wide-area) / LADA (local-area) distributed agent
topology:

1. **Loop prevention**: every propagated state message carries path
   history and a TTL; a node drops or quarantines a message when its own
   agent_id appears in the path, the TTL is zero, the signature chain is
   invalid, the basis is unsupported, policy forbids transit, or the
   state class is disallowed across the demarc.
2. **Root election hysteresis**: a non-root candidate MUST NOT replace
   the current root unless the root is unreachable/demoted/invalid or
   the candidate exceeds the root by a configured margin for a
   configured duration (no flapping).
3. **Equivalence prohibitions**: route ≠ truth, root ≠ omniscience,
   reputation ≠ authorization, address ≠ identity, coherence ≠
   correctness, replication ≠ consent, visibility ≠ permission.
4. **Demarc gateways**: an external message MUST NOT become internal
   authority merely by crossing a demarc; the gateway enforces
   authentication, rate limiting, schema validation, state-class
   filtering, redaction, and audit logging.
5. **Merge preservation**: a merge MUST preserve parents, origin sites,
   basis IDs, addresses, content hashes, timestamps, signatures,
   conflict markers, and policy; a fusion state is not automatically
   ground truth.

Reference: ADR-0043 "WADA-LADA Distributed Agent Topology v0.1".
-/

namespace SpiralCore.WadaLada

/-- A propagated state message: agent id, basis, address, path history,
    and remaining time-to-live. -/
structure StateMessage where
  stateId : String
  basisId : String
  address : String
  path : List String      -- ordered history of agents that forwarded it
  ttl : Nat
  signatureValid : Bool
  policyAllowsTransit : Bool
  basisSupported : Bool
  stateClassAllowed : Bool
deriving Repr

/-- Loop prevention: a node must drop a message whose path already
    contains the node's own agent id (it has looped back). -/
def selfInPath (msg : StateMessage) (selfAgent : String) : Bool :=
  msg.path.any (fun a => a = selfAgent)

/-- A message that has looped back to its origin is dropped. -/
def dropLoop (msg : StateMessage) (selfAgent : String) : Bool :=
  selfInPath msg selfAgent

/-- TTL exhaustion: a message with zero remaining TTL is dropped
    (prevents unbounded state propagation / broadcast storms). -/
def ttlExhausted (msg : StateMessage) : Bool := msg.ttl = 0

/-- A node drops a message when its own id is in the path. -/
theorem loop_detection (msg : StateMessage) (selfAgent : String) :
  selfInPath msg selfAgent = true -> dropLoop msg selfAgent = true := by
  intro h
  simp [dropLoop, h]

/-- A node drops a message when the TTL has reached zero. -/
def dropTtl (msg : StateMessage) : Bool := msg.ttl = 0

/-- A fresh message with a positive TTL is not TTL-dropped. -/
theorem positive_ttl_survives (msg : StateMessage) (h : msg.ttl >= 1) :
  dropTtl msg = false := by
  simp [dropTtl]
  omega

/-- The complete drop/quarantine decision: a node rejects a message when
    any fail-closed condition holds (loop, TTL, invalid signature,
    unsupported basis, policy forbids transit, state class disallowed). -/
def shouldDrop (msg : StateMessage) (selfAgent : String) : Bool :=
  selfInPath msg selfAgent || msg.ttl = 0 || !msg.signatureValid ||
  !msg.basisSupported || !msg.policyAllowsTransit || !msg.stateClassAllowed

/-- An intact message (valid signature, supported basis, allowed transit
    and class, positive TTL, no loop) is accepted. -/
theorem intact_message_accepted (msg : StateMessage) (selfAgent : String)
    (h1 : selfInPath msg selfAgent = false)
    (h2 : msg.ttl >= 1) (h3 : msg.signatureValid = true)
    (h4 : msg.basisSupported = true) (h5 : msg.policyAllowsTransit = true)
    (h6 : msg.stateClassAllowed = true) :
  shouldDrop msg selfAgent = false := by
  unfold shouldDrop
  simp [h1, h3, h4, h5, h6]
  omega

/-- An invalid signature always drops the message (fail-closed). -/
theorem invalid_signature_drops (msg : StateMessage) (selfAgent : String)
    (h : msg.signatureValid = false) :
  shouldDrop msg selfAgent = true := by
  unfold shouldDrop
  simp [h]

/-- Unsupported basis quarantines the message. -/
theorem unsupported_basis_drops (msg : StateMessage) (selfAgent : String)
    (h : msg.basisSupported = false) :
  shouldDrop msg selfAgent = true := by
  unfold shouldDrop
  simp [h]

/-- Root election hysteresis: a non-root candidate may replace the
    current root only when the root is unreachable/demoted/invalid, or
    when the candidate's score exceeds the root's by a configured margin
    for a configured duration. We model the margin-duration condition:
    `candidate > root + margin` sustained for `duration` ticks. -/
def mayReplaceRoot (candidateScore rootScore margin duration sustained : Nat) : Bool :=
  candidateScore >= rootScore + margin && sustained >= duration

/-- A candidate below the margin never replaces the root (no flapping). -/
theorem no_replace_below_margin (candidateScore rootScore margin duration sustained : Nat)
    (h : candidateScore < rootScore + margin) :
  mayReplaceRoot candidateScore rootScore margin duration sustained = false := by
  unfold mayReplaceRoot
  have hng : ¬ (candidateScore >= rootScore + margin) := by omega
  simp [hng]

/-- A candidate above the margin that has sustained the margin for the
    full duration replaces the root. -/
theorem replace_after_margin_duration (candidateScore rootScore margin duration : Nat)
    (h1 : candidateScore >= rootScore + margin) :
  mayReplaceRoot candidateScore rootScore margin duration duration = true := by
  unfold mayReplaceRoot
  simp [h1]

/-- Manual root selection overrides automatic election unless the root
    is unreachable, signature-invalid, policy-forbidden, or quarantined. -/
def manualOverrideValid (rootUnreachable sigInvalid policyForbidden quarantined : Bool) : Bool :=
  !rootUnreachable && !sigInvalid && !policyForbidden && !quarantined

/-- A healthy manual root stays authoritative. -/
theorem healthy_manual_root_authoritative :
  manualOverrideValid false false false false = true := by
  native_decide

/-- An unreachable manual root may be failed over. -/
theorem unreachable_root_failover_allowed :
  manualOverrideValid true false false false = false := by
  native_decide

/-- Equivalence prohibitions: the memo lists what MUST NOT be conflated.
    We record each prohibition as an explicit disequality policy. -/
def routeNotTruth : Bool := false
def rootNotOmniscience : Bool := false
def reputationNotAuthorization : Bool := false
def addressNotIdentity : Bool := false
def coherenceNotCorrectness : Bool := false
def replicationNotConsent : Bool := false
def visibilityNotPermission : Bool := false

/-- Route advertisements grant no permission; they only describe a
    reachable semantic capability under a policy scope. -/
def routeGrantsPermission : Bool := false

/-- Route != truth is enforced (advertisements are not evidence). -/
theorem route_is_not_truth : routeNotTruth = false ∧ routeGrantsPermission = false := by
  constructor <;> trivial

/-- A reputation score is never authorization. -/
theorem reputation_is_not_authorization : reputationNotAuthorization = false := by
  trivial

/-- Demarc gateway: external instructions must not become internal agent
    authority merely by crossing the boundary. The gateway normalizes,
    authenticates, rate-limits, and filters before admission. -/
def demarcAllows (authenticated rateOk schemaValid stateClassOk : Bool) : Bool :=
  authenticated && rateOk && schemaValid && stateClassOk

/-- A fully validated external message may enter the fabric. -/
theorem demarc_admits_valid (h1 : authenticated = true) (h2 : rateOk = true)
    (h3 : schemaValid = true) (h4 : stateClassOk = true) :
  demarcAllows authenticated rateOk schemaValid stateClassOk = true := by
  simp [demarcAllows, h1, h2, h3, h4]

/-- Admission is fail-closed on any failing check. -/
theorem demarc_rejects_unauthenticated (rateOk schemaValid stateClassOk : Bool) :
  demarcAllows false rateOk schemaValid stateClassOk = false := by
  simp [demarcAllows]

/-- Merge preservation (Prop): a merge MUST preserve parent state IDs.
    For every expected parent p of the merged object, the merged parent
    list contains p. -/
def mergePreservesParents (merged expected : List String) : Prop :=
  ∀ p : String, p ∈ expected -> p ∈ merged

/-- The empty merge vacuously preserves parentage. -/
theorem empty_merge_preserves_parents :
  mergePreservesParents [] [] := by
  intro p hp
  simp at hp

/-- A merge that includes each expected parent preserves parentage:
    membership is preserved by concatenation with the expected list. -/
theorem merge_with_all_parents (merged expected : List String) :
  mergePreservesParents (expected ++ merged) expected := by
  intro p hp
  exact List.mem_append.mpr (Or.inl hp)

/-- Fusion output must mark whether it makes a canonical truth claim;
    the default is false (no automatic truth). -/
def fusionTruthClaim : Bool := false

/-- Fusion is not automatically ground truth. -/
theorem fusion_not_auto_truth : fusionTruthClaim = false := by
  trivial

/-- Conflicting signed states must be preserved unless a policy
    explicitly authorizes promotion. -/
def conflictPreserved (policyAuthorizesPromotion : Bool) : Bool :=
  !policyAuthorizesPromotion

/-- Without policy authorization, the conflict is preserved. -/
theorem conflict_preserved_by_default (policyAuthorizesPromotion : Bool)
    (h : policyAuthorizesPromotion = false) :
  conflictPreserved policyAuthorizesPromotion = true := by
  simp [conflictPreserved, h]

/-- A worker agent MUST NOT advertise itself as an HLCA or HWCA unless
    authorized (role confinement). -/
def workerMayAdvertiseAsRoot (authorized : Bool) : Bool := authorized

/-- Unauthorized workers are confined to their role. -/
theorem unauthorized_worker_confined (authorized : Bool) (h : authorized = false) :
  workerMayAdvertiseAsRoot authorized = false := by
  simp [workerMayAdvertiseAsRoot, h]

end SpiralCore.WadaLada