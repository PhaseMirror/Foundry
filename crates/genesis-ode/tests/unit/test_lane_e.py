import pytest
import numpy as np
from genesis_governance.lane_e.engine import LaneECore
from genesis_governance.harness.quantum import QuantumHarness
from genesis_governance.types import SurfaceState

def test_quantum_dynamics():
    core = LaneECore(alpha=0.1, omega=1.0) # Oscillation due to omega
    harness = QuantumHarness(core)
    
    state = SurfaceState(
        substrate="Quantum",
        coherence=1.0,
        stability_threshold=1.0,
        effective_stress=0.0
    )
    
    # Run simulation
    history, phases = harness.run_simulation(state, duration=1.0, dt=0.1, initial_phase=0.0)
    
    # Check coherence decay (alpha=0.1, cx*=1.0, cx=1.0 -> dC/dt should be small initially)
    # Check phase evolution (omega=1.0 -> phase should increase)
    assert len(history) == 11
    assert abs(phases[-1]) > 0.0 # Phase should evolve
    assert history[-1].coherence <= 1.0
