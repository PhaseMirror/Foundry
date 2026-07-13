import numpy as np
import hashlib
import json
from scipy.optimize import linear_sum_assignment

def pad_and_build_cost_matrix(actions_g, actions_h, dummy_penalty=1000.0, temporal_weight=1e-5):
    """
    Constructs a padded cost matrix C for the Hungarian algorithm.
    Integrates Patch B (Temporal symmetry breaking) and Patch D (Deterministic sorting).
    """
    n_g = len(actions_g)
    n_h = len(actions_h)
    N = max(n_g, n_h)
    
    # Patch D: Sort action IDs for deterministic evaluation
    actions_g = sorted(actions_g, key=lambda a: a['id'])
    actions_h = sorted(actions_h, key=lambda a: a['id'])
    
    # Patch B: Padding with high dummy penalty
    C = np.full((N, N), dummy_penalty)
    
    for i in range(n_g):
        for j in range(n_h):
            ag, ah = actions_g[i], actions_h[j]
            # Base semantic distance
            base_dist = 0.0 if ag['type'] == ah['type'] else 10.0
            
            # Patch B: Temporal symmetry breaking for identical operations
            temp_dist = temporal_weight * abs(ag['time'] - ah['time'])
            
            C[i, j] = base_dist + temp_dist
            
    return C, actions_g, actions_h

def generate_lawful_recursion_hash(graph_g, graph_h, distance_value):
    """
    Signs the distance metric by binding it to the canonical state-traces 
    of the hypergraphs G and H. 
    """
    def canonical_repr(graph):
        sorted_nodes = sorted(graph, key=lambda x: x['id'])
        return json.dumps(sorted_nodes, sort_keys=True)

    payload = {
        "graph_g": canonical_repr(graph_g),
        "graph_h": canonical_repr(graph_h),
        "distance": f"{distance_value:.12f}",
        "schema_version": "L0-Scope-Bound-V1"
    }
    
    payload_str = json.dumps(payload, sort_keys=True)
    return hashlib.sha256(payload_str.encode()).hexdigest()

def compute_distance(g_nodes, h_nodes):
    C, ag, ah = pad_and_build_cost_matrix(g_nodes, h_nodes)
    row_ind, col_ind = linear_sum_assignment(C)
    dist = C[row_ind, col_ind].sum()
    hash_val = generate_lawful_recursion_hash(g_nodes, h_nodes, dist)
    return dist, hash_val
