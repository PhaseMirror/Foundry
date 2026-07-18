namespace dynamics.ZenoContractivity

def iterate (f : Nat → Nat) : Nat → Nat → Nat
  | 0, x => x
  | n + 1, x => f (iterate f n x)

/-- Zeno contractivity: operator converges in finite steps -/
def is_zeno_contractive (T : Nat → Nat) (x : Nat) (n : Nat) : Prop :=
  iterate T n x = iterate T (n+1) x

theorem zeno_contractivity_preserved (T₁ T₂ : Nat → Nat) (x : Nat)
  (h_z1 : is_zeno_contractive T₁ x 0)
  (h_z2 : is_zeno_contractive T₂ (T₁ x) 0) :
  is_zeno_contractive (T₂ ∘ T₁) x 0 := by
  unfold is_zeno_contractive at *
  dsimp [iterate, Function.comp] at *
  calc
    x = T₁ x := h_z1
    _ = T₂ (T₁ x) := h_z2

end dynamics.ZenoContractivity
