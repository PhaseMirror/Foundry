import pytest
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState

def test_core_parameter_validation():
    # Valid parameters should not raise
    ScalarCore(alpha=0.5, gamma=0.1)
    
    # Negative parameters should raise ValueError
    with pytest.raises(ValueError, match="Dissipative and coupling parameters must be non-negative"):
        ScalarCore(alpha=-0.1)
    
    with pytest.raises(ValueError, match="Dissipative and coupling parameters must be non-negative"):
        ScalarCore(gamma=-0.1)
        
    # Alpha > 1.0 should raise
    with pytest.raises(ValueError, match="Alpha \(recovery rate\) > 1.0 risk numerical instability"):
        ScalarCore(alpha=1.1)

def test_core_coherence_bounds():
    core = ScalarCore(alpha=0.1, gamma=0.5)
    state = SurfaceState(
        substrate="test",
        coherence=0.5,
        stability_threshold=1.0,
        effective_stress=10.0 # High stress to force coherence down
    )
    
    # Step multiple times
    for _ in range(100):
        state = core.step(state, dt=1.0, next_s_eff=10.0)
        
    # Coherence should never be negative
    assert state.coherence >= 0.0
    
    # High recovery, low stress
    state = SurfaceState(
        substrate="test",
        coherence=0.5,
        stability_threshold=1.0,
        effective_stress=0.0
    )
    for _ in range(100):
        state = core.step(state, dt=1.0, next_s_eff=0.0)
        
    # Coherence should never exceed stability_threshold
    assert state.coherence <= 1.0

def test_impedance_saturation_protection():
    core = ScalarCore()
    # High stress should increase rho
    # rho = cx_star * (1 - e^(-lambda * S_eff))
    # As S_eff -> infinity, rho -> cx_star
    # Omega = 1 / sqrt(1 - (rho/cx_star)^2)
    # If rho == cx_star, Omega is undefined (inf)
    
    state = SurfaceState(
        substrate="test",
        coherence=1.0,
        stability_threshold=1.0,
        effective_stress=1000.0 # Extreme stress
    )
    
    metrics = core.compute_impedance(state)
    # Protection should keep ratio < 1.0
    assert metrics["impedance"] > 0
    assert metrics["impedance"] < 100 # Capped by 0.999 ratio in implementation
