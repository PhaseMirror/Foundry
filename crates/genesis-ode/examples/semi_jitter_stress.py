import sys
import os
import numpy as np
sys.path.append("src")

from genesis_governance.lane_c.engine import LaneCCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp, TimingJitter, ThresholdNoise
from genesis_governance.multiplicity.encoder import MultiplicityEncoder
from genesis_governance.multiplicity.decoder import MultiplicityDecoder
from genesis_governance.types import SurfaceState
from genesis_governance.shared.history import HistoryStore

def main():
    print("=== Lane C: Jitter & High-Frequency Stress Interrogation ===")
    core = LaneCCore(
        alpha_on=0.2, 
        alpha_off=0.05, 
        gamma_on=0.05, 
        gamma_off=0.4,
        delta=0.01
    )
    encoder = MultiplicityEncoder()
    decoder = MultiplicityDecoder()
    exploder = ExploderEngine(core, epsilon_x=0.3, encoder=encoder, decoder=decoder)

    # Initial state: stable ON
    state = SurfaceState(
        substrate="Semi", 
        coherence=0.9, 
        stability_threshold=1.0, 
        effective_stress=0.4, # Just below threshold
        switching_threshold=0.5,
        hysteresis_band=0.05,
        logical_state="ON"
    )
    
    # Stress Suite:
    # 1. Slow ramp to crossing
    # 2. Timing Jitter (mis-timed triggers)
    # 3. Threshold Noise (thermal drift)
    perturbations = [
        AmplitudeRamp(ramp_rate=0.05), # Slow crossing
        TimingJitter(jitter_amplitude=0.15, seed=42), # Chattering potential
        ThresholdNoise(noise_amplitude=0.02, seed=43) # Drift
    ]

    print(f"Running simulation with {len(perturbations)} perturbations...")
    shrapnel_map = exploder.run(state, perturbations, duration=10.0, dt=0.05)
    
    # Analysis
    fragments = shrapnel_map.fragments
    recon_scores = []
    mismatches = 0
    
    for f in fragments:
        m_meta = f.metadata.get("multiplicity", {})
        recon_score = m_meta.get("reconstruction_score", 0.0)
        recon_scores.append(recon_score)
        
        if recon_score < 0.6: 
            mismatches += 1
            
    print(f"Simulation Complete. Steps with fragments: {len(fragments)}")
    if recon_scores:
        print(f"Average Reconstruction Score: {np.mean(recon_scores):.4f}")
        print(f"Min Reconstruction Score: {np.min(recon_scores):.4f}")
        print(f"Potential State Mismatches (low score): {mismatches}")
    
    print("\nImpact Signal:")
    if mismatches > 0:
        print("-> Detected 'Prime Fatigue' or chattering-induced misclassification.")
    else:
        print("-> Multiplicity layer remained stable under jitter.")
        
    # Save for review
    os.makedirs("output", exist_ok=True)
    with open("output/semi_jitter_results.json", "w") as f:
        f.write(shrapnel_map.model_dump_json(indent=2))
        
    # Persist to HistoryStore
    history = HistoryStore()
    history.add_run(shrapnel_map)
    
    print("\nResults saved to output/semi_jitter_results.json and persisted to history.")

if __name__ == "__main__":
    main()
