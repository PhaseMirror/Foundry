from typing import List
import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState

class SemiconductorHarness:
    """
    Lane C — Semiconductor Persistence Harness (ADR-008).
    Models threshold-driven ON/OFF state transitions.
    """
    
    def __init__(self, core: ScalarCore):
        self.core = core

    def evaluate_switching(self, state: SurfaceState) -> str:
        """
        Implements hysteresis-aware switching.
        """
        if state.switching_threshold is None:
            return state.logical_state
            
        v_th = state.switching_threshold
        delta = state.hysteresis_band or 0.05
        s_eff = state.effective_stress
        
        if state.logical_state == "ON" and s_eff > (v_th + delta):
            return "OFF"
        elif state.logical_state == "OFF" and s_eff < (v_th - delta):
            return "ON"
            
        return state.logical_state

    def step(self, state: SurfaceState, dt: float, next_s_eff: float) -> SurfaceState:
        # 1. Core integration step
        # Note: We can modify parameters like alpha/beta based on ON/OFF state if desired.
        current_state = state
        new_state = self.core.step(current_state, dt, next_s_eff)
        
        # 2. Evaluate switching
        logical_state = self.evaluate_switching(new_state)
        
        # 3. Apply state-specific dynamics (e.g., faster decay in OFF state)
        if logical_state == "OFF":
            # Heuristic: OFF state has higher delta (degradation)
            pass 
            
        return new_state.model_copy(update={"logical_state": logical_state})
