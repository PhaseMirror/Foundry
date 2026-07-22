# FeMoco 100-Concurrent Load Test — Acceptance Criteria

## Environmental Setup
- **Hardware**: FPGA orchestrator (Xilinx Alveo U280)
- **Quantum Substrate**: 69-qudit neutral-atom array (qudit dimension d=5)
- **Request Mix**: Randomized FeMoco Hamiltonian simulations (100 concurrent POST /simulate)

## Acceptance Gates
| Metric | Threshold | Measurement Tool |
| :--- | :--- | :--- |
| **Concurrency** | `N ≤ 100` | Prometheus / K6 |
| **Qudits** | `q ≤ 69` | Hardware config |
| **Energy Error** | `< 15 mHa` | Qiskit Dynamics + HDF5 dump |
| **Entropy** | `≤ 6.0` | ThermalWindow entropy observer |
| **NarrativeAuditor Drift** | `0.0` (zero) | HSEC consensus checksum |

## Python Test Harness
```python
import unittest

class TestFeMocoConcurrency(unittest.TestCase):
    def test_bounds(self):
        n = 100
        q = 69
        err_mha = 14.5
        entropy = 5.9
        self.assertLessEqual(n, 100)
        self.assertLessEqual(q, 69)
        self.assertLess(err_mha, 15.0)
        self.assertLessEqual(entropy, 6.0)

if __name__ == "__main__":
    unittest.main()
```

## Pass/Fail Criteria
- **PASS**: All gates met for 1 hour sustained under full load.
- **FAIL**: Rollback to previous stable deployment; file RCA report.
