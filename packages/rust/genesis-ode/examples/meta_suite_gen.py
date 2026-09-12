import os
import sys

# Add src to sys.path
sys.path.append(os.path.abspath("src"))

from genesis_governance.lane_d.schema import MetaContext
from genesis_governance.lane_d.meta_observer import generate_meta_telemetry

def run_suite():
    # Define a suite of runs with different profiles
    profiles = [
        ("v0.5.0", "baseline", "manual"),
        ("v0.5.1-alpha", "aggressive-exploration", "sweep"),
        ("v0.5.1-alpha", "stable-production", "regression")
    ]
    
    # We simulate a "run" output by passing the metallurgical results
    # and assigning different context to each.
    base_results = "output/metallurgical_validation_results.json"
    
    print("=== Generating Meta-Telemetry Suite ===")
    
    for version, profile, trigger in profiles:
        ctx = MetaContext(
            adr_version=version,
            config_profile_id=profile,
            trigger=trigger,
            run_label=f"suite-run-{profile}"
        )
        
        output_path = f"output/meta_telemetry_{profile}.json"
        print(f"Generating telemetry for profile: {profile} ({version})")
        generate_meta_telemetry(base_results, output_path, context=ctx)

if __name__ == "__main__":
    run_suite()
