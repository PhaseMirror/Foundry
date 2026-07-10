import json
import os
from typing import List
from genesis_governance.lane_d.schema import MetaShrapnelFragment

class MetaHistoryStore:
    """
    Persistent store for Lane D meta-telemetry ($\hat{\Xi}(t)$).
    """
    def __init__(self, file_path: str = "output/lane_d_history.json"):
        self.file_path = file_path
        self.history = self._load()

    def _load(self) -> List[MetaShrapnelFragment]:
        if os.path.exists(self.file_path):
            with open(self.file_path, "r") as f:
                try:
                    data = json.load(f)
                    return [MetaShrapnelFragment(**item) for item in data]
                except (json.JSONDecodeError, TypeError):
                    return []
        return []

    def _save(self):
        os.makedirs(os.path.dirname(self.file_path), exist_ok=True)
        with open(self.file_path, "w") as f:
            json.dump([f.model_dump() for f in self.history], f, indent=2, default=str)

    def add_fragment(self, fragment: MetaShrapnelFragment):
        self.history.append(fragment)
        self._save()

    def get_history(self) -> List[MetaShrapnelFragment]:
        return self.history
