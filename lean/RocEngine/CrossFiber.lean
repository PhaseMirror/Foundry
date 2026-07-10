-- CrossFiber.lean
import RocEngine.Lyapunov

/-- Represents the coupled state of two ROC fibres (e.g. Physical and Social) -/
structure JointState where
  phys : State
  soc : State

/-- The uncoupled joint Lyapunov functional -/
def V_joint (js : JointState) : Nat :=
  V js.phys + V js.soc

/-- A coupled update step where K_phys and K_soc represent the symmetric
    cross-talk added to each fibre after the intrinsic contractive update T. -/
def joint_update (js : JointState) (K_phys K_soc : State) : JointState :=
  { phys := { p2 := (T js.phys).p2 + K_phys.p2,
              p3 := (T js.phys).p3 + K_phys.p3,
              p5 := (T js.phys).p5 + K_phys.p5 },
    soc  := { p2 := (T js.soc).p2 + K_soc.p2,
              p3 := (T js.soc).p3 + K_soc.p3,
              p5 := (T js.soc).p5 + K_soc.p5 } }

/-- Helper lemma: V distributes linearly over discrete addition. -/
theorem V_add (a b : State) : 
  V { p2 := a.p2 + b.p2, p3 := a.p3 + b.p3, p5 := a.p5 + b.p5 } = V a + V b := by
  dsimp [V]
  omega

/-- 
  Theorem: Cross-Fibre Joint Descent under Bounded Coupling
  If the intrinsic contractive margin of each fibre (represented by V(T x))
  is strong enough to strictly absorb the cross-talk coupling terms (K_phys, K_soc),
  then the joint system preserves Fejér-monotone descent.
-/
theorem cross_fiber_descent 
    (js : JointState) (K_phys K_soc : State)
    (h_margin_phys : V (T js.phys) + V K_phys ≤ V js.phys)
    (h_margin_soc  : V (T js.soc)  + V K_soc  ≤ V js.soc) :
    V_joint (joint_update js K_phys K_soc) ≤ V_joint js := by
  dsimp [V_joint, joint_update]
  rw [V_add (T js.phys) K_phys, V_add (T js.soc) K_soc]
  exact Nat.add_le_add h_margin_phys h_margin_soc
