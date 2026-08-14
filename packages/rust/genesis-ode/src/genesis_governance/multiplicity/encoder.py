from typing import List, Dict, Optional, Any
import numpy as np
from genesis_governance.types import SurfaceState, MultiplicityEncoding

from genesis_governance.multiplicity.allocator import PrimeBandAllocator

class MultiplicityEncoder:
    """
    Quarantined multiplicity encoding logic (ADR-007, ADR-009).
    Translates scalar states into prime signatures as metadata.
    """
    
    PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]

    def __init__(self, allocator: Optional[PrimeBandAllocator] = None):
        self.allocator = allocator or PrimeBandAllocator()

    def encode(self, state: SurfaceState) -> MultiplicityEncoding:
        """
        Heuristic: Map coherence, stress, and logical_state to primes via allocator.
        """
        mapping = self.allocator.allocate()
        
        c_p = mapping.get("coherence", 2)
        s_p = mapping.get("effective_stress", 3)
        t_p = mapping.get("threshold_state", 5)
        l_p = mapping.get("logical_state", 7)
        f_p = mapping.get("frequency", 13)
        
        c_exp = int(state.coherence * 5)
        s_exp = int(state.effective_stress * 10)
        
        # Threshold state (ADR-008)
        v_th = state.switching_threshold or 0.5
        t_exp = 1 if state.effective_stress > v_th else 0
        
        l_exp = 1 if state.logical_state == "ON" else 2
        f_exp = int(state.frequency * 2) # simplified
        
        exponent_vector = {c_p: c_exp, s_p: s_exp, t_p: t_exp, l_p: l_exp, f_p: f_exp}
        prime_signature = [p for p, e in exponent_vector.items() if e > 0]
        
        # Sparsity = active primes / total available primes in bank
        sparsity = len(prime_signature) / len(self.PRIMES)
        
        return MultiplicityEncoding(
            prime_signature=prime_signature,
            exponent_vector=exponent_vector,
            sparsity_index=sparsity,
            locality_score=1.0 # placeholder
        )

    def attach(self, state: SurfaceState) -> SurfaceState:
        """
        Attaches fresh multiplicity metadata to a state.
        """
        encoding = self.encode(state)
        return state.model_copy(update={"multiplicity": encoding})
