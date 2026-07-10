import ALP.Constitution.Model
import Mathlib

namespace ALP.Constitution.L0

def LAMBDA_M_THRESHOLD : Float := 0.1
def CIRCUIT_BREAKER_THRESHOLD : Nat := 3

def isPrime (n : Nat) : Bool :=
  match n with
  | 0 | 1 => false
  | 2 => true
  | 3 => true
  | n =>
    if n % 2 == 0 || n % 3 == 0 then false
    else
      let rec aux (i : Nat) : Bool :=
        if i * i > n then true
        else if n % i == 0 || n % (i + 2) == 0 then false
        else aux (i + 6)
      aux 5

def l0_1_state_norm_bounded (c : ConstitutionModel) : Bool :=
  c.state_norm.isFinite && c.state_norm > 0

def l0_2_drift_rate_bounded (c : ConstitutionModel) : Bool :=
  let threshold := c.dynamic_lambda_m.getD LAMBDA_M_THRESHOLD
  c.drift_rate < threshold

def l0_3_critique_gates_passed (c : ConstitutionModel) : Bool :=
  c.critique_results.length == 10 &&
  c.critique_results.all (·.passed)

def l0_4_prime_gates_satisfied (c : ConstitutionModel) : Bool :=
  c.prime_gates.all (fun g => isPrime g.gate_value)

def l0_5_lambda_m_compliant (c : ConstitutionModel) : Bool :=
  c.contractivity_score > 0 && c.contractivity_score <= 1.0

def l0_6_kill_switch_not_active (c : ConstitutionModel) : Bool :=
  !c.kill_switch_active

def l0_7_circuit_breaker_not_tripped (c : ConstitutionModel) : Bool :=
  c.consecutive_failures < CIRCUIT_BREAKER_THRESHOLD

def l0_9_proof_anchor_recognized (c : ConstitutionModel) : Bool :=
  match c.proof_anchor with
  | none => true
  | some anchor =>
    if c.active_anchors.isEmpty then true
    else c.active_anchors.contains anchor

def validate (c : ConstitutionModel) : Bool :=
  l0_1_state_norm_bounded c &&
  l0_2_drift_rate_bounded c &&
  l0_3_critique_gates_passed c &&
  l0_4_prime_gates_satisfied c &&
  l0_5_lambda_m_compliant c &&
  l0_6_kill_switch_not_active c &&
  l0_7_circuit_breaker_not_tripped c &&
  l0_9_proof_anchor_recognized c

end ALP.Constitution.L0
