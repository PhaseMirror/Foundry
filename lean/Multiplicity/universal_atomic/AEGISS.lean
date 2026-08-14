namespace Multiplicity.UAC.AEGISS

/-- 
  AEGISS Active Space Selection (ADR-PML-053)
  Score equation: score = alpha * entropy + (1 - alpha) * energy 
  Values are scaled to avoid floating point arithmetic.
-/
def aegiss_score_scaled (entropy_scaled energy_scaled alpha_scaled : Int) (scale : Int := 10000) : Int :=
  (alpha_scaled * entropy_scaled + (scale - alpha_scaled) * energy_scaled) / scale

end Multiplicity.UAC.AEGISS
