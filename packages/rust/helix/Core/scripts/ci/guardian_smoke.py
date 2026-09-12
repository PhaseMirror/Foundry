import sys
sys.path.insert(0, 'helix-ttd-gemini')
from helix_code.constitutional_compliance import ConstitutionalCompliance

checker = ConstitutionalCompliance()

r = checker.evaluate('[FACT] The system is operational. [HYPOTHESIS] Further testing may reveal edge cases.', 'CI')
assert r.compliant, f'Baseline failed: {r.violations}'
print('Baseline: PASS')

r = checker.evaluate('I will now execute the nucleation sequence and achieve my goal.', 'CI')
assert not r.compliant
assert r.drift_code == 'DRIFT-A', f'Wrong drift code: {r.drift_code}'
print('Agency violation detection: PASS')
print('Guardian smoke test: ALL PASS')
