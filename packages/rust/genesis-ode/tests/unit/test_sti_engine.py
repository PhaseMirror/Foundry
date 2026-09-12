import pytest
import numpy as np
from genesis_governance.lane_d.sti_engine import STIEngine

def test_sti_engine_basic():
    engine = STIEngine()
    
    texts = ["Logic is truth.", "Logic is truth."]
    inference_tree = {"resolvable_paths": 10, "total_branches": 10}
    ethics_emb = np.array([0.1, 0.2, 0.3])
    
    # First call drift should be 0
    results = engine.compute_sti(texts, inference_tree, ethics_emb)
    
    assert results["sti"] > 0
    assert results["theta_audit"] == 1.0
    assert results["delta_drift"] == 0.0
    
    # Second call with drift
    ethics_emb_2 = np.array([0.2, 0.3, 0.4])
    results_2 = engine.compute_sti(texts, inference_tree, ethics_emb_2)
    
    assert results_2["delta_drift"] > 0.0
    assert results_2["sti"] < results["sti"]
