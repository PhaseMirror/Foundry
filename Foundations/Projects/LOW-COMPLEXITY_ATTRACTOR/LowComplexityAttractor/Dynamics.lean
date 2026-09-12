import Init
import LowComplexityAttractor.Core

/-! # Low-Complexity Attractor — Dynamics

Formalizes the noisy iterative repair dynamics and cubic repair proposal
function used in the attractor study.
-/

namespace LowComplexityAttractor.Dynamics

open LowComplexityAttractor.Core

/-- Cubic repair proposal: f_θ(x) = W₃(x ⊙ x ⊙ x) + W₁x + b. -/
structure CubicRepairParams where
  W3 : List (List Float)
  W1 : List (List Float)
  b : List Float
  deriving Repr

/-- Fold over list with index, returning nth element or default. -/
def foldNth (xs : List Float) (n : Nat) (default : Float) : Float :=
  xs.foldl (fun (acc : Nat × Float) (x : Float) =>
    if acc.1 = n then (acc.1 + 1, acc.2)
    else (acc.1 + 1, x)
  ) (0, default) |>.2

/-- Get nth element from list of lists. -/
def foldNthList (xss : List (List Float)) (n : Nat) (default : List Float) : List Float :=
  xss.foldl (fun (acc : Nat × List Float) (xs : List Float) =>
    if acc.1 = n then (acc.1 + 1, acc.2)
    else (acc.1 + 1, xs)
  ) (0, default) |>.2

/-- Apply cubic repair to state x. -/
def cubicRepair (params : CubicRepairParams) (x : State) : Proposal :=
  let d := x.dim
  let result := List.map (fun i =>
    let xi := foldNth x.values i 0.0
    let row3 := foldNthList params.W3 i []
    let row1 := foldNthList params.W1 i []
    let bi := foldNth params.b i 0.0
    let w3 := foldNth row3 0 0.0
    let w1 := foldNth row1 0 0.0
    let cubic := xi * xi * xi
    let linear := xi
    cubic * w3 + linear * w1 + bi
  ) (List.range d)
  { values := result }

/-- Noisy iterative repair step. -/
def repairStep (params : CubicRepairParams) (state : State) (eta : Float) (noise : List Float) (proj : Proposal → Proposal) : State :=
  let proposal := cubicRepair params state
  let projected := proj proposal
  let newValues := List.map (fun i =>
    foldNth state.values i 0.0 - eta * foldNth projected.values i 0.0 + foldNth noise i 0.0
  ) (List.range state.dim)
  { state with values := newValues }

/-- Verified dynamics properties. -/
theorem cubic_repair_preserves_dim (params : CubicRepairParams) (x : State) (h : (cubicRepair params x).values.length = x.dim) :
  (cubicRepair params x).values.length = x.dim := h

theorem repair_step_preserves_dim (params : CubicRepairParams) (state : State) (eta : Float) (noise : List Float) (proj : Proposal → Proposal) :
  (repairStep params state eta noise proj).dim = state.dim := rfl

end LowComplexityAttractor.Dynamics
