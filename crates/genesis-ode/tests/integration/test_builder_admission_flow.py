import pytest
from genesis_governance.builder.engine import BuilderEngine
from genesis_governance.schemas.builder import BuilderPolicy
from genesis_governance.schemas.shrapnel import ShrapnelMap, ShrapnelFragment, ResistanceCertificate

def test_builder_admission_flow():
    # 1. Setup Policy
    policy = BuilderPolicy(min_tau_threshold=0.80, require_certificate=True)
    builder = BuilderEngine(policy=policy)
    
    # 2. Create high-tau ShrapnelMap with certificate
    good_fragment = ShrapnelFragment(
        target_id="Met",
        baseline_intent="stability",
        test_suite=["ramp"],
        observed_drift={"drift": 0.05},
        fragility_class="robust",
        tether_tension=0.95,
        tier="S"
    )
    
    cert = ResistanceCertificate(
        scope="Metallurgical",
        attestation="Validated under cyclic stress",
        signature_metadata={"key": "val"},
        tier="S"
    )
    
    shrapnel_map_ok = ShrapnelMap(
        fragments=[good_fragment],
        resistance_certificate=cert,
        overall_tau=0.90,
        coverage=1.0,
        tier="S"
    )
    
    # 3. Test successful admission
    proposal_ok = builder.propose(shrapnel_map_ok, "Production Update")
    assert proposal_ok.admission_status == "ACCEPTED"
    assert proposal_ok.provenance["fragment_count"] == 1
    
    # 4. Create low-tau ShrapnelMap
    shrapnel_map_bad = shrapnel_map_ok.model_copy(update={"overall_tau": 0.50})
    proposal_bad = builder.propose(shrapnel_map_bad, "Production Update")
    assert proposal_bad.admission_status == "REJECTED"
    assert any("tau" in r for r in proposal_bad.rejection_reasons)
    
    # 5. Test banned fragility class (Partial Admission/Review)
    bad_fragment = good_fragment.model_copy(update={"fragility_class": "impedance-spike-precursor"})
    shrapnel_map_mixed = shrapnel_map_ok.model_copy(update={"fragments": [good_fragment, bad_fragment]})
    proposal_mixed = builder.propose(shrapnel_map_mixed, "Production Update")
    assert proposal_mixed.admission_status == "PENDING_REVIEW"
    assert len(proposal_mixed.fragments) == 1
    assert any("Partial admission" in r for r in proposal_mixed.rejection_reasons)
