import sys
import os
sys.path.append("src")

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp
from genesis_governance.builder.engine import BuilderEngine
from genesis_governance.schemas.shrapnel import ResistanceCertificate
from genesis_governance.types import SurfaceState
from genesis_governance.multiplicity.encoder import MultiplicityEncoder
from genesis_governance.multiplicity.decoder import MultiplicityDecoder

def main():
    print("Running Lane C Semiconductor Admission Example...")
    core = ScalarCore(alpha=0.2, gamma=0.05)
    encoder = MultiplicityEncoder()
    decoder = MultiplicityDecoder()
    exploder = ExploderEngine(core, epsilon_x=0.3, encoder=encoder, decoder=decoder)
    builder = BuilderEngine()

    state = SurfaceState(
        substrate="Semi", 
        coherence=0.9, 
        stability_threshold=1.0, 
        effective_stress=0.01,
        switching_threshold=0.5,
        hysteresis_band=0.05,
        logical_state="ON"
    )
    
    # Mild stress but enough to test threshold later
    p = AmplitudeRamp(ramp_rate=0.01)

    shrapnel_map = exploder.run(state, [p], duration=5.0, dt=0.1)
    
    # Manually attach certificate
    shrapnel_map.resistance_certificate = ResistanceCertificate(
        scope="Lane C low-stress",
        attestation="Validated stability under threshold-safe ramp",
        signature_metadata={"prime_signature": [2, 3, 5]},
        tier="S"
    )
    
    print(f"Computed Tau: {shrapnel_map.overall_tau:.4f}")
    print(f"Average Recon Score: {sum([f.metadata['multiplicity']['reconstruction_score'] for f in shrapnel_map.fragments]) / len(shrapnel_map.fragments):.4f}")
    
    proposal = builder.propose(shrapnel_map, "Semiconductor baseline stabilization")
    print(f"Admission Status: {proposal.admission_status}")
    
    if proposal.admission_status == "ACCEPTED":
        print("SUCCESS: Lane C Loop closed. Builder proposal emitted with [S] tier.")

if __name__ == "__main__":
    main()
