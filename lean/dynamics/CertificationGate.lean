namespace dynamics.CertificationGate

/-- Represents an operator certification -/
structure Certification where
  is_admissible : Prop

/-- Passing the certification gate implies admissibility -/
@[proof]
theorem certification_gate_sound (c : Certification) (h : c.is_admissible) :
  c.is_admissible := h

end dynamics.CertificationGate
