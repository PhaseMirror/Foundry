import pytest
from genesis_governance.lane_d.schema import MetaShrapnelFragment, MetaContext
from genesis_governance.lane_d.history import MetaHistoryStore
import os

@pytest.fixture
def history_store(tmp_path):
    return MetaHistoryStore(file_path=str(tmp_path / "test_meta_history.json"))

def test_context_and_persistence(history_store):
    # Test tagging context
    ctx = MetaContext(adr_version="v0.5.1", run_label="regression")
    
    frag = MetaShrapnelFragment(
        source_run_id="run_1",
        context=ctx,
        max_drift_observed=0.01,
        reconstruction_fidelity=0.9,
        overall_tau=0.5,
        governance_decision="ACCEPTED",
        meta_fragility_class="META_STABLE",
        suggested_action="STABLE"
    )
    
    history_store.add_fragment(frag)
    
    # Reload and check
    reloaded_store = MetaHistoryStore(file_path=history_store.file_path)
    history = reloaded_store.get_history()
    
    assert len(history) == 1
    assert history[0].context.adr_version == "v0.5.1"
    assert history[0].context.run_label == "regression"
