import sys
import os
import numpy as np
sys.path.append("src")

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp
from genesis_governance.harness.aging import SemiconductorAgingHarness
from genesis_governance.types import SurfaceState, MultiSubstrateState
from genesis_governance.multiplicity.encoder import MultiplicityEncoder
from genesis_governance.multiplicity.decoder import MultiplicityDecoder
from genesis_governance.shared.history import HistoryStore

def main():
    print("=== Lane D Seed: Semiconductor Aging Experiment ===")
    core = ScalarCore(alpha=0.1, gamma=0.05)
    history = HistoryStore()
    encoder = MultiplicityEncoder()
    decoder = MultiplicityDecoder()
    exploder = ExploderEngine(core, epsilon_x=0.5, encoder=encoder, decoder=decoder)

    # Initial state with aging parameters
    state = SurfaceState(
        substrate="SemiAging", 
        coherence=0.95, 
        stability_threshold=1.0,
        effective_stress=0.1,
        switching_threshold=0.5,
        hysteresis_band=0.02,
        logical_state="ON"
    )
    
    # Aging Harness
    harness = SemiconductorAgingHarness(core, aging_factor=0.05)
    
    # Simulation Loop (demonstrating harness manually as it's a seed prototype)
    current_state = state
    fragments = []
    dt = 0.1
    duration = 10.0
    steps = int(duration / dt)
    
    print(f"Executing {steps} aging steps...")
    for i in range(1, steps + 1):
        # Apply a slow ramp
        next_s = current_state.effective_stress + 0.01
        current_state = harness.step(current_state, dt, next_s)
        
        # Periodic shrapnel capture
        if i % 10 == 0:
            current_state = encoder.attach(current_state)
            current_state.multiplicity.reconstruction_score = decoder.compute_reconstruction_score(current_state, current_state.multiplicity)
            print(f"Step {i}: V_th = {current_state.switching_threshold:.4f}, State = {current_state.logical_state}, Recon = {current_state.multiplicity.reconstruction_score:.4f}")

    print("\nLane D Seed Complete. Threshold drift successfully captured.")

if __name__ == "__main__":
    main()
