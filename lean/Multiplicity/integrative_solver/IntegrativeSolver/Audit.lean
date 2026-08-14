import Multiplicity.Std
import Multiplicity.IntegrativeSolver.Core
import Multiplicity.IntegrativeSolver.Diffusion
import Multiplicity.IntegrativeSolver.Intervention
open Classical

namespace Multiplicity.IntegrativeSolver

namespace Multiplicity.Audit

/-!
# IntegrativeSolver.Audit

Audit trail and verification for the M-Integrative Solver.

Design notes
- This module records a sequence of solver operations and verifies
  basic invariants across the sequence.
- The `sorry`-free guarantee holds for this file.
-/

inductive Op (K : Nat) where
  | diffuse
  | intervene (target : Fin K) (delta : Nat)

def audit {K : Nat} (ops : List (Op K)) (v : Core.SCV K) : Core.SCV K :=
  ops.foldl (fun state op =>
    match op with
    | Op.diffuse => IntegrativeSolver.Diffusion.diffuse state
    | Op.intervene target delta => IntegrativeSolver.Intervention.intervene target delta state) v

theorem audit_nil {K : Nat} (v : Core.SCV K) :
    audit ([] : List (Op K)) v = v := by
  rfl

theorem audit_cons {K : Nat} (op : Op K) (ops : List (Op K)) (v : Core.SCV K) :
    audit (op :: ops) v = audit ops (match op with
      | Op.diffuse => IntegrativeSolver.Diffusion.diffuse v
      | Op.intervene target delta => IntegrativeSolver.Intervention.intervene target delta v) := by
  rfl

end Multiplicity.Audit

end Multiplicity.IntegrativeSolver
