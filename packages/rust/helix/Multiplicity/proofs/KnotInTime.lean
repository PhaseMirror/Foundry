-- Define the constants and types
def DRIFT_THRESHOLD_MAX : Float := 0.17

inductive Authority where
  | CA_FED
  | CA_DEFENCE
  | ITAR
  | POLICY_QC
  | OTHER

def get_multiplier : Authority -> Float
  | Authority.CA_FED => 1.0
  | Authority.CA_DEFENCE => 1.2
  | Authority.ITAR => 1.5
  | Authority.POLICY_QC => 1.1
  | Authority.OTHER => 1.0

def get_effective_threshold (auth : Authority) : Float :=
  DRIFT_THRESHOLD_MAX / get_multiplier auth

-- Invariant check definition
def is_stable (auth : Authority) (current_drift : Float) : Prop :=
  current_drift <= get_effective_threshold auth

-- Proof that ITAR is stricter than CA_FED
theorem itar_stricter : get_effective_threshold Authority.ITAR < get_effective_threshold Authority.CA_FED := by
  simp [get_effective_threshold, get_multiplier, DRIFT_THRESHOLD_MAX]
  -- 0.17 / 1.5 < 0.17 / 1.0
  norm_num
