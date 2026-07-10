import pytest
import time
from genesis_governance.governance.rollback import evaluate_rollback
from genesis_governance.governance.review import summarize_proposal
from genesis_governance.schemas.shrapnel import ShrapnelMap, ShrapnelFragment
from genesis_governance.schemas.builder import BuilderProposal

def test_rollback_trigger_mapping():
    # 1. Create a ShrapnelMap with a critical fragility signal
    bad_fragment = ShrapnelFragment(
        target_id="Met",
        baseline_intent="stability",
        test_suite=["ramp"],
        observed_drift={"coherence_drift": 0.5},
        fragility_class="impedance-spike-precursor",
        tether_tension=0.2,
        tier="I"
    )
    
    shrapnel_map = ShrapnelMap(
        fragments=[bad_fragment],
        overall_tau=0.2,
        coverage=1.0,
        tier="I"
    )
    
    # 2. Evaluate for rollback
    triggers = evaluate_rollback(shrapnel_map)
    
    # 3. Assertions
    assert len(triggers) == 1
    assert triggers[0].trigger_type == "FRAGILITY_SPIKE"
    assert triggers[0].severity == "CRITICAL"

def test_governance_summarization():
    # 1. Setup Mock Proposal and ShrapnelMap
    shrapnel_map = ShrapnelMap(overall_tau=0.9, coverage=1.0, fragments=[])
    proposal = BuilderProposal(
        proposal_id="test-123",
        intended_use="test",
        fragments=[],
        total_tau=0.9,
        admission_status="ACCEPTED",
        provenance={"fragment_count": 0, "source_run_ids": [], "combined_adr_ids": [], "lineage": []},
        tier="S"
    )
    
    # 2. Summarize
    packet = summarize_proposal(proposal, shrapnel_map)
    
    # 3. Assertions
    assert packet.recommendation == "APPROVE"
    assert packet.shrapnel_map_ref == shrapnel_map.run_id
    assert "ACCEPTED" in packet.proposal_summary
