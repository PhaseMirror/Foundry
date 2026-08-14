from genesis_governance.schemas.builder import BuilderProposal
from genesis_governance.schemas.shrapnel import ShrapnelMap, ResistanceCertificate
from genesis_governance.schemas.governance import GovernancePacket
from genesis_governance.shared.history import HistoryStore
from typing import Optional, Dict, Any
import datetime

def generate_resistance_certificate(
    shrapnel_map: ShrapnelMap,
    coverage_threshold: float = 0.80,
    tau_threshold: float = 0.70
) -> Optional[ResistanceCertificate]:
    """
    Evaluates a ShrapnelMap and issues a ResistanceCertificate if criteria are met (ADR-006).
    """
    if shrapnel_map.coverage < coverage_threshold:
        return None
    if shrapnel_map.overall_tau < tau_threshold:
        return None
        
    return ResistanceCertificate(
        scope=f"Substrate coverage: {shrapnel_map.coverage:.2f}",
        attestation="Validated via adversarial Exploder interrogation suite.",
        signature_metadata={
            "certified_at": datetime.datetime.utcnow().isoformat(),
            "tau": shrapnel_map.overall_tau,
            "coverage": shrapnel_map.coverage
        }
    )

def summarize_proposal(
    proposal: BuilderProposal, 
    shrapnel_map: ShrapnelMap,
    history_store: Optional[HistoryStore] = None
) -> GovernancePacket:
    """
    Summarizes a BuilderProposal into a GovernancePacket for human-in-the-loop review.
    Uses HistoryStore for quantitative novelty assessment (ADR-006).
    """
    
    recommendation = "MANUAL_REVIEW"
    if proposal.admission_status == "ACCEPTED":
        recommendation = "APPROVE"
    elif proposal.admission_status == "REJECTED":
        recommendation = "QUARANTINE"
        
    # Novelty Assessment
    novelty = "Low"
    if history_store:
        counts = history_store.get_fragility_class_counts()
        current_classes = {f.fragility_class for f in shrapnel_map.fragments}
        
        is_novel = False
        min_count = 999
        for cls in current_classes:
            count = counts.get(cls, 0)
            if count == 0:
                is_novel = True
            min_count = min(min_count, count)
            
        if is_novel:
            novelty = "High (Unseen fragility classes detected)"
            recommendation = "MANUAL_REVIEW"
        elif min_count < 3:
            novelty = f"Medium (Rare fragility classes detected, count={min_count})"
        elif proposal.total_tau < 0.8:
            novelty = "Medium (Low tau tension)"
    else:
        # Fallback
        novelty = "Medium (Uncertainty - no history store)"
    
    summary = (
        f"Proposal {proposal.proposal_id} for {proposal.intended_use}. "
        f"Status: {proposal.admission_status}. "
        f"Accepted Fragments: {len(proposal.fragments)}. "
        f"Gaps: {len(proposal.inherited_gaps)}."
    )
    
    return GovernancePacket(
        proposal_summary=summary,
        overall_tau=proposal.total_tau,
        novelty_assessment=novelty,
        provenance_summary=proposal.provenance,
        shrapnel_map_ref=shrapnel_map.run_id,
        recommendation=recommendation,
        tier=proposal.tier
    )
