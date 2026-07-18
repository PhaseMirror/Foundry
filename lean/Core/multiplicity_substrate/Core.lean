namespace PRMS

/-- Scale: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Lineage Metrics mapped to bounded Nat -/
structure LineageMetrics where
  dataAge : Nat
  maxAllowedAge : Nat
  nonZeroChannels : Nat
  totalChannels : Nat
  measurementVariance : Nat
  deriving Repr

/-- Compliance Budget -/
structure ComplianceBudget where
  maxAllowedCond : Nat
  p7AdmissibilityThreshold : Nat
  deriving Repr

/-- Telemetry Frame -/
structure TelemetryFrame where
  t : Nat
  condNumber : Nat
  provenanceValid : Bool
  deriving Repr

end PRMS
