from typing import List
import uuid
from genesis_governance.schemas.shrapnel import ShrapnelMap, ShrapnelFragment
from genesis_governance.schemas.builder import BuilderProposal, BuilderPolicy
from genesis_governance.builder.provenance import ProvenanceManager

class BuilderEngine:
    """
    Provenance-preserving assembly engine (ADR-003).
    Ensures that only certified and high-tau fragments are proposed for state updates.
    """
    
    def __init__(self, policy: BuilderPolicy = BuilderPolicy()):
        self.policy = policy

    def propose(
        self, 
        shrapnel_map: ShrapnelMap, 
        intended_use: str
    ) -> BuilderProposal:
        
        rejection_reasons = []
        accepted_fragments = []
        inherited_gaps = []
        
        # 1. Global tau check
        if shrapnel_map.overall_tau < self.policy.min_tau_threshold:
            rejection_reasons.append(
                f"Overall tau {shrapnel_map.overall_tau:.2f} below threshold {self.policy.min_tau_threshold}"
            )
            
        # 2. Certificate check
        if self.policy.require_certificate and not shrapnel_map.resistance_certificate:
            rejection_reasons.append("Missing required resistance certificate")
            
        # 3. Individual fragment checks
        for fragment in shrapnel_map.fragments:
            frag_reasons = []
            
            # Check fragility class
            if fragment.fragility_class in self.policy.banned_fragility_classes:
                frag_reasons.append(f"Banned fragility class: {fragment.fragility_class}")
            
            # Check tier
            if fragment.tier not in self.policy.allowed_tiers:
                frag_reasons.append(f"Tier {fragment.tier} not allowed in Builder")
                
            if not frag_reasons:
                accepted_fragments.append(fragment)
            else:
                inherited_gaps.extend(frag_reasons)

        # Final status determination
        status = "REJECTED" if rejection_reasons else "ACCEPTED"
        if status == "ACCEPTED" and len(accepted_fragments) < len(shrapnel_map.fragments):
            status = "PENDING_REVIEW" # Partial admission
            rejection_reasons.append(f"Partial admission: {len(accepted_fragments)}/{len(shrapnel_map.fragments)} fragments accepted")

        merged_provenance = ProvenanceManager.merge_provenance(accepted_fragments)
        
        return BuilderProposal(
            proposal_id=str(uuid.uuid4()),
            intended_use=intended_use,
            fragments=accepted_fragments,
            total_tau=shrapnel_map.overall_tau,
            admission_status=status,
            rejection_reasons=rejection_reasons,
            inherited_gaps=inherited_gaps,
            provenance=merged_provenance,
            tier="S" if status == "ACCEPTED" else "I"
        )
