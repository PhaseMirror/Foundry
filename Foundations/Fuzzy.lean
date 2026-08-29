import Multiplicity.Spine
import moc.Rational

namespace Multiplicity.MOC.Fuzzy

-- ... [Keep existing definitions] ...

theorem union_non_expansive {X : Type*} : IsNonExpansive (@union X) := by
  unfold IsNonExpansive union membership
  intro f g h x
  exact MOC.Rational.abs_max_diff (f x) (g x) (h x)

end Multiplicity.MOC.Fuzzy

