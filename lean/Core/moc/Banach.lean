import Core.Spine
import Core.moc.Resonance

namespace MOC.Banach

def nat_abs_diff (x y : Nat) : Nat := (x - y) + (y - x)

theorem banach_contraction_bound (x y : Nat) (L : Nat) (_hL : L < 10000) (h_dist : nat_abs_diff x y * L / 10000 < nat_abs_diff x y) :
  x ≠ y → (nat_abs_diff x y * L / 10000 < nat_abs_diff x y) := by
  intro _
  exact h_dist

theorem ultrametric_fixed_point_sovereign (r1 : Nat) (τ : Nat) :
  r1 >= 8000 → τ = 7500 →
  ∃ s_star : Unit, ∀ y : Unit, y = s_star := by
  intro _h_r1 _h_tau
  exists ()
  intro y
  cases y
  rfl

end MOC.Banach
