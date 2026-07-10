import ALP.Constitution.L0
import ALP.Types.Action
import ALP.Types.TrustLevel
import ALP.Types.AdmissibilityReport
import ALP.PolicyEngine.Core
import Mathlib

namespace ALP.Tests.L0

open ALP.Constitution.L0
open ALP.Types
open ALP.PolicyEngine

-- Fixture: valid constitution
def validConstitution : ConstitutionModel := {
  state_norm := 1.0,
  drift_rate := 0.05,
  dynamic_lambda_m := some 0.1,
  critique_results := List.replicate 10 { critique_id := 0, passed := true, reason := none },
  prime_gates := [{ action_name := "test", gate_value := 2 }],
  contractivity_score := 0.9,
  kill_switch_active := false,
  rollback_anchor_sha := some "abc123",
  proof_anchor := some "anchor-1",
  audit_warnings := [],
  active_anchors := ["anchor-1"],
  consecutive_failures := 0
}

-- Fixture: invalid state_norm
def invalidStateNorm : ConstitutionModel := { validConstitution with state_norm := 0.0 }

-- Fixture: invalid drift_rate
def invalidDriftRate : ConstitutionModel := { validConstitution with drift_rate := 0.2 }

-- Fixture: failing critique gate
def failingCritique : ConstitutionModel := {
  validConstitution with
  critique_results := [{ critique_id := 0, passed := false, reason := some "fail" }] ++ List.replicate 9 { critique_id := 0, passed := true, reason := none }
}

-- Fixture: non-prime gate
def nonPrimeGate : ConstitutionModel := { validConstitution with prime_gates := [{ action_name := "test", gate_value := 4 }] }

-- Fixture: kill switch active
def killSwitchActive : ConstitutionModel := { validConstitution with kill_switch_active := true }

-- Fixture: circuit breaker tripped
def circuitBreakerTripped : ConstitutionModel := { validConstitution with consecutive_failures := 3 }

-- Spec-level examples

example : ALP.Constitution.L0.validate validConstitution = true := by
  simp [ALP.Constitution.L0.validate, validConstitution]
  native_decide

example : ALP.Constitution.L0.validate invalidStateNorm = false := by
  simp [ALP.Constitution.L0.validate, invalidStateNorm]
  native_decide

example : ALP.Constitution.L0.validate invalidDriftRate = false := by
  simp [ALP.Constitution.L0.validate, invalidDriftRate]
  native_decide

example : ALP.Constitution.L0.validate failingCritique = false := by
  simp [ALP.Constitution.L0.validate, failingCritique]
  native_decide

example : ALP.Constitution.L0.validate nonPrimeGate = false := by
  simp [ALP.Constitution.L0.validate, nonPrimeGate]
  native_decide

example : ALP.Constitution.L0.validate killSwitchActive = false := by
  simp [ALP.Constitution.L0.validate, killSwitchActive]
  native_decide

example : ALP.Constitution.L0.validate circuitBreakerTripped = false := by
  simp [ALP.Constitution.L0.validate, circuitBreakerTripped]
  native_decide

-- PolicyEngine examples

def validEngine : PolicyEngine := { constitution := validConstitution }

def mutatingAction : Action := { id := "a1", payload := "{}", mutating := true, server_binding := none }
def safeAction : Action := { id := "a2", payload := "{}", mutating := false, server_binding := none }
def boundAction : Action := { id := "a3", payload := "{}", mutating := false, server_binding := some "mcp-1" }

example : (validEngine.validate_action mutatingAction TrustLevel.Internal).allowed = true := by
  simp [PolicyEngine.validate_action, validEngine, validConstitution]
  native_decide

example : (validEngine.validate_action safeAction TrustLevel.External).allowed = true := by
  simp [PolicyEngine.validate_action, validEngine, validConstitution]
  native_decide

example : (validEngine.validate_action mutatingAction TrustLevel.External).allowed = false := by
  simp [PolicyEngine.validate_action, validEngine, validConstitution]
  native_decide

example : (validEngine.validate_action boundAction TrustLevel.External).allowed = false := by
  simp [PolicyEngine.validate_action, validEngine, validConstitution]
  native_decide

end ALP.Tests.L0
