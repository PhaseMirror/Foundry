import LorenzAttractor.Core
import LorenzAttractor.Dynamics
import LorenzAttractor.FeedbackTensor

/-! # LorenzAttractor.Examples

Concrete, executable instantiations of:
1. Canonical chaotic Lorenz system (sigma=10, rho=28, beta=8/3)
2. Prime-encoded parameter system (p1=7, p2=29, p3=3)
3. Multiplicity-stabilized feedback trajectory comparison
-/

namespace LorenzAttractor

/-- Initial standard point (1.0, 1.0, 1.0) in fixed-point representation. -/
def initialPoint111 : LorenzPoint :=
  ⟨1 * Int.ofNat FP_DEN, 1 * Int.ofNat FP_DEN, 1 * Int.ofNat FP_DEN⟩

/-- Canonical initial state at t=0. -/
def exampleCanonicalState : LorenzState :=
  ⟨0, initialPoint111, theoreticalTrace canonicalParams, 0⟩

/-- Prime-encoded initial state at t=0 with (7, 29, 3). -/
def examplePrimeState : LorenzState :=
  let params := primeToLorenzParams primeParams7_29_3
  ⟨0, initialPoint111, theoreticalTrace params, 0⟩

/-- Run Multiplicity-stabilized trajectory for N steps. -/
def runStabilizedSimulation (steps : Nat) : (LorenzState × List LorenzPoint) :=
  let params := canonicalParams
  let gain := 500 -- alpha gain = 0.500
  let rec loop (k : Nat) (curr : LorenzState) (history : List LorenzPoint) : (LorenzState × List LorenzPoint) :=
    match k with
    | 0 => (curr, history.reverse)
    | n + 1 =>
      let nextSt := unifiedStep curr params gain
      loop n nextSt (nextSt.point :: history)

  loop steps exampleCanonicalState []

/-- Run Prime-encoded trajectory for N steps. -/
def runPrimeSimulation (steps : Nat) : (LorenzState × List LorenzPoint) :=
  let params := primeToLorenzParams primeParams7_29_3
  let gain := 300
  let rec loop (k : Nat) (curr : LorenzState) (history : List LorenzPoint) : (LorenzState × List LorenzPoint) :=
    match k with
    | 0 => (curr, history.reverse)
    | n + 1 =>
      let nextSt := unifiedStep curr params gain
      loop n nextSt (nextSt.point :: history)

  loop steps examplePrimeState []

end LorenzAttractor
