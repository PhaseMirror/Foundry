from typing import List, Optional, Dict, Any, Literal
from pydantic import BaseModel, Field
from datetime import datetime
import uuid
import json

class MetaContext(BaseModel):
    adr_version: str = "v0.5.0"
    policy_version: str = "1.0.0"
    commit_hash: str = "HEAD"
    scenario_id: str = "default"
    innovation_budget_id: str = "default"
    config_profile_id: str = "default"
    lane_set: List[str] = Field(default_factory=list)
    run_label: str = "validation"
    trigger: Literal["manual", "regression", "sweep", "release-candidate"] = "manual"
class MetaShrapnelFragment(BaseModel):
    meta_fragment_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    artifact_hash: str = ""
    source_run_id: str
    context: MetaContext
    tau_trajectory_hash: Optional[str] = None
    max_drift_observed: float
    near_failure_events: int = 0
    reconstruction_fidelity: float
    overall_tau: float = 0.0

    # Decomposed Meta-Coherence (C_D) components
    cd_overall: float = 1.0
    cd_tau: float = 1.0
    cd_recon: float = 1.0
    cd_fail: float = 1.0
    bottleneck: str = "NONE"
    slo_status: Dict[str, str] = {}

    governance_decision: str 
    meta_fragility_class: str 
    suggested_action: str 
    is_policy_compliant: bool = True
    violation_reason: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    def compute_hash(self) -> str:
        import hashlib
        data = self.model_dump(exclude={"artifact_hash"})
        return hashlib.sha256(json.dumps(data, sort_keys=True, default=str).encode()).hexdigest()


class GovernanceActionTrace(BaseModel):
    rule_id: str
    rule_source: str # e.g., "ADR-017.R1"
    condition_predicate: str
    evidence_refs: List[str] # List of fragment IDs
    justification: str

class GovernanceAction(BaseModel):
    action_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    lane_id: str
    commanded_profile: str
    target_fragility_class: str
    trace: Optional[GovernanceActionTrace] = None

class HumanAudit(BaseModel):
    reviewer_id: str
    status: Literal["OPEN", "APPROVED", "REJECTED", "ESCALATED"] = "OPEN"
    comment: str = ""
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class ConstitutionalIncidentReport(BaseModel):
    report_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    cir_version: str = "1.0.0"
    artifact_hash: str = "" # To be populated post-generation
    source_run_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    # Governance Context
    context: MetaContext
    
    # State Snapshot
    meta_fragility_class: str
    cd_global: float
    
    # Traceability
    actions: List[GovernanceAction]
    
    # Human Review
    human_audit: Optional[HumanAudit] = None

    def compute_hash(self) -> str:
        import hashlib
        # Exclude human_audit and artifact_hash from hash computation for immutability
        data = self.model_dump(exclude={"human_audit", "artifact_hash"})
        return hashlib.sha256(json.dumps(data, sort_keys=True, default=str).encode()).hexdigest()

class GlobalAssessment(BaseModel):
    cd_global: float
    dominant_bottleneck: str
    collapse_count: int
    protected_lane_violations: int

class MetaShrapnelMap(BaseModel):
    """
    Aggregated meta-telemetry for a set of governance runs.
    """
    meta_run_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    source_run_ids: List[str]
    meta_fragments: List[MetaShrapnelFragment]
    meta_coherence: float = 1.0 # C_D state (decomposed)
    cd_tau: float = 1.0
    cd_recon: float = 1.0
    cd_fail: float = 1.0
    primary_bottleneck: str = "NONE"
    slo_summary: Dict[str, str] = {}
    avg_reconstruction_fidelity: float = 0.0
    meta_tether_tension: float = 0.0
    provenance: Dict[str, Any] = {}

class MultiSubstrateMetaMap(BaseModel):
    meta_run_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    meta_fragments: Dict[str, MetaShrapnelFragment]
    global_context: MetaContext
    global_assessment: GlobalAssessment
    recommended_actions: List[GovernanceAction] = Field(default_factory=list)
