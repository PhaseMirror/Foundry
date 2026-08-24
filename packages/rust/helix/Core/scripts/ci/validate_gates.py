import json

with open('research/physics-gate/checksums/slope_ub_result.json') as f:
    r = json.load(f)
assert r['gate_pass'] == True, 'Phase 5 gate not passing'
assert r['exit_criteria']['ryan_countersignature'] == True, 'Missing countersignature'
print('Phase 5 gate: PASS')

with open('research/physics-gate/checksums/strain_test_results.json') as f:
    s = json.load(f)
assert s['wobble_breaches'] == 0, 'Wobble breaches detected'
print('Strain test: PASS - zero wobble breaches')
