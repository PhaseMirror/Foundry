import pytest
from genesis_governance.lane_f.engine import LaneFCore
from genesis_governance.harness.biological import BiologicalHarness
from genesis_governance.types import SurfaceState

def test_biological_adaptation():
    # beta > 0 enables adaptive recovery
    core = LaneFCore(alpha=0.1, gamma=0.1, beta=0.2)
    harness = BiologicalHarness(core)
    
    # State with low vitality
    state = SurfaceState(
        substrate="Biological",
        coherence=0.2,
        stability_threshold=1.0,
        effective_stress=0.1
    )
    
    # Run simulation for 1 step
    history = harness.run_simulation(state, duration=0.1, dt=0.1)
    
    # Check adaptation: With beta > 0, recovery should be faster than alpha alone.
    # dC/dt = alpha(Cx* - Cx) - gamma*S_eff*Cx + beta(1-Cx)(Cx* - Cx) + coupling - delta
    # dC/dt = 0.1*(1.0-0.2) - 0.1*0.1*0.2 + 0.2*(1.0-0.2)*(1.0-0.2) - 0.01
    #       = 0.08 - 0.002 + 0.128 - 0.01 = 0.196
    # Coherence after dt=0.1: 0.2 + 0.196 * 0.1 = 0.2196
    assert history[-1].coherence > state.coherence
    assert history[-1].coherence == pytest.approx(0.2196, abs=1e-4)

def test_biological_fatigue():
    # High stress load should lead to fatigue accumulation
    # delta=0.01 (default)
    core = LaneFCore(alpha=0.1, gamma=0.5, beta=0.0, delta=0.01) 
    harness = BiologicalHarness(core)
    
    state = SurfaceState(
        substrate="Biological",
        coherence=0.8,
        stability_threshold=1.0,
        effective_stress=0.5
    )
    
    # Run simulation for 1 step
    history = harness.run_simulation(state, duration=0.1, dt=0.1)
    
    # dC/dt = 0.1*(1.0-0.8) - 0.5*0.5*0.8 + 0.0 - 0.01 = 0.02 - 0.2 - 0.01 = -0.19
    # Coherence after dt=0.1: 0.8 + (-0.19)*0.1 = 0.781
    assert history[-1].coherence < state.coherence
    assert history[-1].coherence == pytest.approx(0.781, abs=1e-4)
