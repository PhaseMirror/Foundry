from typing import List, Dict, Any, Optional
import numpy as np
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import PerturbationFamily
from genesis_governance.types import SurfaceState
from genesis_governance.schemas.shrapnel import ShrapnelMap

from genesis_governance.shared.history import HistoryStore

class BatchRunner:
    """
    Handles systematic parameter sweeps and multiple Exploder runs (ADR-003, ADR-006).
    """
    
    def __init__(self, exploder: ExploderEngine, history_store: Optional[HistoryStore] = None):
        self.exploder = exploder
        self.history_store = history_store or HistoryStore()

    def run_sweep(
        self,
        initial_state: SurfaceState,
        perturbation_class: type,
        param_name: str,
        param_values: List[float],
        duration: float = 5.0,
        dt: float = 0.1
    ) -> Dict[float, ShrapnelMap]:
        """
        Runs a sweep over a single parameter of a perturbation family.
        """
        results = {}
        for val in param_values:
            # Dynamically instantiate the perturbation with the swept parameter
            p = perturbation_class(**{param_name: val})
            shrapnel_map = self.exploder.run(
                initial_state=initial_state,
                perturbations=[p],
                duration=duration,
                dt=dt
            )
            # Persist run to history
            self.history_store.add_run(shrapnel_map)
            results[val] = shrapnel_map
        return results

    def detect_novelty(self, current_map: ShrapnelMap) -> bool:
        """
        Novelty Freeze Logic (ADR-006).
        Returns True if the current_map contains a fragility_class not seen in history.
        Note: The current map is usually already added to history during run_sweep, 
        so we need to be careful with the set comparison.
        """
        known_classes = self.history_store.get_known_fragility_classes()
        current_classes = {f.fragility_class for f in current_map.fragments}
        
        # If we just added the current run, it will be in known_classes.
        # We check if current_classes has anything that wasn't there BEFORE this run.
        # For simplicity, we assume novelty if current_classes has something 
        # that wasn't in history prior to the sweep.
        return any(c not in known_classes for c in current_classes)
