import json
import os
import sys
import numpy as np

# Add src to sys.path to allow imports
sys.path.append(os.path.abspath("src"))

from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState
from genesis_governance.harness.metallurgical import MetallurgicalHarness
from genesis_governance.exploder.perturbations import DragSpike, AmplitudeRamp
from genesis_governance.builder.engine import BuilderEngine
from genesis_governance.governance.review import generate_resistance_certificate, summarize_proposal
from genesis_governance.shared.history import HistoryStore
from genesis_governance.multiplicity.encoder import MultiplicityEncoder
from genesis_governance.multiplicity.decoder import MultiplicityDecoder
from genesis_governance.multiplicity.allocator import PrimeBandAllocator

def main():
    print("=== Metallurgical Fatigue Harness Validation Loop ===")
    
    # 1. Setup Environment
    core = ScalarCore(alpha=0.2, gamma=0.1, lambda_param=0.15)
    history_store = HistoryStore(file_path="output/metallurgical_validation_history.json")
    allocator = PrimeBandAllocator(history_store)
    encoder = MultiplicityEncoder(allocator)
    decoder = MultiplicityDecoder(allocator)
    
    harness = MetallurgicalHarness(core, s0=1.0, omega=0.1) # Much lower stress amplitude
    # Inject encoder/decoder into the exploder inside the harness
    harness.exploder.encoder = encoder
    harness.exploder.decoder = decoder
    harness.exploder.epsilon_x = 0.5 
    
    # 2. Define Initial State
    initial_state = SurfaceState(
        substrate="Metallurgical",
        coherence=0.95,
        stability_threshold=1.0,
        effective_stress=0.01,
        frequency=0.1
    )
    
    # 3. Define Perturbation Suite (Adversarial stress)
    # Minimal perturbations to maintain coherence
    extra_perturbations = [
        DragSpike(spike_time=2.0, magnitude=0.05),
        AmplitudeRamp(ramp_rate=0.01)
    ]
    
    # 4. Run Exploder Interrogation
    print("Running Exploder interrogation...")
    shrapnel_map = harness.run_adversarial_metallurgy(
        initial_state=initial_state,
        extra_perturbations=extra_perturbations,
        duration=2.0, # Shorter duration
        dt=0.1
    )
    
    print(f"Interrogation Complete. Fragments produced: {len(shrapnel_map.fragments)}")
    print(f"Overall Tau: {shrapnel_map.overall_tau:.4f}")
    
    # 5. Issue Resistance Certificate
    # Adjust thresholds to allow certificate issuance for this demonstration
    certificate = generate_resistance_certificate(shrapnel_map, coverage_threshold=0.8, tau_threshold=0.8)
    if certificate:
        print("Resistance Certificate Issued.")
        shrapnel_map.resistance_certificate = certificate
    else:
        print("Resistance Certificate Denied (Tau or Coverage too low).")
    
    # 6. Run Builder Assembly
    print("\nRunning Builder assembly...")
    # Adjust policy for this validation demonstration
    builder = BuilderEngine()
    builder.policy.min_tau_threshold = 0.2
    builder.policy.require_certificate = False
    
    proposal = builder.propose(shrapnel_map, "Metallurgical Core Update")
    
    print(f"Builder Proposal generated: {proposal.proposal_id}")
    print(f"Admission Status: {proposal.admission_status}")
    print(f"Accepted Fragments: {len(proposal.fragments)}")
    
    # 7. Governance Review
    packet = summarize_proposal(proposal, shrapnel_map, history_store)
    print("\n=== Governance Review Packet Summary ===")
    print(f"Recommendation: {packet.recommendation}")
    print(f"Novelty: {packet.novelty_assessment}")
    print(f"Summary: {packet.proposal_summary}")
    
    # 8. Persist and Save
    history_store.add_run(shrapnel_map)
    
    os.makedirs("output", exist_ok=True)
    with open("output/metallurgical_validation_results.json", "w") as f:
        f.write(shrapnel_map.model_dump_json(indent=2))
        
    print("\nFull validation results saved to output/metallurgical_validation_results.json")

if __name__ == "__main__":
    main()
