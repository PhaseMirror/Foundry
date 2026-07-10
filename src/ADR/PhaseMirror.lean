/-!
# PhaseMirror module

Defines a PhaseMirror transformation on ADRs, representing an involutive
operation used in the Phase Mirror engine.
-/

namespace ADR

/-- A simple involutive transformation on ADR identifiers.
    For demonstration purposes we model it as a function `mirrorId` that
    maps an `ADRId` to another `ADRId`. The concrete mapping is left abstract
    (could be e.g. bitwise complement, hash, etc.). -/
structure PhaseMirror where
  mirrorId : ADRId → ADRId
  involutive : ∀ id, mirrorId (mirrorId id) = id

/-- Apply the PhaseMirror to an entire ADR, producing a new ADR with the
    mirrored identifier and the same payload (status, context, etc.). -/
def apply (pm : PhaseMirror) (a : ADR) : ADR :=
  { a with id := pm.mirrorId a.id }

/-- The PhaseMirror transformation is an involution on ADRs: applying it twice
    yields the original ADR. -/
theorem apply_involutive (pm : PhaseMirror) (a : ADR) :
    apply pm (apply pm a) = a := by
  unfold apply
  cases a with
  | mk id title status context decision consequences supersedes links =>
    simp [pm.involutive]

end ADR
