from typing import List, Dict
import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState

class SemiconductorAgingHarness:
    """
    Lane D Seed: Semiconductor Aging Prototype.
    Models cumulative threshold drift over time (aging_factor).
    """
    def __init__(self, core: ScalarCore, aging_factor: float = 0.001):
        self.core = core
        self.aging_factor = aging_factor

    def step(self, state: SurfaceState, dt: float, next_s_eff: float) -> SurfaceState:
        # 1. Threshold Drift (The "Aging" mechanism)
        v_th = state.switching_threshold or 0.5
        v_th_new = v_th + self.aging_factor * dt # Threshold increases with wear
        
        # 2. Core Step
        new_state = self.core.step(state, dt, next_s_eff)
        
        # 3. Evaluate switching with drifted threshold
        logical_state = new_state.logical_state
        delta = new_state.hysteresis_band or 0.05
        if new_state.logical_state == "ON" and next_s_eff > (v_th_new + delta):
            logical_state = "OFF"
        elif new_state.logical_state == "OFF" and next_s_eff < (v_th_new - delta):
            logical_state = "ON"
            
        return new_state.model_copy(update={
            "switching_threshold": v_th_new,
            "logical_state": logical_state
        })
