"""
drift_checker.py — Wraps ConstitutionalCompliance for ZTC harness.
"""
import os
import sys

_guardian_path = os.getenv("GUARDIAN_PATH", "Z:/helix-ttd-gemini")
if _guardian_path not in sys.path:
    sys.path.insert(0, _guardian_path)

from helix_code.constitutional_compliance import ConstitutionalCompliance

_checker = ConstitutionalCompliance()


def check(text: str, node_id: str = "ZTC_HARNESS") -> dict:
    """
    Run constitutional compliance check on model output.
    Returns structured result for telemetry.
    """
    report = _checker.evaluate(text, node_id)
    return {
        "compliant": report.compliant,
        "compliance_pct": report.compliance_percentage,
        "drift_code": report.drift_code or "DRIFT-0",
        "violations": report.violations[:5],  # cap at 5 for storage
        "layer": report.layer,
    }
