import json
import math
from typing import Dict, List

class DriftDetector:
    def __init__(self):
        self.threshold_kl = 0.5  # Max allowable divergence
        self.threshold_semantic = 0.8 # Min cosine similarity
        
    def calculate_kl_divergence(self, p: List[float], q: List[float]) -> float:
        """
        Calculates Kullback-Leibler divergence between two probability distributions.
        Used to measure how much the current output probability distribution (Q) 
        drifts from the baseline reference model (P).
        """
        epsilon = 0.00001
        p = [max(i, epsilon) for i in p]
        q = [max(i, epsilon) for i in q]
        
        divergence = sum(p[i] * math.log(p[i] / q[i]) for i in range(len(p)))
        return divergence

    def check_drift(self, p: List[float], q: List[float], operator_score: float = 5.0) -> Dict:
        """
        Combines Quantitative (KL) and Qualitative (Operator) metrics.
        Returns drift status and suggested ABAC enforcement attribute.
        """
        kl_div = self.calculate_kl_divergence(p, q)
        
        drift_detected = False
        reason = []
        
        # Quantitative Check
        if kl_div > self.threshold_kl:
            drift_detected = True
            reason.append(f"KL Divergence {kl_div:.4f} exceeds threshold {self.threshold_kl}")
            
        # Qualitative Check (Human in the Loop)
        if operator_score < 3.5:
            drift_detected = True
            reason.append(f"Operator Score {operator_score} below threshold 3.5")
            
        result = {
            "drift_detected": drift_detected,
            "kl_divergence": kl_div,
            "operator_score": operator_score,
            "reasons": reason,
            "abac_attribute_update": {"drift_status": drift_detected}
        }
        
        return result

# Example Usage
if __name__ == "__main__":
    detector = DriftDetector()
    # Simulated Distributions (Baseline vs Current)
    baseline = [0.1, 0.4, 0.5]
    current = [0.2, 0.3, 0.5] # Slight shift
    
    # 1. Pass Case
    print(json.dumps(detector.check_drift(baseline, current, operator_score=4.0), indent=2))
    
    # 2. Fail Case (Bad Human Score)
    print(json.dumps(detector.check_drift(baseline, current, operator_score=2.0), indent=2))
