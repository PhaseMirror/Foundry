/-!
# Foundations.CrossFiber.Core — Cross-Fiber Coupling & Joint Lyapunov Descent

Formalizes multi-fiber coupled state spaces (e.g. physical and social fibers),
linear Lyapunov functional additivity, and joint descent under bounded cross-talk coupling.
-/

namespace Foundations.CrossFiber

/-- Discrete state representation across prime components (2, 3, 5). -/
structure FiberState where
  p2 : Nat
  p3 : Nat
  p5 : Nat
deriving Repr, DecidableEq

/-- Discrete Lyapunov energy functional. -/
def V (s : FiberState) : Nat :=
  s.p2 + s.p3 + s.p5

/-- State vector addition. -/
def addState (a b : FiberState) : FiberState :=
  { p2 := a.p2 + b.p2, p3 := a.p3 + b.p3, p5 := a.p5 + b.p5 }

/-- Coupled joint state of two fibers (physical and social). -/
structure JointState where
  phys : FiberState
  soc : FiberState
deriving Repr, DecidableEq

/-- Uncoupled joint Lyapunov functional. -/
def V_joint (js : JointState) : Nat :=
  V js.phys + V js.soc

/-- Coupled update step under cross-talk perturbations K_phys and K_soc. -/
def joint_update (T : FiberState → FiberState) (js : JointState) (K_phys K_soc : FiberState) : JointState :=
  { phys := addState (T js.phys) K_phys,
    soc := addState (T js.soc) K_soc }

/-- Theorem: Lyapunov functional distributes linearly over vector addition. -/
theorem V_add (a b : FiberState) : 
    V (addState a b) = V a + V b := by
  dsimp [V, addState]
  omega

/-- Theorem: Cross-Fiber Joint Descent under Bounded Coupling.
    If the intrinsic contractive margin of each fiber absorbs cross-talk coupling,
    the joint coupled system preserves Fejér-monotone Lyapunov descent. -/
theorem cross_fiber_descent 
    (T : FiberState → FiberState)
    (js : JointState) (K_phys K_soc : FiberState)
    (h_margin_phys : V (T js.phys) + V K_phys ≤ V js.phys)
    (h_margin_soc  : V (T js.soc)  + V K_soc  ≤ V js.soc) :
    V_joint (joint_update T js K_phys K_soc) ≤ V_joint js := by
  dsimp [V_joint, joint_update]
  rw [V_add (T js.phys) K_phys, V_add (T js.soc) K_soc]
  omega

end Foundations.CrossFiber
