from typing import List
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState
from genesis_governance.lane_g.engine import LaneGCore

class EcologicalHarness:
    """
    Harness for Ecological Composite Persistence simulation (ADR-015).
    """
    
    def __init__(self, core: LaneGCore):
        self.core = core

    def run_simulation(self, initial_state: SurfaceState, duration: float, dt: float) -> List[SurfaceState]:
        """
        Runs a simulation of ecological resilience dynamics.
        """
        history = [initial_state]
        current_state = initial_state
        
        steps = int(duration / dt)
        for i in range(1, steps + 1):
            # Effective stress (constant or varying)
            next_s_eff = current_state.effective_stress
            
            # Step the core
            current_state = self.core.step(current_state, dt, next_s_eff)
            
            history.append(current_state)
            
        return history
