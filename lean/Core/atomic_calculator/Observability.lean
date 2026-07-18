/-
Copyright (c) 2026. Sedona Spine Governance.
Formal verification of the AI Anomaly Detection Model artifact.
-/
namespace UAC.Observability

/-- SHA-256 hash of the production Isolation Forest model (anomaly_model.pkl).
    This hash is mathematically bound to the Sedona Spine invariants.
    The build system (build.rs) verifies the on-disk model matches this
    digest. A mismatch causes the Rust compilation to abort, preventing
    operational drift. -/
def MODEL_SHA256 : String :=
  "d75d7919966a3abe8c7d9f873714263822466d997365938d06ee6f18afc0a4b4"

/-- The 3-sigma governance threshold derived from WORM calibration.
    This must match the value used in anomaly_monitor.py. -/
def ANOMALY_GOV_THRESHOLD : Float := 0.0006

/-- The 5D feature vector order used in the Isolation Forest. -/
def FEATURE_ORDER : List String :=
  ["entropy", "unstable_rate", "utilization", "d16_frac", "thermal_slope"]

end UAC.Observability
