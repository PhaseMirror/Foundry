import json
import os
from typing import List, Set, Dict, Any
from genesis_governance.schemas.shrapnel import ShrapnelMap

class HistoryStore:
    """
    Persistent store for run history and fragility classes (ADR-006).
    """
    def __init__(self, file_path: str = "output/run_history.json"):
        self.file_path = file_path
        self.history = self._load()

    def _load(self) -> List[Dict]:
        if os.path.exists(self.file_path):
            with open(self.file_path, "r") as f:
                try:
                    return json.load(f)
                except json.JSONDecodeError:
                    return []
        return []

    def _save(self):
        os.makedirs(os.path.dirname(self.file_path), exist_ok=True)
        with open(self.file_path, "w") as f:
            json.dump(self.history, f, indent=2, default=str)

    def add_run(self, shrapnel_map: ShrapnelMap):
        self.history.append(shrapnel_map.model_dump())
        self._save()

    def get_known_fragility_classes(self) -> Set[str]:
        known = set()
        for run in self.history:
            for frag in run.get("fragments", []):
                known.add(frag.get("fragility_class"))
        return known

    def get_fragility_class_counts(self) -> Dict[str, int]:
        counts = {}
        for run in self.history:
            for frag in run.get("fragments", []):
                cls = frag.get("fragility_class")
                counts[cls] = counts.get(cls, 0) + 1
        return counts

    def get_reconstruction_history(self) -> List[Dict[str, Any]]:
        """
        Extracts all reconstruction metrics from history for sensitivity analysis.
        """
        records = []
        for run in self.history:
            for frag in run.get("fragments", []):
                m_meta = frag.get("metadata", {}).get("multiplicity", {})
                if "reconstruction_score" in m_meta:
                    records.append({
                        "target_id": frag.get("target_id"),
                        "score": m_meta.get("reconstruction_score"),
                        "delta": m_meta.get("locality_delta"),
                        "mapping": m_meta.get("exponent_vector") # used to trace primes
                    })
        return records
