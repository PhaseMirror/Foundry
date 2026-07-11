namespace SnapKitty.Observability

/-- The calibrated 3-sigma anomaly threshold derived from the WORM baseline.
    Any Isolation Forest decision score strictly below this float triggers SIG_GOV_KILL. --/
def ANOMALY_GOV_THRESHOLD : Float := 0.0067

/-- The SHA-256 hash of the exact IsolationForest binary model used for inference.
    Prevents degenerate or malicious models from being loaded in production. --/
def ANOMALY_MODEL_HASH : String := "edc00143ac1541961a22ae989cf751cca43ee64e19c49475f2f76f2cbecafba3"

end SnapKitty.Observability
