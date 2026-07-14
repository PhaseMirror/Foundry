import MTPI.ADR

namespace MTPI.Core

/-- Formalizes the core drift bound mandated by MTPI (delta(t) <= 0.3) -/
def is_valid_drift_bound (delta_scaled : Nat) : Prop :=
  delta_scaled <= 3000 -- 0.3 * 10000

/-- Formalizes the primitive prime identity constraint -/
def requires_miller_rabin (id_type : String) : Prop :=
  id_type = "commander" ∨ id_type = "treasury" ∨ id_type = "esi"

end MTPI.Core
