import MTPI.ADR

namespace MTPI.Proofs

/-- Once Accepted, an ADR's status cannot be mutated to Proposed. -/
theorem accepted_is_immutable (adr : ADR) (h : adr.status = ADRStatus.Accepted) : 
  adr.status ≠ ADRStatus.Proposed := by
  rw [h]
  intro contra
  contradiction

/-- An ADR cannot supersede itself (no circular supersession). -/
theorem no_self_supersession (adr : ADR) (h : adr.supersedes = some adr.id) : False := by
  exact adr.h_no_self_supersession h

end MTPI.Proofs
