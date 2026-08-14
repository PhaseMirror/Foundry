from typing import List, Dict, Any, Literal, Optional
from genesis_governance.types import GenesisBaseModel
from genesis_governance.schemas.shrapnel import ShrapnelMap
from genesis_governance.schemas.builder import BuilderProposal

class RollbackTrigger(GenesisBaseModel):
    trigger_type: str # "FRAGILITY_SPIKE", "DRIFT_EXCESS", "NOVELTY_FREEZE"
    severity: Literal["CRITICAL", "WARNING"]
    affected_substrate: str
    reason: str

class GovernancePacket(GenesisBaseModel):
    proposal_summary: str
    overall_tau: float
    novelty_assessment: str
    provenance_summary: Dict[str, Any]
    shrapnel_map_ref: str # run_id
    recommendation: Literal["APPROVE", "QUARANTINE", "MANUAL_REVIEW"]

class TieredDecision(GenesisBaseModel):
    decision: Literal["PROMOTED", "QUARANTINED", "REJECTED"]
    target_tier: Optional[str] = None
    reviewer_signature: str
    timestamp_applied: float
