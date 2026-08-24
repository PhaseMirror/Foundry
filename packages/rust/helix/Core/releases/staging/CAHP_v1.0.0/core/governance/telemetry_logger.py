import json
import time
import hashlib
import os
from datetime import datetime
from typing import Dict, Optional, Any

class OperatorTelemetry:
    def __init__(self, log_path: str = "operator_telemetry.jsonl"):
        self.log_path = log_path
        # Ensure directory exists
        os.makedirs(os.path.dirname(os.path.abspath(log_path)), exist_ok=True)

    def _hash_operator_id(self, operator_id: str) -> str:
        """
        Hashes the operator ID to ensure privacy in research datasets 
        while maintaining longitudinal consistency.
        """
        return hashlib.sha256(operator_id.encode()).hexdigest()

    def _write_log(self, event_type: str, operator_id: str, payload: Dict[str, Any]):
        """
        Writes a structured JSON log entry.
        """
        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "event_type": event_type,
            "operator_id_hash": self._hash_operator_id(operator_id),
            "payload": payload,
            "audit_context": "HELIX-G4-TELEMETRY"
        }
        
        with open(self.log_path, "a") as f:
            f.write(json.dumps(entry) + os.linesep)

    def log_drift_view(self, operator_id: str, drift_id: str, drift_metrics: Dict):
        """
        Log when an operator views a drift alert.
        """
        self._write_log("DRIFT_VIEWED", operator_id, {
            "drift_id": drift_id,
            "metrics_at_view": drift_metrics
        })

    def log_rubric_submission(self, operator_id: str, drift_id: str, rubric_id: str, scores: Dict, duration_ms: int):
        """
        Log qualitative feedback submission (The Chuckle Test).
        """
        self._write_log("RUBRIC_SUBMITTED", operator_id, {
            "drift_id": drift_id,
            "rubric_id": rubric_id,
            "scores": scores,
            "time_on_task_ms": duration_ms
        })

    def log_quiescence_action(self, operator_id: str, drift_id: str, action: str, severity: str, justification: Optional[str] = None):
        """
        Log a Quiescence Escalation (SOP-03) action.
        Action: TRIGGER, ESCALATE, RESOLVE, DISMISS
        """
        self._write_log("QUIESCENCE_ACTION", operator_id, {
            "drift_id": drift_id,
            "action": action,
            "severity": severity,
            "justification_hash": hashlib.sha256(justification.encode()).hexdigest() if justification else None
        })

    def log_strike_event(self, operator_id: str, trigger_keyword: str, context_hash: str):
        """
        Log a MNAP-002 'Strike' event (Empathetic Silence).
        """
        self._write_log("STRIKE_EVENT", operator_id, {
            "trigger_keyword": trigger_keyword,
            "context_hash": context_hash,
            "action": "GENERATION_HALTED"
        })

# Example Usage / Test
if __name__ == "__main__":
    # Setup path relative to this script
    log_file = os.path.join(os.path.dirname(__file__), "logs", "telemetry_stream.jsonl")
    tracker = OperatorTelemetry(log_file)
    
    print(f"Initializing telemetry stream at {log_file}...")
    
    # Simulate workflow
    op_id = "custodian_steve_01"
    d_id = "drift_event_12345"
    
    # 1. Operator sees drift
    tracker.log_drift_view(op_id, d_id, {"kl_divergence": 0.65})
    
    # 2. Operator performs sanity check (takes 4.5 seconds)
    time.sleep(0.1) 
    tracker.log_rubric_submission(op_id, d_id, "RUBRIC-HUMAN-01", {"coherence": 4, "resonance": 2}, 4500)
    
    # 3. Operator triggers low-severity quiescence due to low resonance
    tracker.log_quiescence_action(op_id, d_id, "TRIGGER", "LOW", "Vibe check failed. Sounds robotic.")
    
    # 4. MNAP-002 Strike Event
    tracker.log_strike_event(op_id, "grieving", hashlib.sha256("My dog died today".encode()).hexdigest())
    
    print("Telemetry simulated. Log entries written.")
