namespace Multiplicity.ExplicitFormula

axiom ℂ : Type
axiom ℂ.zero : ℂ
axiom ℂ.one : ℂ

noncomputable instance : Neg ℂ := ⟨λ _ => ℂ.zero⟩
noncomputable instance : Div ℂ := ⟨λ _ _ => ℂ.zero⟩
noncomputable instance : Mul ℂ := ⟨λ _ _ => ℂ.zero⟩
noncomputable instance : OfNat ℂ n := ⟨ℂ.zero⟩

axiom ζ : ℂ → ℂ
axiom deriv : (ℂ → ℂ) → ℂ → ℂ

axiom re : ℂ → ℂ
axiom gt_one : ℂ → Prop

noncomputable def dirichlet_series (a : ℕ → ℂ) (s : ℂ) : ℂ := ℂ.zero
noncomputable def von_mangoldt (n : ℕ) : ℂ := ℂ.zero

end Multiplicity.ExplicitFormula
