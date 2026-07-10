import pytest
import json
import os
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp
from genesis_governance.types import SurfaceState

def test_metallurgical_golden_master_regression():
    # 1. Setup matching the golden master generation (make golden-master)
    core = ScalarCore()
    exploder = ExploderEngine(core)
    state = SurfaceState(substrate="Met", coherence=0.9, stability_threshold=1.0, effective_stress=0.1)
    p = AmplitudeRamp(ramp_rate=0.1)
    
    # 2. Run
    current_run = exploder.run(state, [p], duration=5.0, dt=0.1)
    current_data = current_run.model_dump()
    
    # 3. Load Golden Master
    golden_path = "tests/golden/expected-metallurgical-shrapnel.json"
    assert os.path.exists(golden_path), "Golden master file missing. Run 'make golden-master' first."
    
    with open(golden_path, "r") as f:
        golden_data = json.load(f)
        
    # 4. Compare (excluding transient fields like run_id and created_at)
    def clean(data):
        if isinstance(data, dict):
            # Recursively clean fragments
            if "fragments" in data:
                for f in data["fragments"]:
                    f.pop("run_id", None)
                    f.pop("created_at", None)
            data.pop("run_id", None)
            data.pop("created_at", None)
        return data

    assert clean(current_data) == clean(golden_data)
