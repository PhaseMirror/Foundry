import Foundations.IntegrativeSolver.Core
import Foundations.IntegrativeSolver.Diffusion
import Foundations.IntegrativeSolver.Intervention

/-!
# Foundations.IntegrativeSolver.Audit — Audit Trail & Sequence Verification
-/

namespace Foundations.IntegrativeSolver

inductive Op (K : Nat) where
  | diffuse
  | intervene (target : Fin K) (delta : Nat)

def audit {K : Nat} (ops : List (Op K)) (v : SCV K) : SCV K :=
  ops.foldl (fun state op =>
    match op with
    | Op.diffuse => diffuse state
    | Op.intervene target delta => intervene target delta state) v

theorem audit_nil {K : Nat} (v : SCV K) :
    audit ([] : List (Op K)) v = v := rfl

theorem audit_cons {K : Nat} (op : Op K) (ops : List (Op K)) (v : SCV K) :
    audit (op :: ops) v = audit ops (match op with
      | Op.diffuse => diffuse v
      | Op.intervene target delta => intervene target delta v) := rfl

end Foundations.IntegrativeSolver
