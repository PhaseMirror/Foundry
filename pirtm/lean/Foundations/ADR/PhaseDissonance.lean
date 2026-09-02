import Foundations.ADR.Core
import Foundations.ADR.Proofs

/-!
# ADR-037: Prime-Indexed Phase-Dissonance Functionals

Formal Lean 4 implementation of ADR-037:
- Prime-weighted contradiction components \Delta_{p,a}.
- Phase-dissonance functional computation D(\Phi_t).
- Dynamic phase band check [L_t, U_t].
- Invariants: Dissonance within phase band implies governance in-bounds.
-/

namespace PIRTM.PhaseDissonance

/-- Artifact types: Spec, Code, Log, SLA. -/
inductive ArtifactType where
  | Spec : ArtifactType
  | Code : ArtifactType
  | Log  : ArtifactType
  | SLA  : ArtifactType
  deriving Repr, DecidableEq

/-- Prime-indexed contradiction entry. -/
structure ContradictionEntry where
  primeAxis  : Nat  -- Prime index p_i
  artifact   : ArtifactType
  weight     : Nat  -- Weight w_{p,a}
  delta      : Nat  -- Contradiction magnitude \Delta_{p,a}
  deriving Repr

/-- Compute squared term (p_i * w * \Delta)^2 for a single entry. -/
def entrySquare (e : ContradictionEntry) : Nat :=
  (e.primeAxis * e.weight * e.delta) ^ 2

/-- Aggregate dissonance squared sum. -/
def dissonanceSquareSum (entries : List ContradictionEntry) : Nat :=
  entries.foldl (fun acc e => acc + entrySquare e) 0

/-- Integer square root helper for discrete dissonance calculation. -/
def natSqrt (n : Nat) : Nat :=
  Nat.sqrt n

/-- Calculate discrete phase dissonance D(\Phi_t). -/
def calculateDissonance (entries : List ContradictionEntry) : Nat :=
  natSqrt (dissonanceSquareSum entries)

/-- Dynamic Phase Band [L_t, U_t]. -/
structure PhaseBand where
  lowerBound : Nat
  upperBound : Nat
  deriving Repr

/-- Governance status check. -/
def isGovernanceInBounds (entries : List ContradictionEntry) (band : PhaseBand) : Bool :=
  let d := calculateDissonance entries
  band.lowerBound <= d && d <= band.upperBound

/-- Theorem: In-bounds governance strictly guarantees lower and upper dissonance bounds. -/
theorem in_bounds_implies_band_satisfied (entries : List ContradictionEntry) (band : PhaseBand)
    (h : isGovernanceInBounds entries band = true) :
    band.lowerBound <= calculateDissonance entries ∧ calculateDissonance entries <= band.upperBound := by
  dsimp [isGovernanceInBounds] at h
  have h_and := Bool.and_eq_true _ _ |>.mp h
  exact ⟨of_decide_eq_true h_and.1, of_decide_eq_true h_and.2⟩

end PIRTM.PhaseDissonance
