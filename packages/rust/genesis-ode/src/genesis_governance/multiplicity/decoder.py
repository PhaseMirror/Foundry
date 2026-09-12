from typing import Dict, Any, Tuple, Optional
import numpy as np
from genesis_governance.types import SurfaceState, MultiplicityEncoding

from genesis_governance.multiplicity.allocator import PrimeBandAllocator

class MultiplicityDecoder:
    """
    Quarantined multiplicity decoding logic (ADR-007, ADR-009).
    Reconstructs approximate scalar states from prime signatures.
    """
    
    def __init__(self, allocator: Optional[PrimeBandAllocator] = None):
        self.allocator = allocator or PrimeBandAllocator()

    def decode(self, encoding: MultiplicityEncoding) -> Tuple[float, float, str, bool]:
        """
        Reconstructs state from the exponent vector via dynamic mapping.
        """
        mapping = self.allocator.allocate()
        
        c_p = mapping.get("coherence", 2)
        s_p = mapping.get("effective_stress", 3)
        t_p = mapping.get("threshold_state", 5)
        l_p = mapping.get("logical_state", 7)
        
        c_exp = encoding.exponent_vector.get(c_p, 0)
        s_exp = encoding.exponent_vector.get(s_p, 0)
        t_exp = encoding.exponent_vector.get(t_p, 0)
        l_exp = encoding.exponent_vector.get(l_p, 0)
        
        # Center of the quantization bins
        recon_coherence = (c_exp + 0.5) / 5.0
        recon_stress = (s_exp + 0.5) / 10.0
        recon_threshold_exceeded = (t_exp == 1)
        recon_state = "ON" if l_exp == 1 else "OFF"
        
        return recon_coherence, recon_stress, recon_state, recon_threshold_exceeded

    def compute_reconstruction_score(self, original_state: SurfaceState, encoding: MultiplicityEncoding) -> float:
        """
        Computes the reconstruction score (1.0 = perfect match).
        Includes categorical logical_state penalty.
        """
        recon_c, recon_s, recon_state, recon_th = self.decode(encoding)
        
        # Original values
        orig_c = original_state.coherence
        orig_s = original_state.effective_stress
        orig_state = original_state.logical_state
        
        v_th = original_state.switching_threshold or 0.5
        orig_th = (orig_s > v_th)
        
        # L2 Distance for numerical values
        dist = np.sqrt((orig_c - recon_c)**2 + (orig_s - recon_s)**2)
        
        # Categorical penalty for logical state mismatch
        if recon_state != orig_state:
            dist += 0.5 # Substantial penalty
            
        # Penalty for threshold state mismatch
        if recon_th != orig_th:
            dist += 0.3
        
        score = np.exp(-dist * 2.0)
        return float(score)

    def validate_locality(self, encoding: MultiplicityEncoding, perturbation: Dict[int, int]) -> float:
        """
        Measures locality_delta: max change under single-exponent perturbation.
        """
        # Original reconstruction
        base_c, base_s, base_state, base_th = self.decode(encoding)
        
        # Perturbed reconstruction
        p_vector = encoding.exponent_vector.copy()
        for p, d in perturbation.items():
            p_vector[p] = max(0, p_vector.get(p, 0) + d)
        
        p_encoding = MultiplicityEncoding(exponent_vector=p_vector)
        p_c, p_s, p_state, p_th = self.decode(p_encoding)
        
        # Delta
        delta = np.sqrt((base_c - p_c)**2 + (base_s - p_s)**2)
        if base_state != p_state:
            delta += 0.5
        if base_th != p_th:
            delta += 0.3
            
        return float(delta)
