import Init

/-!
# IfmdSafety Spec (Pure Lean 4 Core)
-/

namespace IfmdSafety.Legacy

def weightedL1Norm (w x : List Float) : Float :=
  let pairs := w.zip x
  pairs.foldl (fun acc (wi, xi) => acc + wi * Float.abs xi) 0.0

def gapLB (w x : List Float) (T : Float) : Float :=
  let norm := weightedL1Norm w x
  if norm > T then norm - T else 0.0

theorem gapLB_nonneg (w x : List Float) (T : Float) :
  gapLB w x T >= 0.0 := by
  dsimp [gapLB]
  split
  · -- norm > T implies norm - T > 0
    decide
  · decide

end IfmdSafety.Legacy
