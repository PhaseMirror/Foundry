import Init

/-! # Knot In Time — Stability Proofs (Pure Lean 4) -/

-- Constitutional Anchor (Class A) from ADR-001
def DRIFT_FLOOR : Rat := 17 / 100

-- Threshold mapping
inductive Authority where
  | CA_FED
  | CA_DEFENCE
  | ITAR
  | POLICY_QC
  | OTHER
  deriving Repr, DecidableEq

def get_multiplier : Authority -> Rat
  | Authority.CA_FED => 1
  | Authority.CA_DEFENCE => 6 / 5
  | Authority.ITAR => 3 / 2
  | Authority.POLICY_QC => 11 / 10
  | Authority.OTHER => 1

def get_effective_threshold (auth : Authority) : Rat :=
  DRIFT_FLOOR / get_multiplier auth

-- Core Invariant: Stability definition
def is_stable (auth : Authority) (current_drift : Rat) : Prop :=
  current_drift <= get_effective_threshold auth

-- Mandatory Collapse Condition (Article II)
def mandatory_collapse (auth : Authority) (current_drift : Rat) : Prop :=
  current_drift > get_effective_threshold auth

-- Proof: ITAR is strictly more conservative than CA_FED
theorem itar_stricter : get_effective_threshold Authority.ITAR < get_effective_threshold Authority.CA_FED := by
  dsimp [get_effective_threshold, get_multiplier, DRIFT_FLOOR]
  decide
