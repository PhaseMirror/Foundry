namespace SnapKitty.Observability

/-- The calibrated 3-sigma anomaly threshold derived from the WORM baseline.
    Any Isolation Forest decision score strictly below this float triggers SIG_GOV_KILL. --/
def ANOMALY_GOV_THRESHOLD : Float := 0.0006

end SnapKitty.Observability
