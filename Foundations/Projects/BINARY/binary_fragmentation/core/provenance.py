"""
core/provenance.py
==================
First-Class Provenance Tracking and Rollback Ledger.
Enforces that every transformation records:
- State ID & Parent State ID
- Operator name & Parameters
- Information removed & Information added
- Checksums and Reversibility status
"""

from __future__ import annotations
import copy
import hashlib
import time
from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class ProvenanceRecord:
    """Detailed causal ledger entry documenting a single state transformation."""
    state_id: str
    parent_state_id: Optional[str]
    operator: str
    timestamp: float = field(default_factory=time.time)
    parameters: Dict[str, Any] = field(default_factory=dict)
    info_removed: Dict[str, Any] = field(default_factory=dict)
    info_added: Dict[str, Any] = field(default_factory=dict)
    checksum_before: str = ""
    checksum_after: str = ""
    reversible: bool = True
    reversibility_notes: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> ProvenanceRecord:
        return cls(
            state_id=str(data["state_id"]),
            parent_state_id=data.get("parent_state_id"),
            operator=str(data.get("operator", "unknown")),
            timestamp=float(data.get("timestamp", time.time())),
            parameters=data.get("parameters", {}),
            info_removed=data.get("info_removed", {}),
            info_added=data.get("info_added", {}),
            checksum_before=str(data.get("checksum_before", "")),
            checksum_after=str(data.get("checksum_after", "")),
            reversible=bool(data.get("reversible", True)),
            reversibility_notes=str(data.get("reversibility_notes", "")),
        )


class ProvenanceLedger:
    """
    Append-only causal lineage tracking ledger for state evolutions.
    Maintains full chain of custody and evaluates causal graph depth.
    """

    def __init__(self) -> None:
        self.records: List[ProvenanceRecord] = []
        self._index_by_state: Dict[str, ProvenanceRecord] = {}

    def append(self, record: ProvenanceRecord) -> None:
        self.records.append(record)
        self._index_by_state[record.state_id] = record

    def get_history(self, state_id: str) -> List[ProvenanceRecord]:
        """Traces the backward causal ancestry from a given state to root."""
        chain: List[ProvenanceRecord] = []
        current_id: Optional[str] = state_id
        visited = set()

        while current_id and current_id in self._index_by_state:
            if current_id in visited:
                break  # Prevent infinite cycle
            visited.add(current_id)
            rec = self._index_by_state[current_id]
            chain.append(rec)
            current_id = rec.parent_state_id

        chain.reverse()
        return chain

    def compute_irreversibility_score(self) -> float:
        """
        Fraction of transformations marked irreversible in the ledger.
        Range: 0.0 (fully reversible) to 1.0 (completely irreversible).
        """
        if not self.records:
            return 0.0
        irreversible_count = sum(1 for r in self.records if not r.reversible)
        return irreversible_count / len(self.records)

    def to_dict_list(self) -> List[Dict[str, Any]]:
        return [r.to_dict() for r in self.records]
