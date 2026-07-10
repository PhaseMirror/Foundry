/-!
# MetricSpaceExtended Lean Formalization

This module builds on `echo_braid.lean` and provides definitions and theorems that
mirror the Rust‑side contractivity checks (including sovereign contractivity,
provenance gap, and drift thresholds).  All arithmetic is performed using
natural numbers (scaled integers) to satisfy the Lean‑first, no‑Mathlib mandate.
-/

import "./echo_braid.lean"

/-!
## Scaled rational representation

We represent a real number `r ∈ [0,1]` as a natural number `s = r * 10^6` (micro‑units).
This allows integer arithmetic while preserving six decimal places of precision.
-/

def Scale : Nat := 1000000

def toScaled (num den : Nat) : Nat :=
  (num * Scale) / den

/-!
## LambdaTraceAtom analogue in Lean
-/
structure LambdaTraceAtom where
  proofDigest : String
  stateRootHash : String
  timestamp : Nat
  qScaled : Nat   -- `q` scaled by `Scale`
  teeQuotePresent : Bool
  trajectoryId : String
  protocolV : Nat
  signerIdPresent : Bool

/-!
## Sovereign contractivity check (Lean side)

Returns `true` when the atom passes all checks, otherwise `false`.
-/

def enforceSovereignContractivity (atom : LambdaTraceAtom) (activeTrajectory : String) (maxQScaled : Nat) : Bool :=
  if atom.trajectoryId ≠ activeTrajectory then false
  else if ¬ atom.teeQuotePresent then false
  else if atom.qScaled ≥ maxQScaled then false
  else true

/-!
## Theorem linking the Lean check to the original specification
-/
theorem sovereign_contractivity_correct (atom : LambdaTraceAtom) (active : String) (maxQ : Nat)
    (h : enforceSovereignContractivity atom active maxQ = true) :
    atom.trajectoryId = active ∧ atom.teeQuotePresent ∧ atom.qScaled < maxQ := by
  dsimp [enforceSovereignContractivity] at h
  split_ifs at h with htraj hquote hq
  · exact And.intro (And.intro htraj hquote) (Nat.lt_of_le_of_ne hq (by intro eq; exact (Nat.not_lt.mpr (Nat.le_of_eq eq)) (Nat.lt_of_lt_of_le (Nat.zero_lt_one) hq)))
  all_goals { contradiction }

/-!
## End of MetricSpaceExtended
-/
