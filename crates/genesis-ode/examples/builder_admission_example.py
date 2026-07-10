import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "src"))

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp
from genesis_governance.builder.engine import BuilderEngine
from genesis_governance.schemas.shrapnel import ResistanceCertificate
from genesis_governance.types import SurfaceState

def main():
    print("Running Builder Admission Example...")
    core = ScalarCore(alpha=0.2, gamma=0.02)
    exploder = ExploderEngine(core, epsilon_x=0.3)
    builder = BuilderEngine()

    state = SurfaceState(substrate="Met", coherence=0.9, stability_threshold=1.0, effective_stress=0.01)
    p = AmplitudeRamp(ramp_rate=0.005) # Mild stress

    shrapnel_map = exploder.run(state, [p], duration=10.0, dt=0.1)
    
    # Add mandatory certificate
    shrapnel_map.resistance_certificate = ResistanceCertificate(
        scope="Low-stress baseline",
        attestation="Validated stability under mild ramp",
        signature_metadata={"prime": "7"},
        tier="S"
    )
    
    print(f"Computed Tau: {shrapnel_map.overall_tau:.4f}")
    proposal = builder.propose(shrapnel_map, "Cross-substrate stabilization baseline")
    print(f"Admission Status: {proposal.admission_status}")
    
    if proposal.admission_status == "ACCEPTED":
        print("SUCCESS: Builder proposal accepted and emitted with [S] tier.")
        
    os.makedirs("output", exist_ok=True)
    with open("output/example_builder_proposal.json", "w") as f:
        f.write(proposal.model_dump_json(indent=2))
    print("Proposal saved to output/example_builder_proposal.json")

if __name__ == "__main__":
    main()
