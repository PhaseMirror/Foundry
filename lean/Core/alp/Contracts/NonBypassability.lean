import Core.alp.PolicyEngine.Core

namespace ALP.Contracts.NonBypassability

open ALP.Types

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

/--
No action may be executed at the ALP gate unless a prior AlpCheck transition
has recorded a successful check for the same action.
-/
axiom no_unaligned_execution :
  ∀ (trace : List (SystemState × Transition)) (a : Action),
  (SystemState.Execute a, Transition.ExecuteAction a) ∈ trace →
    (SystemState.AlpGate a true, Transition.AlpCheck a) ∈ trace

end ALP.Contracts.NonBypassability
