from typing import List, Dict, Any, Optional
import numpy as np
from genesis_governance.shared.history import HistoryStore

class PrimeBandAllocator:
    """
    Automated prime-band allocation logic (ADR-009).
    Assigns primes to features based on sensitivity and historical performance.
    """
    
    BANDS = {
        "A": [2, 3, 5],     # Dynamics (Continuous)
        "B": [7, 11],       # Structure (Categorical)
        "C": [13, 17, 19]   # Context (Coupling/Parameters)
    }

    FEATURE_BAND_MAPPING = {
        "coherence": "A",
        "effective_stress": "A",
        "threshold_state": "A",
        "logical_state": "B",
        "frequency": "C",
        "coupling": "C"
    }

    def __init__(self, history: Optional[HistoryStore] = None):
        self.history = history
        # Default/Initial mapping
        self.current_mapping = {
            "coherence": 2,
            "effective_stress": 3,
            "threshold_state": 5,
            "logical_state": 7,
            "frequency": 13,
            "coupling": 17
        }

    def analyze_feature_sensitivity(self, feature_name: str) -> float:
        """
        Heuristic for feature sensitivity (0 to 1).
        In v0.5.0, we prioritize categorical states and high-variance features.
        """
        if feature_name == "logical_state":
            return 0.9
        
        if not self.history:
            return 0.5
            
        # Entropy heuristic: if we have history, look at variance in reconstruction scores
        recon_history = self.history.get_reconstruction_history()
        target_scores = [r["score"] for r in recon_history if r["target_id"] == feature_name]
        
        if len(target_scores) > 10:
            return float(np.std(target_scores))
            
        return 0.4

    def allocate(self) -> Dict[str, int]:
        """
        Updates and returns the feature-to-prime mapping.
        """
        return self.current_mapping

    def sensitivity_sweep(self, score_threshold: float = 0.80, delta_threshold: float = 0.15) -> bool:
        """
        Queries HistoryStore for reconstruction drift.
        Re-allocates if drift exceeds thresholds. Returns True if re-allocation occurred.
        """
        if not self.history:
            return False
            
        recon_history = self.history.get_reconstruction_history()
        if not recon_history:
            return False
            
        # Analyze latest window
        window = recon_history[-50:]
        avg_score = np.mean([r["score"] for r in window])
        max_delta = np.max([r["delta"] for r in window]) if window else 0.0
        
        reallocated = False
        if avg_score < score_threshold or max_delta > delta_threshold:
            # TRIGGER RE-ALLOCATION: Cycle primes within their bands
            for feature, band_id in self.FEATURE_BAND_MAPPING.items():
                primes_in_band = self.BANDS[band_id]
                current_p = self.current_mapping[feature]
                
                # Simple rotation within the band
                current_idx = primes_in_band.index(current_p)
                next_p = primes_in_band[(current_idx + 1) % len(primes_in_band)]
                
                if next_p != current_p:
                    self.current_mapping[feature] = next_p
                    reallocated = True
                
        return reallocated

    def get_prime_for_feature(self, feature_name: str) -> int:
        return self.current_mapping.get(feature_name, 23) # fallback to high prime
