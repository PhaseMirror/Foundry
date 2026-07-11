#!/usr/bin/env python3
"""
Phase 2: Historical Boundary Optimization (WORM Replay)
Derives the 3-sigma anomaly threshold for the 5D feature vector.
"""
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
import json
import random
from pathlib import Path

# --- Configuration ---
FEATURES = ['entropy', 'unstable_rate', 'utilization', 'd16_frac', 'thermal_slope']
N_SAMPLES = 500  # Simulate a robust historical baseline (e.g., 5x 100-run batches)
RANDOM_SEED = 42

# --- 1. Load or Generate Baseline Data ---
# Since we are calibrating NOW, we generate a mock dataset strictly bounded by
# the proven First-Wave envelope. This represents a "healthy" WORM archive.
def generate_healthy_baseline(n=N_SAMPLES):
    data = []
    for _ in range(n):
        # Entropy: centered at 5.4, rarely touching 6.0
        entropy = np.random.normal(5.4, 0.15)
        entropy = np.clip(entropy, 4.9, 5.9)
        
        # Unstable Rate: strictly 0 in healthy runs, but let's add tiny variance for the model
        unstable_rate = np.random.beta(0.5, 50) * 0.01  # ~0% with rare micro-spikes
        
        # Utilization: centered at 84%, normally 65%-88%
        utilization = np.random.normal(0.84, 0.035)
        utilization = np.clip(utilization, 0.65, 0.88)
        
        # d16_frac: centered at 87%, rarely drops below 80%
        d16_frac = np.random.normal(0.87, 0.025)
        d16_frac = np.clip(d16_frac, 0.82, 0.92)
        
        # Thermal Slope: 1st derivative of util (simulate stable slopes)
        thermal_slope = np.random.normal(0.0, 0.02)
        thermal_slope = np.clip(thermal_slope, -0.05, 0.05)
        
        data.append([entropy, unstable_rate, utilization, d16_frac, thermal_slope])
    
    return pd.DataFrame(data, columns=FEATURES)

print("🔄 Generating healthy WORM baseline for Isolation Forest...")
df = generate_healthy_baseline()

# --- 2. Fit Isolation Forest ---
model = IsolationForest(
    contamination=0.01,          # Expected outlier rate in training
    random_state=RANDOM_SEED,
    n_estimators=100
)
model.fit(df.values)

# --- 3. Calculate 3-Sigma Threshold ---
scores = model.decision_function(df.values)
mean_score = np.mean(scores)
std_score = np.std(scores)

# 3-Sigma boundary: We want to catch truly anomalous events.
# In a Gaussian distribution, mean - 3*std captures ~0.15% false positives.
THRESHOLD = mean_score - (3 * std_score)

print(f"\n📊 Calibration Results (n={N_SAMPLES}):")
print(f"   Mean decision score: {mean_score:.4f}")
print(f"   Std decision score:  {std_score:.4f}")
print(f"   ✅ New ANOMALY_THRESHOLD = {THRESHOLD:.4f}")

# --- 4. Validate against our known "Critical" states ---
print("\n🧪 Validating against known synthetic breach states:")
test_cases = {
    "Thermal Spike": np.array([[5.8, 0.0, 0.94, 0.78, 0.12]]),  # High util, low d16, high slope
    "HSEC Breach": np.array([[6.5, 2.0, 0.80, 0.85, 0.01]]),    # High entropy + unstable
}
for name, vec in test_cases.items():
    score = model.decision_function(vec)[0]
    status = "🚨 CRITICAL (Breaches threshold)" if score < THRESHOLD else "✅ Nominal"
    print(f"   {name}: Score={score:.4f} -> {status}")

# --- 5. Export for Sedona Spine Integration ---
# This mimics what build.rs will eventually extract from Observability.lean
config_export = {
    "feature_vector": FEATURES,
    "contamination": 0.01,
    "anomaly_threshold": float(THRESHOLD),
    "n_estimators": 100
}
with open("observability/anomaly_config.json", "w") as f:
    json.dump(config_export, f, indent=2)

print("\n✅ Config exported to observability/anomaly_config.json")
print(f"🔄 Update ANOMALY_THRESHOLD in anomaly_monitor.py to: {THRESHOLD:.4f}")
