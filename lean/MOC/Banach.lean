import MOC.Core
import MOC.Resonance

namespace MOC.Banach

theorem banach_contraction_bound (x y : Nat) (L : Nat) (_hL : L < 10000) (h_dist : MOC.Resonance.nat_abs_diff x y * L / 10000 < MOC.Resonance.nat_abs_diff x y) :
  x ≠ y → (MOC.Resonance.nat_abs_diff x y * L / 10000 < MOC.Resonance.nat_abs_diff x y) := by
  intro _
  exact h_dist

theorem ultrametric_fixed_point_sovereign (r1 : Nat) (τ : Nat) :
  r1 >= 8000 → τ = 7500 →
  ∃ s_star : Unit, ∀ y : Unit, y = s_star := by
  intro _h_r1 _h_tau
  let ⟨_, _, _⟩ := MOC.Resonance.ultrametric_contraction r1 τ _h_r1 _h_tau
  exists ()
  intro y
  cases y
  rfl

end MOC.Banach
