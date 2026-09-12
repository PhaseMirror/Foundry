from typing import List, Dict, Union, Optional
import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState, MultiSubstrateState
from genesis_governance.exploder.perturbations import PerturbationFamily
from genesis_governance.schemas.shrapnel import ShrapnelMap, ShrapnelFragment
from genesis_governance.tether.metric import compute_tau
from genesis_governance.harness.cross_coupling import CrossSubstrateHarness
from genesis_governance.multiplicity.encoder import MultiplicityEncoder
from genesis_governance.multiplicity.decoder import MultiplicityDecoder

class ExploderEngine:
    """
    Deterministic adversarial stress-testing engine (ADR-003).
    Includes optional Multiplicity tagging (ADR-007).
    """
    
    def __init__(
        self, 
        core: ScalarCore, 
        epsilon_x: float = 0.5, 
        encoder: Optional[MultiplicityEncoder] = None,
        decoder: Optional[MultiplicityDecoder] = None
    ):
        self.core = core
        self.epsilon_x = epsilon_x
        self.encoder = encoder
        self.decoder = decoder

    def run(
        self, 
        initial_state: SurfaceState, 
        perturbations: List[PerturbationFamily],
        duration: float, 
        dt: float,
        required_coverage: float = 1.0
    ) -> ShrapnelMap:
        
        history = [initial_state]
        current_state = initial_state
        baseline_state = initial_state
        
        steps = int(duration / dt)
        fragments = []
        
        for i in range(1, steps + 1):
            t = current_state.timestamp + dt
            
            # Apply perturbations
            for p in perturbations:
                current_state = p.apply(current_state, t)
            
            current_state = self.core.step(current_state, dt, current_state.effective_stress)
            history.append(current_state)
            
            drift = abs(current_state.coherence - baseline_state.coherence)
            if drift > 0.01:
                metadata = {}
                if self.encoder:
                    encoding = self.encoder.encode(current_state)
                    
                    if self.decoder:
                        # Attach validation metrics
                        encoding.reconstruction_score = self.decoder.compute_reconstruction_score(current_state, encoding)
                        encoding.locality_delta = self.decoder.validate_locality(encoding, {2: 1})
                        
                    metadata["multiplicity"] = encoding.model_dump()

                fragments.append(ShrapnelFragment(
                    target_id=current_state.substrate,
                    baseline_intent="stability",
                    test_suite=[p.name for p in perturbations],
                    observed_drift={"coherence_drift": drift},
                    fragility_class="impedance-spike-precursor" if drift > self.epsilon_x else "robust",
                    tether_tension=0.0,
                    tier="S",
                    metadata=metadata
                ))

        max_drift = max([f.observed_drift["coherence_drift"] for f in fragments]) if fragments else 0.0
        coverage = len(fragments) / steps if steps > 0 else 0.0
        
        tau = compute_tau(coverage, required_coverage, max_drift, self.epsilon_x)
        
        return ShrapnelMap(fragments=fragments, overall_tau=tau, coverage=coverage, tier="S")

    def run_multi(
        self,
        initial_multi_state: MultiSubstrateState,
        harness: CrossSubstrateHarness,
        perturbations: List[Union[PerturbationFamily, "CouplingPerturbation"]],
        duration: float,
        dt: float,
        required_coverage: float = 1.0
    ) -> ShrapnelMap:
        """
        Runs an adversarial trajectory across multiple coupled substrates.
        """
        current_multi_state = initial_multi_state
        baseline_multi_state = initial_multi_state
        
        steps = int(duration / dt)
        fragments = []
        
        for i in range(1, steps + 1):
            t = current_multi_state.timestamp + dt
            
            # 1. Apply multi-substrate perturbations (like CouplingWeightSpike)
            for p in perturbations:
                if hasattr(p, "apply_to_multi"):
                    current_multi_state = p.apply_to_multi(current_multi_state, t)
            
            # 2. Apply individual perturbations
            new_states = {}
            for sub_id, state in current_multi_state.states.items():
                temp_state = state
                for p in perturbations:
                    if hasattr(p, "apply") and not hasattr(p, "apply_to_multi"):
                        temp_state = p.apply(temp_state, t)
                new_states[sub_id] = temp_state
            
            current_multi_state = MultiSubstrateState(
                states=new_states,
                coupling_matrix=current_multi_state.coupling_matrix,
                timestamp=current_multi_state.timestamp
            )
            
            # 3. Harness step (coupling + core evolution)
            next_stresses = {sid: s.effective_stress for sid, s in current_multi_state.states.items()}
            current_multi_state = harness.step(current_multi_state, dt, next_stresses)
            
            # 4. Drift measurement and fragment generation
            for sub_id, state in current_multi_state.states.items():
                baseline_state = baseline_multi_state.states[sub_id]
                drift = abs(state.coherence - baseline_state.coherence)
                
                if drift > 0.01:
                    metadata = {}
                    if self.encoder:
                        encoding = self.encoder.encode(state)
                        
                        if self.decoder:
                            encoding.reconstruction_score = self.decoder.compute_reconstruction_score(state, encoding)
                            encoding.locality_delta = self.decoder.validate_locality(encoding, {2: 1})
                            
                        metadata["multiplicity"] = encoding.model_dump()

                    fragments.append(ShrapnelFragment(
                        target_id=f"substrate:{sub_id}",
                        baseline_intent="coupled stability",
                        test_suite=[p.name if hasattr(p, 'name') else "coupling_spike" for p in perturbations],
                        observed_drift={"coherence_drift": drift},
                        fragility_class="recovery-deficit-amplification" if drift > self.epsilon_x else "robust",
                        tether_tension=0.0,
                        tier="S",
                        metadata=metadata
                    ))
                    
        max_drift = max([f.observed_drift["coherence_drift"] for f in fragments]) if fragments else 0.0
        coverage = len(fragments) / (steps * len(initial_multi_state.states)) if steps > 0 else 0.0
        
        tau = compute_tau(coverage, required_coverage, max_drift, self.epsilon_x)
        
        return ShrapnelMap(fragments=fragments, overall_tau=tau, coverage=coverage, tier="S")
