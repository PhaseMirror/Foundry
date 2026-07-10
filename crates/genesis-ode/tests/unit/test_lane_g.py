import pytest
from genesis_governance.lane_g.engine import LaneGCore
from genesis_governance.harness.ecological import EcologicalHarness
from genesis_governance.types import SurfaceState

def test_ecological_resilience():
    # beta > 0 enables logistic recovery
    core = LaneGCore(alpha=0.1, gamma=0.1, beta=0.2, delta=0.01)
    harness = EcologicalHarness(core)
    
    # State with moderate resilience
    state = SurfaceState(
        substrate="Ecological",
        coherence=0.5,
        stability_threshold=1.0,
        effective_stress=0.1
    )
    
    # Run simulation for 1 step
    history = harness.run_simulation(state, duration=0.1, dt=0.1)
    
    # dC/dt = alpha(Cx* - Cx) - gamma*S_eff*Cx + beta*Cx(1 - Cx/Cx*) + coupling - delta
    # dC/dt = 0.1*(1.0-0.5) - 0.1*0.1*0.5 + 0.2*0.5*(1.0 - 0.5/1.0) - 0.01
    #       = 0.05 - 0.005 + 0.2*0.5*0.5 - 0.01
    #       = 0.05 - 0.005 + 0.05 - 0.01 = 0.085
    # Coherence after dt=0.1: 0.5 + 0.085 * 0.1 = 0.5085
    assert history[-1].coherence > state.coherence
    assert history[-1].coherence == pytest.approx(0.5085, abs=1e-4)

def test_ecological_tipping_point():
    # High stress load should lead to collapse
    core = LaneGCore(alpha=0.1, gamma=0.8, beta=0.05, delta=0.01) 
    harness = EcologicalHarness(core)
    
    state = SurfaceState(
        substrate="Ecological",
        coherence=0.2,
        stability_threshold=1.0,
        effective_stress=0.8
    )
    
    history = harness.run_simulation(state, duration=0.1, dt=0.1)
    
    # dC/dt = 0.1*(1.0-0.2) - 0.8*0.8*0.2 + 0.05*0.2*(1.0-0.2) - 0.01
    #       = 0.08 - 0.128 + 0.008 - 0.01 = -0.05
    # Coherence after dt=0.1: 0.2 + (-0.05)*0.1 = 0.195
    assert history[-1].coherence < state.coherence
    assert history[-1].coherence == pytest.approx(0.195, abs=1e-4)
