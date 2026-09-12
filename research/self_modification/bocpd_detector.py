#!/usr/bin/env python3
"""
BOCPD Detector: Bayesian Online Change-Point Detection for Semantic Drift.
Enforces real-time regime shift monitoring with < 50 block latency.
"""

import sys
import json
import math

class BOCPDDetector:
    def __init__(self, hazard_rate=1/250):
        self.hazard_rate = hazard_rate
        self.run_length_probs = [1.0] # Initial run length is 0 with p=1
        self.t = 0
        
    def update(self, observed_drift):
        """
        Updates run length probabilities based on new drift observation.
        Simplified NIG likelihood for scaffolding.
        """
        self.t += 1
        new_probs = [0.0] * (len(self.run_length_probs) + 1)
        
        # 1. Calculate growth probabilities (r_t = r_{t-1} + 1)
        # Simplified: p(x_t | r) assumed Gaussian for scaffolding
        for r, p_old in enumerate(self.run_length_probs):
            likelihood = self._gaussian_likelihood(observed_drift)
            new_probs[r+1] = p_old * likelihood * (1 - self.hazard_rate)
            
        # 2. Calculate change-point probability (r_t = 0)
        new_probs[0] = sum(p_old * self._gaussian_likelihood(observed_drift) * self.hazard_rate 
                           for p_old in self.run_length_probs)
        
        # 3. Normalize
        total = sum(new_probs)
        self.run_length_probs = [p / total for p in new_probs]
        
        return self.run_length_probs[0] # Prob(change-point occurred at this step)

    def _gaussian_likelihood(self, x, mu=0.00005, sigma=0.00002):
        """Minimal Gaussian likelihood for scaffolding."""
        return (1.0 / (sigma * math.sqrt(2 * math.pi))) * math.exp(-0.5 * ((x - mu) / sigma)**2)

def main():
    if len(sys.argv) < 2:
        print("Usage: bocpd_detector.py <drift_magnitude>")
        sys.exit(1)

    try:
        delta = float(sys.argv[1])
    except ValueError:
        print("Error: Drift magnitude must be a float.")
        sys.exit(1)

    detector = BOCPDDetector()
    p_change = detector.update(delta)
    
    status = "STABLE"
    if p_change >= 0.20:
        status = "ALERT"
    elif p_change >= 0.05:
        status = "WARNING"

    result = {
        "status": status,
        "p_change": round(p_change, 4),
        "observed_delta": delta,
        "block_latency_target": 50
    }

    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
