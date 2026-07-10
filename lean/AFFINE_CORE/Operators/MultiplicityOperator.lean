import AffineCore.Foundations.BanachSpace

-- Use a Banach space E
variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℂ E] [CompleteSpace E]

/--
Multiplicity Operator Φ^op = Λ_m(t) · I.
Scalar multiple of identity.
Formalizes Theorem C1.
-/
noncomputable def MultiplicityOp (Λ : ℂ) : E →L[ℂ] E :=
  Λ • ContinuousLinearMap.id ℂ E

/--
Its operator norm is exactly |Λ_m| if the space is non-trivial.
-/
theorem multiplicity_op_norm [Nontrivial E] (Λ : ℂ) :
    ‖MultiplicityOp (E := E) Λ‖ = ‖Λ‖ := by
  simp [MultiplicityOp, ContinuousLinearMap.norm_smul,
        ContinuousLinearMap.norm_id]
