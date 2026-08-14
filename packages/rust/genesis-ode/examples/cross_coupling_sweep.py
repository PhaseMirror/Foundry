import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "src"))

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp, ContradictionInflation, FrequencyShift, CouplingWeightSpike
from genesis_governance.harness.cross_coupling import CrossSubstrateHarness
from genesis_governance.types import SurfaceState, MultiSubstrateState

def main():
    print("Running Path A Heterogeneous Cross-Coupling Sweep (Met + AI)...")
    core = ScalarCore(alpha=0.1, gamma=0.1)
    exploder = ExploderEngine(core, epsilon_x=0.5)
    
    state_met = SurfaceState(substrate="Met", coherence=0.9, stability_threshold=1.0, effective_stress=0.1, frequency=1.0)
    state_ai = SurfaceState(substrate="AI", coherence=0.9, stability_threshold=1.0, effective_stress=0.1)
    
    perturbations = [
        AmplitudeRamp(ramp_rate=0.2, target_substrate="Met"),
        FrequencyShift(shift_rate=0.1, target_substrate="Met"),
        ContradictionInflation(inflation_rate=0.15, target_substrate="AI"),
        CouplingWeightSpike(spike_time=1.0, magnitude=2.0, from_sub="Met", to_sub="AI")
    ]
    
    kappa = 0.5
    harness = CrossSubstrateHarness(core, kappa=kappa)
    multi_state = MultiSubstrateState(
        states={"Met": state_met, "AI": state_ai},
        coupling_matrix={"Met": {"AI": 1.0}, "AI": {"Met": 1.0}}
    )
    
    shrapnel_map = exploder.run_multi(
        multi_state, 
        harness, 
        perturbations, 
        duration=5.0, 
        dt=0.1
    )
    
    print(f"Sweep Trajectory Complete for kappa={kappa}.")
    print(f"Overall Tau: {shrapnel_map.overall_tau:.4f}")
    
    os.makedirs("output", exist_ok=True)
    with open("output/example_cross_coupling.json", "w") as f:
        f.write(shrapnel_map.model_dump_json(indent=2))
    print("Result saved to output/example_cross_coupling.json")

if __name__ == "__main__":
    main()
