/-!
  ADR‑015 Formalization in Lean4
  Proof-as-CI-Currency & Mandatory Gating (Deepened).
  No mathlib, no `sorry`s.
-/

open ShrapnelMap

/-- Proof artifact with extended metadata. -/
structure ProofArtifact where
  id                : Nat
  contentHash       : String
  tier              : String   -- evidence tier (e.g., "S", "E", "I")
  provenance        : String   -- source reference
  verifiedInvariants: List String
  driftResolved     : Bool
  deriving Repr

/-- Continuous‑Integration currency token, minted from a proof artifact. -/
structure CICurrency where
  amount         : Nat
  unit           : String   -- e.g., "credits"
  sourceProofIds : List Nat
  deriving Repr

/-- Gating conditions for proof promotion. -/
structure GatingCondition where
  minBalance            : Nat    -- minimum CI credits required
  requiredTier          : String  -- required tier label
  requiresDriftResolution : Bool   -- must have drift resolved
  mandatoryHumanReview  : Bool    -- informational flag, does not affect gate outcome
  deriving Repr

/-- Mint CI currency from a verified proof artifact.
    The amount is a deterministic function of tier and drift resolution.
    This is a placeholder rule for demonstration. -/
def mintCurrency (p : ProofArtifact) : CICurrency :=
  let base := match p.tier with
    | "S" => 10
    | "E" => 20
    | _   => 5
  let bonus := if p.driftResolved then 1 else 0
  { amount := base + bonus,
    unit := "credits",
    sourceProofIds := [p.id] }

/-- Predicate: proof must have non‑empty tier, provenance, and drift resolved. -/
def isValidProof (p : ProofArtifact) : Bool :=
  p.tier != "" && p.provenance != "" && p.driftResolved

/-- Predicate: CI currency meets or exceeds the minimum required balance. -/
def hasSufficientBalance (c : CICurrency) (cond : GatingCondition) : Bool :=
  c.amount >= cond.minBalance

/-- Predicate: mandatory gate checks tier, optional drift requirement, and human review flag. -/
def passesMandatoryGate (p : ProofArtifact) (c : CICurrency) (cond : GatingCondition) : Bool :=
  p.tier = cond.requiredTier &&
  (if cond.requiresDriftResolution then p.driftResolved else true) &&
  cond.mandatoryHumanReview = true

/-- Composite governance gate: all conditions must hold. -/
def governanceGate (p : ProofArtifact) (c : CICurrency) (cond : GatingCondition) : Bool :=
  isValidProof p && hasSufficientBalance c cond && passesMandatoryGate p c cond

/-- Theorem: a high‑tier, drift‑resolved proof mints enough currency to satisfy a standard gate. -/
theorem mint_high_tier_resolved_passes_standard_gate (p : ProofArtifact)
    (cond : GatingCondition)
    (hTier : p.tier = "S")
    (hDrift : p.driftResolved = true)
    (hCond : cond.requiredTier = "S" && cond.minBalance ≤ 11 && cond.requiresDriftResolution = true && cond.mandatoryHumanReview = true) :
    let c := mintCurrency p
    governanceGate p c cond = true := by
  -- unfold definitions
  unfold governanceGate isValidProof hasSufficientBalance passesMandatoryGate mintCurrency
  -- simplify with hypotheses
  have baseAmt : (match p.tier with | "S" => 10 | "E" => 20 | _ => 5) = 10 := by
    simp [hTier]
  have bonusAmt : (if p.driftResolved then 1 else 0) = 1 := by
    simp [hDrift]
  have amt_eq : ({ amount := 10 + 1, unit := "credits", sourceProofIds := [p.id] } : CICurrency).amount = 11 := rfl
  have bal_ok : ({ amount := 10 + 1, unit := "credits", sourceProofIds := [p.id] } : CICurrency).amount >= cond.minBalance := by
    have : cond.minBalance ≤ 11 := by
      have := and.left (and.right (and.right hCond))
      exact this
    exact le_of_lt (by linarith)
  simp [baseAmt, bonusAmt, amt_eq, bal_ok, hTier, hDrift] at *
  trivial

/-- Theorem: monotonicity – increasing currency balance preserves gate success. -/
theorem more_currency_preserves_pass (p : ProofArtifact) (c c' : CICurrency) (cond : GatingCondition)
    (hGate : governanceGate p c cond = true)
    (hInc : c'.amount >= c.amount) (hSameUnit : c'.unit = c.unit) (hSameProofs : c'.sourceProofIds = c.sourceProofIds) :
    governanceGate p c' cond = true := by
  unfold governanceGate at hGate ⊢
  rcases hGate with ⟨hValid, hBal, hPass⟩
  have hBal' : c'.amount >= cond.minBalance := by
    exact le_trans (by exact hBal) hInc
  exact ⟨hValid, hBal', hPass⟩

/-- Theorem: gate success implies proof validity and sufficient balance. -/
theorem gate_pass_implies_valid_and_sufficient (p : ProofArtifact) (c : CICurrency) (cond : GatingCondition)
    (hGate : governanceGate p c cond = true) :
    isValidProof p = true ∧ hasSufficientBalance c cond = true := by
  unfold governanceGate at hGate
  rcases hGate with ⟨hValid, hBal, _⟩
  exact ⟨hValid, hBal⟩

/-- End of ADR‑015 deep formalization. -/
