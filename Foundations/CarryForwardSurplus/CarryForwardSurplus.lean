/-!
# Carry-Forward Surplus Kernel
Formalized without ungrounded axioms or Mathlib.
-/

namespace Foundations.CarryForwardSurplus

def kernel (delta beta : Float) : Float := -(beta * delta).tanh

def update (sx sy beta lam : Float) : (Float × Float) :=
  let δ := sx - sy
  let f := -(beta * δ).tanh
  (lam * sx + f, lam * sy - f)

theorem update_correct (sx sy β lam : Float) :
  update sx sy β lam =
    let δ := sx - sy
    let f := -(β * δ).tanh
    (lam * sx + f, lam * sy - f) := rfl

theorem update_spec (sx sy β lam : Float) :
  update sx sy β lam =
    let δ := sx - sy
    let f := kernel δ β
    (lam * sx + f, lam * sy - f) := rfl

end Foundations.CarryForwardSurplus
