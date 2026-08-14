import pytest
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp, DragSpike
from genesis_governance.harness.metallurgical import MetallurgicalHarness

def test_exploder_metallurgical_run():
    # 1. Setup Core and Engine
    core = ScalarCore(alpha=0.2, gamma=0.5)
    exploder = ExploderEngine(core, epsilon_x=0.8)
    
    # 2. Initial State
    initial_state = SurfaceState(
        substrate="Metallurgical",
        coherence=0.9,
        stability_threshold=1.0,
        effective_stress=0.1
    )
    
    # 3. Define Perturbations
    perturbations = [
        AmplitudeRamp(ramp_rate=0.5),
        DragSpike(spike_time=1.0, magnitude=2.0)
    ]
    
    # 4. Run Exploder
    shrapnel_map = exploder.run(
        initial_state=initial_state,
        perturbations=perturbations,
        duration=2.0,
        dt=0.1,
        required_coverage=0.5
    )
    
    # 5. Assertions
    assert shrapnel_map.tier == "S"
    assert len(shrapnel_map.fragments) > 0
    assert shrapnel_map.overall_tau >= 0.0
    
    # Verify drift was captured
    drifts = [f.observed_drift["coherence_drift"] for f in shrapnel_map.fragments]
    assert max(drifts) > 0.0
    
    print(f"Final Tau: {shrapnel_map.overall_tau}")
    print(f"Coverage: {shrapnel_map.coverage}")
