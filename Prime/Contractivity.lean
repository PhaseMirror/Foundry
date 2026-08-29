import Mathlib.Data.Real.Basic

namespace Prime.Contractivity

/--
  Simple scalar contraction identity on the reals.
  For any real numbers `γ`, `η`, `S` satisfying
  `0 < γ` and `γ < 1`, `η ≥ 0`, `S ≥ 0`, and `S + η ≠ 0`,
  we have `(γ / (S + η)) * (S + η) = γ`.
--/
theorem scalar_contraction
  (γ η S : ℝ)
  (hγpos : 0 < γ) (hγlt1 : γ < 1) (hη : 0 ≤ η) (hS : 0 ≤ S) (hne : S + η ≠ 0) :
    (γ / (S + η)) * (S + η) = γ := by
  field_simp [hne]
  ring

end Prime.Contractivity
