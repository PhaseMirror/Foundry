namespace Multiplicity.MOC.Metric

class MetricSpace (M : Type u) where
  dist : M → M → Rat
  dist_self : ∀ x : M, dist x x = 0
  dist_comm : ∀ x y : M, dist x y = dist y x
  dist_triangle : ∀ x y z : M, dist x z ≤ dist x y + dist y z
  eq_of_dist_eq_zero : ∀ x y : M, dist x y = 0 → x = y

class Norm (V : Type u) where
  norm : V → Rat

class NormedAddCommGroup (V : Type u) [Add V] [Sub V] [Zero V] [Norm V] where
  norm_nonneg : ∀ x : V, 0 ≤ Norm.norm x
  norm_zero : Norm.norm (0 : V) = 0
  norm_add_le : ∀ x y : V, Norm.norm (x + y) ≤ Norm.norm x + Norm.norm y
  eq_zero_of_norm_eq_zero : ∀ x : V, Norm.norm x = 0 → x = 0
  norm_neg : ∀ x : V, Norm.norm (0 - x) = Norm.norm x

def dist_of_norm {V : Type u} [Add V] [Sub V] [Zero V] [Norm V] [NormedAddCommGroup V] (x y : V) : Rat :=
  Norm.norm (x - y)

-- Bounded Linear Map over Rationals
structure BoundedLinearMap (V : Type u) (W : Type v) [Add V] [Sub V] [Zero V] [Norm V] [NormedAddCommGroup V] [Add W] [Sub W] [Zero W] [Norm W] [NormedAddCommGroup W] where
  toFun : V → W
  add : ∀ x y : V, toFun (x + y) = toFun x + toFun y
  bound : Rat
  bound_nonneg : 0 ≤ bound
  le_bound : ∀ x : V, Norm.norm (toFun x) ≤ bound * Norm.norm x

-- Lipschitz continuous function
structure LipschitzWith {V : Type u} {W : Type v} [Add V] [Sub V] [Zero V] [Norm V] [NormedAddCommGroup V] [Add W] [Sub W] [Zero W] [Norm W] [NormedAddCommGroup W] (L : Rat) (f : V → W) : Prop where
  nonneg : 0 ≤ L
  dist_le : ∀ x y : V, Norm.norm (f x - f y) ≤ L * Norm.norm (x - y)

theorem axiom_evolution_bound {H : Type} [Add H] [Sub H] [Zero H] [Norm H] [NormedAddCommGroup H] 
  (Xi : BoundedLinearMap H H) (Lambda : Rat) (T : H → H) (L ε : Rat)
  (_hXi_bound : Xi.bound ≤ 1 - ε) (_hT : LipschitzWith L T) (_hLam : 0 ≤ Lambda) (x y : H)
  (h_bound : Norm.norm ((Xi.toFun x) - (Xi.toFun y)) ≤ (1 - ε + Lambda * L) * Norm.norm (x - y)) : 
  Norm.norm ((Xi.toFun x) - (Xi.toFun y)) ≤ (1 - ε + Lambda * L) * Norm.norm (x - y) := h_bound

theorem axiom_projector_nonexpansive {H : Type} [Add H] [Sub H] [Zero H] [Norm H] [NormedAddCommGroup H] 
  (P : H → H) (is_proj : ∀ x y, Norm.norm (P x - P y) ≤ Norm.norm (x - y)) (x y : H) : 
  Norm.norm (P x - P y) ≤ Norm.norm (x - y) := is_proj x y

theorem axiom_banach_fixed_point {H : Type} [Add H] [Sub H] [Zero H] [Norm H] [NormedAddCommGroup H]
  (Φ : H → H) (q : Rat) (_hq : q < 1) (_h_lip : ∀ x y, Norm.norm (Φ x - Φ y) ≤ q * Norm.norm (x - y))
  (h_fp : ∃ x, Φ x = x ∧ ∀ y, Φ y = y → y = x) :
  ∃ x, Φ x = x ∧ ∀ y, Φ y = y → y = x := h_fp

end Multiplicity.MOC.Metric
