import pytest
import numpy as np
from genesis_governance.multiplicity.allocator import PrimeBandAllocator
from genesis_governance.shared.history import HistoryStore
from genesis_governance.schemas.shrapnel import ShrapnelMap, ShrapnelFragment

@pytest.fixture
def history_file(tmp_path):
    return str(tmp_path / "test_history.json")

@pytest.fixture
def history_store(history_file):
    return HistoryStore(file_path=history_file)

def test_sensitivity_sweep_triggers_reallocation(history_store):
    allocator = PrimeBandAllocator(history=history_store)
    
    # Initial mapping
    assert allocator.current_mapping["logical_state"] == 7
    
    # Add some poor reconstruction history
    bad_fragments = []
    for _ in range(60):
        bad_fragments.append(ShrapnelFragment(
            target_id="Semi",
            baseline_intent="stability",
            test_suite=["timing_jitter"],
            observed_drift={"coherence_drift": 0.1},
            fragility_class="robust",
            tether_tension=0.0,
            tier="S",
            metadata={"multiplicity": {"reconstruction_score": 0.5, "locality_delta": 0.2}}
        ))
    
    bad_run = ShrapnelMap(fragments=bad_fragments, overall_tau=1.0, coverage=1.0, tier="S")
    history_store.add_run(bad_run)
    
    # Run sweep
    reallocated = allocator.sensitivity_sweep(score_threshold=0.8, delta_threshold=0.15)
    
    assert reallocated is True
    # Logic in allocator.py: if logical_state == 7, shift to 11
    assert allocator.current_mapping["logical_state"] == 11

def test_banded_allocation_invariants():
    allocator = PrimeBandAllocator()
    mapping = allocator.allocate()
    
    # Continuous dynamics should be in Band A [2, 3, 5]
    assert mapping["coherence"] in [2, 3, 5]
    assert mapping["effective_stress"] in [2, 3, 5]
    
    # Categorical should be in Band B [7, 11]
    assert mapping["logical_state"] in [7, 11]
    
    # Context should be in Band C [13, 17, 19]
    assert mapping["frequency"] in [13, 17, 19]
    assert mapping["coupling"] in [13, 17, 19]
