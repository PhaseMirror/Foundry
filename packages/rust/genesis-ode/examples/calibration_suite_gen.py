import os
import sys
import numpy as np

# Add src to sys.path
sys.path.append(os.path.abspath("src"))

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState
from genesis_governance.lane_e.engine import LaneECore
from genesis_governance.harness.quantum import QuantumHarness
from genesis_governance.lane_f.engine import LaneFCore
from genesis_governance.harness.biological import BiologicalHarness
from genesis_governance.lane_g.engine import LaneGCore
from genesis_governance.harness.ecological import EcologicalHarness
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp, DragSpike
from genesis_governance.lane_d.schema import MetaContext
from genesis_governance.lane_d.meta_observer import generate_meta_telemetry

def run_lane_run(lane_id, substrate, engine, harness, perturbations, profile, version):
    print(f"Running {substrate} ({profile})...")
    # Setup state
    initial_state = SurfaceState(
        substrate=substrate,
        coherence=0.9,
        stability_threshold=1.0,
        effective_stress=0.1
    )
    
    # Run
    # Quantum is special, handled separately, E, F, G handled by Exploder
    exploder = ExploderEngine(engine)
    shrapnel_map = exploder.run(initial_state, perturbations, duration=2.0, dt=0.1)
    
    # Save shrapnel
    output_path = f"output/calibration_{lane_id}_{profile}.json"
    os.makedirs("output", exist_ok=True)
    with open(output_path, "w") as f:
        f.write(shrapnel_map.model_dump_json(indent=2))
        
    # Generate meta telemetry
    ctx = MetaContext(adr_version=version, config_profile_id=profile, run_label=f"cal-{lane_id}-{profile}")
    generate_meta_telemetry(output_path, f"output/meta_{lane_id}_{profile}.json", context=ctx)

def main():
    print("=== Generating Calibration Telemetry Suite ===")
    
    # Lane E
    e_core = LaneECore(alpha=0.1, omega=0.5)
    
    # Lane F
    f_core = LaneFCore(alpha=0.1, gamma=0.1, beta=0.2)
    
    # Lane G
    g_core = LaneGCore(alpha=0.1, gamma=0.1, beta=0.2)
    
    profiles = ["baseline", "exploration", "production"]
    
    for profile in profiles:
        # Lane E
        pert_e = [AmplitudeRamp(ramp_rate=0.01 if profile=="baseline" else 0.1)]
        run_lane_run("E", "Quantum", e_core, None, pert_e, profile, "v0.5.1-alpha")
        
        # Lane F
        pert_f = [DragSpike(spike_time=1.0, magnitude=0.1 if profile=="baseline" else 0.5)]
        run_lane_run("F", "Biological", f_core, None, pert_f, profile, "v0.5.1-alpha")
        
        # Lane G
        pert_g = [AmplitudeRamp(ramp_rate=0.05 if profile=="baseline" else 0.2)]
        run_lane_run("G", "Ecological", g_core, None, pert_g, profile, "v0.5.1-alpha")

if __name__ == "__main__":
    main()
