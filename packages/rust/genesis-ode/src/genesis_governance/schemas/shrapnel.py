from typing import List, Optional, Dict, Any, Literal
from genesis_governance.types import GenesisBaseModel, EvidenceTier

class ShrapnelFragment(GenesisBaseModel):
    target_id: str
    baseline_intent: str
    test_suite: List[str]
    observed_drift: Dict[str, float]
    fragility_class: str
    tether_tension: float
    metadata: Dict[str, Any] = {}

class ResistanceCertificate(GenesisBaseModel):
    scope: str
    attestation: str
    signature_metadata: Dict[str, Any]
    metadata: Dict[str, Any] = {}

class ShrapnelMap(GenesisBaseModel):
    fragments: List[ShrapnelFragment]
    resistance_certificate: Optional[ResistanceCertificate] = None
    overall_tau: float
    coverage: float
