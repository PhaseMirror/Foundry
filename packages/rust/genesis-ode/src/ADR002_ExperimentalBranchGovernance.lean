structure ExperimentalBranch where
  name : String
  status : String   -- e.g., "EXPERIMENTAL"
  branch : String
  coreStatus : String
  evidenceTier : String
  claimBoundary : String
  nonClaims : String

/-- Simple predicate that checks the status field is "EXPERIMENTAL" -/
def isExperimental (b : ExperimentalBranch) : Bool :=
  b.status == "EXPERIMENTAL"

/-- Reuse promotion criteria from ADR001 -/
open ADR001_CoreVsExperimental

def canPromoteExperimental (b : ExperimentalBranch) (c : PromotionCriteria) : Prop :=
  isExperimental b && c.declaredScope && c.evidenceTier && c.validationContract &&
  c.layerTags && c.noAmbiguity && c.calibration && c.refereeReview

-- End of ADR‑002 formalization.
