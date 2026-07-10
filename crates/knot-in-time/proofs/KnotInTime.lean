structure Q where
  num : Nat
  den : Nat

instance : LT Q where
  lt a b := a.num * b.den < b.num * a.den

instance (a b : Q) : Decidable (a < b) :=
  inferInstanceAs (Decidable (a.num * b.den < b.num * a.den))

instance : LE Q where
  le a b := a.num * b.den <= b.num * a.den

instance (a b : Q) : Decidable (a <= b) :=
  inferInstanceAs (Decidable (a.num * b.den <= b.num * a.den))

def Q.div (a b : Q) : Q where
  num := a.num * b.den
  den := a.den * b.num

-- Define the constants and types
def DRIFT_THRESHOLD_MAX : Q := Q.mk 17 100

inductive Authority where
  | CA_FED
  | CA_DEFENCE
  | ITAR
  | POLICY_QC
  | OTHER

def get_multiplier : Authority -> Q
  | Authority.CA_FED => Q.mk 10 10
  | Authority.CA_DEFENCE => Q.mk 12 10
  | Authority.ITAR => Q.mk 15 10
  | Authority.POLICY_QC => Q.mk 11 10
  | Authority.OTHER => Q.mk 10 10

def get_effective_threshold (auth : Authority) : Q :=
  Q.div DRIFT_THRESHOLD_MAX (get_multiplier auth)

-- Invariant check definition
abbrev is_stable (auth : Authority) (current_drift : Q) : Prop :=
  current_drift <= get_effective_threshold auth

-- Proof that ITAR is stricter than CA_FED
theorem itar_stricter : get_effective_threshold Authority.ITAR < get_effective_threshold Authority.CA_FED := by
  decide
