import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "src"))

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp
from genesis_governance.types import SurfaceState

def main():
    print("Running Metallurgical Fatigue Demo (Lane A)...")
    core = ScalarCore(alpha=0.1, gamma=0.1)
    exploder = ExploderEngine(core, epsilon_x=0.08)
    
    state = SurfaceState(
        substrate="substrate:metallurgical_fatigue",
        coherence=0.9,
        stability_threshold=1.0,
        effective_stress=0.1
    )
    
    # Apply a standard amplitude ramp
    p = AmplitudeRamp(ramp_rate=0.05)
    shrapnel_map = exploder.run(state, [p], duration=5.0, dt=0.1)
    
    print(f"Run Complete.")
    print(f"Overall Tau: {shrapnel_map.overall_tau:.4f}")
    print(f"Fragments Generated: {len(shrapnel_map.fragments)}")
    
    # Save the result
    os.makedirs("output", exist_ok=True)
    with open("output/example_metallurgical.json", "w") as f:
        f.write(shrapnel_map.model_dump_json(indent=2))
    print("Result saved to output/example_metallurgical.json")

if __name__ == "__main__":
    main()
