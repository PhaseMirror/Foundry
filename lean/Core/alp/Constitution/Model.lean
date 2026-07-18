import Core.alp.Basic

namespace ALP.Constitution

structure ConstitutionViolation where
  invariant : String
  detail : String

structure CritiqueResult where
  critique_id : Nat
  passed : Bool
  reason : Option String

structure PrimeGate where
  action_name : String
  gate_value : Nat

structure ConstitutionModel where
  state_norm : Float
  drift_rate : Float
  dynamic_lambda_m : Option Float
  critique_results : List CritiqueResult
  prime_gates : List PrimeGate
  contractivity_score : Float
  kill_switch_active : Bool
  rollback_anchor_sha : Option String
  proof_anchor : Option String
  audit_warnings : List String
  active_anchors : List String
  consecutive_failures : Nat

end ALP.Constitution
