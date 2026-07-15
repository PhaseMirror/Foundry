/-!
# EchoBraid — contractivity proofs (consolidated)

Consolidates `ECHO_BRAID/echo_braid.lean` and `ECHO_BRAID/MetricSpaceExtended.lean`:
a `Nat`-valued metric space, a contractivity oracle, and the sovereign-contractivity
check used by the Rust `echo-kernel`. All arithmetic is discrete (`Nat`); no
`Mathlib`, no `sorry`.
-/
namespace EchoBraid

/-! ## Metric Space -/

/-- A metric space with `Nat`-valued distance. -/
class MetricSpace (α : Type) where
  distance : α → α → Nat

/-! ## Contractivity Errors -/

inductive ContractivityError
  | TooFar
  | InvalidEpsilon

/-! ## Contractivity Check -/

/-- `enforceContractivity x y ε` returns `(pass, error)` for `distance(x,y) ≤ ε`. -/
def enforceContractivity {α : Type} [MetricSpace α] (x y : α) (ε : Nat) :
    Bool × Option ContractivityError :=
  if h : ε = 0 then (false, some ContractivityError.InvalidEpsilon)
  else if MetricSpace.distance x y ≤ ε then (true, none) else (false, some ContractivityError.TooFar)

/-- Contractivity implies the distance bound. -/
theorem contractivity_implies_bound {α : Type} [MetricSpace α] (x y : α) (ε : Nat)
    (h : enforceContractivity x y ε = (true, none)) :
    MetricSpace.distance x y ≤ ε := by
  unfold enforceContractivity at h
  have hε : ε ≠ 0 := by
    intro hzero
    have : (false, some ContractivityError.InvalidEpsilon) = (true, none) := by simpa [hzero] using h
    cases this
  have h' : (let d := MetricSpace.distance x y; if d ≤ ε then (true, none) else (false, some ContractivityError.TooFar)) = (true, none) := by
    simpa [hε] using h
  by_cases hdist : MetricSpace.distance x y ≤ ε
  · exact hdist
  · have : (false, some ContractivityError.TooFar) = (true, none) := by simpa [hdist] using h'
    cases this

/-! ## Example Instance -/

structure MockMetric where
  val : Nat

instance : MetricSpace MockMetric where
  distance a b := Nat.max a.val b.val - Nat.min a.val b.val

/-! ## Sovereign Contractivity (Rust `echo-kernel`) -/

def Scale : Nat := 1_000_000

def toScaled (num den : Nat) : Nat := (num * Scale) / den

structure LambdaTraceAtom where
  proofDigest : String
  stateRootHash : String
  timestamp : Nat
  qScaled : Nat
  teeQuotePresent : Bool
  trajectoryId : String
  protocolV : Nat
  signerIdPresent : Bool

/-- Sovereign contractivity predicate over a trace atom. -/
def enforceSovereignContractivity (atom : LambdaTraceAtom) (active : String) (maxQ : Nat) : Bool :=
  if atom.trajectoryId ≠ active then false
  else if ¬ atom.teeQuotePresent then false
  else if atom.qScaled ≥ maxQ then false
  else true

/-- The sovereign check implies the atom is active, attested, and below `maxQ`. -/
theorem sovereign_contractivity_correct (atom : LambdaTraceAtom) (active : String) (maxQ : Nat)
    (h : enforceSovereignContractivity atom active maxQ = true) :
    atom.trajectoryId = active ∧ atom.teeQuotePresent ∧ atom.qScaled < maxQ := by
  unfold enforceSovereignContractivity at h
  split_ifs at h with htraj hquote hq <;> try contradiction
  constructor
  · exact htraj
  · constructor
    · exact hquote
    · exact Nat.lt_of_not_ge hq

end EchoBraid
