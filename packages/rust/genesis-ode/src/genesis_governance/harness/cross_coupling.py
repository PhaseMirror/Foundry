from typing import List, Dict
import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState, MultiSubstrateState

class CrossSubstrateHarness:
    """
    Harness for heterogeneous substrate interaction (ADR-003).
    Models C_Met <-> C_A coupling.
    """
    
    def __init__(self, core: ScalarCore, kappa: float = 0.1):
        self.core = core
        self.kappa = kappa

    def step(self, multi_state: MultiSubstrateState, dt: float, next_stresses: Dict[str, float]) -> MultiSubstrateState:
        new_states = {}
        
        for sub_id, state in multi_state.states.items():
            # Compute coupling: kappa * sum(wj(Cj - Ci))
            coupling_term = 0.0
            for other_id, other_state in multi_state.states.items():
                if sub_id == other_id:
                    continue
                weight = multi_state.coupling_matrix.get(sub_id, {}).get(other_id, 1.0)
                coupling_term += weight * (other_state.coherence - state.coherence)
            
            full_coupling = self.kappa * coupling_term
            
            # Step the individual core
            next_s = next_stresses.get(sub_id, state.effective_stress)
            stepped_state = self.core.step(
                state, 
                dt, 
                next_s_eff=next_s,
                external_coupling=full_coupling
            )
            
            # 2. Evaluate switching for Semiconductor-like substrates
            logical_state = stepped_state.logical_state
            if stepped_state.switching_threshold is not None:
                v_th = stepped_state.switching_threshold
                delta = stepped_state.hysteresis_band or 0.05
                if stepped_state.logical_state == "ON" and next_s > (v_th + delta):
                    logical_state = "OFF"
                elif stepped_state.logical_state == "OFF" and next_s < (v_th - delta):
                    logical_state = "ON"
            
            new_states[sub_id] = stepped_state.model_copy(update={"logical_state": logical_state})
            
        return MultiSubstrateState(
            states=new_states,
            coupling_matrix=multi_state.coupling_matrix,
            timestamp=multi_state.timestamp + dt
        )
