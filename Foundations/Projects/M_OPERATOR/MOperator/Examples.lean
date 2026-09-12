import MOperator.Core
import MOperator.Algebra
import MOperator.CSLDynamics

/-! # MOperator.Examples

Concrete executable instantiations and multi-agent simulation benchmarks:
1. Canonical Golden Ratio Phi state initialization (phi, phi, phi)
2. Euler / Prime-indexed target states
3. Multi-step CSL trajectory simulations
-/

namespace MOperator

/-- Initial perturbed agent state near Phi vector. -/
def initialPerturbedState : AgentState :=
  let p0 : MVector3 := ⟨PHI_FP + 100, PHI_FP - 80, PHI_FP + 50⟩
  let dist := vectorDistSq p0 phiVector
  ⟨0, p0, dist, 0, dist <= (EPSILON_CSL_FP * EPSILON_CSL_FP)⟩

/-- Run CSL multi-step trajectory simulation towards target Phi for N steps. -/
def runCSLSimulation (steps : Nat) : (AgentState × List MVector3) :=
  let alpha := 300 -- alpha = 0.300
  let rec loop (k : Nat) (curr : AgentState) (history : List MVector3) : (AgentState × List MVector3) :=
    match k with
    | 0 => (curr, history.reverse)
    | n + 1 =>
      let nextSt := cslStepCubic curr phiVector alpha
      loop n nextSt (nextSt.position :: history)

  loop steps initialPerturbedState []

end MOperator
