from typing import List, Dict, Any, Optional
from genesis_governance.types import GenesisBaseModel
from genesis_governance.schemas.shrapnel import ShrapnelMap, ShrapnelFragment

class BuilderProposal(GenesisBaseModel):
    proposal_id: str
    intended_use: str
    fragments: List[ShrapnelFragment]
    total_tau: float
    admission_status: str # "ACCEPTED", "REJECTED", "PENDING_REVIEW"
    rejection_reasons: List[str] = []
    inherited_gaps: List[str] = []
    
class BuilderPolicy(GenesisBaseModel):
    min_tau_threshold: float = 0.70
    require_certificate: bool = True
    banned_fragility_classes: List[str] = ["impedance-spike-precursor", "time-delayed-failure"]
    allowed_tiers: List[str] = ["S", "E"]
