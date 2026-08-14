from typing import List
import numpy as np

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState
from genesis_governance.exploder.perturbations import CyclicStress, PerturbationFamily
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.schemas.shrapnel import ShrapnelMap

class MetallurgicalHarness:
    """
    Standard harness for Metallurgical Fatigue simulation (ADR-001).
    Now integrated with ExploderEngine for adversarial stress testing.
    """
    
    def __init__(self, core: ScalarCore, s0: float = 10.0, omega: float = 1.0):
        self.core = core
        self.s0 = s0
        self.omega = omega
        self.exploder = ExploderEngine(core)

    def run_simulation(self, initial_state: SurfaceState, duration: float, dt: float) -> List[SurfaceState]:
        """
        Legacy direct simulation runner.
        """
        history = [initial_state]
        current_state = initial_state
        
        steps = int(duration / dt)
        for i in range(1, steps + 1):
            # S_eff,Met(t) = S0 * |sin(omega * t)|
            next_s_eff = abs(self.s0 * np.sin(self.omega * current_state.timestamp))
            current_state = self.core.step(current_state, dt, next_s_eff)
            history.append(current_state)
            
        return history

    def run_adversarial_metallurgy(
        self, 
        initial_state: SurfaceState, 
        extra_perturbations: List[PerturbationFamily] = [],
        duration: float = 5.0,
        dt: float = 0.1
    ) -> ShrapnelMap:
        """
        Adversarial runner using the ExploderEngine and CyclicStress baseline.
        """
        # Baseline cyclic stress is treated as a perturbation in the Exploder
        base_cyclic = CyclicStress(amplitude=self.s0, frequency=self.omega)
        all_perturbations = [base_cyclic] + extra_perturbations
        
        return self.exploder.run(
            initial_state=initial_state,
            perturbations=all_perturbations,
            duration=duration,
            dt=dt
        )
