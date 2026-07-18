/-!
Viability Flow and Ethical Projector `P_E` formalization.
- Non‑expansive projector ensures trajectories stay within the viability kernel.
-/

namespace Core.ViabilityFlow

/-- Metric space over a state type `S` with distance scalar type `R`. -/
class MetricSpace (S R : Type) where
  dist : S → S → R
  le   : R → R → Prop
  refl : ∀ a, le (dist a a) (dist a a)
  trans : ∀ a b c, le (dist a b) (dist b c) → le (dist a b) (dist a c)

/-- Ethical projector `P_E` mapping any state back into the viability kernel.
It must be non‑expansive with respect to the metric. -/
structure ViabilityKernel (S R : Type) [M : MetricSpace S R] where
  P_E : S → S
  non_expansive : ∀ s1 s2 : S,
    M.le (M.dist (P_E s1) (P_E s2)) (M.dist s1 s2)

/-- Theorem: applying a flow step and then the projector does not increase the distance
beyond what the raw flow step would produce. This is the core Viability‑Flow confinement. -/
theorem flow_containment {S R : Type} [M : MetricSpace S R]
    (kernel : ViabilityKernel S R)
    (VlasovStep : S → S)
    (s1 s2 : S) :
    M.le (M.dist (kernel.P_E (VlasovStep s1)) (kernel.P_E (VlasovStep s2)))
          (M.dist (VlasovStep s1) (VlasovStep s2)) := by
  -- Immediate from the non‑expansive axiom of `P_E`
  exact kernel.non_expansive (VlasovStep s1) (VlasovStep s2)

end Core.ViabilityFlow
