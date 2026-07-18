import Core.alp.PolicyEngine.Core

namespace ALP.Contracts.NonBypassability

-- Operational semantics stubs; full model in Integration.lean
inductive SystemState
  | Idle
  | AlpGate (a : Action) (result : Bool)
  | Execute (a : Action)
  | ArchivumRecord (witness_id : String)

inductive Transition
  | Start (a : Action)
  | AlpCheck (a : Action)
  | ExecuteAction (a : Action)
  | RecordWitness (a : Action) (witness_id : String)

axiom no_unaligned_execution :
  ∀ (trace : List (SystemState × Transition)) (a : ALP.Types.Action),
  (SystemState.Execute a, Transition.ExecuteAction a) ∈ trace →
    (SystemState.AlpGate a true, Transition.AlpCheck a) ∈ trace

end ALP.Contracts.NonBypassability
