import time
import json
import os
from hypergraph.distance import compute_distance

def test_five_wash_identical():
    # 5 identical wash actions at sequential timesteps
    nodes_g = [{"id": f"a{i}", "type": "wash", "time": i} for i in range(5)]
    nodes_h = [{"id": f"a{i}", "type": "wash", "time": i} for i in range(5)]
    
    start = time.perf_counter()
    dist, hash_val = compute_distance(nodes_g, nodes_h)
    end = time.perf_counter()
    
    assert dist == 0.0, f"Expected d(G, G) == 0.0, got {dist}"
    
    # Load golden hash
    golden_path = os.path.join(os.path.dirname(__file__), 'test_data', 'golden_hashes.json')
    with open(golden_path, 'r') as f:
        golden_hashes = json.load(f)
    
    expected_hash = golden_hashes['5_wash_identical']
    assert hash_val == expected_hash, f"Hash mismatch! Expected {expected_hash}, got {hash_val}"
    
    print(f"5 Wash test passed in {end - start:.6f} seconds")
    print(f"Cryptographic Signature: {hash_val}")

if __name__ == "__main__":
    test_five_wash_identical()
